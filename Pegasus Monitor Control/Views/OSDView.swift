//
//  OSDView.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

import Combine
import SwiftUI


struct OSDView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    @State private var osdTimeoutValue: Double = 60.0
    @State private var osdTransparencyValue: Double = 0.0
    
    @State private var isLoadingState: Bool = true
    @State private var isUpdatingProgrammatically: Bool = false
    
    @AppStorage("osdModifier1") private var osdModifier1Raw: String =
    ModifierKeyOption.control.rawValue
    @AppStorage("osdModifier2") private var osdModifier2Raw: String =
    ModifierKeyOption.none.rawValue
    
    private var osdModifier1: ModifierKeyOption {
        ModifierKeyOption(rawValue: osdModifier1Raw) ?? .control
    }
    private var osdModifier2: ModifierKeyOption {
        ModifierKeyOption(rawValue: osdModifier2Raw) ?? .none
    }
    private var primaryModifierOptions: [ModifierKeyOption] {
        ModifierKeyOption.allCases.filter {
            $0 != .none && $0.rawValue != osdModifier2Raw
        }
    }
    private var secondaryModifierOptions: [ModifierKeyOption] {
        ModifierKeyOption.allCases.filter { $0.rawValue != osdModifier1Raw }
    }
    private var fullModifierString: String {
        let mod1 = osdModifier1
        let mod2 = osdModifier2
        if mod2 == .none || mod1 == mod2 {
            return mod1.description
        } else {
            let modifiers = [mod1, mod2].filter { $0 != .none }
            let order: [ModifierKeyOption: Int] = [.command: 0, .control: 1, .option: 2, .shift: 3]
            let sortedModifiers = modifiers.sorted { (order[$0] ?? 99) < (order[$1] ?? 99) }
            return sortedModifiers.map { $0.description }.joined(separator: " + ")
        }
    }
    
    private let osdTimeoutRange: ClosedRange<Double> = 0...120
    private let osdTransparencyRange: ClosedRange<Double> = 0...100
    private let osdTransparencySteps: [Double] = [0, 20, 40, 60, 80, 100]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("OSD Settings")
                .font(.title)
                .fontWeight(.medium)
            
            GroupBox("OSD Display") {
                VStack(spacing: 15) {
                    SettingsSliderRow(
                        label: "Timeout (secs)",
                        value: $osdTimeoutValue,
                        range: osdTimeoutRange,
                        decimals: 0,
                        step: 1,
                        onEditingChanged: { editingFinished in
                            if editingFinished && !isUpdatingProgrammatically {
                                sendCombinedOSDSetting()
                            }
                        }
                    )
                    SettingsSliderRow(
                        label: "Transparency (%)",
                        value: $osdTransparencyValue,
                        range: osdTransparencyRange,
                        decimals: 0,
                        step: 20,
                        onEditingChanged: { editingFinished in
                            if editingFinished && !isUpdatingProgrammatically {
                                snapAndSendTransparency()
                            }
                        }
                    )
                }
                .padding(5)
                .disabled(isLoadingState)
                .opacity(isLoadingState ? 0.5 : 1.0)
            }
            
            Divider()
            
            GroupBox("OSD Keyboard Navigation") {
                VStack(alignment: .leading, spacing: 15) {
                    let _ = print("OSDView GroupBox: viewModel.hasAccessibilityPermissions = \(viewModel.hasAccessibilityPermissions)")
                    // ---- START: Accessibility Permissions UI ----
                    if !viewModel.hasAccessibilityPermissions {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Accessibility Access Needed")
                                    .font(.headline)
                            }
                            Text("To use global keyboard shortcuts for OSD navigation, this application requires Accessibility permissions. This allows it to listen for key presses even when it's not the active application.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Button {
                                viewModel.openAccessibilitySystemSettings()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    viewModel.checkAccessibilityPermissions()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "lock.shield")
                                    Text("Open System Settings")
                                }
                            }
                            .controlSize(.regular)
                            .padding(.top, 2)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.bottom, 10)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(
                            "Use keyboard shortcuts to navigate the monitor's OSD:"
                        ).font(.subheadline)
                        Grid(alignment: .leading, horizontalSpacing: 10) {
                            GridRow { Text("• **\(fullModifierString) + ↑**"); Text("Navigate Up") }
                            GridRow { Text("• **\(fullModifierString) + ↓**"); Text("Navigate Down") }
                            GridRow { Text("• **\(fullModifierString) + ←**"); Text("Navigate Left") }
                            GridRow { Text("• **\(fullModifierString) + →**"); Text("Navigate Right") }
                            GridRow { Text("• **\(fullModifierString) + 0**"); Text("Show OSD") }
                            GridRow { Text("• **\(fullModifierString) + Enter**"); Text("Select / Confirm") }
                            GridRow { Text("• **\(fullModifierString) + Esc**"); Text("Exit / Back") }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Divider().padding(.vertical, 5)
                    
                    Text("Shortcut Modifiers:").font(.headline)
                    HStack {
                        Text("Primary Key:").frame(width: 100, alignment: .leading)
                        Picker("Primary Key", selection: $osdModifier1Raw) {
                            ForEach(primaryModifierOptions) { option in
                                Text(option.description).tag(option.rawValue)
                            }
                        }
                        .labelsHidden().frame(maxWidth: 150)
                        .onChange(of: osdModifier1Raw) { newValue in handlePrimaryModifierChange(newValue) }
                    }
                    HStack {
                        Text("Secondary Key:").frame(width: 100, alignment: .leading)
                        Picker("Secondary Key", selection: $osdModifier2Raw) {
                            ForEach(secondaryModifierOptions) { option in
                                Text(option.description).tag(option.rawValue)
                            }
                        }
                        .labelsHidden().frame(maxWidth: 150)
                        .onChange(of: osdModifier2Raw) { newValue in handleSecondaryModifierChange(newValue) }
                    }
                    
                    Text(
                        "Note: If the chosen shortcut conflicts with a system or other application shortcut, it may not work as expected."
                    )
                    .font(.caption).italic().foregroundColor(.secondary)
                    .padding(.top, 5)
                    
                }
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .onAppear {
            fetchInitialOSDState()
            viewModel.checkAccessibilityPermissions() // Check when view appears
            print("OSDView.onAppear: Called viewModel.checkAccessibilityPermissions()")
            
        }
        .onChange(of: viewModel.selectedDisplayID) { _ in
            fetchInitialOSDState()
        }
        
    }
    
    // MARK: - Action Handlers & DDC Logic
    private func handlePrimaryModifierChange(_ newPrimaryRawValue: String) {
        if newPrimaryRawValue != ModifierKeyOption.none.rawValue
            && newPrimaryRawValue == osdModifier2Raw
        {
            osdModifier2Raw = ModifierKeyOption.none.rawValue
        }
    }
    
    private func handleSecondaryModifierChange(_ newSecondaryRawValue: String) {
        if newSecondaryRawValue != ModifierKeyOption.none.rawValue
            && newSecondaryRawValue == osdModifier1Raw
        {
            osdModifier2Raw = ModifierKeyOption.none.rawValue
        }
    }
    
    private func snapAndSendTransparency() {
        let closestStep = osdTransparencySteps.min(by: { abs($0 - osdTransparencyValue) < abs($1 - osdTransparencyValue) }) ?? 0
        if osdTransparencyValue != closestStep {
            let currentUpdatingFlag = isUpdatingProgrammatically
            isUpdatingProgrammatically = true
            osdTransparencyValue = closestStep
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                isUpdatingProgrammatically = currentUpdatingFlag
            }
        }
        sendCombinedOSDSetting()
    }
    
    private func sendCombinedOSDSetting() {
        guard !isLoadingState, !isUpdatingProgrammatically else { return }
        guard viewModel.selectedDisplayID != nil else { return }
        
        let timeoutToSend = UInt16(osdTimeoutValue.rounded()).clamped(to: 0...120)
        let transparencyBase = UInt16(osdTransparencyValue)
        let transparencyMultiplied = transparencyBase * 256
        let combinedValue = timeoutToSend + transparencyMultiplied
        let command = VCP.Codes.OSD_SETTINGS
        
        print("Sending OSD Settings (\(String(format: "0x%02X", command))) -> Timeout:\(timeoutToSend) + Transp:\(transparencyBase)(\(transparencyMultiplied)) = \(combinedValue)")
        viewModel.writeDDC(command: command, value: combinedValue) { success, msg in
            if !success {
                print("Error setting OSD Settings: \(msg)")
                viewModel.updateStatus("Error setting OSD: \(msg)")
                fetchInitialOSDState()
            }
        }
    }
    
    private func updateUIFromCombinedValue(_ combinedValue: UInt16) {
        print("Received Combined OSD Value: \(combinedValue)")
        let timeoutRead = Double(combinedValue % 256).clamped(to: osdTimeoutRange)
        let transparencyBaseRead = Double(combinedValue / 256)
        let closestTransparencyStep = osdTransparencySteps.min(by: { abs($0 - transparencyBaseRead) < abs($1 - transparencyBaseRead) }) ?? 0
        
        print("Extracted -> Timeout: \(timeoutRead), Transparency Base Read: \(transparencyBaseRead), Closest Step Snapped: \(closestTransparencyStep)")
        if self.osdTimeoutValue != timeoutRead { self.osdTimeoutValue = timeoutRead }
        if self.osdTransparencyValue != closestTransparencyStep { self.osdTransparencyValue = closestTransparencyStep }
    }
    
    func fetchInitialOSDState() {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            isLoadingState = false
            return
        }
        isLoadingState = true
        isUpdatingProgrammatically = true
        let command = VCP.Codes.OSD_SETTINGS
        print("OSDView: Fetching initial OSD Settings (\(String(format: "0x%02X", command)))...")
        viewModel.updateStatus("Reading OSD settings...")
        
        viewModel.readDDC(command: command) { current, _, message in
            DispatchQueue.main.async {
                guard viewModel.selectedDisplayID == currentDisplayID else {
                    print("OSDView Fetch: Monitor changed during read. Aborting update.")
                    self.isLoadingState = false
                    self.isUpdatingProgrammatically = false
                    return
                }
                if let currentValue = current {
                    self.updateUIFromCombinedValue(currentValue)
                    viewModel.updateStatus("Selected: \(viewModel.selectedMonitorName)")
                } else {
                    print("Error fetching OSD Settings: \(message)")
                    viewModel.updateStatus("Error reading OSD settings.")
                    self.osdTimeoutValue = 60
                    self.osdTransparencyValue = 0
                }
                self.isLoadingState = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isUpdatingProgrammatically = false
                }
            }
        }
    }
}

// MARK: - Extensions (Clamped Helper)
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Preview Provider
#Preview {
    let mockViewModel = DDCViewModel()
    return ScrollView {
        OSDView()
            .environmentObject(mockViewModel)
            .padding()
    }
    .frame(width: 600, height: 750) // Increased height for the new UI element
    .preferredColorScheme(.dark)
}
