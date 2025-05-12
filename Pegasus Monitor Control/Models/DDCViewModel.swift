// DDCViewModel.swift

import Combine
import CoreGraphics
import IOKit
import SwiftUI
import os
import AppKit
import ApplicationServices

extension Arm64DDC.Arm64Service: Identifiable {
    public var id: CGDirectDisplayID { self.displayID }
}

class DDCViewModel: ObservableObject {
    @Published var matchedServices: [Arm64DDC.Arm64Service] = []
    @Published var selectedDisplayID: CGDirectDisplayID? = nil {
        didSet {
            handleMonitorSelectionChange(from: oldValue, to: selectedDisplayID)
        }
    }
    @Published var statusMessage: String = "Initializing..."
    @Published var isScanning: Bool = false
    @Published var selectedSidebarIdentifier: String? = "GameVisual"
    @Published var hasAccessibilityPermissions: Bool = false
    
    private static let ddcQueue = DispatchQueue(
        label: "beef.code.PegasusMonitorControl.ddcQueue",
        qos: .userInitiated
    )
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "beef.code.PegasusMonitorControl",
        category: "DDCViewModel"
    )
    
    let targetMonitorName = "PG27UCDM"
    
    var selectedService: IOAVService? {
        guard let id = selectedDisplayID else { return nil }
        return matchedServices.first { $0.displayID == id }?.service
    }
    
    var selectedMonitorName: String {
        guard selectedDisplayID != nil, let monitor = matchedServices.first
        else {
            return "No Monitor Selected"
        }
        return monitor.serviceDetails.productName.isEmpty
        ? "Unknown (\(monitor.displayID))"
        : monitor.serviceDetails.productName
    }
    
    var isTargetMonitorConnected: Bool {
        !matchedServices.isEmpty && selectedDisplayID != nil
    }
    
    init() {
        logger.debug("DDCViewModel Initialized for \(self.targetMonitorName)")
        // + Add these lines to check permissions on init and observe app activation
        checkAccessibilityPermissions()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        logger.info("App became active, re-checking accessibility permissions.")
        checkAccessibilityPermissions()
    }
    
    func checkAccessibilityPermissions(promptUserIfNeeded: Bool = false) {
        let optionsKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [optionsKey: promptUserIfNeeded] as CFDictionary
        
        let systemPermissionStatus = AXIsProcessTrustedWithOptions(options)
        logger.info("Accessibility: AXIsProcessTrustedWithOptions returned: \(systemPermissionStatus)")
        
        if systemPermissionStatus != self.hasAccessibilityPermissions {
            DispatchQueue.main.async {
                self.hasAccessibilityPermissions = systemPermissionStatus
                self.logger.info("Accessibility: DDCViewModel.hasAccessibilityPermissions updated to: \(self.hasAccessibilityPermissions)")
            }
        } else {
            logger.info("Accessibility: DDCViewModel.hasAccessibilityPermissions already \(self.hasAccessibilityPermissions). No change.")
        }
    }
    
    func openAccessibilitySystemSettings() {
        logger.info("Attempting to open Accessibility System Settings.")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            logger.warning("Could not construct specific Accessibility URL, trying general Security & Privacy.")
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                NSWorkspace.shared.open(url)
            } else {
                logger.error("Could not construct URL for System Settings.")
                DispatchQueue.main.async {
                    self.updateStatus("Error: Could not open System Settings.")
                }
            }
        }
    }
    
    private func handleMonitorSelectionChange(
        from oldID: CGDirectDisplayID?,
        to newID: CGDirectDisplayID?
    ) {
        updateStatusBasedOnSelection()
        if oldID != newID {
            logger.log(
                "Monitor selection changed from \(oldID ?? 0) to \(newID ?? 0)"
            )
        }
    }
    
    func updateStatusBasedOnSelection() {
        if isTargetMonitorConnected {
            updateStatus("Selected: \(selectedMonitorName)")
        } else if !matchedServices.isEmpty && selectedDisplayID == nil {
            updateStatus(
                "Error: \(self.targetMonitorName) found but not selected."
            )
        } else {
            updateStatus(
                "\(self.targetMonitorName) not detected. Please connect the monitor."
            )
        }
    }
    
    func scanMonitors(completion: (() -> Void)? = nil) {
#if arch(arm64)
        guard Arm64DDC.isArm64 else {
            logger.warning("Scan: Not on Arm64 architecture.")
            updateStatus("Requires Apple Silicon Mac (ARM64).")
            DispatchQueue.main.async {
                self.matchedServices = []
                self.selectedDisplayID = nil
                self.isScanning = false
                completion?()
            }
            return
        }
        
        logger.info("Scan: Starting for \(self.targetMonitorName)")
        DispatchQueue.main.async {
            self.isScanning = true
            self.updateStatus("Scanning for \(self.targetMonitorName)...")
        }
        
        DDCViewModel.ddcQueue.async { [weak self] in
            guard let self = self else { return }
            self.logger.debug("Scan BG: Performing scan...")
            let foundTargetService =
            self.performTargetMonitorScanInBackground()
            
            DispatchQueue.main.async {
                self.logger.debug("Scan: Results received on main thread.")
                self.isScanning = false
                
                if let targetService = foundTargetService {
                    self.logger.info(
                        "Scan Result: \(self.targetMonitorName) FOUND."
                    )
                    self.matchedServices = [targetService]
                    self.selectedDisplayID = targetService.displayID
                } else {
                    self.logger.info(
                        "Scan Result: \(self.targetMonitorName) NOT found."
                    )
                    self.matchedServices = []
                    self.selectedDisplayID = nil
                }
                self.updateStatusBasedOnSelection()
                self.logger.debug("Scan: UI update complete.")
                completion?()
            }
        }
#else
        logger.warning("Scan: Not on Arm64 architecture (build target).")
        updateStatus(
            "Application built for Intel. DDC control not available."
        )
        DispatchQueue.main.async {
            self.matchedServices = []
            self.selectedDisplayID = nil
            self.isScanning = false
            completion?()
        }
#endif
    }
    
    private func performTargetMonitorScanInBackground() -> Arm64DDC
        .Arm64Service?
    {
#if arch(arm64)
        logger.debug("Scan BG: Getting active display list...")
        var displayCount: UInt32 = 0
        var cgError = CGGetActiveDisplayList(0, nil, &displayCount)
        guard cgError == .success, displayCount > 0 else {
            logger.error(
                "Scan BG Error: CGGetActiveDisplayList count failed (\(cgError.rawValue)) or count is 0."
            )
            DispatchQueue.main.async {
                self.updateStatus(
                    "Error: Could not get display count (\(cgError.rawValue))."
                )
            }
            return nil
        }
        
        var displayIDs = [CGDirectDisplayID](
            repeating: 0,
            count: Int(displayCount)
        )
        cgError = CGGetActiveDisplayList(
            displayCount,
            &displayIDs,
            &displayCount
        )
        guard cgError == .success else {
            logger.error(
                "Scan BG Error: CGGetActiveDisplayList IDs failed: \(cgError.rawValue)"
            )
            DispatchQueue.main.async {
                self.updateStatus(
                    "Error: Could not get display list (\(cgError.rawValue))."
                )
            }
            return nil
        }
        
        logger.debug("Scan BG: Found display IDs: \(displayIDs)")
        logger.debug(
            "Scan BG: Calling Arm64DDC.getServiceMatches and filtering for '\(self.targetMonitorName)'..."
        )
        let allServices = Arm64DDC.getServiceMatches(displayIDs: displayIDs)
        
        let targetService = allServices.first { service in
            !service.dummy && !service.discouraged
            && service.serviceDetails.productName.uppercased().contains(
                self.targetMonitorName.uppercased()
            )
        }
        
        if let service = targetService {
            logger.debug(
                "Scan BG: \(self.targetMonitorName) found with ID \(service.displayID)."
            )
            return service
        } else {
            logger.debug(
                "Scan BG: \(self.targetMonitorName) not found among services."
            )
            return nil
        }
#else
        return nil
#endif
    }
    
    func writeDDC(
        command: UInt8,
        value: UInt16,
        completion: ((Bool, String) -> Void)? = nil
    ) {
        guard isTargetMonitorConnected, let service = selectedService else {
            let msg =
            "Set Error: \(self.targetMonitorName) not connected or service unavailable."
            logger.error("DDC Write Error: \(msg)")
            updateStatus(msg)
            completion?(false, msg)
            return
        }
        let monitorName = selectedMonitorName
        let commandHex = String(format: "0x%02X", command)
        let msg =
        "Queueing Write \(commandHex) = \(value) for \(monitorName)..."
        updateStatus(msg)
        logger.debug("\(msg)")
        
        DDCViewModel.ddcQueue.async { [weak self] in
            guard let self = self else { return }
            self.logger.debug(
                "DDC Write BG: Executing \(commandHex) = \(value) for \(monitorName)..."
            )
            let success = Arm64DDC.write(
                service: service,
                command: command,
                value: value,
                numOfWriteCycles: 1
            )
            
            DispatchQueue.main.async {
                let resultMessage: String
                if success {
                    resultMessage =
                    "Set OK: \(commandHex) = \(value) for \(monitorName)."
                    self.logger.debug("DDC Write Success for \(monitorName).")
                } else {
                    resultMessage =
                    "Set FAILED: Could not set \(commandHex) for \(monitorName)."
                    self.logger.error("DDC Write Failed for \(monitorName).")
                }
                if !success || self.statusMessage != resultMessage {
                    self.updateStatus(resultMessage)
                }
                completion?(success, resultMessage)
            }
        }
    }
    
    func readDDC(
        command: UInt8,
        completion: @escaping (
            _ current: UInt16?, _ max: UInt16?, _ message: String
        ) -> Void
    ) {
        guard isTargetMonitorConnected, let service = selectedService else {
            let commandHex = String(format: "0x%02X", command)
            let msg =
            "Read Error: \(self.targetMonitorName) not connected or service unavailable. VCP: \(commandHex)"
            logger.error("DDC Read Error: \(msg)")
            updateStatus(msg)
            completion(nil, nil, msg)
            return
        }
        let monitorName = selectedMonitorName
        let commandHex = String(format: "0x%02X", command)
        
        DDCViewModel.ddcQueue.async { [weak self] in
            guard let self = self else { return }
            self.logger.debug(
                "DDC Read BG: Executing VCP \(commandHex) for \(monitorName)..."
            )
            let readResult = Arm64DDC.read(
                service: service,
                command: command,
                numOfRetryAttemps: 3
            )
            
            DispatchQueue.main.async {
                if let (current, max) = readResult {
                    self.logger.debug(
                        "DDC Read OK: VCP \(commandHex) for \(monitorName). Current=\(current), Max=\(max)"
                    )
                    completion(current, max, "Read OK")
                } else {
                    let errorMsg =
                    "Read FAILED: VCP \(commandHex) for \(monitorName)."
                    self.logger.error("\(errorMsg)")
                    if self.statusMessage != errorMsg {
                        self.updateStatus(errorMsg)
                    }
                    self.scanMonitors()
                    completion(nil, nil, errorMsg)
                }
            }
        }
    }
    
    func readCapabilities(
        completion: @escaping (_ data: Data?, _ message: String) -> Void
    ) {
        guard isTargetMonitorConnected, let service = selectedService else {
            let msg =
            "Capabilities Error: \(self.targetMonitorName) not connected or service unavailable."
            logger.error("\(msg)")
            updateStatus(msg)
            completion(nil, msg)
            return
        }
        let monitorName = selectedMonitorName
        let command = VCP.Codes.CAPABILITIES_REQUEST
        let commandHex = String(format: "0x%02X", command)
        let msg = "Reading Capabilities (\(commandHex)) from \(monitorName)..."
        updateStatus(msg)
        logger.debug("DDC Read Caps: \(msg)")
        
        DDCViewModel.ddcQueue.async { [weak self] in
            guard let self = self else { return }
            self.logger.debug(
                "DDC Read Caps BG: Executing VCP \(commandHex)..."
            )
            var send: [UInt8] = [command]
            var replyBuffer = [UInt8](repeating: 0, count: 300)
            var success = false
            var dummyReply: [UInt8] = []
            
            let requestSuccess = Arm64DDC.performDDCCommunication(
                service: service,
                send: &send,
                reply: &dummyReply,
                readSleepTime: 70000,
                numOfRetryAttemps: 4
            )
            if requestSuccess {
                self.logger.debug(
                    "DDC Read Caps BG: Request \(commandHex) sent. Reading response..."
                )
                usleep(150000)
                if IOAVServiceReadI2C(
                    service,
                    UInt32(ARM64_DDC_7BIT_ADDRESS),
                    0,
                    &replyBuffer,
                    UInt32(replyBuffer.count)
                ) == KERN_SUCCESS {
                    success = true
                } else {
                    self.logger.error(
                        "DDC Read Caps BG: IOAVServiceReadI2C failed."
                    )
                }
            } else {
                self.logger.error(
                    "DDC Read Caps BG: Failed to send \(commandHex) request."
                )
            }
            
            DispatchQueue.main.async {
                if success {
                    guard replyBuffer.count >= 3, replyBuffer[0] == 0x51,
                          (replyBuffer[1] & 0x80) == 0x80
                    else {
                        let hexString =
                        replyBuffer.prefix(20).map {
                            String(format: "%02X", $0)
                        }.joined(separator: " ")
                        + (replyBuffer.count > 20 ? "..." : "")
                        let errorMsg =
                        "Caps (\(commandHex)) reply format invalid.\nRaw: \(hexString)"
                        self.logger.error("\(errorMsg)")
                        self.updateStatus("Caps Read Format Error")
                        completion(nil, errorMsg)
                        return
                    }
                    let reportedLength = Int(replyBuffer[1] & 0x7F)
                    let dataStartIndex = 2
                    let dataEndIndex = dataStartIndex + reportedLength
                    guard dataEndIndex <= replyBuffer.count else {
                        let errorMsg =
                        "Caps reported length (\(reportedLength)) exceeds buffer."
                        self.logger.error("\(errorMsg)")
                        self.updateStatus("Caps Read Length Error")
                        completion(nil, errorMsg)
                        return
                    }
                    let capabilityData = Data(
                        replyBuffer[dataStartIndex..<dataEndIndex]
                    )
                    self.updateStatus("Capabilities Read OK")
                    completion(capabilityData, "Caps Read OK")
                } else {
                    let errorMsg =
                    "Capabilities (\(commandHex)) Read FAILED for \(monitorName)."
                    self.logger.error("\(errorMsg)")
                    self.updateStatus("Capabilities Read FAILED")
                    completion(nil, errorMsg)
                }
            }
        }
    }
    
    func updateStatus(_ message: String) {
        if Thread.isMainThread {
            if self.statusMessage != message {
                self.statusMessage = message
                logger.info("Status Update: \(message)")
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.statusMessage != message {
                    self.statusMessage = message
                    self.logger.info("Status Update (from bg): \(message)")
                }
            }
        }
    }
    func triggerPixelCleaningDDC() {
        let pixelCleaningVCPCode: UInt8 = VCP.Codes.OLED_CARE_FLAGS
        let pixelCleaningDDCValue: UInt16 = VCP.Values.CareFeatures.PIXEL_CLEANING
        
        guard isTargetMonitorConnected, let service = selectedService else {
            let msg =
            "Pixel Cleaning Error: \(self.targetMonitorName) not connected or service unavailable."
            logger.error("DDC Write Error for Pixel Cleaning: \(msg)")
            updateStatus(msg)
            return
        }
        
        let monitorName = selectedMonitorName
        let commandHex = String(format: "0x%02X", pixelCleaningVCPCode)
        let valueHex = String(format: "0x%04X", pixelCleaningDDCValue)
        
        let statusMsg =
        "Queueing Pixel Cleaning (\(commandHex)=\(valueHex)) for \(monitorName)..."
        updateStatus(statusMsg)
        logger.info("\(statusMsg)")
        
        DDCViewModel.ddcQueue.async { [weak self] in
            guard let self = self else { return }
            self.logger.debug(
                "DDC Write BG: Executing Pixel Cleaning (\(commandHex)=\(valueHex)) for \(monitorName)..."
            )
            
            let success = Arm64DDC.write(
                service: service,
                command: pixelCleaningVCPCode,
                value: pixelCleaningDDCValue,
                numOfRetryAttemps: 5
            )
            
            DispatchQueue.main.async {
                let resultMessage: String
                if success {
                    resultMessage =
                    "Pixel Cleaning command sent to \(monitorName). Monitor will start the process."
                    self.logger.info(
                        "Pixel Cleaning DDC Write Success for \(monitorName)."
                    )
                } else {
                    resultMessage =
                    "Pixel Cleaning FAILED for \(monitorName). Could not send command \(commandHex)=\(valueHex)."
                    self.logger.error(
                        "Pixel Cleaning DDC Write Failed for \(monitorName)."
                    )
                }
                if self.statusMessage != resultMessage {
                    self.updateStatus(resultMessage)
                }
            }
        }
    }
}
