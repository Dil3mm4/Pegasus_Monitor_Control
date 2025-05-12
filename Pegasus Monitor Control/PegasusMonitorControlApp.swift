//
//  PegasusMonitorControlApp.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

import Cocoa
import SwiftUI

@main
struct PegasusMonitorControlApp: App {
    @StateObject private var viewModel = DDCViewModel()
    @StateObject private var hotkeyManagerContainer = HotkeyManagerContainer()
    
    @AppStorage("osdModifier1")
    private var osdModifier1Raw: String = ModifierKeyOption.control.rawValue
    @AppStorage("osdModifier2")
    private var osdModifier2Raw: String = ModifierKeyOption.none.rawValue
    
    private var combinedModifiers: EventModifiers {
        var modifiers: EventModifiers = []
        let mod1 = ModifierKeyOption(rawValue: osdModifier1Raw) ?? .control
        let mod2 = ModifierKeyOption(rawValue: osdModifier2Raw) ?? .none
        
        if let mask1 = mod1.keyMask {
            modifiers.insert(mask1)
        }
        if let mask2 = mod2.keyMask, mod1 != mod2 {
            modifiers.insert(mask2)
        }
        return modifiers
    }
    
    class HotkeyManagerContainer: ObservableObject {
        var manager: GlobalHotkeyManager?
        
        func setupOrUpdate(
            viewModel: DDCViewModel,
            mod1Raw: String,
            mod2Raw: String
        ) {
            print("HotkeyManagerContainer.setupOrUpdate: Called.") // Log A
            if manager == nil {
                print("HotkeyManagerContainer.setupOrUpdate: GlobalHotkeyManager is nil, creating new instance.") // Log B
                self.manager = GlobalHotkeyManager(viewModel: viewModel)
                // Log B.1 is now inside GlobalHotkeyManager.init
            } else {
                print("HotkeyManagerContainer.setupOrUpdate: GlobalHotkeyManager instance already exists.") // Log C
            }
            
            let m1 = ModifierKeyOption(rawValue: mod1Raw) ?? .control
            let m2 = ModifierKeyOption(rawValue: mod2Raw) ?? .none
            self.manager?.updateModifiers(mod1: m1, mod2: m2)
            
            print("HotkeyManagerContainer.setupOrUpdate: Current viewModel.hasAccessibilityPermissions = \(viewModel.hasAccessibilityPermissions)") // Log E
        }
    }
    init() {
        print(">>> DDCTest_App Initializing")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    hotkeyManagerContainer.setupOrUpdate(
                        viewModel: viewModel,
                        mod1Raw: osdModifier1Raw,
                        mod2Raw: osdModifier2Raw
                    )
                }
        }
        .onChange(of: osdModifier1Raw) { newValue in
            hotkeyManagerContainer.setupOrUpdate(
                viewModel: viewModel,
                mod1Raw: newValue,
                mod2Raw: osdModifier2Raw
            )
        }
        .onChange(of: osdModifier2Raw) { newValue in
            hotkeyManagerContainer.setupOrUpdate(
                viewModel: viewModel,
                mod1Raw: osdModifier1Raw,
                mod2Raw: newValue
            )
        }
        .commands {
            CommandMenu("OSD Navigation") {
                Button("Navigate Up") { sendOSDNavCommandViaViewModel(VCP.Values.OSDNavCommand.up) }
                    .keyboardShortcut(.upArrow, modifiers: combinedModifiers)
                
                Button("Navigate Down") { sendOSDNavCommandViaViewModel(VCP.Values.OSDNavCommand.down) }
                    .keyboardShortcut(.downArrow, modifiers: combinedModifiers)
                
                Button("Navigate Left") { sendOSDNavCommandViaViewModel(VCP.Values.OSDNavCommand.left) }
                    .keyboardShortcut(.leftArrow, modifiers: combinedModifiers)
                
                Button("Navigate Right") {
                    sendOSDNavCommandViaViewModel(VCP.Values.OSDNavCommand.right)
                }
                .keyboardShortcut(.rightArrow, modifiers: combinedModifiers)
                
                Button("Open OSD") { sendOSDNavCommandViaViewModel(VCP.Values.OSDNavCommand.open) }
                    .keyboardShortcut("0", modifiers: combinedModifiers)  // Use key '0'
                
                Button("Select/Confirm OSD") {
                    sendOSDNavCommandViaViewModel(VCP.Values.OSDNavCommand.select)
                }
                .keyboardShortcut(.return, modifiers: combinedModifiers)  // Use Enter/Return key
                
                Button("Exit OSD") { sendOSDNavCommandViaViewModel(VCP.Values.OSDNavCommand.exit) }
                    .keyboardShortcut(.escape, modifiers: combinedModifiers)  // Use Escape key
            }
        }
        
        MenuBarExtra {
            MenuBarExtraContentView()
                .environmentObject(viewModel)
                .onAppear {
                    hotkeyManagerContainer.setupOrUpdate(
                        viewModel: viewModel,
                        mod1Raw: osdModifier1Raw,
                        mod2Raw: osdModifier2Raw
                    )
                }
        } label: {
            Image(systemName: "display.and.arrow.down")
        }.menuBarExtraStyle(.window)
    }
    
    private func sendOSDNavCommandViaViewModel(
        _ commandValue: VCP.Values.OSDNavCommand
    ) {
        print(
            "Sending OSD Nav Command from App Scene: \(commandValue) (DDC Value: \(commandValue.rawValue))"
        )
        guard viewModel.selectedDisplayID != nil else {
            let errorMsg = "OSD Nav Error: No monitor selected."
            print(errorMsg)
            viewModel.updateStatus(errorMsg)
            return
        }
        
        viewModel.writeDDC(
            command: VCP.Codes.OSD_CONTROL,
            value: commandValue.rawValue
        ) { success, message in
            if !success {
                let errorMsg =
                "OSD Nav Error sending \(commandValue): \(message)"
                print(errorMsg)
                viewModel.updateStatus(errorMsg)
            } else {
                print(
                    "OSD Nav Command \(commandValue) sent successfully from App Scene."
                )
            }
        }
    }
}

extension Bundle {
    var appName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}
