//
//  OLEDCareView.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

import SwiftUI

// MARK: - OptionSet for VCP FD Flags
struct OLEDCareFlags: OptionSet, CustomStringConvertible {
    let rawValue: UInt16
    
    var description: String {
        var descriptions: [String] = []
        if contains(VCP.Values.CareFeatures.SCREEN_DIMMING) { descriptions.append("ScreenDimming(8)") }
        if contains(VCP.Values.CareFeatures.LOGO_DETECTION) { descriptions.append("LogoDetection(32)") }
        if contains(VCP.Values.CareFeatures.UNIFORM_BRIGHTNESS) {
            descriptions.append("UniformBrightness(64)")
        }
        if contains(VCP.Values.CareFeatures.TASKBAR_DETECTION) {
            descriptions.append("TaskbarDetection(2048)")
        }
        if contains(VCP.Values.CareFeatures.BOUNDARY_DETECTION) {
            descriptions.append("BoundaryDetection(4096)")
        }
        if contains(VCP.Values.CareFeatures.OUTER_DIMMING) {
            descriptions.append("OuterDimming(8192)")
        }
        if contains(VCP.Values.CareFeatures.GLOBAL_DIMMING) {
            descriptions.append("GlobalDimming(16384)")
        }
        return descriptions.isEmpty
        ? "None" : descriptions.joined(separator: "|")
    }
}

// MARK: - Main OLED Care View
struct OLEDCareView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    @State private var screenDimmingOn: Bool = false
    @State private var logoDetectionOn: Bool = false
    @State private var uniformBrightnessOn: Bool = false
    @State private var taskbarDetectionOn: Bool = false
    @State private var boundaryDetectionOn: Bool = false
    @State private var outerDimmingOn: Bool = false
    @State private var globalDimmingOn: Bool = false
    
    @State private var cleaningReminderSelection: UInt16 = 8
    @State private var screenMoveSelection: UInt16 = 2
    
    @State private var isLoadingState: Bool = true
    @State private var isUpdatingProgrammatically: Bool = false
    @State private var showPixelCleaningAlert: Bool = false
    private let pixelCleaningVCPCode: UInt8 = VCP.Codes.OLED_CARE_FLAGS
    private let pixelCleaningDDCValue: UInt16 = VCP.Values.CareFeatures.PIXEL_CLEANING
    
    let reminderOptions: [ReminderOption] = [
        ReminderOption(label: "Never", tagValue: 0, ddcValue: VCP.Values.CareFeatures.REMINDER_NEVER),
        ReminderOption(label: "2 hours", tagValue: 2, ddcValue: VCP.Values.CareFeatures.REMINDER_TWO_HOURS),
        ReminderOption(label: "4 hours", tagValue: 4, ddcValue: VCP.Values.CareFeatures.REMINDER_FOUR_HOURS),
        ReminderOption(label: "8 hours", tagValue: 8, ddcValue: VCP.Values.CareFeatures.REMINDER_EIGHT_HOURS),
    ]
    let screenMoveOptions: [ScreenMoveOption] = [
        ScreenMoveOption(label: "Off", tagValue: 0, ddcValue: VCP.Values.CareFeatures.SCREEN_MOVE_OFF),
        ScreenMoveOption(label: "Light", tagValue: 1, ddcValue: VCP.Values.CareFeatures.SCREEN_MOVE_LIGHT),
        ScreenMoveOption(label: "Middle", tagValue: 2, ddcValue: VCP.Values.CareFeatures.SCREEN_MOVE_MIDDLE),
        ScreenMoveOption(label: "Strong", tagValue: 3, ddcValue: VCP.Values.CareFeatures.SCREEN_MOVE_STRONG),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("OLED Care")
                .font(.title)
                .fontWeight(.medium)
            
            Group {
                SettingsToggleRow(
                    title: "Screen Dimming Control",
                    description:
                        "Dims screen brightness when no movement is detected.",
                    isOn: $screenDimmingOn,
                    action: { _ in handleFlagToggleChange() }
                )
                SettingsToggleRow(
                    title: "Logo Detection",
                    description: "Adjusts logo brightness automatically.",
                    isOn: $logoDetectionOn,
                    action: { _ in handleFlagToggleChange() }
                )
                SettingsToggleRow(
                    title: "Taskbar Detection",
                    description: "Reduces brightness around the taskbar.",
                    isOn: $taskbarDetectionOn,
                    action: { _ in handleFlagToggleChange() }
                )
                SettingsToggleRow(
                    title: "Boundary Detection",
                    description:
                        "Reduces burn-in risk from static boundaries (black bars, PbP).",
                    isOn: $boundaryDetectionOn,
                    action: { _ in handleFlagToggleChange() }
                )
                SettingsToggleRow(
                    title: "Outer Dimming Control",
                    description:
                        "Adjusts brightness around peak areas (may enable Pixel Shift).",
                    isOn: $outerDimmingOn,  // Corresponds to bit 13 (8192)
                    action: { _ in handleFlagToggleChange() }
                )
                SettingsToggleRow(
                    title: "Global Dimming Control",
                    description:
                        "Dynamically adjusts overall brightness (may enable ABL).",
                    isOn: $globalDimmingOn,  // Corresponds to bit 14 (16384)
                    action: { _ in handleFlagToggleChange() }
                )
                SettingsToggleRow(
                    title: "Uniform Brightness",
                    description: "Maintains consistent brightness level.",
                    isOn: $uniformBrightnessOn,
                    action: { _ in handleFlagToggleChange() }
                )
            }
            .disabled(isLoadingState)
            
            Divider()
            
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Pixel Cleaning").fontWeight(.medium)
                    Text(
                        "Manual pixel maintenance process (approx. 6 mins). Monitor may turn off. Use when prompted or if image issues appear. Overuse may reduce panel lifespan."
                    )  // Enhanced warning
                    .font(.caption).foregroundColor(.secondary).fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
                Spacer()
                Button("Run Pixel Cleaning Now") {
                    showPixelCleaningAlert = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)  // Warning color
                .disabled(isLoadingState || viewModel.selectedDisplayID == nil)
            }
            .alert(
                "Confirm Pixel Cleaning",
                isPresented: $showPixelCleaningAlert
            ) {
                Button("Run Now", role: .destructive) {
                    triggerPixelCleaning()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This process will take about 6 minutes. The screen may turn off. Ensure the monitor is not in use.\n\nAre you sure you want to start pixel cleaning?"
                )
            }
            // --- END OF MODIFIED PIXEL CLEANING SECTION ---
            
            Divider()
            
            // Pixel Cleaning Reminder Picker (VCP F8)
            SettingsPickerRow(
                title: "Pixel Cleaning Reminder",
                description: "Set interval for cleaning notifications.",
                selection: $cleaningReminderSelection,
                options: reminderOptions,
                optionId: \.ddcValue,
                optionTitle: \.label,
                action: { option in
                    handlePickerChange(
                        code: VCP.Codes.OLED_CLEANING_REMINDER,
                        ddcValue: option.ddcValue
                    )
                },
                isDisabled: isLoadingState
            )
            
            Divider()
            
            // Screen Move (Pixel Shift) Picker (VCP F9)
            SettingsPickerRow(
                title: "Screen Move (Pixel Shift)",
                description:
                    "Select pixel shift intensity to prevent image sticking.",
                selection: $screenMoveSelection,
                options: screenMoveOptions,
                optionId: \.ddcValue,
                optionTitle: \.label,
                action: { option in
                    handlePickerChange(
                        code: VCP.Codes.OLED_SCREEN_MOVE,
                        ddcValue: option.ddcValue
                    )
                },
                isDisabled: isLoadingState
            )
            
            Spacer()  // Push content up
        }
        .disabled(viewModel.selectedDisplayID == nil)
        .opacity(viewModel.selectedDisplayID == nil ? 0.5 : 1.0)
        .onAppear(perform: fetchOLEDCareState)
        .onChange(of: viewModel.selectedDisplayID) { _ in fetchOLEDCareState() }
    }
    
    // MARK: - Action Handlers
    
    // Called when any VCP FD flag toggle changes
    private func handleFlagToggleChange() {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        sendCombinedFlags()
    }
    
    // Called when Mode toggle changes
    private func handleSimpleToggleChange(code: UInt8, enabled: Bool) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        setSimpleToggle(code: code, enabled: enabled)
    }
    
    // Called when Reminder or Screen Move picker changes
    private func handlePickerChange(code: UInt8, ddcValue: UInt16) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        setPickerValue(code: code, ddcValue: ddcValue)
    }
    
    // MARK: - DDC Command Functions
    
    // Sends the combined flags value for VCP FD
    private func sendCombinedFlags() {
        var flags: OLEDCareFlags = []
        if screenDimmingOn { flags.insert(VCP.Values.CareFeatures.SCREEN_DIMMING) }
        if logoDetectionOn { flags.insert(VCP.Values.CareFeatures.LOGO_DETECTION) }
        if uniformBrightnessOn { flags.insert(VCP.Values.CareFeatures.UNIFORM_BRIGHTNESS) }
        if taskbarDetectionOn { flags.insert(VCP.Values.CareFeatures.TASKBAR_DETECTION) }
        if boundaryDetectionOn { flags.insert(VCP.Values.CareFeatures.BOUNDARY_DETECTION) }
        if outerDimmingOn { flags.insert(VCP.Values.CareFeatures.OUTER_DIMMING) }
        if globalDimmingOn { flags.insert(VCP.Values.CareFeatures.GLOBAL_DIMMING) }
        
        let valueToSend = flags.rawValue
        let command = VCP.Codes.OLED_CARE_FLAGS
        print(
            "Setting OLED Care Flags (\(String(format: "0x%02X", command))) -> \(valueToSend) (\(flags))"
        )
        
        viewModel.writeDDC(command: command, value: valueToSend) {
            success,
            message in
            if !success {
                print("Error setting OLED Care Flags: \(message)")
                viewModel.updateStatus("Error setting OLED Care flags")
                fetchOLEDCareState()  // Revert UI on failure
            }
            // No automatic fetch needed after flag change usually
        }
    }
    
    // Sends a simple 0/1 toggle command
    private func setSimpleToggle(code: UInt8, enabled: Bool) {
        let value: UInt16 = enabled ? 1 : 0
        print("Setting Toggle (\(String(format: "0x%02X", code))) -> \(value)")
        viewModel.writeDDC(command: code, value: value) { success, message in
            if !success {
                print(
                    "Error setting Toggle \(String(format: "0x%02X", code)): \(message)"
                )
                viewModel.updateStatus("Error setting \(code)")
                fetchOLEDCareState()
            }
        }
    }
    
    private func setPickerValue(code: UInt8, ddcValue: UInt16) {
        print(
            "Setting Picker (\(String(format: "0x%02X", code))) -> \(ddcValue)"
        )
        viewModel.writeDDC(command: code, value: ddcValue) { success, message in
            if !success {
                print(
                    "Error setting Picker \(String(format: "0x%02X", code)): \(message)"
                )
                viewModel.updateStatus("Error setting \(code)")
                fetchOLEDCareState()  // Revert UI on failure
            }
        }
    }
    
    // MARK: - Initial State Fetch
    func fetchOLEDCareState() {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            isLoadingState = false
            return
        }
        
        isLoadingState = true
        isUpdatingProgrammatically = true
        print(
            "OLEDCareView: Fetching initial states for monitor \(currentDisplayID)..."
        )
        viewModel.updateStatus("Reading OLED Care settings...")
        
        let group = DispatchGroup()
        var fetchedValues: [UInt8: UInt16] = [:]
        var fetchErrors: [String] = []
        let fetchLock = NSLock()
        
        let codesToRead: [UInt8] = [
            VCP.Codes.OLED_CARE_FLAGS,
            VCP.Codes.OLED_CLEANING_REMINDER,
            VCP.Codes.OLED_SCREEN_MOVE,
        ]
        
        for code in codesToRead {
            group.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard self.viewModel.selectedDisplayID == currentDisplayID
                else {
                    print(
                        "OLEDCare Fetch Error: Monitor changed during read of VCP \(String(format:"0x%02X", code))."
                    )
                    group.leave()
                    return
                }
                fetchLock.lock()
                if let val = current {
                    fetchedValues[code] = val
                } else {
                    fetchErrors.append(
                        "\(String(format:"0x%02X", code)): \(msg)"
                    )
                }
                fetchLock.unlock()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print(
                "OLEDCareView: Fetch complete for monitor \(currentDisplayID). Errors: \(fetchErrors.count)"
            )
            
            guard self.viewModel.selectedDisplayID == currentDisplayID else {
                print(
                    "OLEDCareView: Monitor changed just before processing fetch results for \(currentDisplayID). Aborting state update."
                )
                self.isLoadingState = false
                self.isUpdatingProgrammatically = false
                return
            }
            
            if let flagsValue = fetchedValues[VCP.Codes.OLED_CARE_FLAGS] {
                updateFlagsState(from: flagsValue)
            } else {
                print("OLEDCareView: Failed to read Flags (FD).")
            }
            
            if let reminderValue = fetchedValues[VCP.Codes.OLED_CLEANING_REMINDER]
            {
                if reminderOptions.contains(where: {
                    $0.ddcValue == reminderValue
                }) {
                    self.cleaningReminderSelection = reminderValue
                } else {
                    print(
                        "OLEDCare Fetch Warning: Read invalid value (\(reminderValue)) for Cleaning Reminder (F8)."
                    )
                }
            } else {
                print("OLEDCareView: Failed to read Cleaning Reminder (F8).")
            }
            
            if let moveValue = fetchedValues[VCP.Codes.OLED_SCREEN_MOVE] {
                if screenMoveOptions.contains(where: {
                    $0.ddcValue == moveValue
                }) {
                    self.screenMoveSelection = moveValue
                } else {
                    print(
                        "OLEDCare Fetch Warning: Read invalid value (\(moveValue)) for Screen Move (F9)."
                    )
                }
            } else {
                print("OLEDCareView: Failed to read Screen Move (F9).")
            }
            
            if !fetchErrors.isEmpty {
                viewModel.updateStatus("Error reading some OLED Care settings.")
            } else {
                viewModel.updateStatus(
                    "Selected: \(viewModel.selectedMonitorName)"
                )
            }
            
            isLoadingState = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isUpdatingProgrammatically = false
            }
            print(
                "OLEDCareView: State update finished. isUpdatingProgrammatically=\(self.isUpdatingProgrammatically)"
            )
        }
    }
    
    private func updateFlagsState(from flagsValue: UInt16) {
        let flags = OLEDCareFlags(rawValue: flagsValue)
        print("OLEDCareView: Fetched Flags (FD) = \(flagsValue) -> \(flags)")
        screenDimmingOn = flags.contains(VCP.Values.CareFeatures.SCREEN_DIMMING)
        logoDetectionOn = flags.contains(VCP.Values.CareFeatures.LOGO_DETECTION)
        uniformBrightnessOn = flags.contains(VCP.Values.CareFeatures.UNIFORM_BRIGHTNESS)
        taskbarDetectionOn = flags.contains(VCP.Values.CareFeatures.TASKBAR_DETECTION)
        boundaryDetectionOn = flags.contains(VCP.Values.CareFeatures.BOUNDARY_DETECTION)
        outerDimmingOn = flags.contains(VCP.Values.CareFeatures.OUTER_DIMMING)
        globalDimmingOn = flags.contains(VCP.Values.CareFeatures.GLOBAL_DIMMING)
    }
    
    private func resetStateToDefaults() {
        isUpdatingProgrammatically = true
        screenDimmingOn = false
        logoDetectionOn = false
        uniformBrightnessOn = false
        taskbarDetectionOn = false
        boundaryDetectionOn = false
        outerDimmingOn = false
        globalDimmingOn = false
        cleaningReminderSelection = 8
        screenMoveSelection = 2
        DispatchQueue.main.async { self.isUpdatingProgrammatically = false }
    }
    
    private func triggerPixelCleaning() {
        print(
            "Pixel Cleaning: Sending command VCP \(String(format: "0x%02X", pixelCleaningVCPCode)) = \(pixelCleaningDDCValue)"
        )
        viewModel.updateStatus("Sending Pixel Cleaning command...")
        viewModel.writeDDC(
            command: pixelCleaningVCPCode,
            value: pixelCleaningDDCValue
        ) { success, message in
            if success {
                viewModel.updateStatus(
                    "Pixel Cleaning command sent. Monitor will start the process."
                )
                print("Pixel Cleaning DDC write successful.")
            } else {
                viewModel.updateStatus(
                    "Failed to send Pixel Cleaning command: \(message)"
                )
                print("Error sending Pixel Cleaning DDC command: \(message)")
            }
        }
    }
    
}

// MARK: - Preview Provider
#Preview {
    let previewVM = DDCViewModel()
    previewVM.selectedDisplayID = 1
    return OLEDCareView()
        .environmentObject(previewVM)
        .padding()
        .frame(width: 600, height: 700) 
        .preferredColorScheme(.dark)
}
