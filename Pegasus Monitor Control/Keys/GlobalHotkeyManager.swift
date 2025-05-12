// GlobalHotkeyManager.swift

import Cocoa
import SwiftUI
import Combine

class GlobalHotkeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private weak var viewModel: DDCViewModel?
    
    private var requiredModifiers: CGEventFlags = []
    private var activeModifier1: ModifierKeyOption = .control
    private var activeModifier2: ModifierKeyOption = .none
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: DDCViewModel) {
        self.viewModel = viewModel
        print("GlobalHotkeyManager: Initializing with viewModel.")
        
        viewModel.$hasAccessibilityPermissions
            .print("GlobalHotkeyManager.hasAccessibilityPermissions")
            .sink { [weak self] hasPermissions in
                guard let self = self else {
                    print("GlobalHotkeyManager.sink: self is nil, bailing.")
                    return
                }
                print("GlobalHotkeyManager.sink: Received hasPermissions = \(hasPermissions)")
                self.handlePermissionChange(hasPermissions: hasPermissions)
            }
            .store(in: &cancellables)
        
        // Check initial permission state RIGHT AFTER subscribing
        if viewModel.hasAccessibilityPermissions {
            print("GlobalHotkeyManager.init: Permissions were already true. Manually triggering handlePermissionChange.")
            handlePermissionChange(hasPermissions: true)
        } else {
            print("GlobalHotkeyManager.init: Permissions are currently false.")
        }
    }
    
    func updateModifiers(mod1: ModifierKeyOption, mod2: ModifierKeyOption) {
        self.activeModifier1 = mod1
        self.activeModifier2 = mod2
        
        var flags: CGEventFlags = []
        if let mask1 = mod1.cgEventFlag { flags.insert(mask1) }
        if let mask2 = mod2.cgEventFlag, mod1 != mod2 { flags.insert(mask2) }
        self.requiredModifiers = flags
        
        print(
            "GlobalHotkeyManager: Modifiers updated. Active: \(mod1.description) + \(mod2.description). Required CGEventFlags: \(flags.rawValue)"
        )
    }
    
    private func handlePermissionChange(hasPermissions: Bool) {
        print("GlobalHotkeyManager.handlePermissionChange: Called with hasPermissions = \(hasPermissions)") // Log 3
        if hasPermissions {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in // Small delay
                self?.startMonitoring()
            }
        } else {
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        print("GlobalHotkeyManager.startMonitoring: Attempting to start...") // Log 4
        
        guard eventTap == nil else {
            print("GlobalHotkeyManager.startMonitoring: Already monitoring (eventTap is not nil). No action.") // Log 4.1
            return
        }
        
        guard let strongViewModel = self.viewModel else {
            print("GlobalHotkeyManager.startMonitoring: ViewModel is nil. Cannot start.") // Log 4.2
            return
        }
        
        guard strongViewModel.hasAccessibilityPermissions else {
            print("GlobalHotkeyManager.startMonitoring: ViewModel reports NO permissions (hasAccessibilityPermissions is false). Cannot start.") // Log 4.3
            return
        }
        print("GlobalHotkeyManager.startMonitoring: All initial guards passed. Proceeding to create event tap.") // Log 4.4
        
        let eventCallback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard type == .keyDown else {
                return Unmanaged.passRetained(event)
            }
            
            guard let manager = refcon.map({ Unmanaged<GlobalHotkeyManager>.fromOpaque($0).takeUnretainedValue() }) else {
                print("Event tap: Could not get manager reference from refcon. Passing event.")
                return Unmanaged.passRetained(event)
            }
            
            if manager.handleKeyDown(event: event) {
                return nil
            }
            return Unmanaged.passRetained(event)
        }
        
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: eventCallback,
            userInfo: refcon
        )
        
        guard let eventTap = eventTap else {
            print("GlobalHotkeyManager.startMonitoring: CRITICAL - CGEvent.tapCreate FAILED (returned nil). Check Input Monitoring permissions in System Settings.")
            strongViewModel.updateStatus("Hotkeys disabled. Grant Input Monitoring permission.")
            return
        }
        print("GlobalHotkeyManager.startMonitoring: CGEvent.tapCreate SUCCEEDED.")
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            print("GlobalHotkeyManager.startMonitoring: Event tap enabled and run loop source added. Monitoring active.")
        } else {
            print("GlobalHotkeyManager.startMonitoring: FAILED to create run loop source.")
            self.eventTap = nil
            strongViewModel.updateStatus("Error: Could not start hotkey listener.")
        }
    }
    
    private func stopMonitoring() {
        print("GlobalHotkeyManager.stopMonitoring: Attempting to stop...")
        guard eventTap != nil else {
            print("GlobalHotkeyManager.stopMonitoring: Not monitoring (eventTap is nil). No action.")
            return
        }
        
        if let currentEventTap = self.eventTap {
            CGEvent.tapEnable(tap: currentEventTap, enable: false)
            print("GlobalHotkeyManager.stopMonitoring: CGEvent.tapEnable(false) called.")
        }
        
        if let currentRunLoopSource = self.runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), currentRunLoopSource, .commonModes)
            print("GlobalHotkeyManager.stopMonitoring: CFRunLoopRemoveSource called.")
            self.runLoopSource = nil
        }
        
        self.eventTap = nil
        print("GlobalHotkeyManager.stopMonitoring: Event tap stopped successfully (eventTap and runLoopSource nilled).")
    }
    
    private func handleKeyDown(event: CGEvent) -> Bool {
        guard let viewModel = viewModel else {
            return false
        }
        
        
        if activeModifier1 == .none && (activeModifier2 == .none || activeModifier1 == activeModifier2) && requiredModifiers.isEmpty {
            return false
        }
        
        let eventFlags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let relevantEventFlags = eventFlags.intersection([.maskShift, .maskControl, .maskAlternate, .maskCommand])
        
        
        if relevantEventFlags != requiredModifiers {
            return false
        }
        
        var navCommand: VCP.Values.OSDNavCommand?
        switch keyCode {
            case VCP.Values.KeyCodes.kVK_UpArrow: navCommand = .up
            case VCP.Values.KeyCodes.kVK_DownArrow: navCommand = .down
            case VCP.Values.KeyCodes.kVK_LeftArrow: navCommand = .left
            case VCP.Values.KeyCodes.kVK_RightArrow: navCommand = .right
            case VCP.Values.KeyCodes.kVK_ANSI_0: navCommand = .open
            case VCP.Values.KeyCodes.kVK_Return: navCommand = .select
            case VCP.Values.KeyCodes.kVK_ANSI_KeypadEnter: navCommand = .select
            case VCP.Values.KeyCodes.kVK_Escape: navCommand = .exit
            default:
                break
        }
        
        if let command = navCommand {
            print("GlobalHotkeyManager: Matched OSD command: \(command) for key code \(keyCode) with modifiers.")
            DispatchQueue.main.async {
                viewModel.writeDDC(command: VCP.Codes.OSD_CONTROL, value: command.rawValue) { success, message in
                    if !success {
                        let errorMsg = "Global OSD Nav Error (key \(keyCode)) sending \(command): \(message)"
                        print(errorMsg)
                        viewModel.updateStatus(errorMsg)
                    } else {
                        print("Global OSD Nav Command \(command) (key \(keyCode)) sent successfully.")
                    }
                }
            }
            return true
        }
        return false
    }
    
    deinit {
        print("GlobalHotkeyManager: Deinitializing...")
        stopMonitoring()
        cancellables.forEach { $0.cancel() }
        print("GlobalHotkeyManager deinitialized fully.")
    }
}
