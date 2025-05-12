//
//  PipView.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

import SwiftUI

struct PipView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    @State private var selectedPipModeDDCValue: UInt16 = VCP.Values.PIP.OFF
    @State private var selectedPipSourceDDCValue: UInt16 = VCP.Values.PIP.SOURCE_USB_C
    
    @State private var isLoadingState: Bool = true
    @State private var isUpdatingProgrammatically: Bool = false
    
    let pipModeOptions: [PipModeOption] = [
        PipModeOption(id: VCP.Values.PIP.OFF, name: "OFF", iconName: "pip.exit"),
        PipModeOption(id: VCP.Values.PIP.TOP_RIGHT, name: "Top Right", iconName: "pip.enter"),
        PipModeOption(id: VCP.Values.PIP.TOP_LEFT, name: "Top Left", iconName: "pip.enter"),
        PipModeOption(id: VCP.Values.PIP.BOTTOM_RIGHT, name: "Bottom Right", iconName: "pip.enter"),
        PipModeOption(id: VCP.Values.PIP.BOTTOM_LEFT, name: "Bottom Left", iconName: "pip.enter"),
        PipModeOption(id: VCP.Values.PIP.VERTICAL_SPLIT, name: "Vertical Split", iconName: "pip.swap"),
    ]
    
    let pipSourceOptions: [PipSourceOption] = [
        PipSourceOption(
            id: VCP.Values.PIP.SOURCE_USB_C,
            name: "PIP source to USB-C",
            iconName: "appletvremote.gen1.fill"
        ),
        PipSourceOption(
            id: VCP.Values.PIP.SOURCE_HDMI_1,
            name: "PIP source to HDMI 1",
            iconName: "display"
        ),
        PipSourceOption(
            id: VCP.Values.PIP.SOURCE_HDMI_2,
            name: "PIP source to HDMI 2",
            iconName: "display.2"
        ),
    ]
    
    let modeButtonLayout: [GridItem] = [
        GridItem(.adaptive(minimum: 120, maximum: 150))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Picture-in-Picture (PiP)")
                .font(.title).fontWeight(.medium)
            
            GroupBox("PiP Mode / Layout") {
                LazyVGrid(columns: modeButtonLayout, spacing: 10) {
                    ForEach(pipModeOptions) { option in
                        ModeButton(
                            iconName: option.iconName,
                            label: option.name,
                            isSelected: selectedPipModeDDCValue == option.id
                        ) {
                            handlePipModeSelection(option)
                        }
                    }
                }
                .padding(5)
            }
            .disabled(isLoadingState)
            
            GroupBox("PiP Source") {
                LazyVGrid(columns: modeButtonLayout, spacing: 10) {
                    ForEach(pipSourceOptions) { option in
                        ModeButton(
                            iconName: option.iconName,
                            label: option.name,
                            isSelected: selectedPipSourceDDCValue == option.id
                        ) {
                            handlePipSourceSelection(option)
                        }
                    }
                }
                .padding(5)
            }
            .disabled(isLoadingState || selectedPipModeDDCValue == 0)  
            .opacity((selectedPipModeDDCValue == 0) ? 0.5 : 1.0)
            
            Spacer()
        }
        .disabled(viewModel.selectedDisplayID == nil)
        .opacity(viewModel.selectedDisplayID == nil ? 0.5 : 1.0)
        .onAppear(perform: fetchPipState)
        .onChange(of: viewModel.selectedDisplayID) { _ in fetchPipState() }
    }
    
    // MARK: - Action Handlers
    private func handlePipModeSelection(_ option: PipModeOption) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        selectedPipModeDDCValue = option.id
        setPipValue(
            code: VCP.Codes.PIP_MODE_LAYOUT,
            value: option.id,
            description: "PiP Mode"
        )
    }
    
    private func handlePipSourceSelection(_ option: PipSourceOption) {
        guard !isLoadingState && !isUpdatingProgrammatically else { return }
        selectedPipSourceDDCValue = option.id
        setPipValue(
            code: VCP.Codes.PIP_CONTROL,
            value: option.id,
            description: "PiP Source"
        )
    }
    
    // MARK: - DDC Command Logic
    private func setPipValue(code: UInt8, value: UInt16, description: String) {
        print(
            "Setting \(description) (VCP \(String(format: "0x%02X", code))) -> \(value)"
        )
        viewModel.writeDDC(command: code, value: value) { success, message in
            if !success {
                print("Error setting \(description): \(message)")
                viewModel.updateStatus("Error setting \(description)")
                fetchPipState()  // Revert UI on failure
            }
            // Consider a short delay then fetch if PiP mode change might affect source readability
            if code == VCP.Codes.PIP_MODE_LAYOUT {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    fetchPipState()
                }
            }
        }
    }
    
    // MARK: - Initial State Fetch
    func fetchPipState() {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            isLoadingState = false
            resetPipStateToDefaults()
            return
        }
        
        isLoadingState = true
        isUpdatingProgrammatically = true
        print("PipView: Fetching PiP states for monitor \(currentDisplayID)...")
        viewModel.updateStatus("Reading PiP settings...")
        
        let group = DispatchGroup()
        var fetchedValues: [UInt8: UInt16] = [:]
        var fetchErrors: [String] = []
        let fetchLock = NSLock()
        
        let codesToRead: [UInt8] = [
            VCP.Codes.PIP_MODE_LAYOUT,
            VCP.Codes.PIP_CONTROL,
        ]
        
        for code in codesToRead {
            group.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard viewModel.selectedDisplayID == currentDisplayID else {
                    group.leave()
                    return
                }
                fetchLock.lock()
                if let val = current {
                    fetchedValues[code] = val
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
            guard viewModel.selectedDisplayID == currentDisplayID else {
                isLoadingState = false
                isUpdatingProgrammatically = false
                return
            }
            
            if let modeVal = fetchedValues[VCP.Codes.PIP_MODE_LAYOUT] {
                if pipModeOptions.contains(where: { $0.id == modeVal }) {
                    selectedPipModeDDCValue = modeVal
                } else {
                    print(
                        "PipView Fetch Warning: Read invalid value (\(modeVal)) for PiP Mode (F4). Defaulting to OFF."
                    )
                    selectedPipModeDDCValue = VCP.Values.PIP.OFF
                }
            } else {
                print("PipView Fetch Error: PiP Mode (F4)")
                selectedPipModeDDCValue = VCP.Values.PIP.OFF
            }
            
            if let sourceVal = fetchedValues[VCP.Codes.PIP_CONTROL] {
                if pipSourceOptions.contains(where: { $0.id == sourceVal }) {
                    selectedPipSourceDDCValue = sourceVal
                } else {
                    print(
                        "PipView Fetch Warning: Read invalid value (\(sourceVal)) for PiP Source (F5). Defaulting to USB-C."
                    )
                    selectedPipSourceDDCValue = VCP.Values.PIP.SOURCE_USB_C
                }
            } else {
                print("PipView Fetch Error: PiP Source (F5)")
                selectedPipSourceDDCValue = VCP.Values.PIP.SOURCE_USB_C
            }
            
            if !fetchErrors.isEmpty {
                viewModel.updateStatus("Error reading some PiP settings.")
            } else {
                viewModel.updateStatus(
                    "Selected: \(viewModel.selectedMonitorName)"
                )
            }
            
            isLoadingState = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isUpdatingProgrammatically = false
            }
        }
    }
    
    private func resetPipStateToDefaults() {
        isUpdatingProgrammatically = true
        selectedPipModeDDCValue = 0
        selectedPipSourceDDCValue = VCP.Values.PIP.SOURCE_USB_C
        DispatchQueue.main.async { isUpdatingProgrammatically = false }
    }
}

// MARK: - Preview Provider
#Preview {
    PipView()
        .environmentObject(DDCViewModel())
        .padding()
        .frame(width: 600, height: 400)
        .preferredColorScheme(.dark)
}
