// GamePlusView.swift

import SwiftUI

// MARK: - Main GamePlus View
struct GamePlusView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    // Local State for Mode Selection
    @State private var selectedModeIdentifier: String = "crosshair"
    let gamePlusModes: [SelectableMode] = [
        SelectableMode(
            name: "Crosshair",
            iconName: "plus.viewfinder",
            identifier: "crosshair"
        ),
        SelectableMode(name: "Timer", iconName: "timer", identifier: "timer"),
        SelectableMode(
            name: "FPS Counter",
            iconName: "character.cursor.ibeam",
            identifier: "fps"
        ),
        SelectableMode(
            name: "Display Alignment",
            iconName: "textbox",
            identifier: "displayAlignment"
        ),
    ]
    
    // State for Crosshair Settings
    @State private var selectedCrosshairStyleId: String = "off"
    let crosshairStyles: [CrosshairStyle] = [
        CrosshairStyle(
            name: "OFF",
            iconName: "xmark.circle",
            identifier: "off"
        ),
        CrosshairStyle(
            name: "Blue Dot",
            iconName: "smallcircle.filled.circle",
            identifier: "blue_dot"
        ),
        CrosshairStyle(
            name: "Green Dot",
            iconName: "smallcircle.filled.circle",
            identifier: "green_dot"
        ),
        CrosshairStyle(
            name: "Blue Mini Duplex",
            iconName: "plus",
            identifier: "blue_mini"
        ),
        CrosshairStyle(
            name: "Green Mini Duplex",
            iconName: "plus",
            identifier: "green_mini"
        ),
        CrosshairStyle(
            name: "Blue Heavy Duplex",
            iconName: "plus.circle.fill",
            identifier: "blue_heavy"
        ),
        CrosshairStyle(
            name: "Green Heavy Duplex",
            iconName: "plus.circle.fill",
            identifier: "green_heavy"
        ),
    ]
    let crosshairColumns: [GridItem] = Array(
        repeating: .init(.flexible()),
        count: 2
    )
    
    // State for Timer Settings
    @State private var selectedTimerValue: Int? = nil
    let timerOptions: [(label: String, value: Int?, ddcValue: UInt16)] = [
        (label: "OFF", value: nil, ddcValue: VCP.Values.TimerOptions.OFF),
        (label: "30 MIN", value: 30, ddcValue: VCP.Values.TimerOptions.THIRTY_MINUTES),
        (label: "40 MIN", value: 40, ddcValue: VCP.Values.TimerOptions.FOURTY_MINUTES),
        (label: "50 MIN", value: 50, ddcValue: VCP.Values.TimerOptions.FIFTY_MINUTES),
        (label: "60 MIN", value: 60, ddcValue: VCP.Values.TimerOptions.SIXTY_MINUTES),
        (label: "90 MIN", value: 90, ddcValue: VCP.Values.TimerOptions.NINETY_MINUTES),
    ]
    
    // State for FPS Counter Settings
    @State private var selectedFpsOptionId: String = "off"
    let fpsOptions: [(mode: SelectableMode, ddcValue: UInt16)] = [
        (
            mode: SelectableMode(
                name: "OFF",
                iconName: "xmark",
                identifier: "off"
            ), ddcValue: VCP.Values.FPSOptions.OFF
        ),
        (
            mode: SelectableMode(
                name: "Number Only",
                iconName: "number",
                identifier: "number"
            ), ddcValue: VCP.Values.FPSOptions.NUMBER_ONLY
        ),
        (
            mode: SelectableMode(
                name: "Number and Graph",
                iconName: "chart.bar.xaxis",
                identifier: "graph"
            ), ddcValue: VCP.Values.FPSOptions.NUMBER_AND_GRAPH
        ),
    ]
    
    // State for Display Alignment
    @State private var displayAlignmentOn: Bool = false
    
    // Loading and Update Control State
    @State private var isLoadingGamePlusState: Bool = true
    @State private var isUpdatingProgrammaticallyGP: Bool = false
    @State private var hasFetchedGPOnceForCurrentMonitor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("GamePlus")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Select Mode").font(.title3)
            HStack(spacing: 15) {
                ForEach(gamePlusModes) { mode in
                    ModeButton(
                        iconName: mode.iconName,
                        label: mode.name,
                        isSelected: mode.identifier == selectedModeIdentifier
                    ) {
                        withAnimation {
                            selectedModeIdentifier = mode.identifier
                        }
                        print("Selected GamePlus mode: \(mode.name)")
                    }
                }
                Spacer()
            }
            
            Group {
                switch selectedModeIdentifier {
                    case "crosshair":
                        CrosshairSettingsView(
                            selectedStyleId: $selectedCrosshairStyleId,
                            styles: crosshairStyles,
                            columns: crosshairColumns,
                            fetchGamePlusState: fetchGamePlusState,
                            getCrosshairDDCValue: getCrosshairDDCValue
                        )
                        .environmentObject(viewModel)
                    case "timer":
                        TimerSettingsView(
                            selectedValue: $selectedTimerValue,
                            options: timerOptions,
                            fetchGamePlusState: fetchGamePlusState
                        )
                        .environmentObject(viewModel)
                    case "fps":
                        FPSSettingsView(
                            selectedOptionId: $selectedFpsOptionId,
                            options: fpsOptions,
                            fetchGamePlusState: fetchGamePlusState
                        )
                        .environmentObject(viewModel)
                    case "displayAlignment":
                        displayAlignmentSettingsView(
                            displayAlignmentOn: $displayAlignmentOn,
                            fetchGamePlusState: fetchGamePlusState
                        )
                        .environmentObject(viewModel)
                    default:
                        EmptyView()
                }
            }
            .transition(
                .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
            )
            .disabled(isLoadingGamePlusState)
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: selectedModeIdentifier)
        .onAppear { handleGPOnAppear() }
        .onChange(of: viewModel.selectedDisplayID) { _ in
            handleGPMonitorChange()
        }
    }
    
    private func handleGPOnAppear() {
        if viewModel.selectedDisplayID != nil
            && !hasFetchedGPOnceForCurrentMonitor
        {
            fetchGamePlusState()
        } else if viewModel.selectedDisplayID == nil {
            isLoadingGamePlusState = false
            hasFetchedGPOnceForCurrentMonitor = false
        }
    }
    
    private func handleGPMonitorChange() {
        hasFetchedGPOnceForCurrentMonitor = false
        if viewModel.selectedDisplayID != nil {
            fetchGamePlusState()
        } else {
            isLoadingGamePlusState = false
        }
    }
    
    public func fetchGamePlusState() {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            isLoadingGamePlusState = false
            return
        }
        
        isLoadingGamePlusState = true
        isUpdatingProgrammaticallyGP = true
        viewModel.updateStatus("Reading GamePlus settings...")
        
        let group = DispatchGroup()
        var fetchedValues: [UInt8: UInt16] = [:]
        var fetchErrors: [String] = []
        let fetchLock = NSLock()
        
        let codesToRead: [UInt8] = [
            VCP.Codes.GAMEPLUS_CROSSHAIR,
            VCP.Codes.GAMEPLUS_TIMER,
            VCP.Codes.GAMEPLUS_FPS_COUNTER,
            VCP.Codes.OLED_TARGET_MODE,
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
                        "GP VCP \(String(format:"0x%02X", code)): \(msg)"
                    )
                }
                fetchLock.unlock()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            guard viewModel.selectedDisplayID == currentDisplayID else {
                isLoadingGamePlusState = false
                isUpdatingProgrammaticallyGP = false
                return
            }
            
            if let crosshairVal = fetchedValues[VCP.Codes.GAMEPLUS_CROSSHAIR] {
                selectedCrosshairStyleId =
                crosshairStyles.first(where: { style in
                    let normal = getCrosshairDDCValue(
                        styleIdentifier: style.identifier
                    )
                    let alt = getCrosshairDDCValue(
                        styleIdentifier: style.identifier,
                        altMode: true
                    )
                    return normal == crosshairVal || alt == crosshairVal
                })?.identifier ?? "off"
            }
            
            if let timerVal = fetchedValues[VCP.Codes.GAMEPLUS_TIMER] {
                selectedTimerValue =
                timerOptions.first { $0.ddcValue == timerVal }?.value
            }
            
            if let fpsVal = fetchedValues[VCP.Codes.GAMEPLUS_FPS_COUNTER] {
                selectedFpsOptionId =
                fpsOptions.first { $0.ddcValue == fpsVal }?.mode.identifier
                ?? "off"
            }
            
            if let alignmentVal = fetchedValues[VCP.Codes.OLED_TARGET_MODE] {
                displayAlignmentOn = (alignmentVal == 1)
            }
            
            isLoadingGamePlusState = false
            DispatchQueue.main.async {  // Ensure state update is processed before allowing writes
                self.isUpdatingProgrammaticallyGP = false
                self.hasFetchedGPOnceForCurrentMonitor = true
            }
            viewModel.updateStatus(
                fetchErrors.isEmpty
                ? "Selected: \(viewModel.selectedMonitorName)"
                : "Error reading some GamePlus settings."
            )
        }
    }
    
    public func getCrosshairDDCValue(styleIdentifier: String) -> UInt16? {
        return getCrosshairDDCValue(
            styleIdentifier: styleIdentifier,
            altMode: false
        )
    }
    
    public func getCrosshairDDCValue(styleIdentifier: String, altMode: Bool)
    -> UInt16?
    {
        switch styleIdentifier {
            case "off": return VCP.Values.Crosshair.OFF
            case "blue_dot":
                return !altMode ? VCP.Values.Crosshair.BLUE_DOT : VCP.Values.Crosshair.BLUE_DOT_ALT
            case "green_dot":
                return !altMode ? VCP.Values.Crosshair.GREEN_DOT : VCP.Values.Crosshair.GREEN_DOT_ALT
            case "blue_mini":
                return !altMode ? VCP.Values.Crosshair.BLUE_MINI : VCP.Values.Crosshair.BLUE_MINI_ALT
            case "green_mini":
                return !altMode ? VCP.Values.Crosshair.GREEN_MINI : VCP.Values.Crosshair.GREEN_MINI_ALT
            case "blue_heavy":
                return !altMode ? VCP.Values.Crosshair.BLUE_HEAVY : VCP.Values.Crosshair.BLUE_HEAVY_ALT
            case "green_heavy":
                return !altMode ? VCP.Values.Crosshair.GREEN_HEAVY : VCP.Values.Crosshair.GREEN_HEAVY_ALT
            default: return nil
        }
    }
}

// MARK: - Subview Definitions
struct CrosshairSettingsView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    @Binding var selectedStyleId: String
    let styles: [CrosshairStyle]
    let columns: [GridItem]
    let fetchGamePlusState: () -> Void
    let getCrosshairDDCValue: (String) -> UInt16?
    
    var body: some View {
        GroupBox("Crosshair Style & Position") {
            HStack(alignment: .top, spacing: 30) {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(styles) { style in
                        CrosshairButton(
                            style: style,
                            isSelected: style.identifier == selectedStyleId
                        ) {
                            selectedStyleId = style.identifier
                            setCrosshairDDC(styleIdentifier: style.identifier)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                GamePlusPositionControl(
                    selectedCrosshairId: selectedStyleId,
                    getCrosshairDDCValue: getCrosshairDDCValue
                )
                .environmentObject(viewModel)
            }
            .padding(5)
        }
    }
    
    private func setCrosshairDDC(styleIdentifier: String) {
        let command = VCP.Codes.GAMEPLUS_CROSSHAIR
        guard let value = getCrosshairDDCValue(styleIdentifier) else {
            print("Warning: Unknown crosshair identifier: \(styleIdentifier)")
            return
        }
        print(
            "Setting Crosshair (\(String(format: "0x%02X", command))) to Style Value \(value)"
        )
        viewModel.writeDDC(command: command, value: value) { success, message in
            if !success {
                print("Error setting crosshair: \(message)")
                viewModel.updateStatus("Error setting crosshair")
                fetchGamePlusState()
            }
        }
    }
}

struct TimerSettingsView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    @Binding var selectedValue: Int?
    let options: [(label: String, value: Int?, ddcValue: UInt16)]
    let fetchGamePlusState: () -> Void
    let timerColumns: [GridItem] = Array(
        repeating: .init(.flexible()),
        count: 3
    )
    
    var body: some View {
        GroupBox("Timer Duration") {
            LazyVGrid(columns: timerColumns, spacing: 10) {
                ForEach(options, id: \.label) { option in
                    let iconName =
                    (option.value == nil) ? "xmark.circle" : "timer"
                    let isSelected = (selectedValue == option.value)
                    ModeButton(
                        iconName: iconName,
                        label: option.label,
                        isSelected: isSelected
                    ) {
                        selectedValue = option.value
                        print(
                            "Selected Timer: \(option.label) (DDC: \(option.ddcValue))"
                        )
                        viewModel.writeDDC(
                            command: VCP.Codes.GAMEPLUS_TIMER,
                            value: option.ddcValue
                        ) { success, message in
                            if !success {
                                print("Error setting timer: \(message)")
                                viewModel.updateStatus("Error setting timer")
                                fetchGamePlusState()
                            }
                        }
                    }
                    .frame(minWidth: 80, maxWidth: 120)
                }
            }
            .padding(5)
        }
    }
}

struct FPSSettingsView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    @Binding var selectedOptionId: String
    let options: [(mode: SelectableMode, ddcValue: UInt16)]
    let fetchGamePlusState: () -> Void
    let fpsColumns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    var body: some View {
        GroupBox("FPS Counter Mode") {
            LazyVGrid(columns: fpsColumns, spacing: 10) {
                ForEach(options, id: \.mode.identifier) { optionTuple in
                    let isSelected =
                    (selectedOptionId == optionTuple.mode.identifier)
                    ModeButton(
                        iconName: optionTuple.mode.iconName,
                        label: optionTuple.mode.name,
                        isSelected: isSelected
                    ) {
                        selectedOptionId = optionTuple.mode.identifier
                        print(
                            "Selected FPS Option: \(optionTuple.mode.name) (DDC: \(optionTuple.ddcValue))"
                        )
                        viewModel.writeDDC(
                            command: VCP.Codes.GAMEPLUS_FPS_COUNTER,
                            value: optionTuple.ddcValue
                        ) { success, message in
                            if !success {
                                print("Error setting FPS counter: \(message)")
                                viewModel.updateStatus(
                                    "Error setting FPS counter"
                                )
                                fetchGamePlusState()
                            }
                        }
                    }
                    .frame(minWidth: 80, maxWidth: 150)
                }
            }
            .padding(5)
        }
    }
}

struct displayAlignmentSettingsView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    @Binding var displayAlignmentOn: Bool
    let fetchGamePlusState: () -> Void
    
    var body: some View {
        GroupBox("Display Alignment") {
            SettingsToggleRow(
                title: "Enable Display Alignment",
                description: "",
                isOn: $displayAlignmentOn
            ) { newState in
                setdisplayAlignment(enabled: newState)
            }
            .padding(5)
        }
    }
    
    private func setdisplayAlignment(enabled: Bool) {
        let value: UInt16 = enabled ? VCP.Values.DisplayAlignment.ON : VCP.Values.DisplayAlignment.OFF
        print(
            "Setting Display Alignment (VCP \(String(format: "0x%02X", VCP.Codes.OLED_TARGET_MODE))) -> \(value)"
        )
        viewModel.writeDDC(command: VCP.Codes.OLED_TARGET_MODE, value: value) {
            success,
            message in
            if !success {
                print("Error setting Display Alignment: \(message)")
                viewModel.updateStatus("Error setting Display Alignment")
                fetchGamePlusState()
            }
        }
    }
}

// MARK: - Helper Views
struct CrosshairButton: View {
    let style: CrosshairStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: style.iconName)
                    .symbolRenderingMode(
                        style.identifier == "off" ? .monochrome : .palette
                    )
                    .foregroundStyle(
                        style.identifier.contains("blue")
                        ? Color.blue : Color.primary,
                        style.identifier.contains("green")
                        ? Color.green : Color.primary
                    )
                    .font(.title2)
                    .frame(width: 30, alignment: .center)
                Text(style.name).lineLimit(1).fixedSize(
                    horizontal: false,
                    vertical: true
                )
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6).fill(
                    isSelected
                    ? Color.accentColor.opacity(0.4)
                    : Color.primary.opacity(0.1)
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6).stroke(
                    isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                    lineWidth: 1.5
                )
            )
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}

struct GamePlusPositionControl: View {
    @EnvironmentObject var viewModel: DDCViewModel
    @Environment(\.colorScheme) var colorScheme
    let selectedCrosshairId: String
    let getCrosshairDDCValue: (String) -> UInt16?  // Receive helper
    
    private let controlSize: CGFloat = 30
    @State private var lastSentTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.25  // Debounce for position commands
    private let command = VCP.Codes.GAMEPLUS_POSITION_CONTROL
    
    public enum PositionCommand: UInt16 {
        case up = 2
        case down = 3
        case left = 5
        case right = 4
    }
    private var isEnabled: Bool { selectedCrosshairId != "off" }
    
    var body: some View {
        VStack(spacing: 5) {
            Text("Set Position").font(.headline)
            Grid(horizontalSpacing: 5, verticalSpacing: 5) {
                GridRow {
                    Color.clear.gridCellUnsizedAxes(.horizontal)
                    positionButton(position: .up, iconDirection: .up)
                    Color.clear.gridCellUnsizedAxes(.horizontal)
                }
                GridRow {
                    positionButton(position: .left, iconDirection: .left)
                    resetButton()  // Reset button in the center
                    positionButton(position: .right, iconDirection: .right)
                }
                GridRow {
                    Color.clear.gridCellUnsizedAxes(.horizontal)
                    positionButton(position: .down, iconDirection: .down)
                    Color.clear.gridCellUnsizedAxes(.horizontal)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlColor).opacity(0.2))
        .cornerRadius(8)
        .opacity(isEnabled ? 1.0 : 0.5)
        .disabled(!isEnabled)
    }
    
    @ViewBuilder
    private func positionButton(
        position: PositionCommand,
        iconDirection: ArrowImage.Direction
    ) -> some View {
        Button {
            sendPositionCommand(position)
        } label: {
            ArrowImage(direction: iconDirection)
        }
        .buttonStyle(.bordered).tint(.primary.opacity(0.8))
    }
    
    @ViewBuilder
    private func resetButton() -> some View {
        Button {
            if let currentStyleDDC = getCrosshairDDCValue(selectedCrosshairId),
               currentStyleDDC != 0
            {
                viewModel.writeDDC(
                    command: VCP.Codes.GAMEPLUS_CROSSHAIR,
                    value: VCP.Values.Crosshair.OFF
                ) { success, _ in
                    if success {
                        // Turn back on after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15)
                        {  // Slightly increased delay
                            viewModel.writeDDC(
                                command: VCP.Codes.GAMEPLUS_CROSSHAIR,
                                value: currentStyleDDC
                            )
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.title3).frame(width: controlSize, height: controlSize)
        }
        .buttonStyle(.bordered).tint(
            colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7)
        )
    }
    
    private func sendPositionCommand(_ position: PositionCommand) {
        let now = Date()
        guard now.timeIntervalSince(lastSentTime) > debounceInterval else {
            print("Position command \(position) ignored (debounce).")
            return
        }
        guard isEnabled else {
            print("Position command \(position) ignored (disabled).")
            return
        }
        print(
            "Position Control Sending: \(position) (Value: \(position.rawValue))"
        )
        lastSentTime = now
        viewModel.writeDDC(command: command, value: position.rawValue) {
            success,
            message in
            if !success {
                print(
                    "Error setting position (\(String(format: "0x%02X", command)) = \(position.rawValue)): \(message)"
                )
                viewModel.updateStatus("Error setting position")
            }
        }
    }
}

struct ArrowImage: View {
    enum Direction: String {
        case up = "arrowtriangle.up.fill"
        case down = "arrowtriangle.down.fill"
        case left = "arrowtriangle.left.fill"
        case right = "arrowtriangle.right.fill"
    }
    let direction: Direction
    var body: some View {
        Image(systemName: direction.rawValue).font(.title3).frame(
            width: 30,
            height: 30
        )
    }
}

// MARK: - Preview Provider
#Preview {
    let previewVM = DDCViewModel()
    return ScrollView {
        GamePlusView().environmentObject(previewVM)
            .padding()
    }
    .frame(width: 600, height: 700)
    .preferredColorScheme(.dark)
}
