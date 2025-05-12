//
//  MenuBarExtraContentView.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

import AVFoundation
import AppKit
import Combine
import SwiftUI

struct MenuBarExtraContentView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    // MARK: - General State
    @State private var isLoadingMenuState: Bool = true
    @State private var isUpdatingProgrammatically: Bool = false
    @State private var hasFetchedMenuOnceForCurrentMonitor = false
    @State private var showEnableHDRAlertInMenu: Bool = false
    @State private var displayIDForMenuHDRAlert: CGDirectDisplayID? = nil
    
    // MARK: - GameVisual States
    @State private var menuSelectedPresetIdentifier: String = "user"
    @State private var menuSelectedColorSpaceIdentifier: String = "wide"
    @State private var menuSelectedHDRModeIdentifier: String? = nil
    @State private var menuSelectedHDRDDCValue: UInt16? = nil
    @State private var menuSelectedPresetDDCValue: UInt16 = 4
    @State private var menuBrightness: Double = 75.0
    @State private var menuContrast: Double = 80.0
    @State private var menuSaturation: Double = 50.0
    @State private var menuVividPixelLevel: Double = 50.0
    @State private var menuBlueLightFilterDDCValue: UInt16 = 0
    @State private var menuShadowBoostDDCValue: UInt16 = 0
    @State private var menuGammaDDCValue: UInt16 = 120
    @State private var menuColorTempPresetDDCValue: UInt16 = 11
    @State private var menuRedValue: Double = 100
    @State private var menuGreenValue: Double = 100
    @State private var menuBlueValue: Double = 100
    @State private var menuAdjustableHDROn: Bool = false
    @State private var menuVrrEnabled: Bool = false
    
    private let gameVisualViewInstance = GameVisualView()
    var gvPresets: [GameVisualPreset] {
        gameVisualViewInstance.gameVisualPresets
    }
    var gvHdrStandardPresets: [HdrPreset] {
        gameVisualViewInstance.hdrStandardPresets
    }
    var gvHdrDolbyPresets: [HdrPreset] {
        gameVisualViewInstance.hdrDolbyPresets
    }
    var gvColorTempOptions: [VCPickerOption] {
        gameVisualViewInstance.colorTempOptions
    }
    var gvColorSpaceOptions: [ColorSpaceOption] {
        gameVisualViewInstance.colorSpaceOptions
    }
    var gvBlueLightOptions: [VCPickerOption] {
        gameVisualViewInstance.blueLightOptions
    }
    var gvShadowBoostOptions: [VCPickerOption] {
        gameVisualViewInstance.shadowBoostOptions
    }
    var gvGammaOptions: [VCPickerOption] { gameVisualViewInstance.gammaOptions }
    
    private var gvAllDisplayableModesInMenu: [DisplayablePreset] {
        var combined: [DisplayablePreset] = []
        for preset in gvPresets {
            let valueToSelect =
            preset.ddcValueWideGamut ?? preset.ddcValueSRGB ?? preset
                .ddcValueDCIP3 ?? 9999
            if valueToSelect != 9999 {
                combined.append(
                    DisplayablePreset(
                        name: preset.mode.name,
                        iconName: preset.mode.iconName,
                        identifier: preset.mode.identifier,
                        isHDRMode: false,
                        command: VCP.Codes.GAMEVISUAL_PRESET,
                        value: valueToSelect,
                        mainCategoryIdentifier: preset.mode.identifier
                    )
                )
            }
        }
        for hdrPreset in gvHdrStandardPresets {
            combined.append(
                DisplayablePreset(
                    name: hdrPreset.name,
                    iconName: "h.square.fill",
                    identifier: hdrPreset.identifier,
                    isHDRMode: true,
                    command: VCP.Codes.HDR_SETTING,
                    value: hdrPreset.ddcValue,
                    mainCategoryIdentifier: "hdr"
                )
            )
        }
        for hdrPreset in gvHdrDolbyPresets {
            combined.append(
                DisplayablePreset(
                    name: hdrPreset.name,
                    iconName: "video.badge.waveform",
                    identifier: hdrPreset.identifier,
                    isHDRMode: true,
                    command: VCP.Codes.HDR_SETTING,
                    value: hdrPreset.ddcValue,
                    mainCategoryIdentifier: "hdr_dolby"
                )
            )
        }
        return combined
    }
    var menuIsCurrentlyInHDRMode: Bool {
        menuSelectedHDRDDCValue != nil && menuSelectedHDRDDCValue != 0
    }
    var menuCurrentPresetNameText: String {
        if let hdrId = menuSelectedHDRModeIdentifier,
           let hdrPreset = gvHdrStandardPresets.first(where: {
               $0.identifier == hdrId
           }) ?? gvHdrDolbyPresets.first(where: { $0.identifier == hdrId })
        {
            return hdrPreset.name
        } else {
            return gvPresets.first {
                $0.mode.identifier == menuSelectedPresetIdentifier
            }?.mode.name ?? menuSelectedPresetIdentifier.capitalized
        }
    }
    var menuIsUserColorTempSelected: Bool { menuColorTempPresetDDCValue == 11 }
    var menuAreSlidersAdjustable: Bool {
        !menuIsCurrentlyInHDRMode || menuAdjustableHDROn
    }
    
    // MARK: - GamePlus States
    @State private var menuGpSelectedModeIdentifier: String = "crosshair"
    @State private var menuGpSelectedCrosshairStyleId: String = "off"
    @State private var menuGpSelectedTimerValue: Int? = nil
    @State private var menuGpSelectedFpsOptionId: String = "off"
    @State private var menuGpDisplayAlignmentOn: Bool = false
    
    private let gamePlusViewInstance = GamePlusView()
    var gpModes: [SelectableMode] { gamePlusViewInstance.gamePlusModes }
    var gpCrosshairStyles: [CrosshairStyle] {
        gamePlusViewInstance.crosshairStyles
    }
    var gpTimerOptions: [(label: String, value: Int?, ddcValue: UInt16)] {
        gamePlusViewInstance.timerOptions
    }
    var gpFpsOptions: [(mode: SelectableMode, ddcValue: UInt16)] {
        gamePlusViewInstance.fpsOptions
    }
    
    // MARK: - OLED Care States
    @State private var menuOledScreenDimmingOn: Bool = false
    @State private var menuOledLogoDetectionOn: Bool = false
    @State private var menuOledUniformBrightnessOn: Bool = false
    @State private var menuOledTaskbarDetectionOn: Bool = false
    @State private var menuOledBoundaryDetectionOn: Bool = false
    @State private var menuOledOuterDimmingOn: Bool = false
    @State private var menuOledGlobalDimmingOn: Bool = false
    @State private var menuOledCleaningReminderDDCValue: UInt16 = 8
    @State private var menuOledScreenMoveDDCValue: UInt16 = 2
    
    private let oledCareViewInstance = OLEDCareView()
    var oledReminderOptions: [ReminderOption] {
        oledCareViewInstance.reminderOptions
    }
    var oledScreenMoveOptions: [ScreenMoveOption] {
        oledCareViewInstance.screenMoveOptions
    }
    
    // MARK: - OSD Settings States
    @State private var menuOsdTimeoutValue: Double = 60.0
    @State private var menuOsdTransparencyValue: Double = 0.0
    @AppStorage("osdModifier1_menu") private var menuOsdModifier1Raw: String =
    ModifierKeyOption.control.rawValue
    @AppStorage("osdModifier2_menu") private var menuOsdModifier2Raw: String =
    ModifierKeyOption.none.rawValue
    
    private var menuOsdModifier1: ModifierKeyOption {
        ModifierKeyOption(rawValue: menuOsdModifier1Raw) ?? .control
    }
    private var menuOsdModifier2: ModifierKeyOption {
        ModifierKeyOption(rawValue: menuOsdModifier2Raw) ?? .none
    }
    private var menuPrimaryModifierOptions: [ModifierKeyOption] {
        ModifierKeyOption.allCases.filter {
            $0 != .none && $0.rawValue != menuOsdModifier2Raw
        }
    }
    private var menuSecondaryModifierOptions: [ModifierKeyOption] {
        ModifierKeyOption.allCases.filter { $0.rawValue != menuOsdModifier1Raw }
    }
    private var menuFullModifierString: String {
        let mod1 = menuOsdModifier1
        let mod2 = menuOsdModifier2
        if mod2 == .none || mod1 == mod2 {
            return mod1.description
        } else {
            let sortedMasks = [mod1.keyMask, mod2.keyMask]
                .compactMap { $0?.rawValue }
                .sorted { $0 > $1 }
            let descriptions = sortedMasks.compactMap { rawValue -> String? in
                switch EventModifiers(rawValue: rawValue) {
                    case .command: return ModifierKeyOption.command.description
                    case .option: return ModifierKeyOption.option.description
                    case .control: return ModifierKeyOption.control.description
                    case .shift: return ModifierKeyOption.shift.description
                    default: return nil
                }
            }
            return descriptions.joined(separator: " + ")
        }
    }
    
    // MARK: - System Settings States
    @State private var menuSysPowerSettingId: String = "Standard"
    @State private var menuSysAuraLightModeId: String = "OFF"
    @State private var menuSysPowerIndicatorModeId: UInt16 = 1
    @State private var menuSysProximityDistanceId: String = "OFF"
    @State private var menuSysProximityTimerId: String = "10min"
    @State private var menuSysSelectedKVMInputId: UInt16? = nil
    
    private let systemSettingsViewInstance = SystemSettingsView()
    var sysPowerOptions:
    [(id: String, title: String, description: String, ddcValue: UInt16)]
    { systemSettingsViewInstance.powerOptions }
    var sysAuraOptions: [(mode: SelectableMode, ddcValue: UInt16)] {
        systemSettingsViewInstance.auraOptions
    }
    var sysPowerIndicatorOptions: [PowerIndicatorOption] {
        systemSettingsViewInstance.powerIndicatorOptions
    }
    var sysDistanceOptions: [SelectableMode] {
        systemSettingsViewInstance.distanceOptions
    }
    var sysTimerOptions: [SelectableMode] {
        systemSettingsViewInstance.timerOptions
    }
    var sysKvmInputOptions: [(name: String, iconName: String, ddcValue: UInt16)]
    { systemSettingsViewInstance.kvmInputOptions }
    
    // MARK: - Pip States
    @State private var menuPipSelectedModeDDCValue: UInt16 = 0
    @State private var menuPipSelectedSourceDDCValue: UInt16 = 6682
    
    private let pipViewInstance = PipView()
    var pipModeOptions_menu: [PipModeOption] { pipViewInstance.pipModeOptions }
    var pipSourceOptions_menu: [PipSourceOption] {
        pipViewInstance.pipSourceOptions
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if viewModel.isScanning {
                    ProgressView("Scanning for monitors...")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.matchedServices.isEmpty
                            || viewModel.selectedDisplayID == nil
                {
                    VStack(spacing: 8) {
                        Text("\(viewModel.targetMonitorName) not found.")
                            .font(.headline)
                        Text("Please ensure it's connected and powered on.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if viewModel.matchedServices.count > 0
                            && viewModel.selectedDisplayID == nil
                        {
                            Picker(
                                "Select Monitor:",
                                selection: $viewModel.selectedDisplayID
                            ) {
                                Text("Select a Display").tag(
                                    nil as CGDirectDisplayID?
                                )
                                ForEach(viewModel.matchedServices) { service in
                                    Text(
                                        service.serviceDetails.productName
                                            .isEmpty
                                        ? "\(viewModel.targetMonitorName) (ID: \(service.displayID))"
                                        : service.serviceDetails.productName
                                    )
                                    .tag(
                                        service.displayID as CGDirectDisplayID?
                                    )
                                }
                            }
                            .labelsHidden()
                            .padding(.horizontal)
                        }
                        Button("Rescan Monitors") { viewModel.scanMonitors() }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monitor: \(viewModel.selectedMonitorName)")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Status: \(viewModel.statusMessage)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    Divider()
                    
                    if isLoadingMenuState {
                        ProgressView("Loading Settings...")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        DisclosureGroup("GameVisual") {
                            gameVisualMenuContent().padding(.leading, 10)
                        }
                        DisclosureGroup("GamePlus") {
                            gamePlusMenuContent().padding(.leading, 10)
                        }
                        DisclosureGroup("OLED Care") {
                            oledCareMenuContent().padding(.leading, 10)
                        }
                        DisclosureGroup("OSD") {
                            osdMenuContent().padding(.leading, 10)
                        }
                        DisclosureGroup("System Settings") {
                            systemSettingsMenuContent().padding(.leading, 10)
                        }
                        DisclosureGroup("Picture-in-Picture") {
                            pipMenuContent().padding(.leading, 10)
                        }
                    }
                }
                
                Divider().padding(.vertical, 4)
                
                VStack(spacing: 6) {
                    Button("Rescan Monitors") { viewModel.scanMonitors() }
                        .disabled(viewModel.isScanning)
                        .buttonStyle(.bordered).controlSize(.small)
                    Button("Open \(Bundle.main.appName ?? "App")") {
                        NSApp.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.windows.first(
                            where: { $0.windowNumber > 0 && $0.isVisible })
                        {
                            window.makeKeyAndOrderFront(nil)
                        } else {
                            NotificationCenter.default.post(
                                name: NSApplication
                                    .didFinishLaunchingNotification,
                                object: nil
                            )
                        }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    Button("Quit \(Bundle.main.appName ?? "App")") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }
        .frame(
            minWidth: 300,
            idealWidth: 350,
            maxWidth: 400,
            minHeight: 200,
            idealHeight: 550,
            maxHeight: (NSScreen.main?.visibleFrame.height ?? 700) * 0.8
        )
        .onAppear(perform: handleMenuOnAppear)
        .onChange(of: viewModel.selectedDisplayID) { _ in
            handleMenuMonitorChange()
        }
        .alert(
            "Enable HDR in System Settings",
            isPresented: $showEnableHDRAlertInMenu
        ) {
            Button("Open Display Settings") { openDisplaySettingsInMenu() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "To use HDR presets, please enable 'High Dynamic Range' for this display in macOS System Settings."
            )
        }
    }
    
    // MARK: - Menu Section Content Views
    
    @ViewBuilder
    private func gameVisualMenuContent() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Preset:", selection: $menuSelectedPresetIdentifier) {
                ForEach(
                    gvAllDisplayableModesInMenu.filter {
                        !$0.isHDRMode && $0.identifier != "hdr"
                        && $0.identifier != "hdr_dolby"
                    }
                ) { preset in
                    Text(preset.name).tag(preset.identifier)
                }
            }.controlSize(.small)
                .disabled(menuIsCurrentlyInHDRMode)
                .onChange(of: menuSelectedPresetIdentifier) { newPresetId in
                    guard !isUpdatingProgrammatically else { return }
                    let mode = gvAllDisplayableModesInMenu.first(where: {
                        $0.identifier == newPresetId
                    })
                    if let mode = mode { handleMenuGVModeSelection(mode) }
                }
            
            Picker("HDR Mode:", selection: $menuSelectedHDRModeIdentifier) {
                Text("Off (SDR)").tag(nil as String?)
                ForEach(gvAllDisplayableModesInMenu.filter { $0.isHDRMode }) {
                    preset in
                    Text(preset.name).tag(preset.identifier as String?)
                }
            }.controlSize(.small)
                .onChange(of: menuSelectedHDRModeIdentifier) { newHdrId in
                    guard !isUpdatingProgrammatically else { return }
                    if let newHdrId = newHdrId,
                       let mode = gvAllDisplayableModesInMenu.first(where: {
                           $0.identifier == newHdrId
                       })
                    {
                        handleMenuGVModeSelection(mode)
                    } else if newHdrId == nil {
                        let currentSDRMode =
                        gvAllDisplayableModesInMenu.first {
                            $0.identifier == menuSelectedPresetIdentifier
                            && !$0.isHDRMode
                        }
                        ?? gvAllDisplayableModesInMenu.first {
                            $0.identifier == "user" && !$0.isHDRMode
                        }!
                        handleMenuGVModeSelection(currentSDRMode)
                    }
                }
            
            if !menuIsCurrentlyInHDRMode
                && menuSelectedPresetIdentifier != "srgb"
            {
                Picker(
                    "Color Space:",
                    selection: $menuSelectedColorSpaceIdentifier
                ) {
                    ForEach(gvColorSpaceOptions) { option in
                        Text(option.name).tag(option.identifier)
                    }
                }.controlSize(.small)
                    .onChange(of: menuSelectedColorSpaceIdentifier) {
                        newSpaceId in
                        guard !isUpdatingProgrammatically else { return }
                        handleMenuGVColorSpaceChange(newSpaceId)
                    }
            } else {
                Text(
                    "Color Space: \(menuSelectedColorSpaceIdentifier.uppercased()) (Fixed)"
                )
                .font(.caption).foregroundColor(.secondary)
            }
            
            Divider()
            let sliderNeedsDisabling =
            menuIsCurrentlyInHDRMode
            ? (menuSelectedHDRModeIdentifier != "hdr_console"
               && menuSelectedHDRModeIdentifier != "hdr_dolby_console")
            : menuBlueLightFilterDDCValue == 4
            MenuSliderView(
                label: "Brightness",
                value: $menuBrightness,
                range: 0...100,
                ddcStep: 1,
                decimals: 0,
                vcpCode: VCP.Codes.BRIGHTNESS,
                viewModel: viewModel,
                isUpdatingProgrammatically: $isUpdatingProgrammatically,
                onCommit: { scheduleMenuFetch(category: .gameVisual) }
            )
            .disabled(sliderNeedsDisabling)
            MenuSliderView(
                label: "Contrast",
                value: $menuContrast,
                range: 0...100,
                ddcStep: 1,
                decimals: 0,
                vcpCode: VCP.Codes.CONTRAST,
                viewModel: viewModel,
                isUpdatingProgrammatically: $isUpdatingProgrammatically,
                onCommit: { scheduleMenuFetch(category: .gameVisual) }
            )
            .disabled(menuIsCurrentlyInHDRMode && !menuAdjustableHDROn)
            MenuSliderView(
                label: "Saturation",
                value: $menuSaturation,
                range: 0...100,
                ddcStep: 1,
                decimals: 0,
                vcpCode: VCP.Codes.SATURATION,
                viewModel: viewModel,
                isUpdatingProgrammatically: $isUpdatingProgrammatically,
                onCommit: { scheduleMenuFetch(category: .gameVisual) }
            )
            .disabled(
                menuSelectedPresetIdentifier == "srgb" || sliderNeedsDisabling
            )
            MenuSliderView(
                label: "VividPixel",
                value: $menuVividPixelLevel,
                range: 0...100,
                ddcStep: 10,
                decimals: 0,
                vcpCode: VCP.Codes.VIVID_PIXEL,
                viewModel: viewModel,
                isUpdatingProgrammatically: $isUpdatingProgrammatically,
                onCommit: { scheduleMenuFetch(category: .gameVisual) }
            )
            .disabled(
                menuSelectedPresetIdentifier == "srgb" || sliderNeedsDisabling
            )
            
            Picker(
                "Blue Light Filter:",
                selection: $menuBlueLightFilterDDCValue
            ) {
                ForEach(gvBlueLightOptions) { option in
                    Text(option.name).tag(option.ddcValue)
                }
            }.controlSize(.small)
                .onChange(of: menuBlueLightFilterDDCValue) {
                    handleMenuGVPickerChange(
                        code: VCP.Codes.BLUE_LIGHT,
                        newValue: $0
                    )
                }
                .disabled(
                    menuSelectedPresetIdentifier == "srgb"
                    || menuIsCurrentlyInHDRMode
                )
            
            Picker("Shadow Boost:", selection: $menuShadowBoostDDCValue) {
                ForEach(gvShadowBoostOptions) { option in
                    Text(option.name).tag(option.ddcValue)
                }
            }.controlSize(.small)
                .onChange(of: menuShadowBoostDDCValue) {
                    handleMenuGVPickerChange(
                        code: VCP.Codes.SHADOW_BOOST,
                        newValue: $0
                    )
                }
                .disabled(
                    menuSelectedPresetIdentifier == "srgb"
                    || menuSelectedPresetIdentifier == "moba"
                    || menuIsCurrentlyInHDRMode
                )
            
            Picker("Gamma:", selection: $menuGammaDDCValue) {
                ForEach(gvGammaOptions) { option in
                    Text(option.name).tag(option.ddcValue)
                }
            }.controlSize(.small)
                .onChange(of: menuGammaDDCValue) {
                    handleMenuGVPickerChange(code: VCP.Codes.GAMMA, newValue: $0)
                }
                .disabled(
                    menuSelectedPresetIdentifier == "srgb"
                    || menuIsCurrentlyInHDRMode
                )
            
            Picker("Color Temp:", selection: $menuColorTempPresetDDCValue) {
                ForEach(gvColorTempOptions) { Text($0.name).tag($0.ddcValue) }
            }.controlSize(.small)
                .onChange(of: menuColorTempPresetDDCValue) {
                    handleMenuGVPickerChange(
                        code: VCP.Codes.COLOR_TEMP_PRESET,
                        newValue: $0
                    )
                }
                .disabled(
                    menuSelectedPresetIdentifier == "srgb"
                    || (menuIsCurrentlyInHDRMode && !menuAdjustableHDROn)
                )
            
            if menuIsUserColorTempSelected
                && !menuSelectedPresetIdentifier.elementsEqual("srgb")
                && (!menuIsCurrentlyInHDRMode || menuAdjustableHDROn)
            {
                MenuSliderView(
                    label: "Red",
                    value: $menuRedValue,
                    range: 0...100,
                    ddcStep: 1,
                    decimals: 0,
                    vcpCode: VCP.Codes.GAIN_R,
                    viewModel: viewModel,
                    isUpdatingProgrammatically: $isUpdatingProgrammatically,
                    onCommit: { scheduleMenuFetch(category: .gameVisual) }
                )
                MenuSliderView(
                    label: "Green",
                    value: $menuGreenValue,
                    range: 0...100,
                    ddcStep: 1,
                    decimals: 0,
                    vcpCode: VCP.Codes.GAIN_G,
                    viewModel: viewModel,
                    isUpdatingProgrammatically: $isUpdatingProgrammatically,
                    onCommit: { scheduleMenuFetch(category: .gameVisual) }
                )
                MenuSliderView(
                    label: "Blue",
                    value: $menuBlueValue,
                    range: 0...100,
                    ddcStep: 1,
                    decimals: 0,
                    vcpCode: VCP.Codes.GAIN_B,
                    viewModel: viewModel,
                    isUpdatingProgrammatically: $isUpdatingProgrammatically,
                    onCommit: { scheduleMenuFetch(category: .gameVisual) }
                )
            }
            
            Toggle("Adjustable HDR", isOn: $menuAdjustableHDROn)
                .onChange(of: menuAdjustableHDROn) {
                    handleMenuGVToggleChange(
                        code: VCP.Codes.ADJUSTABLE_HDR,
                        enabled: $0
                    )
                }
                .disabled(!menuIsCurrentlyInHDRMode)
                .opacity(!menuIsCurrentlyInHDRMode ? 0.6 : 1.0)
                .controlSize(.small)
            
            Toggle("Variable Refresh Rate", isOn: $menuVrrEnabled)
                .onChange(of: menuVrrEnabled) {
                    handleMenuGVToggleChange(code: VCP.Codes.VRR, enabled: $0)
                }
                .controlSize(.small)
        }
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func gamePlusMenuContent() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Mode:", selection: $menuGpSelectedModeIdentifier) {
                ForEach(gpModes) { mode in Text(mode.name).tag(mode.identifier)
                }
            }.controlSize(.small)
                .onChange(of: menuGpSelectedModeIdentifier) { newModeId in
                    guard !isUpdatingProgrammatically else { return }
                    handleMenuGPModeChange(newModeId: newModeId)
                }
            
            if menuGpSelectedModeIdentifier == "crosshair" {
                Picker(
                    "Crosshair Style:",
                    selection: $menuGpSelectedCrosshairStyleId
                ) {
                    ForEach(gpCrosshairStyles) { style in
                        Text(style.name).tag(style.identifier)
                    }
                }.controlSize(.small)
                    .onChange(of: menuGpSelectedCrosshairStyleId) {
                        newStyleId in
                        guard !isUpdatingProgrammatically else { return }
                        setMenuGPCrosshairDDC(styleIdentifier: newStyleId)
                    }
                Text("Crosshair Position:").font(.caption)
                HStack(spacing: 4) {
                    Button("↑") {
                        sendMenuGPPositionCommand(
                            GamePlusPositionControl.PositionCommand.up
                        )
                    }
                    Button("↓") {
                        sendMenuGPPositionCommand(
                            GamePlusPositionControl.PositionCommand.down
                        )
                    }
                    Button("←") {
                        sendMenuGPPositionCommand(
                            GamePlusPositionControl.PositionCommand.left
                        )
                    }
                    Button("→") {
                        sendMenuGPPositionCommand(
                            GamePlusPositionControl.PositionCommand.right
                        )
                    }
                    Button("◎") {  // Reset Button
                        resetMenuGPCrosshairPosition()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(menuGpSelectedCrosshairStyleId == "off")
                
            } else if menuGpSelectedModeIdentifier == "timer" {
                Picker("Timer Duration:", selection: $menuGpSelectedTimerValue)
                {
                    Text("OFF").tag(nil as Int?)
                    ForEach(
                        gpTimerOptions.filter { $0.value != nil },
                        id: \.ddcValue
                    ) { option in
                        Text(option.label).tag(option.value as Int?)
                    }
                }.controlSize(.small)
                    .onChange(of: menuGpSelectedTimerValue) { newTimerValue in
                        guard !isUpdatingProgrammatically else { return }
                        let ddcVal =
                        gpTimerOptions.first(where: {
                            $0.value == newTimerValue
                        })?.ddcValue ?? 0
                        sendMenuGPCommand(
                            code: VCP.Codes.GAMEPLUS_TIMER,
                            value: ddcVal,
                            description: "Timer"
                        )
                    }
            } else if menuGpSelectedModeIdentifier == "fps" {
                Picker("FPS Counter:", selection: $menuGpSelectedFpsOptionId) {
                    ForEach(gpFpsOptions, id: \.mode.identifier) { option in
                        Text(option.mode.name).tag(option.mode.identifier)
                    }
                }.controlSize(.small)
                    .onChange(of: menuGpSelectedFpsOptionId) { newFpsId in
                        guard !isUpdatingProgrammatically else { return }
                        let ddcVal =
                        gpFpsOptions.first(where: {
                            $0.mode.identifier == newFpsId
                        })?.ddcValue ?? 0
                        sendMenuGPCommand(
                            code: VCP.Codes.GAMEPLUS_FPS_COUNTER,
                            value: ddcVal,
                            description: "FPS Counter"
                        )
                    }
            } else if menuGpSelectedModeIdentifier == "displayAlignment" {
                Toggle("Display Alignment", isOn: $menuGpDisplayAlignmentOn)
                    .onChange(of: menuGpDisplayAlignmentOn) { newState in
                        guard !isUpdatingProgrammatically else { return }
                        sendMenuGPCommand(
                            code: VCP.Codes.OLED_TARGET_MODE,
                            value: newState ? 1 : 0,
                            description: "Display Alignment"
                        )
                    }
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func oledCareMenuContent() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Screen Dimming", isOn: $menuOledScreenDimmingOn)
                .controlSize(.small)
                .onChange(of: menuOledScreenDimmingOn) { _ in
                    if !isUpdatingProgrammatically {
                        sendMenuOledCombinedFlags()
                    }
                }
            Toggle("Logo Detection", isOn: $menuOledLogoDetectionOn)
                .controlSize(.small)
                .onChange(of: menuOledLogoDetectionOn) { _ in
                    if !isUpdatingProgrammatically {
                        sendMenuOledCombinedFlags()
                    }
                }
            Toggle("Uniform Brightness", isOn: $menuOledUniformBrightnessOn)
                .controlSize(.small)
                .onChange(of: menuOledUniformBrightnessOn) { _ in
                    if !isUpdatingProgrammatically {
                        sendMenuOledCombinedFlags()
                    }
                }
            Toggle("Taskbar Detection", isOn: $menuOledTaskbarDetectionOn)
                .controlSize(.small)
                .onChange(of: menuOledTaskbarDetectionOn) { _ in
                    if !isUpdatingProgrammatically {
                        sendMenuOledCombinedFlags()
                    }
                }
            Toggle("Boundary Detection", isOn: $menuOledBoundaryDetectionOn)
                .controlSize(.small)
                .onChange(of: menuOledBoundaryDetectionOn) { _ in
                    if !isUpdatingProgrammatically {
                        sendMenuOledCombinedFlags()
                    }
                }
            Toggle("Outer Dimming (Pixel Shift)", isOn: $menuOledOuterDimmingOn)
                .controlSize(.small)
                .onChange(of: menuOledOuterDimmingOn) { _ in
                    if !isUpdatingProgrammatically {
                        sendMenuOledCombinedFlags()
                    }
                }
            Toggle("Global Dimming (ABL)", isOn: $menuOledGlobalDimmingOn)
                .controlSize(.small)
                .onChange(of: menuOledGlobalDimmingOn) { _ in
                    if !isUpdatingProgrammatically {
                        sendMenuOledCombinedFlags()
                    }
                }
            
            Divider()
            Button("Run Pixel Cleaning Now") {
                viewModel.triggerPixelCleaningDDC()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .buttonStyle(.bordered)
            .controlSize(.small)
            Divider()
            
            Picker(
                "Cleaning Reminder:",
                selection: $menuOledCleaningReminderDDCValue
            ) {
                ForEach(oledCareViewInstance.reminderOptions) { option in
                    Text(option.label).tag(option.ddcValue)
                }
            }.controlSize(.small)
                .onChange(of: menuOledCleaningReminderDDCValue) {
                    handleMenuOledPickerChange(
                        code: VCP.Codes.OLED_CLEANING_REMINDER,
                        ddcValue: $0
                    )
                }
            
            Picker("Screen Move:", selection: $menuOledScreenMoveDDCValue) {
                ForEach(oledCareViewInstance.screenMoveOptions) { option in
                    Text(option.label).tag(option.ddcValue)
                }
            }.controlSize(.small)
                .onChange(of: menuOledScreenMoveDDCValue) {
                    handleMenuOledPickerChange(
                        code: VCP.Codes.OLED_SCREEN_MOVE,
                        ddcValue: $0
                    )
                }
        }
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func osdMenuContent() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MenuSliderView(
                label: "Timeout (s)",
                value: $menuOsdTimeoutValue,
                range: 0...120,
                ddcStep: 1,
                decimals: 0,
                isCombinedOSD: true,
                otherOSDValue: $menuOsdTransparencyValue,
                isTimeoutSlider: true,
                viewModel: viewModel,
                isUpdatingProgrammatically: $isUpdatingProgrammatically,
                onCommit: { scheduleMenuFetch(category: .osd) }
            )
            
            MenuSliderView(
                label: "Transparency (%)",
                value: $menuOsdTransparencyValue,
                range: 0...100,
                ddcStep: 20,
                decimals: 0,
                isCombinedOSD: true,
                otherOSDValue: $menuOsdTimeoutValue,
                isTimeoutSlider: false,
                viewModel: viewModel,
                isUpdatingProgrammatically: $isUpdatingProgrammatically,
                onCommit: { scheduleMenuFetch(category: .osd) }
            )
            
            Divider()
            DisclosureGroup(
                "Keyboard Navigation Shortcuts (\(menuFullModifierString))"
            ) {
                VStack(alignment: .leading, spacing: 5) {
                    Button("Up (\(menuFullModifierString) + ↑)") {
                        sendMenuOSDNavCommand(VCP.Values.OSDNavCommand.up)
                    }
                    Button("Down (\(menuFullModifierString) + ↓)") {
                        sendMenuOSDNavCommand(VCP.Values.OSDNavCommand.down)
                    }
                    Button("Left (\(menuFullModifierString) + ←)") {
                        sendMenuOSDNavCommand(VCP.Values.OSDNavCommand.left)
                    }
                    Button("Right (\(menuFullModifierString) + →)") {
                        sendMenuOSDNavCommand(VCP.Values.OSDNavCommand.right)
                    }
                    Button("Open OSD (\(menuFullModifierString) + 0)") {
                        sendMenuOSDNavCommand(VCP.Values.OSDNavCommand.open)
                    }
                    Button("Select (\(menuFullModifierString) + Enter)") {
                        sendMenuOSDNavCommand(VCP.Values.OSDNavCommand.select)
                    }
                    Button("Exit (\(menuFullModifierString) + Esc)") {
                        sendMenuOSDNavCommand(VCP.Values.OSDNavCommand.exit)
                    }
                }.padding(.leading).buttonStyle(.plain).controlSize(.small)
            }
            DisclosureGroup("Shortcut Modifiers") {
                VStack(alignment: .leading, spacing: 5) {
                    Picker("Primary Key:", selection: $menuOsdModifier1Raw) {
                        ForEach(menuPrimaryModifierOptions) { option in
                            Text(option.description).tag(option.rawValue)
                        }
                    }.controlSize(.small)
                        .onChange(of: menuOsdModifier1Raw) {
                            newPrimaryRawValue in
                            if newPrimaryRawValue
                                != ModifierKeyOption.none.rawValue
                                && newPrimaryRawValue == menuOsdModifier2Raw
                            {
                                menuOsdModifier2Raw =
                                ModifierKeyOption.none.rawValue
                            }
                        }
                    
                    Picker("Secondary Key:", selection: $menuOsdModifier2Raw) {
                        ForEach(menuSecondaryModifierOptions) { option in
                            Text(option.description).tag(option.rawValue)
                        }
                    }.controlSize(.small)
                        .onChange(of: menuOsdModifier2Raw) {
                            newSecondaryRawValue in
                            if newSecondaryRawValue
                                != ModifierKeyOption.none.rawValue
                                && newSecondaryRawValue == menuOsdModifier1Raw
                            {
                                menuOsdModifier2Raw =
                                ModifierKeyOption.none.rawValue
                            }
                        }
                }.padding(.leading)
            }
        }
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func systemSettingsMenuContent() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Power Mode:", selection: $menuSysPowerSettingId) {
                ForEach(sysPowerOptions, id: \.id) { Text($0.title).tag($0.id) }
            }.controlSize(.small)
                .onChange(of: menuSysPowerSettingId) { newId in
                    guard !isUpdatingProgrammatically else { return }
                    let ddcVal =
                    sysPowerOptions.first(where: { $0.id == newId })?
                        .ddcValue ?? 0
                    handleMenuSysSimpleWrite(
                        code: VCP.Codes.POWER_MODE,
                        value: ddcVal,
                        description: "Power Mode"
                    )
                }
            
            Picker("Aura Lights:", selection: $menuSysAuraLightModeId) {
                ForEach(sysAuraOptions, id: \.mode.identifier) {
                    Text($0.mode.name).tag($0.mode.identifier)
                }
            }.controlSize(.small)
                .onChange(of: menuSysAuraLightModeId) { newId in
                    guard !isUpdatingProgrammatically else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        let ddcVal =
                        sysAuraOptions.first(where: {
                            $0.mode.identifier == newId
                        })?.ddcValue ?? 0
                        handleMenuSysSimpleWrite(
                            code: VCP.Codes.AURA_LIGHT,
                            value: ddcVal,
                            description: "Aura Lights"
                        )
                    }
                }
            
            Picker("Power Indicator:", selection: $menuSysPowerIndicatorModeId)
            {
                ForEach(sysPowerIndicatorOptions) {
                    Text($0.title).tag($0.ddcValue)
                }
            }.controlSize(.small)
                .onChange(of: menuSysPowerIndicatorModeId) {
                    handleMenuSysSimpleWrite(
                        code: VCP.Codes.POWER_INDICATOR,
                        value: $0,
                        description: "Power Indicator"
                    )
                }
            
            DisclosureGroup("Proximity Sensor") {
                VStack(alignment: .leading, spacing: 5) {
                    Picker("Distance:", selection: $menuSysProximityDistanceId)
                    {
                        ForEach(sysDistanceOptions) {
                            Text($0.name).tag($0.identifier)
                        }
                    }.controlSize(.small)
                        .onChange(of: menuSysProximityDistanceId) { _ in
                            if !isUpdatingProgrammatically {
                                sendMenuSysProximityCommand()
                            }
                        }
                    Picker("Timeout:", selection: $menuSysProximityTimerId) {
                        ForEach(sysTimerOptions) {
                            Text($0.name).tag($0.identifier)
                        }
                    }.controlSize(.small)
                        .onChange(of: menuSysProximityTimerId) { _ in
                            if !isUpdatingProgrammatically {
                                sendMenuSysProximityCommand()
                            }
                        }
                        .disabled(menuSysProximityDistanceId == "OFF")
                }.padding(.leading)
            }
            
            Picker("KVM Input:", selection: $menuSysSelectedKVMInputId) {
                Text("Unknown / Auto").tag(nil as UInt16?)
                ForEach(sysKvmInputOptions, id: \.ddcValue) { kvmOption in
                    Text(kvmOption.name).tag(kvmOption.ddcValue as UInt16?)
                }
            }.controlSize(.small)
                .onChange(of: menuSysSelectedKVMInputId) { newInputId in
                    guard !isUpdatingProgrammatically, let ddcValue = newInputId
                    else { return }
                    handleMenuSysSimpleWrite(
                        code: VCP.Codes.CAPABILITIES_REQUEST,  // Still F3 for KVM switch action
                        value: ddcValue,
                        description: "KVM Input"
                    )
                }
        }
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func pipMenuContent() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("PiP Mode:", selection: $menuPipSelectedModeDDCValue) {
                ForEach(pipModeOptions_menu) { option in
                    Text(option.name).tag(option.id)
                }
            }
            .controlSize(.small)
            .onChange(of: menuPipSelectedModeDDCValue) { newModeDDC in
                guard !isUpdatingProgrammatically else { return }
                handleMenuPipSimpleWrite(
                    code: VCP.Codes.PIP_MODE_LAYOUT,
                    value: newModeDDC,
                    description: "PiP Mode"
                )
            }
            
            Picker("PiP Source:", selection: $menuPipSelectedSourceDDCValue) {
                ForEach(pipSourceOptions_menu) { option in
                    Text(option.name).tag(option.id)
                }
            }
            .controlSize(.small)
            .onChange(of: menuPipSelectedSourceDDCValue) { newSourceDDC in
                guard !isUpdatingProgrammatically else { return }
                handleMenuPipSimpleWrite(
                    code: VCP.Codes.PIP_CONTROL,
                    value: newSourceDDC,
                    description: "PiP Source"
                )
            }
            .disabled(menuPipSelectedModeDDCValue == 0)
            .opacity(menuPipSelectedModeDDCValue == 0 ? 0.6 : 1.0)
        }
        .padding(.vertical, 5)
    }
    
    enum MenuFetchCategory {
        case gameVisual, gamePlus, oledCare, osd, systemSettings, pip, all
    }
    
    private func handleMenuPipSimpleWrite(
        code: UInt8,
        value: UInt16,
        description: String
    ) {
        guard !isUpdatingProgrammatically else { return }
        viewModel.writeDDC(command: code, value: value) { success, msg in
            if !success {
                scheduleMenuFetch(category: .pip)
                viewModel.updateStatus("Error setting menu \(description)")
            }
            if code == VCP.Codes.PIP_MODE_LAYOUT {
                scheduleMenuFetch(category: .pip, delay: 0.3)
            }
        }
    }
    private func handleMenuOnAppear() {
        if viewModel.selectedDisplayID != nil
            && !hasFetchedMenuOnceForCurrentMonitor
        {
            fetchAllStatesForMenu(category: .all)
        } else if viewModel.selectedDisplayID == nil {
            isLoadingMenuState = false
            hasFetchedMenuOnceForCurrentMonitor = false
        }
        if viewModel.matchedServices.isEmpty && !viewModel.isScanning {
            viewModel.scanMonitors()
        }
    }
    
    private func handleMenuMonitorChange() {
        hasFetchedMenuOnceForCurrentMonitor = false
        if viewModel.selectedDisplayID != nil {
            fetchAllStatesForMenu(category: .all)
        } else {
            isLoadingMenuState = false
        }
    }
    
    private func scheduleMenuFetch(
        category: MenuFetchCategory,
        delay: TimeInterval = 0.3
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            fetchAllStatesForMenu(category: category)
        }
    }
    
    private let errorAccumulationLock = NSLock()
    
    private func fetchAllStatesForMenu(category: MenuFetchCategory) {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            self.isLoadingMenuState = false
            self.hasFetchedMenuOnceForCurrentMonitor = false
            self.isUpdatingProgrammatically = false
            return
        }
        
        if category == .all && self.isLoadingMenuState
            && hasFetchedMenuOnceForCurrentMonitor
        {
            return
        } else if category == .all {
            self.isLoadingMenuState = true
        }
        
        self.isUpdatingProgrammatically = true
        
        let mainGroup = DispatchGroup()
        var collectedFetchErrors: [String] = []
        
        let categoriesToFetch: [MenuFetchCategory]
        if category == .all {
            categoriesToFetch = [
                .gameVisual, .gamePlus, .oledCare, .osd, .systemSettings, .pip,
            ]
        } else {
            categoriesToFetch = [category]
        }
        
        if categoriesToFetch.isEmpty {
            if category == .all { self.isLoadingMenuState = false }
            self.isUpdatingProgrammatically = false
            DispatchQueue.main.async {
                if category == .all {
                    self.hasFetchedMenuOnceForCurrentMonitor = true
                }
                if !collectedFetchErrors.isEmpty {
                    viewModel.updateStatus(
                        "Menu: Error reading settings (\(collectedFetchErrors.count) failed)."
                    )
                } else if category == .all {
                    viewModel.updateStatus(
                        "Selected: \(viewModel.selectedMonitorName)"
                    )
                }
            }
            return
        }
        
        for cat in categoriesToFetch {
            mainGroup.enter()
            switch cat {
                case .gameVisual:
                    fetchGameVisualStateForMenu { errors in
                        self.errorAccumulationLock.lock()
                        collectedFetchErrors.append(contentsOf: errors)
                        self.errorAccumulationLock.unlock()
                        mainGroup.leave()
                    }
                case .gamePlus:
                    fetchGamePlusStateForMenu { errors in
                        self.errorAccumulationLock.lock()
                        collectedFetchErrors.append(contentsOf: errors)
                        self.errorAccumulationLock.unlock()
                        mainGroup.leave()
                    }
                case .oledCare:
                    fetchOLEDCareStateForMenu { errors in
                        self.errorAccumulationLock.lock()
                        collectedFetchErrors.append(contentsOf: errors)
                        self.errorAccumulationLock.unlock()
                        mainGroup.leave()
                    }
                case .osd:
                    fetchOSDStateForMenu { errors in
                        self.errorAccumulationLock.lock()
                        collectedFetchErrors.append(contentsOf: errors)
                        self.errorAccumulationLock.unlock()
                        mainGroup.leave()
                    }
                case .systemSettings:
                    fetchSystemSettingsStateForMenu { errors in
                        self.errorAccumulationLock.lock()
                        collectedFetchErrors.append(contentsOf: errors)
                        self.errorAccumulationLock.unlock()
                        mainGroup.leave()
                    }
                case .pip:
                    fetchPipStateForMenu { errors in
                        self.errorAccumulationLock.lock()
                        collectedFetchErrors.append(contentsOf: errors)
                        self.errorAccumulationLock.unlock()
                        mainGroup.leave()
                    }
                case .all:  // Should not be reached if categoriesToFetch is handled correctly
                    mainGroup.leave()
                    break
            }
        }
        
        mainGroup.notify(queue: .main) {
            guard viewModel.selectedDisplayID == currentDisplayID else {
                if category == .all { self.isLoadingMenuState = false }
                self.isUpdatingProgrammatically = false
                return
            }
            
            if category == .all {
                self.hasFetchedMenuOnceForCurrentMonitor = true
                self.isLoadingMenuState = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {  // Allow UI updates to settle
                self.isUpdatingProgrammatically = false
            }
            
            if !collectedFetchErrors.isEmpty {
                viewModel.updateStatus(
                    "Menu: Error reading settings (\(collectedFetchErrors.count) failed)."
                )
                print("Menu Fetch Errors: \(collectedFetchErrors)")
            } else if category == .all {
                viewModel.updateStatus(
                    "Selected: \(viewModel.selectedMonitorName)"
                )
            }
        }
    }
    
    // MARK: - GameVisual Menu Logic & Mappings
    private func fetchGameVisualStateForMenu(
        completion: @escaping ([String]) -> Void
    ) {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            completion([])
            return
        }
        
        var fetchedValues: [UInt8: UInt16] = [:]
        var localCategoryErrors: [String] = []
        let codesToRead: [UInt8] = [
            VCP.Codes.BRIGHTNESS, VCP.Codes.CONTRAST, VCP.Codes.GAMEVISUAL_PRESET,
            VCP.Codes.HDR_SETTING,
            VCP.Codes.BLUE_LIGHT, VCP.Codes.SHADOW_BOOST, VCP.Codes.VIVID_PIXEL,
            VCP.Codes.SATURATION,
            VCP.Codes.GAMMA, VCP.Codes.COLOR_TEMP_PRESET, VCP.Codes.GAIN_R,
            VCP.Codes.GAIN_G, VCP.Codes.GAIN_B,
            VCP.Codes.ADJUSTABLE_HDR, VCP.Codes.VRR,
        ]
        let localGroup = DispatchGroup()
        for code in codesToRead {
            localGroup.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard viewModel.selectedDisplayID == currentDisplayID else {
                    localGroup.leave()
                    return
                }
                if let currentValue = current {
                    fetchedValues[code] = currentValue
                } else {
                    localCategoryErrors.append(
                        "GV:\(String(format:"0x%02X", code))-\(msg)"
                    )
                }
                localGroup.leave()
            }
        }
        localGroup.notify(queue: .main) {
            updateMenuGVStateFromFetchedValues(fetchedValues)
            completion(localCategoryErrors)
        }
    }
    
    private func updateMenuGVStateFromFetchedValues(_ values: [UInt8: UInt16]) {
        // This function should be run on the main thread and after `isUpdatingProgrammatically` is set to true.
        // isUpdatingProgrammatically = true // Ensure this is set before updating @State vars
        
        let fetchedDCValue = values[VCP.Codes.GAMEVISUAL_PRESET]
        let fetchedE2Value = values[VCP.Codes.HDR_SETTING]
        let hdrActiveOnMonitor = fetchedE2Value != nil && fetchedE2Value != 0
        let specificHdrIdOnMonitor =
        hdrActiveOnMonitor ? mapMenuDdcToHdrPresetId(fetchedE2Value!) : nil
        
        menuSelectedHDRDDCValue = fetchedE2Value
        if let dcVal = fetchedDCValue { menuSelectedPresetDDCValue = dcVal }
        
        if hdrActiveOnMonitor, let currentSpecificHdrId = specificHdrIdOnMonitor
        {
            menuSelectedHDRModeIdentifier = currentSpecificHdrId
            menuSelectedPresetIdentifier =
            currentSpecificHdrId.contains("dolby") ? "hdr_dolby" : "hdr"
            if let dcValueFromMonitor = fetchedDCValue {
                let (_, spaceId) = mapMenuDdcToPresetAndSpaceIds(
                    dcValueFromMonitor
                )
                menuSelectedColorSpaceIdentifier = spaceId
            } else {
                menuSelectedColorSpaceIdentifier = "wide"
            }
        } else {
            menuSelectedHDRModeIdentifier = nil
            if let dcValueFromMonitor = fetchedDCValue {
                let (presetId, spaceId) = mapMenuDdcToPresetAndSpaceIds(
                    dcValueFromMonitor
                )
                menuSelectedPresetIdentifier = presetId
                menuSelectedColorSpaceIdentifier =
                (presetId == "srgb") ? "srgb" : spaceId
            } else {
                menuSelectedPresetIdentifier = "user"
                menuSelectedColorSpaceIdentifier = "wide"
            }
        }
        
        menuBrightness = Double(
            values[VCP.Codes.BRIGHTNESS, default: UInt16(self.menuBrightness)]
        )
        menuContrast = Double(
            values[VCP.Codes.CONTRAST, default: UInt16(self.menuContrast)]
        )
        menuBlueLightFilterDDCValue = values[VCP.Codes.BLUE_LIGHT, default: 0]
        menuShadowBoostDDCValue = values[VCP.Codes.SHADOW_BOOST, default: 0]
        menuVividPixelLevel = Double(
            values[
                VCP.Codes.VIVID_PIXEL,
                default: UInt16(self.menuVividPixelLevel)
            ]
        )
        menuAdjustableHDROn =
        (values[
            VCP.Codes.ADJUSTABLE_HDR,
            default: self.menuAdjustableHDROn ? 1 : 0
        ] == 1)
        menuVrrEnabled =
        (values[VCP.Codes.VRR, default: self.menuVrrEnabled ? 1 : 0] == 1)
        menuSaturation = Double(
            values[VCP.Codes.SATURATION, default: UInt16(self.menuSaturation)]
        )
        menuGammaDDCValue = values[VCP.Codes.GAMMA, default: 120]
        menuColorTempPresetDDCValue =
        values[
            VCP.Codes.COLOR_TEMP_PRESET,
            default: self.menuColorTempPresetDDCValue
        ]
        menuRedValue = Double(
            values[VCP.Codes.GAIN_R, default: UInt16(self.menuRedValue)]
        )
        menuGreenValue = Double(
            values[VCP.Codes.GAIN_G, default: UInt16(self.menuGreenValue)]
        )
        menuBlueValue = Double(
            values[VCP.Codes.GAIN_B, default: UInt16(self.menuBlueValue)]
        )
    }
    
    private func mapMenuDdcToPresetAndSpaceIds(_ ddcValue: UInt16) -> (
        presetId: String, spaceId: String
    ) {
        if ddcValue == 3 { return ("srgb", "srgb") }
        for preset in gvPresets where preset.mode.identifier != "srgb" {
            if preset.ddcValueWideGamut == ddcValue {
                return (preset.mode.identifier, "wide")
            }
            if preset.ddcValueSRGB == ddcValue {
                return (preset.mode.identifier, "srgb")
            }
            if preset.ddcValueDCIP3 == ddcValue {
                return (preset.mode.identifier, "p3")
            }
        }
        return ("user", "wide")
    }
    
    private func mapMenuDdcToHdrPresetId(_ ddcValue: UInt16) -> String? {
        if let standard = gvHdrStandardPresets.first(where: {
            $0.ddcValue == ddcValue
        }) {
            return standard.identifier
        }
        if let dolby = gvHdrDolbyPresets.first(where: {
            $0.ddcValue == ddcValue
        }) {
            return dolby.identifier
        }
        return nil
    }
    
    private func handleMenuGVModeSelection(_ mode: DisplayablePreset) {
        guard !isLoadingMenuState, !isUpdatingProgrammatically else { return }
        isUpdatingProgrammatically = true
        
        if !mode.isHDRMode {
            menuSelectedPresetIdentifier = mode.identifier
            menuSelectedHDRModeIdentifier = nil
            menuSelectedHDRDDCValue = nil
            if mode.identifier == "srgb" {
                menuSelectedColorSpaceIdentifier = "srgb"
            }
            
            viewModel.writeDDC(command: VCP.Codes.HDR_SETTING, value: 0) {
                hdrSuccess,
                _ in
                guard
                    let presetData = self.gvPresets.first(where: {
                        $0.mode.identifier == self.menuSelectedPresetIdentifier
                    })
                else {
                    self.isUpdatingProgrammatically = false
                    self.scheduleMenuFetch(category: .gameVisual)
                    return
                }
                var dcValueToSend = self.menuSelectedPresetDDCValue
                let targetSpace =
                (self.menuSelectedPresetIdentifier == "srgb")
                ? "srgb" : self.menuSelectedColorSpaceIdentifier
                
                switch targetSpace {
                    case "wide":
                        dcValueToSend =
                        presetData.ddcValueWideGamut ?? dcValueToSend
                    case "srgb":
                        dcValueToSend = presetData.ddcValueSRGB ?? dcValueToSend
                    case "p3":
                        dcValueToSend = presetData.ddcValueDCIP3 ?? dcValueToSend
                    default: break
                }
                if self.menuSelectedPresetIdentifier == "srgb" {
                    dcValueToSend = presetData.ddcValueSRGB ?? 3
                }
                
                self.viewModel.writeDDC(
                    command: VCP.Codes.GAMEVISUAL_PRESET,
                    value: dcValueToSend
                ) { dcSuccess, _ in
                    self.isUpdatingProgrammatically = false
                    self.scheduleMenuFetch(category: .gameVisual, delay: 0.8)
                }
            }
        } else {
            menuSelectedPresetIdentifier = mode.mainCategoryIdentifier
            menuSelectedHDRModeIdentifier = mode.identifier
            menuSelectedHDRDDCValue = mode.value
            
            guard let displayID = viewModel.selectedDisplayID else {
                isUpdatingProgrammatically = false
                scheduleMenuFetch(category: .gameVisual)
                return
            }
            
            if isSystemHDREnabledInMenu(for: displayID) {
                viewModel.writeDDC(
                    command: VCP.Codes.HDR_SETTING,
                    value: mode.value
                ) { success, _ in
                    self.isUpdatingProgrammatically = false
                    self.scheduleMenuFetch(category: .gameVisual, delay: 0.8)
                }
            } else {
                displayIDForMenuHDRAlert = displayID
                showEnableHDRAlertInMenu = true
                self.isUpdatingProgrammatically = false
                scheduleMenuFetch(category: .gameVisual)
            }
        }
    }
    
    private func handleMenuGVColorSpaceChange(_ newSpaceId: String) {
        guard viewModel.selectedDisplayID != nil, !isLoadingMenuState,
              !isUpdatingProgrammatically
        else { return }
        guard menuSelectedPresetIdentifier != "srgb" else {
            if menuSelectedColorSpaceIdentifier != "srgb" {
                isUpdatingProgrammatically = true
                menuSelectedColorSpaceIdentifier = "srgb"
                DispatchQueue.main.async {
                    self.isUpdatingProgrammatically = false
                }
            }
            return
        }
        
        isUpdatingProgrammatically = true
        menuSelectedColorSpaceIdentifier = newSpaceId
        
        guard
            let presetData = gvPresets.first(where: {
                $0.mode.identifier == menuSelectedPresetIdentifier
            })
        else {
            self.isUpdatingProgrammatically = false
            scheduleMenuFetch(category: .gameVisual)
            return
        }
        var dcValueToSend = menuSelectedPresetDDCValue
        switch newSpaceId {
            case "wide":
                dcValueToSend = presetData.ddcValueWideGamut ?? dcValueToSend
            case "srgb": dcValueToSend = presetData.ddcValueSRGB ?? dcValueToSend
            case "p3": dcValueToSend = presetData.ddcValueDCIP3 ?? dcValueToSend
            default: break
        }
        
        viewModel.writeDDC(
            command: VCP.Codes.GAMEVISUAL_PRESET,
            value: dcValueToSend
        ) { success, _ in
            self.isUpdatingProgrammatically = false
            self.scheduleMenuFetch(category: .gameVisual, delay: 0.8)
        }
    }
    
    private func handleMenuGVPickerChange(code: UInt8, newValue: UInt16) {
        guard !isUpdatingProgrammatically else { return }
        viewModel.writeDDC(command: code, value: newValue) { success, msg in
            if !success {
                scheduleMenuFetch(category: .gameVisual)
            } else {
                let needsFullRefetch =
                (code == VCP.Codes.COLOR_TEMP_PRESET)
                || (code == VCP.Codes.BLUE_LIGHT && newValue == 4)
                || (code == VCP.Codes.SHADOW_BOOST) || (code == VCP.Codes.GAMMA)
                if needsFullRefetch {
                    scheduleMenuFetch(category: .gameVisual, delay: 0.3)
                }
            }
        }
    }
    
    private func handleMenuGVToggleChange(code: UInt8, enabled: Bool) {
        guard !isUpdatingProgrammatically else { return }
        let ddcValue: UInt16 = enabled ? 1 : 0
        
        viewModel.writeDDC(command: code, value: ddcValue) { success, msg in
            if !success {
                scheduleMenuFetch(category: .gameVisual)
            } else {
                if code == VCP.Codes.VRR {
                    scheduleMenuFetch(category: .gameVisual, delay: 2.0)
                } else if code == VCP.Codes.ADJUSTABLE_HDR {
                    scheduleMenuFetch(category: .gameVisual, delay: 0.3)
                }
            }
        }
    }
    
    private func isSystemHDREnabledInMenu(for displayID: CGDirectDisplayID)
    -> Bool
    {
        guard
            let screen = NSScreen.screens.first(where: {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                 as? CGDirectDisplayID) == displayID
            })
        else { return false }
        return screen.maximumPotentialExtendedDynamicRangeColorComponentValue
        > 1.0
    }
    
    private func openDisplaySettingsInMenu() {
        guard
            let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.displays"
            )
        else { return }
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - GamePlus Menu Logic
    private func fetchGamePlusStateForMenu(
        completion: @escaping ([String]) -> Void
    ) {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            completion([])
            return
        }
        
        var fetchedValues: [UInt8: UInt16] = [:]
        var localCategoryErrors: [String] = []
        let codesToRead: [UInt8] = [
            VCP.Codes.GAMEPLUS_CROSSHAIR, VCP.Codes.GAMEPLUS_TIMER,
            VCP.Codes.GAMEPLUS_FPS_COUNTER, VCP.Codes.OLED_TARGET_MODE,  // For Display Alignment
        ]
        let localGroup = DispatchGroup()
        for code in codesToRead {
            localGroup.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard viewModel.selectedDisplayID == currentDisplayID else {
                    localGroup.leave()
                    return
                }
                if let currentValue = current {
                    fetchedValues[code] = currentValue
                } else {
                    localCategoryErrors.append(
                        "GP:\(String(format:"0x%02X", code))-\(msg)"
                    )
                }
                localGroup.leave()
            }
        }
        localGroup.notify(queue: .main) {
            // isUpdatingProgrammatically = true // Already set by fetchAllStatesForMenu
            if let crosshairVal = fetchedValues[VCP.Codes.GAMEPLUS_CROSSHAIR] {
                menuGpSelectedCrosshairStyleId =
                getMenuGPCrosshairStyleId(ddcValue: crosshairVal) ?? "off"
            }
            if let timerVal = fetchedValues[VCP.Codes.GAMEPLUS_TIMER] {
                menuGpSelectedTimerValue =
                gpTimerOptions.first(where: { $0.ddcValue == timerVal })?
                    .value
            }
            if let fpsVal = fetchedValues[VCP.Codes.GAMEPLUS_FPS_COUNTER] {
                menuGpSelectedFpsOptionId =
                gpFpsOptions.first(where: { $0.ddcValue == fpsVal })?.mode
                    .identifier ?? "off"
            }
            if let alignmentVal = fetchedValues[VCP.Codes.OLED_TARGET_MODE] {
                menuGpDisplayAlignmentOn = (alignmentVal == 1)
            }
            completion(localCategoryErrors)
        }
    }
    
    private func handleMenuGPModeChange(newModeId: String) {
        if newModeId == "displayAlignment" {  // Only fetch specifically for alignment if it's selected
            guard !isUpdatingProgrammatically,
                  let did = viewModel.selectedDisplayID
            else { return }
            viewModel.readDDC(command: VCP.Codes.OLED_TARGET_MODE) {
                current,
                _,
                _ in
                if let current = current {
                    DispatchQueue.main.async {
                        let wasUpdating = self.isUpdatingProgrammatically
                        self.isUpdatingProgrammatically = true
                        self.menuGpDisplayAlignmentOn = (current == 1)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01)
                        {  // Allow UI to settle
                            self.isUpdatingProgrammatically = wasUpdating
                        }
                    }
                }
            }
        }
        // For other modes, the selection change itself is enough, DDC write will confirm or fail.
    }
    
    private func setMenuGPCrosshairDDC(styleIdentifier: String) {
        guard
            let value = getMenuGPCrosshairDDCValue(
                styleIdentifier: styleIdentifier
            )
        else { return }
        sendMenuGPCommand(
            code: VCP.Codes.GAMEPLUS_CROSSHAIR,
            value: value,
            description: "Crosshair Style"
        )
    }
    
    private func sendMenuGPPositionCommand(
        _ position: GamePlusPositionControl.PositionCommand
    ) {
        sendMenuGPCommand(
            code: VCP.Codes.GAMEPLUS_POSITION_CONTROL,
            value: position.rawValue,
            description: "Crosshair Position"
        )
    }
    
    private func resetMenuGPCrosshairPosition() {
        guard
            let currentStyleDDC = getMenuGPCrosshairDDCValue(
                styleIdentifier: menuGpSelectedCrosshairStyleId
            ),
            currentStyleDDC != 0
        else { return }
        
        viewModel.writeDDC(command: VCP.Codes.GAMEPLUS_CROSSHAIR, value: 0) {
            success,
            _ in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {  // Increased delay
                    viewModel.writeDDC(
                        command: VCP.Codes.GAMEPLUS_CROSSHAIR,
                        value: currentStyleDDC
                    ) { _, _ in
                        scheduleMenuFetch(category: .gamePlus, delay: 0.2)
                    }
                }
            } else {
                scheduleMenuFetch(category: .gamePlus)  // Fetch even on initial fail
            }
        }
    }
    
    private func sendMenuGPCommand(
        code: UInt8,
        value: UInt16,
        description: String
    ) {
        guard !isUpdatingProgrammatically else { return }
        viewModel.writeDDC(command: code, value: value) { success, msg in
            if !success {
                scheduleMenuFetch(category: .gamePlus)
                viewModel.updateStatus("Error setting \(description)")
            }
            // For FPS and Timer, a quick re-fetch might be good if the monitor provides immediate feedback.
            // For Display Alignment, a re-fetch might also be useful.
            if code == VCP.Codes.GAMEPLUS_FPS_COUNTER
                || code == VCP.Codes.GAMEPLUS_TIMER
                || code == VCP.Codes.OLED_TARGET_MODE
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    scheduleMenuFetch(category: .gamePlus)
                }
            }
        }
    }
    
    public func getMenuGPCrosshairDDCValue(styleIdentifier: String) -> UInt16? {
        return getMenuGPCrosshairDDCValue(
            styleIdentifier: styleIdentifier,
            altMode: false
        )
    }
    
    public func getMenuGPCrosshairDDCValue(
        styleIdentifier: String,
        altMode: Bool
    )
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
    
    private func getMenuGPCrosshairStyleId(ddcValue: UInt16) -> String? {
        return gpCrosshairStyles.first(where: { style in
            getMenuGPCrosshairDDCValue(styleIdentifier: style.identifier)
            == ddcValue
        })?.identifier
    }
    
    // MARK: - OLED Care Menu Logic & Mappings
    private func fetchOLEDCareStateForMenu(
        completion: @escaping ([String]) -> Void
    ) {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            completion([])
            return
        }
        
        var fetchedValues: [UInt8: UInt16] = [:]
        var localCategoryErrors: [String] = []
        let codesToRead: [UInt8] = [
            VCP.Codes.OLED_CARE_FLAGS, VCP.Codes.OLED_CLEANING_REMINDER,
            VCP.Codes.OLED_SCREEN_MOVE,
        ]
        let localGroup = DispatchGroup()
        for code in codesToRead {
            localGroup.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard viewModel.selectedDisplayID == currentDisplayID else {
                    localGroup.leave()
                    return
                }
                if let currentValue = current {
                    fetchedValues[code] = currentValue
                } else {
                    localCategoryErrors.append(
                        "OLED:\(String(format:"0x%02X", code))-\(msg)"
                    )
                }
                localGroup.leave()
            }
        }
        localGroup.notify(queue: .main) {
            // isUpdatingProgrammatically = true // Already set
            if let flagsValue = fetchedValues[VCP.Codes.OLED_CARE_FLAGS] {
                let flags = OLEDCareFlags(rawValue: flagsValue)
                menuOledScreenDimmingOn = flags.contains(VCP.Values.CareFeatures.SCREEN_DIMMING)
                menuOledLogoDetectionOn = flags.contains(VCP.Values.CareFeatures.LOGO_DETECTION)
                menuOledUniformBrightnessOn = flags.contains(VCP.Values.CareFeatures.UNIFORM_BRIGHTNESS)
                menuOledTaskbarDetectionOn = flags.contains(VCP.Values.CareFeatures.TASKBAR_DETECTION)
                menuOledBoundaryDetectionOn = flags.contains(VCP.Values.CareFeatures.BOUNDARY_DETECTION)
                menuOledOuterDimmingOn = flags.contains(VCP.Values.CareFeatures.OUTER_DIMMING)
                menuOledGlobalDimmingOn = flags.contains(VCP.Values.CareFeatures.GLOBAL_DIMMING)
            }
            menuOledCleaningReminderDDCValue =
            fetchedValues[VCP.Codes.OLED_CLEANING_REMINDER, default: 8]
            menuOledScreenMoveDDCValue =
            fetchedValues[VCP.Codes.OLED_SCREEN_MOVE, default: 2]
            
            completion(localCategoryErrors)
        }
    }
    
    private func sendMenuOledCombinedFlags() {
        guard !isUpdatingProgrammatically else { return }
        var flags: OLEDCareFlags = []
        if menuOledScreenDimmingOn { flags.insert(VCP.Values.CareFeatures.SCREEN_DIMMING) }
        if menuOledLogoDetectionOn { flags.insert(VCP.Values.CareFeatures.LOGO_DETECTION) }
        if menuOledUniformBrightnessOn { flags.insert(VCP.Values.CareFeatures.UNIFORM_BRIGHTNESS) }
        if menuOledTaskbarDetectionOn { flags.insert(VCP.Values.CareFeatures.TASKBAR_DETECTION) }
        if menuOledBoundaryDetectionOn { flags.insert(VCP.Values.CareFeatures.BOUNDARY_DETECTION) }
        if menuOledOuterDimmingOn { flags.insert(VCP.Values.CareFeatures.OUTER_DIMMING) }
        if menuOledGlobalDimmingOn { flags.insert(VCP.Values.CareFeatures.GLOBAL_DIMMING) }
        
        viewModel.writeDDC(
            command: VCP.Codes.OLED_CARE_FLAGS,
            value: flags.rawValue
        ) { success, _ in
            if !success { scheduleMenuFetch(category: .oledCare) }
        }
    }
    
    private func triggerPixelCleaningInMenu() {
        viewModel.triggerPixelCleaningDDC()
    }
    
    private func handleMenuOledPickerChange(code: UInt8, ddcValue: UInt16) {
        guard !isUpdatingProgrammatically else { return }
        viewModel.writeDDC(command: code, value: ddcValue) { success, _ in
            if !success { scheduleMenuFetch(category: .oledCare) }
        }
    }
    
    // MARK: - OSD Menu Logic
    private func fetchOSDStateForMenu(completion: @escaping ([String]) -> Void)
    {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            completion([])
            return
        }
        var localCategoryErrors: [String] = []
        
        viewModel.readDDC(command: VCP.Codes.OSD_SETTINGS) { current, _, msg in
            guard viewModel.selectedDisplayID == currentDisplayID else {
                completion(localCategoryErrors)
                return
            }
            if let currentValue = current {
                // isUpdatingProgrammatically = true // Already set
                let timeoutRead = Double(currentValue % 256).clamped(
                    to: 0...120
                )
                let transparencyBaseRead = Double(currentValue / 256)
                let validTransparencySteps: [Double] = [0, 20, 40, 60, 80, 100]
                let closestTransparencyStep =
                validTransparencySteps.min(by: {
                    abs($0 - transparencyBaseRead)
                    < abs($1 - transparencyBaseRead)
                }) ?? 0
                
                menuOsdTimeoutValue = timeoutRead
                menuOsdTransparencyValue = closestTransparencyStep
            } else {
                localCategoryErrors.append(
                    "OSD:\(String(format:"0x%02X", VCP.Codes.OSD_SETTINGS))-\(msg)"
                )
            }
            completion(localCategoryErrors)
        }
    }
    
    private func sendMenuOSDNavCommand(
        _ commandValue: VCP.Values.OSDNavCommand
    ) {
        guard !isUpdatingProgrammatically else { return }
        viewModel.writeDDC(
            command: VCP.Codes.OSD_CONTROL,
            value: commandValue.rawValue
        ) { success, msg in
            if !success {
                viewModel.updateStatus("OSD Nav Error: \(msg)")
            } else {
                // viewModel.updateStatus("OSD Nav: \(commandValue) sent.") // Optional: can be too noisy
            }
        }
    }
    
    // MARK: - System Settings Menu Logic
    private func fetchSystemSettingsStateForMenu(
        completion: @escaping ([String]) -> Void
    ) {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            completion([])
            return
        }
        
        var fetchedValues: [UInt8: UInt16] = [:]
        var localCategoryErrors: [String] = []
        let codesToRead: [UInt8] = [
            VCP.Codes.POWER_MODE, VCP.Codes.AURA_LIGHT, VCP.Codes.POWER_INDICATOR,
            VCP.Codes.PROXIMITY_SENSOR,
            VCP.Codes.CAPABILITIES_REQUEST,  // For KVM status
        ]
        let localGroup = DispatchGroup()
        for code in codesToRead {
            localGroup.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard viewModel.selectedDisplayID == currentDisplayID else {
                    localGroup.leave()
                    return
                }
                if let currentValue = current {
                    fetchedValues[code] = currentValue
                } else {
                    localCategoryErrors.append(
                        "SYS:\(String(format:"0x%02X", code))-\(msg)"
                    )
                }
                localGroup.leave()
            }
        }
        localGroup.notify(queue: .main) {
            // isUpdatingProgrammatically = true // Already set
            if let powerVal = fetchedValues[VCP.Codes.POWER_MODE] {
                menuSysPowerSettingId =
                sysPowerOptions.first { $0.ddcValue == powerVal }?.id
                ?? "Standard"
            }
            if let auraVal = fetchedValues[VCP.Codes.AURA_LIGHT] {
                menuSysAuraLightModeId =
                sysAuraOptions.first { $0.ddcValue == auraVal }?.mode
                    .identifier ?? "OFF"
            }
            if let indicatorVal = fetchedValues[VCP.Codes.POWER_INDICATOR] {
                menuSysPowerIndicatorModeId =
                sysPowerIndicatorOptions.first {
                    $0.ddcValue == indicatorVal
                }?.ddcValue ?? 1
            }
            if let proximityVal = fetchedValues[VCP.Codes.PROXIMITY_SENSOR] {
                let (distId, timeId) = mapMenuDDCValueToProximityIds(
                    proximityVal
                )
                menuSysProximityDistanceId = distId
                menuSysProximityTimerId = timeId
            }
            if let kvmVal = fetchedValues[VCP.Codes.CAPABILITIES_REQUEST] {
                if sysKvmInputOptions.contains(where: { $0.ddcValue == kvmVal })
                {
                    menuSysSelectedKVMInputId = kvmVal
                } else {
                    // Don't reset to nil here if KVM read doesn't match,
                    // as it might just be a capabilities string.
                    // KVM selection is mostly write-only for UI.
                }
            }
            completion(localCategoryErrors)
        }
    }
    
    private func handleMenuSysSimpleWrite(
        code: UInt8,
        value: UInt16,
        description: String
    ) {
        guard !isUpdatingProgrammatically else { return }
        viewModel.writeDDC(command: code, value: value) { success, msg in
            if !success {
                scheduleMenuFetch(category: .systemSettings)
                viewModel.updateStatus("Error setting menu \(description)")
            }
            if code == VCP.Codes.CAPABILITIES_REQUEST
                && description.starts(with: "KVM")
            {
                scheduleMenuFetch(category: .systemSettings, delay: 1.0)  // Longer delay for KVM switch
            }
        }
    }
    
    private func sendMenuSysProximityCommand() {
        guard !isUpdatingProgrammatically else { return }
        let distId = menuSysProximityDistanceId
        let timerId = menuSysProximityTimerId
        
        let ddcValue: UInt16?
        if distId == "OFF" {
            ddcValue = 1280
        } else {
            switch (distId, timerId) {
                case ("60cm", "5min"): ddcValue = 259
                case ("60cm", "10min"): ddcValue = 1283
                case ("60cm", "15min"): ddcValue = 2563
                case ("90cm", "5min"): ddcValue = 258
                case ("90cm", "10min"): ddcValue = 1282
                case ("90cm", "15min"): ddcValue = 2562
                case ("120cm", "5min"): ddcValue = 257
                case ("120cm", "10min"): ddcValue = 1281
                case ("120cm", "15min"): ddcValue = 2561
                case ("Tailored", "5min"): ddcValue = 511
                case ("Tailored", "10min"): ddcValue = 1535
                case ("Tailored", "15min"): ddcValue = 2815
                default: ddcValue = nil
            }
        }
        
        if let val = ddcValue {
            handleMenuSysSimpleWrite(
                code: VCP.Codes.PROXIMITY_SENSOR,
                value: val,
                description: "Proximity Sensor"
            )
        } else {
            viewModel.updateStatus("Invalid Proximity settings.")
            scheduleMenuFetch(category: .systemSettings)
        }
    }
    
    private func mapMenuDDCValueToProximityIds(_ ddcValue: UInt16) -> (
        distanceId: String, timerId: String
    ) {
        switch ddcValue {
            case 1280: return ("OFF", "10min")
            case 259: return ("60cm", "5min")
            case 1283: return ("60cm", "10min")
            case 2563: return ("60cm", "15min")
            case 258: return ("90cm", "5min")
            case 1282: return ("90cm", "10min")
            case 2562: return ("90cm", "15min")
            case 257: return ("120cm", "5min")
            case 1281: return ("120cm", "10min")
            case 2561: return ("120cm", "15min")
            case 511: return ("Tailored", "5min")
            case 1535: return ("Tailored", "10min")
            case 2815: return ("Tailored", "15min")
            default: return ("OFF", "10min")
        }
    }
    
    // MARK: - Pip Menu Logic
    private func fetchPipStateForMenu(completion: @escaping ([String]) -> Void)
    {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            completion([])
            return
        }
        
        var fetchedValues: [UInt8: UInt16] = [:]
        var localCategoryErrors: [String] = []
        let codesToRead: [UInt8] = [
            VCP.Codes.PIP_MODE_LAYOUT,
            VCP.Codes.PIP_CONTROL,  // For PiP Source (F5)
        ]
        let localGroup = DispatchGroup()
        for code in codesToRead {
            localGroup.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard viewModel.selectedDisplayID == currentDisplayID else {
                    localGroup.leave()
                    return
                }
                if let currentValue = current {
                    fetchedValues[code] = currentValue
                } else {
                    localCategoryErrors.append(
                        "PIP:\(String(format:"0x%02X", code))-\(msg)"
                    )
                }
                localGroup.leave()
            }
        }
        localGroup.notify(queue: .main) {
            // isUpdatingProgrammatically = true // Already set
            if let modeVal = fetchedValues[VCP.Codes.PIP_MODE_LAYOUT],
               pipModeOptions_menu.contains(where: { $0.id == modeVal })
            {
                menuPipSelectedModeDDCValue = modeVal
            } else {
                menuPipSelectedModeDDCValue = 0  // Default to OFF
            }
            
            if let sourceVal = fetchedValues[VCP.Codes.PIP_CONTROL],
               pipSourceOptions_menu.contains(where: { $0.id == sourceVal })
            {
                menuPipSelectedSourceDDCValue = sourceVal
            } else {
                menuPipSelectedSourceDDCValue = 6682  // Default to USB-C
            }
            completion(localCategoryErrors)
        }
    }
}

// MARK: - Helper Menu Slider View
struct MenuSliderView: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let ddcStep: Double
    var decimals: Int = 0
    
    var isCombinedOSD: Bool = false
    @Binding var otherOSDValue: Double
    var isTimeoutSlider: Bool = false
    
    var vcpCode: UInt8? = nil
    var customWriteAction: ((Double) -> Void)?
    
    @ObservedObject var viewModel: DDCViewModel
    @Binding var isUpdatingProgrammatically: Bool
    var onCommit: (() -> Void)?
    
    @State private var internalEditValue: Double
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        ddcStep: Double,
        decimals: Int = 0,
        isCombinedOSD: Bool = false,
        otherOSDValue: Binding<Double> = .constant(0.0),
        isTimeoutSlider: Bool = false,
        vcpCode: UInt8? = nil,
        customWriteAction: ((Double) -> Void)? = nil,
        viewModel: DDCViewModel,
        isUpdatingProgrammatically: Binding<Bool>,
        onCommit: (() -> Void)? = nil
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.ddcStep = ddcStep
        self.decimals = decimals
        
        self.isCombinedOSD = isCombinedOSD
        self._otherOSDValue = otherOSDValue
        self.isTimeoutSlider = isTimeoutSlider
        self.vcpCode = vcpCode
        self.customWriteAction = customWriteAction
        
        self.viewModel = viewModel
        self._isUpdatingProgrammatically = isUpdatingProgrammatically
        self.onCommit = onCommit
        
        self._internalEditValue = State(initialValue: value.wrappedValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(label): \(internalEditValue, specifier: "%.\(decimals)f")")
                .font(.system(size: 12))
                .lineLimit(1)
            Slider(
                value: $internalEditValue,
                in: range,
                onEditingChanged: { editingDidEnd in
                    if !editingDidEnd {  // editingDidEnd is true when dragging *ends*
                        // This block now executes continuously while dragging
                        // We want to send DDC command when dragging *ends*
                        return
                    }
                    // This block executes when dragging *ends*
                    let ddcOrientedValue =
                    (internalEditValue / ddcStep).rounded() * ddcStep
                    
                    if abs(value - ddcOrientedValue) > (ddcStep / 1000.0) {  // If actual value needs update
                        value = ddcOrientedValue  // Update bound @State
                    }
                    // Always send DDC on commit, even if UI value didn't change but slider was interacted with
                    sendDDCWriteCommand(valueToSend: ddcOrientedValue)
                    
                    if abs(internalEditValue - ddcOrientedValue)
                        > (ddcStep / 1000.0)
                    {  // Snap UI slider visually
                        internalEditValue = ddcOrientedValue
                    }
                }
            )
            .controlSize(.small)
            .onChange(of: value) { newValue in  // Keep internalEditValue in sync if external @State changes
                if abs(internalEditValue - newValue) > (ddcStep / 1000.0) {
                    internalEditValue = newValue
                }
            }
        }
        .padding(.vertical, 3)
    }
    
    private func sendDDCWriteCommand(valueToSend: Double) {
        guard !isUpdatingProgrammatically else { return }
        
        let ddcUInt16Value = UInt16(valueToSend.rounded())
        
        if let action = customWriteAction {
            action(valueToSend)
        } else if isCombinedOSD {
            let otherDdcVal = UInt16(otherOSDValue.rounded())
            let finalDDCValue: UInt16
            
            if isTimeoutSlider {
                finalDDCValue = ddcUInt16Value + (otherDdcVal * 256)
            } else {
                finalDDCValue = otherDdcVal + (ddcUInt16Value * 256)
            }
            viewModel.writeDDC(
                command: VCP.Codes.OSD_SETTINGS,
                value: finalDDCValue
            ) { success, _ in
                self.onCommit?()
            }
        } else if let cmd = vcpCode {
            viewModel.writeDDC(command: cmd, value: ddcUInt16Value) {
                success,
                _ in
                self.onCommit?()
            }
        }
    }
}

extension GamePlusPositionControl {
}
