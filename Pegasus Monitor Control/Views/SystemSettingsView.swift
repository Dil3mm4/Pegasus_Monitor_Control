//
//  SystemSettingsView.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

import SwiftUI

private let radioSpacing: CGFloat = 8
private let sectionSpacing: CGFloat = 20
private let descriptionIndent: CGFloat = 28

struct SystemSettingsView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    // State Variables
    @State private var powerSettingId: String = "Standard"
    @State private var auraLightModeId: String = "OFF"
    @State private var powerIndicatorModeId: UInt16 = 1
    @State private var proximityDistanceId: String = "OFF"
    @State private var proximityTimerId: String = "10min"
    @State private var selectedKVMInputId: UInt16? = nil
    
    // Loading/Update Control State
    @State private var isLoadingState: Bool = true
    @State private var isUpdatingProgrammatically: Bool = false
    
    // Options Data
    let powerOptions:
    [(id: String, title: String, description: String, ddcValue: UInt16)] = [
        (
            "Standard", "Standard / Performance Mode",
            "Allows access to all functions.", 0
        ),
        (
            "Power saving", "Power saving mode",
            "Limits some functions (e.g., brightness only).", 1
        ),
    ]
    
    let auraOptions: [(mode: SelectableMode, ddcValue: UInt16)] = [
        (
            mode: SelectableMode(
                name: "OFF",
                iconName: "lightbulb.slash",
                identifier: "OFF"
            ), ddcValue: 0
        ),
        (
            mode: SelectableMode(
                name: "RAINBOW",
                iconName: "rainbow",
                identifier: "RAINBOW"
            ), ddcValue: 4
        ),
        (
            mode: SelectableMode(
                name: "CIRCLE",
                iconName: "circle.dashed",
                identifier: "CIRCLE"
            ), ddcValue: 8
        ),
    ]
    
    let powerIndicatorOptions: [PowerIndicatorOption] = [
        PowerIndicatorOption(
            id: 0,
            title: "Indicator Off",
            description: "Power LED is off.",
            ddcValue: VCP.Values.OSD.INDICATOR_OFF
        ),
        PowerIndicatorOption(
            id: 1,
            title: "Indicator On",
            description: "Power LED is on when monitor is on.",
            ddcValue: VCP.Values.OSD.INDICATOR_ON
        ),
        PowerIndicatorOption(
            id: 2048,
            title: "Power Sync On",
            description: "Sync power state with input signal.",
            ddcValue: VCP.Values.OSD.POWER_SYNC_ON
        ),
        PowerIndicatorOption(
            id: 2049,
            title: "Sync On + Indicator On",
            description: "Sync power state and keep LED on.",
            ddcValue: VCP.Values.OSD.POWER_SYNC_ON_INDICATOR_ON
        ),
        PowerIndicatorOption(
            id: 2055,
            title: "Sync On + Indicator On + Key Lock",
            description: "Sync power, LED on, and OSD keys locked.",
            ddcValue: VCP.Values.OSD.POWER_SYNC_ON_INDICATOR_ON_KEY_LOCK
        ),
    ]
    
    let distanceOptions: [SelectableMode] = [
        SelectableMode(
            name: "OFF",
            iconName: "xmark.circle.fill",
            identifier: "OFF"
        ),
        SelectableMode(
            name: "60cm",
            iconName: "figure.walk",
            identifier: "60cm"
        ),
        SelectableMode(
            name: "90cm",
            iconName: "figure.walk.motion",
            identifier: "90cm"
        ),
        SelectableMode(
            name: "120cm",
            iconName: "figure.wave",
            identifier: "120cm"
        ),
        SelectableMode(
            name: "Tailored",
            iconName: "person.crop.circle.badge.questionmark",
            identifier: "Tailored"
        ),
    ]
    let timerOptions: [SelectableMode] = [
        SelectableMode(name: "5min", iconName: "5.circle", identifier: "5min"),
        SelectableMode(
            name: "10min",
            iconName: "10.circle",
            identifier: "10min"
        ),
        SelectableMode(
            name: "15min",
            iconName: "15.circle",
            identifier: "15min"
        ),
    ]
    
    let kvmInputOptions: [(name: String, iconName: String, ddcValue: UInt16)] =
    [
        ("USB-C", "shippingbox.fill", VCP.Values.KVM_USB.USB_C),
        ("USB-A", "externaldrive.connected.to.line.below.fill", VCP.Values.KVM_USB.USB_A),
    ]
    
    let horizontalButtonLayout: [GridItem] = [GridItem(.adaptive(minimum: 80))]
    let kvmButtonLayout: [GridItem] = [GridItem(.adaptive(minimum: 100))]  // For KVM buttons
    
    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            Text("System Settings")
                .font(.title).fontWeight(.medium)
            
            // Power Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Power Settings").font(.title2)
                ForEach(powerOptions, id: \.id) { option in
                    powerModeRadioButton(option: option)
                }
            }
            .disabled(isLoadingState)
            Divider()
            
            // Power Indicator / Sync
            SettingsPickerRow(
                title: "Power Indicator / Sync",
                description:
                    "Configure the monitor's power LED and sync behavior.",
                selection: $powerIndicatorModeId,
                options: powerIndicatorOptions,
                optionId: \.id,
                optionTitle: \.title,
                action: { selectedOption in
                    handlePickerChange(
                        code: VCP.Codes.POWER_INDICATOR,
                        ddcValue: selectedOption.ddcValue
                    )
                },
                isDisabled: isLoadingState
            )
            
            if false {
                Divider()
                // Aura Lights
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aura Lights").font(.headline)
                    LazyVGrid(
                        columns: horizontalButtonLayout,
                        alignment: .leading,
                        spacing: 10
                    ) {
                        ForEach(auraOptions, id: \.mode.identifier) {
                            optionTuple in
                            ModeButton(
                                iconName: optionTuple.mode.iconName,
                                label: optionTuple.mode.name,
                                isSelected: auraLightModeId
                                == optionTuple.mode.identifier
                            ) {
                                handleAuraLightSelection(optionTuple)
                            }
                        }
                    }
                }
                .disabled(isLoadingState)
                .hidden()
                
                Divider()
            }
            Divider()
            
            // Proximity Sensor
            VStack(alignment: .leading, spacing: 15) {
                Text("Proximity Sensor").font(.title2)
                proximitySection(
                    title: "Distance:",
                    options: distanceOptions,
                    selection: $proximityDistanceId
                )
                proximitySection(
                    title: "Timeout:",
                    options: timerOptions,
                    selection: $proximityTimerId
                )
                .disabled(proximityDistanceId == "OFF")
                .opacity(proximityDistanceId == "OFF" ? 0.5 : 1.0)
            }
            .disabled(isLoadingState)
            
            Divider()
            
            // KVM Switch
            VStack(alignment: .leading, spacing: 8) {
                Text("KVM Switch (Manual)").font(.title2)
                Text(
                    "Note: This works when 'Auto KVM Switch' is OFF in the monitor OSD."
                )
                .font(.caption).foregroundColor(.secondary).padding(.bottom, 5)
                LazyVGrid(
                    columns: kvmButtonLayout,
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(kvmInputOptions, id: \.ddcValue) { kvmOption in
                        ModeButton(
                            iconName: kvmOption.iconName,
                            label: kvmOption.name,
                            isSelected: selectedKVMInputId == kvmOption.ddcValue
                        ) {
                            handleKVMSelection(kvmOption)
                        }
                    }
                }
            }
            .disabled(isLoadingState)
            
            Spacer()
        }
        .disabled(viewModel.selectedDisplayID == nil)
        .opacity(viewModel.selectedDisplayID == nil ? 0.5 : 1.0)
        .onAppear(perform: fetchSystemSettingsState)
        .onChange(of: viewModel.selectedDisplayID) { _ in
            fetchSystemSettingsState()
        }
    }
    
    // MARK: - Subviews & Helpers
    
    @ViewBuilder
    private func powerModeRadioButton(
        option: (
            id: String, title: String, description: String, ddcValue: UInt16
        )
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Button {
                handlePowerModeSelection(option)
            } label: {
                HStack(spacing: radioSpacing) {
                    Image(
                        systemName: powerSettingId == option.id
                        ? "largecircle.fill.circle" : "circle"
                    )
                    .foregroundColor(.accentColor).imageScale(.large).frame(
                        width: 20
                    )
                    Text(option.title).foregroundColor(.primary)
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
            
            Text(option.description)
                .font(.caption).foregroundColor(.secondary)
                .padding(.leading, descriptionIndent)
        }.padding(.bottom, 5)
    }
    
    @ViewBuilder
    private func proximitySection(
        title: String,
        options: [SelectableMode],
        selection: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline)
            LazyVGrid(
                columns: horizontalButtonLayout,
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(options) { option in
                    ModeButton(
                        iconName: option.iconName,
                        label: option.name,
                        isSelected: selection.wrappedValue == option.identifier
                    ) {
                        handleProximitySelection(
                            option: option,
                            currentSelection: selection
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func handlePowerModeSelection(
        _ option: (
            id: String, title: String, description: String, ddcValue: UInt16
        )
    ) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        powerSettingId = option.id
        setSimpleValue(
            code: VCP.Codes.POWER_MODE,
            value: option.ddcValue,
            description: "Power Mode"
        )
    }
    
    private func handlePickerChange(code: UInt8, ddcValue: UInt16) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        let description =
        (code == VCP.Codes.POWER_INDICATOR)
        ? "Power Indicator" : "Unknown Picker"
        setSimpleValue(code: code, value: ddcValue, description: description)
    }
    
    private func handleAuraLightSelection(
        _ optionTuple: (mode: SelectableMode, ddcValue: UInt16)
    ) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        auraLightModeId = optionTuple.mode.identifier
        let writeDelay: TimeInterval = 0.1
        print(
            "[AuraLight Button Tap] Scheduling write for \(optionTuple.mode.name) (\(optionTuple.ddcValue)) after \(writeDelay)s delay..."
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + writeDelay) {
            setSimpleValue(
                code: VCP.Codes.AURA_LIGHT,
                value: optionTuple.ddcValue,
                description: "Aura Light"
            )
        }
    }
    
    private func handleProximitySelection(
        option: SelectableMode,
        currentSelection: Binding<String>
    ) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        currentSelection.wrappedValue = option.identifier
        if currentSelection.wrappedValue == proximityDistanceId
            && option.identifier == "OFF"
        {
            proximityTimerId = "10min"
        } else if currentSelection.wrappedValue == proximityTimerId
                    && proximityDistanceId == "OFF"
        {
            proximityDistanceId = "90cm"
        }
        sendProximityCommand()
    }
    
    private func handleKVMSelection(
        _ kvmOption: (name: String, iconName: String, ddcValue: UInt16)
    ) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        selectedKVMInputId = kvmOption.ddcValue  // Update local state first
        setSimpleValue(
            code: VCP.Codes.CAPABILITIES_REQUEST,
            value: kvmOption.ddcValue,
            description: "KVM Input to \(kvmOption.name)"
        )
    }
    
    // MARK: - DDC Command Logic
    
    private func setSimpleValue(code: UInt8, value: UInt16, description: String)
    {
        print(
            "Setting \(description) (\(String(format: "0x%02X", code))) -> \(value)"
        )
        viewModel.writeDDC(command: code, value: value) { success, message in
            if !success {
                print("Error setting \(description): \(message)")
                viewModel.updateStatus("Error setting \(description)")
                fetchSystemSettingsState()
            }
            // After KVM switch, always re-fetch state as other settings might change or read might be needed to confirm.
            if code == VCP.Codes.CAPABILITIES_REQUEST
                && description.starts(with: "KVM")
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {  // Give monitor time to switch
                    fetchSystemSettingsState()
                }
            }
        }
    }
    
    private func sendProximityCommand() {
        guard
            let ddcValue = calculateProximityDDCValue(
                distanceId: proximityDistanceId,
                timerId: proximityTimerId
            )
        else {
            print(
                "Error: Could not calculate valid DDC value for proximity state (\(proximityDistanceId), \(proximityTimerId))."
            )
            viewModel.updateStatus("Invalid proximity setting")
            return
        }
        setSimpleValue(
            code: VCP.Codes.PROXIMITY_SENSOR,
            value: ddcValue,
            description: "Proximity Sensor"
        )
    }
    
    private func calculateProximityDDCValue(distanceId: String, timerId: String)
    -> UInt16?
    {
        if distanceId == "OFF" { return VCP.Values.ProximityCombo.OFF_10_MIN }
        switch (distanceId, timerId) {
            case ("60cm", "5min"): return VCP.Values.ProximityCombo.SIXTY_CM_5_MIN
            case ("60cm", "10min"): return VCP.Values.ProximityCombo.SIXTY_CM_10_MIN
            case ("60cm", "15min"): return VCP.Values.ProximityCombo.SIXTY_CM_15_MIN
            case ("90cm", "5min"): return VCP.Values.ProximityCombo.NINETY_CM_5_MIN
            case ("90cm", "10min"): return VCP.Values.ProximityCombo.NINETY_CM_10_MIN
            case ("90cm", "15min"): return VCP.Values.ProximityCombo.NINETY_CM_15_MIN
            case ("120cm", "5min"): return VCP.Values.ProximityCombo.ONEHUNDREDTWENTY_CM_5_MIN
            case ("120cm", "10min"): return VCP.Values.ProximityCombo.ONEHUNDREDTWENTY_CM_10_MIN
            case ("120cm", "15min"): return VCP.Values.ProximityCombo.ONEHUNDREDTWENTY_CM_15_MIN
            case ("Tailored", "5min"): return VCP.Values.ProximityCombo.TAILORED_CM_5_MIN
            case ("Tailored", "10min"): return VCP.Values.ProximityCombo.TAILORED_CM_10_MIN
            case ("Tailored", "15min"): return VCP.Values.ProximityCombo.TAILORED_CM_15_MIN
            default:
                print(
                    "Warn: Invalid proximity combination: \(distanceId) / \(timerId)"
                )
                return nil
        }
    }
    
    // MARK: - Initial State Fetch
    func fetchSystemSettingsState() {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            isLoadingState = false
            return
        }
        isLoadingState = true
        isUpdatingProgrammatically = true
        print(
            "SystemSettingsView: Fetching initial states for monitor \(currentDisplayID)..."
        )
        viewModel.updateStatus("Reading System settings...")
        
        let group = DispatchGroup()
        var fetchedValues: [UInt8: UInt16] = [:]
        var fetchErrors: [String] = []
        let fetchLock = NSLock()
        
        let codesToRead: [UInt8] = [
            VCP.Codes.POWER_MODE,
            VCP.Codes.AURA_LIGHT,
            VCP.Codes.POWER_INDICATOR,
            VCP.Codes.PROXIMITY_SENSOR,
            VCP.Codes.CAPABILITIES_REQUEST,
        ]
        
        for code in codesToRead {
            group.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard self.viewModel.selectedDisplayID == currentDisplayID
                else {
                    print(
                        "SystemSettings Fetch Error: Monitor changed during read of VCP \(String(format:"0x%02X", code))."
                    )
                    group.leave()
                    return
                }
                fetchLock.lock()
                if let val = current {
                    fetchedValues[code] = val
                    // Specifically for KVM (F3), also update selectedKVMInputId if value matches known options
                    if code == VCP.Codes.CAPABILITIES_REQUEST {
                        if self.kvmInputOptions.contains(where: {
                            $0.ddcValue == val
                        }) {
                            print(
                                "SystemSettings Fetch: Read VCP F3 (KVM attempt) = \(val). Monitor might not report current KVM on read."
                            )
                        }
                    }
                } else {
                    fetchErrors.append(
                        "VCP \(String(format:"0x%02X", code)): \(msg)"
                    )
                }
                fetchLock.unlock()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print(
                "SystemSettingsView: Fetch complete for monitor \(currentDisplayID). Errors: \(fetchErrors.count)"
            )
            guard self.viewModel.selectedDisplayID == currentDisplayID else {
                print(
                    "SystemSettingsView: Monitor changed just before processing results. Aborting."
                )
                self.isLoadingState = false
                self.isUpdatingProgrammatically = false
                return
            }
            
            if let powerVal = fetchedValues[VCP.Codes.POWER_MODE] {
                self.powerSettingId =
                powerOptions.first { $0.ddcValue == powerVal }?.id
                ?? "Standard"
            } else {
                print("SystemSettings Fetch Error: Power Mode (E1)")
            }
            
            if let auraVal = fetchedValues[VCP.Codes.AURA_LIGHT] {
                self.auraLightModeId =
                auraOptions.first { $0.ddcValue == auraVal }?.mode
                    .identifier ?? "OFF"
            } else {
                print("SystemSettings Fetch Error: Aura Light (F2)")
            }
            
            if let indicatorVal = fetchedValues[VCP.Codes.POWER_INDICATOR] {
                if powerIndicatorOptions.contains(where: {
                    $0.ddcValue == indicatorVal
                }) {
                    self.powerIndicatorModeId = indicatorVal
                } else {
                    print(
                        "SystemSettings Fetch Warning: Read invalid value (\(indicatorVal)) for Power Indicator (FC)."
                    )
                }
            } else {
                print("SystemSettings Fetch Error: Power Indicator (FC)")
            }
            
            if let proximityVal = fetchedValues[VCP.Codes.PROXIMITY_SENSOR] {
                let (distId, timeId) = mapDDCValueToProximityIds(proximityVal)
                self.proximityDistanceId = distId
                self.proximityTimerId = timeId
            } else {
                print("SystemSettings Fetch Error: Proximity (ED)")
            }
            
            if let kvmReadVal = fetchedValues[VCP.Codes.CAPABILITIES_REQUEST] {
                if kvmInputOptions.contains(where: { $0.ddcValue == kvmReadVal }
                ) {
                    print(
                        "SystemSettings Fetch: KVM VCP F3 read returned \(kvmReadVal). Updating UI selection."
                    )
                    self.selectedKVMInputId = kvmReadVal
                } else {
                    print(
                        "SystemSettings Fetch: KVM VCP F3 read returned \(kvmReadVal), not matching known KVM input values. UI selection not updated from this read."
                    )
                }
            } else {
                print(
                    "SystemSettings Fetch Error or no relevant data from KVM VCP F3 read."
                )
            }
            
            if !fetchErrors.isEmpty {
                viewModel.updateStatus("Error reading some System settings.")
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
                "SystemSettingsView: State update finished. isUpdatingProgrammatically=\(self.isUpdatingProgrammatically)"
            )
        }
    }
    
    // MARK: - Mapping DDC Value back to State IDs
    private func mapDDCValueToProximityIds(_ ddcValue: UInt16) -> (
        distanceId: String, timerId: String
    ) {
        switch ddcValue {
            case VCP.Values.ProximityCombo.OFF_10_MIN: return ("OFF", "10min")
            case VCP.Values.ProximityCombo.SIXTY_CM_5_MIN: return ("60cm", "5min")
            case VCP.Values.ProximityCombo.SIXTY_CM_10_MIN: return ("60cm", "10min")
            case VCP.Values.ProximityCombo.SIXTY_CM_15_MIN: return ("60cm", "15min")
            case VCP.Values.ProximityCombo.NINETY_CM_5_MIN: return ("90cm", "5min")
            case VCP.Values.ProximityCombo.NINETY_CM_10_MIN: return ("90cm", "10min")
            case VCP.Values.ProximityCombo.NINETY_CM_15_MIN: return ("90cm", "15min")
            case VCP.Values.ProximityCombo.ONEHUNDREDTWENTY_CM_5_MIN: return ("120cm", "5min")
            case VCP.Values.ProximityCombo.ONEHUNDREDTWENTY_CM_10_MIN: return ("120cm", "10min")
            case VCP.Values.ProximityCombo.ONEHUNDREDTWENTY_CM_15_MIN: return ("120cm", "15min")
            case VCP.Values.ProximityCombo.TAILORED_CM_5_MIN: return ("Tailored", "5min")
            case VCP.Values.ProximityCombo.TAILORED_CM_10_MIN: return ("Tailored", "10min")
            case VCP.Values.ProximityCombo.TAILORED_CM_15_MIN: return ("Tailored", "15min")
            default:
                print(
                    "Warn: Unknown Proximity DDC value read: \(ddcValue). Defaulting to OFF/10min."
                )
                return ("OFF", "10min")
        }
    }
    
    private func resetStateToDefaults() {
        isUpdatingProgrammatically = true
        powerSettingId = "Standard"
        auraLightModeId = "OFF"
        powerIndicatorModeId = VCP.Values.OSD.INDICATOR_ON
        proximityDistanceId = "OFF"
        proximityTimerId = "10min"
        selectedKVMInputId = nil  // Reset KVM selection
        DispatchQueue.main.async { self.isUpdatingProgrammatically = false }
    }
}

// MARK: - Preview Provider
#Preview {
    let previewVM = DDCViewModel()
    return SystemSettingsView()
        .environmentObject(previewVM)
        .padding()
        .frame(width: 600, height: 800) 
        .preferredColorScheme(.dark)
}
