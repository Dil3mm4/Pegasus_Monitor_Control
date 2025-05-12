// GameVisualView.swift

import AVFoundation
import AppKit
import Combine
import SwiftUI

struct GameVisualView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    // MARK: - Preset Default Values
    static let presetDefaults: [String: [UInt8: UInt16]] = [
        "racing": [
            VCP.Codes.BRIGHTNESS: 15,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.BLUE_LIGHT: 0,
            VCP.Codes.SHADOW_BOOST: 0,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 120,
            VCP.Codes.COLOR_TEMP_PRESET: 5,
            VCP.Codes.VRR: 0,
        ],
        "cinema": [
            VCP.Codes.BRIGHTNESS: 90,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.BLUE_LIGHT: 0,
            VCP.Codes.SHADOW_BOOST: 0,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 120,
            VCP.Codes.COLOR_TEMP_PRESET: 6,
            VCP.Codes.VRR: 0,
        ],
        "scenery": [
            VCP.Codes.BRIGHTNESS: 100,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.BLUE_LIGHT: 0,
            VCP.Codes.SHADOW_BOOST: 0,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 120,
            VCP.Codes.COLOR_TEMP_PRESET: 11,
            VCP.Codes.GAIN_R: 100,
            VCP.Codes.GAIN_G: 100,
            VCP.Codes.GAIN_B: 100,
            VCP.Codes.VRR: 0,
        ],
        "user": [
            VCP.Codes.BRIGHTNESS: 80,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.BLUE_LIGHT: 0,
            VCP.Codes.SHADOW_BOOST: 0,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 120,
            VCP.Codes.COLOR_TEMP_PRESET: 11,
            VCP.Codes.GAIN_R: 100,
            VCP.Codes.GAIN_G: 100,
            VCP.Codes.GAIN_B: 100,
            VCP.Codes.VRR: 0,
        ],
        "rtsrpgmode": [
            VCP.Codes.BRIGHTNESS: 90,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.BLUE_LIGHT: 0,
            VCP.Codes.SHADOW_BOOST: 0,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 160,
            VCP.Codes.COLOR_TEMP_PRESET: 11,
            VCP.Codes.GAIN_R: 100,
            VCP.Codes.GAIN_G: 100,
            VCP.Codes.GAIN_B: 100,
            VCP.Codes.VRR: 0,
        ],
        "fpsmode": [
            VCP.Codes.BRIGHTNESS: 100,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.BLUE_LIGHT: 0,
            VCP.Codes.SHADOW_BOOST: 3,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 100,
            VCP.Codes.COLOR_TEMP_PRESET: 5,
            VCP.Codes.VRR: 0,
        ],
        "moba": [
            VCP.Codes.BRIGHTNESS: 90,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.BLUE_LIGHT: 0,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 120,
            VCP.Codes.COLOR_TEMP_PRESET: 11,
            VCP.Codes.GAIN_R: 100,
            VCP.Codes.GAIN_G: 100,
            VCP.Codes.GAIN_B: 100,
            VCP.Codes.VRR: 0,
        ],
        "nightvision": [
            VCP.Codes.BRIGHTNESS: 30,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.BLUE_LIGHT: 0,
            VCP.Codes.SHADOW_BOOST: 4,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 80,
            VCP.Codes.COLOR_TEMP_PRESET: 11,
            VCP.Codes.GAIN_R: 100,
            VCP.Codes.GAIN_G: 100,
            VCP.Codes.GAIN_B: 100,
            VCP.Codes.VRR: 0,
        ],
        "srgb": [
            VCP.Codes.BRIGHTNESS: 29,
            VCP.Codes.CONTRAST: 80,
            VCP.Codes.VIVID_PIXEL: 50,
            VCP.Codes.SATURATION: 50,
            VCP.Codes.GAMMA: 120,
            VCP.Codes.VRR: 0,
        ],
        "hdr_cinema": [VCP.Codes.ADJUSTABLE_HDR: 0],
        "hdr_gaming": [VCP.Codes.ADJUSTABLE_HDR: 0],
        "hdr_console": [VCP.Codes.ADJUSTABLE_HDR: 0],
        "hdr_400": [VCP.Codes.ADJUSTABLE_HDR: 0],
        "hdr_dolby_cinema": [VCP.Codes.ADJUSTABLE_HDR: 0],
        "hdr_dolby_gaming": [VCP.Codes.ADJUSTABLE_HDR: 0],
        "hdr_dolby_console": [VCP.Codes.ADJUSTABLE_HDR: 0],
        "hdr_dolby_trueblack": [VCP.Codes.ADJUSTABLE_HDR: 0],
    ]
    
    @State private var selectedPresetIdentifier: String = "user"
    @State private var selectedColorSpaceIdentifier: String = "wide"
    @State private var selectedHDRModeIdentifier: String? = nil
    @State private var selectedHDRDDCValue: UInt16? = nil
    @State private var selectedPresetDDCValue: UInt16 = 4
    @State private var brightness: Double = 75
    @State private var contrast: Double = 80
    @State private var blueLightFilterLevel: UInt16 = 0
    @State private var shadowBoostLevel: UInt16 = 0
    @State private var vividPixelLevel: Double = 50
    @State private var saturation: Double = 50
    @State private var gammaDDCValue: UInt16 = 120
    @State private var colorTempPresetDDCValue: UInt16 = 11
    @State private var redValue: Double = 100
    @State private var greenValue: Double = 100
    @State private var blueValue: Double = 100
    @State private var adjustableHDROn: Bool = false
    @State private var vrrEnabled: Bool = false
    @State private var isLoadingState: Bool = false
    @State private var hasFetchedOnceForCurrentMonitor = false
    @State private var isUpdatingProgrammatically: Bool = false
    @State private var isApplyingStoredSettings: Bool = false
    @State private var showEnableHDRAlert: Bool = false
    @State private var displayIDForHDRAlert: CGDirectDisplayID? = nil
    @State private var showFileExporter = false
    @State private var showFileImporter = false
    @State private var exportedSettingsData: Data? = nil
    
    let gameVisualPresets: [GameVisualPreset] = [
        GameVisualPreset(
            mode: SelectableMode(
                name: "CINEMA",
                iconName: "film",
                identifier: "cinema"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.CINEMA_WG,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.CINEMA_SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.CINEMA_DCIP3
        ),
        GameVisualPreset(
            mode: SelectableMode(
                name: "SCENERY",
                iconName: "mountain.2",
                identifier: "scenery"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.SCENERY_WG,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.SCENERY_SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.SCENERY_DCIP3
        ),
        GameVisualPreset(
            mode: SelectableMode(
                name: "USER",
                iconName: "person",
                identifier: "user"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.USER_WG,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.USER_SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.USER_DCIP3
        ),
        GameVisualPreset(
            mode: SelectableMode(
                name: "RACING",
                iconName: "flag.checkered.2.crossed",
                identifier: "racing"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.RACING_WG,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.RACING_SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.RACING_DCIP3
        ),
        GameVisualPreset(
            mode: SelectableMode(
                name: "RTS/RPG Mode",
                iconName: "shield",
                identifier: "rtsrpgmode"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.RTS_WG,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.RTS_SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.RTS_DCIP3
        ),
        GameVisualPreset(
            mode: SelectableMode(
                name: "FPS Mode",
                iconName: "scope",
                identifier: "fpsmode"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.FPS_WG,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.FPS_SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.FPS_DCIP3
        ),
        GameVisualPreset(
            mode: SelectableMode(
                name: "MOBA",
                iconName: "gamecontroller",
                identifier: "moba"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.MOBA_WG,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.MOBA_SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.MOBA_DCIP3
        ),
        GameVisualPreset(
            mode: SelectableMode(
                name: "Night Vision",
                iconName: "moon.stars",
                identifier: "nightvision"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.NIGHT_VISION_WG,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.NIGHT_VISION_SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.NIGHT_VISION_DCIP3
        ),
        GameVisualPreset(
            mode: SelectableMode(
                name: "sRGB",
                iconName: "circle.grid.3x3",
                identifier: "srgb"
            ),
            ddcValueWideGamut: VCP.Values.VisualPresets.SDR.SRGB,
            ddcValueSRGB: VCP.Values.VisualPresets.SDR.SRGB,
            ddcValueDCIP3: VCP.Values.VisualPresets.SDR.SRGB
        ),
    ]
    let hdrStandardPresets: [HdrPreset] = [
        HdrPreset(
            name: "Cinema HDR",
            identifier: "hdr_cinema",
            ddcValue: VCP.Values.VisualPresets.HDR.STANDARD.CINEMA
        ),
        HdrPreset(
            name: "Gaming HDR",
            identifier: "hdr_gaming",
            ddcValue: VCP.Values.VisualPresets.HDR.STANDARD.GAMING
        ),
        HdrPreset(
            name: "Console HDR",
            identifier: "hdr_console",
            ddcValue: VCP.Values.VisualPresets.HDR.STANDARD.CONSOLE
        ),
        HdrPreset(
            name: "HDR400",
            identifier: "hdr_400",
            ddcValue: VCP.Values.VisualPresets.HDR.STANDARD.HDR_400
        ),
    ]
    let hdrDolbyPresets: [HdrPreset] = [
        HdrPreset(
            name: "Dolby Cinema",
            identifier: "hdr_dolby_cinema",
            ddcValue: VCP.Values.VisualPresets.HDR.DOLBY.CINEMA
        ),
        HdrPreset(
            name: "Dolby Gaming",
            identifier: "hdr_dolby_gaming",
            ddcValue: VCP.Values.VisualPresets.HDR.DOLBY.GAMING
        ),
        HdrPreset(
            name: "Dolby Console",
            identifier: "hdr_dolby_console",
            ddcValue: VCP.Values.VisualPresets.HDR.DOLBY.CONSOLE
        ),
        HdrPreset(
            name: "Dolby TrueBlack",
            identifier: "hdr_dolby_trueblack",
            ddcValue: VCP.Values.VisualPresets.HDR.DOLBY.TRUEBLACK
        ),
    ]
    let shadowBoostOptions: [VCPickerOption] = (0...4).map {
        VCPickerOption(
            name: $0 == 0 ? "OFF" : "Level \($0)",
            ddcValue: UInt16($0)
        )
    }
    let blueLightOptions: [VCPickerOption] = (0...4).map {
        VCPickerOption(name: "Level \($0)", ddcValue: UInt16($0))
    }
    let colorTempOptions: [VCPickerOption] = [
        VCPickerOption(name: "4000K", ddcValue: VCP.Values.ColorTemp.FOUR_THOUSAND_K),
        VCPickerOption(name: "5000K", ddcValue: VCP.Values.ColorTemp.FIVE_THOUSAND_K),
        VCPickerOption(name: "6500K", ddcValue: VCP.Values.ColorTemp.SIXTYFIVE_THOUSAND_K),
        VCPickerOption(name: "7500K", ddcValue: VCP.Values.ColorTemp.SEVENTYFIVE_THOUSAND_K),
        VCPickerOption(name: "8200K", ddcValue: VCP.Values.ColorTemp.EIGHTYTWO_THOUSAND_K),
        VCPickerOption(name: "9300K", ddcValue: VCP.Values.ColorTemp.NINETYTHREE_THOUSAND_K),
        VCPickerOption(name: "10000K", ddcValue: VCP.Values.ColorTemp.TEN_THOUSAND_K),
        VCPickerOption(name: "User", ddcValue: VCP.Values.ColorTemp.USER),
    ]
    let vividPixelOptions: [VCPickerOption] = stride(
        from: 0,
        through: 100,
        by: 10
    ).map {
        VCPickerOption(name: "\($0)", ddcValue: UInt16($0))
    }
    let gammaOptions: [VCPickerOption] = [
        VCPickerOption(name: "1.8", ddcValue: VCP.Values.Gamma.ONE_DOT_EIGHT),
        VCPickerOption(name: "2.0", ddcValue: VCP.Values.Gamma.TWO_DOT_ZERO),
        VCPickerOption(name: "2.2", ddcValue: VCP.Values.Gamma.TWO_DOT_TWO),
        VCPickerOption(name: "2.4", ddcValue: VCP.Values.Gamma.TWO_DOT_FOUR),
        VCPickerOption(name: "2.6", ddcValue: VCP.Values.Gamma.TWO_DOT_SIX),
    ]
    let colorSpaceOptions: [ColorSpaceOption] = [
        ColorSpaceOption(name: "Wide Gamut", identifier: "wide"),
        ColorSpaceOption(name: "sRGB", identifier: "srgb"),
        ColorSpaceOption(name: "DCI-P3", identifier: "p3"),
    ]
    let modeButtonColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 100, maximum: 120))
    ]
    
    var isCurrentlyInHDRMode: Bool {
        selectedHDRDDCValue != nil && selectedHDRDDCValue != 0
    }
    var currentPresetName: String {
        if let hdrId = selectedHDRModeIdentifier,
           let hdrPreset = hdrStandardPresets.first(where: {
               $0.identifier == hdrId
           }) ?? hdrDolbyPresets.first(where: { $0.identifier == hdrId })
        {
            return hdrPreset.name
        } else {
            return gameVisualPresets.first {
                $0.mode.identifier == selectedPresetIdentifier
            }?.mode.name ?? selectedPresetIdentifier.capitalized
        }
    }
    
    var isUserColorTempSelected: Bool { colorTempPresetDDCValue == 11 }
    var areSlidersAdjustable: Bool { !isCurrentlyInHDRMode || adjustableHDROn }
    
    private var allDisplayableModes: [DisplayablePreset] {
        var combined: [DisplayablePreset] = []
        for preset in gameVisualPresets {
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
        for hdrPreset in hdrStandardPresets {
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
        for hdrPreset in hdrDolbyPresets {
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
    
    private var sdrModes: [DisplayablePreset] {
        allDisplayableModes.filter { !$0.isHDRMode }
    }
    
    private var hdrModes: [DisplayablePreset] {
        allDisplayableModes.filter { $0.isHDRMode }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("GameVisual").font(.title).fontWeight(.medium)
            if isLoadingState {
                ProgressView("Loading Settings...").frame(
                    maxWidth: .infinity,
                    alignment: .center
                ).padding(.vertical, 50)
            } else if viewModel.selectedDisplayID == nil {
                Text("No monitor selected.").font(.title3).foregroundColor(
                    .secondary
                ).frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                ).padding()
            } else {
                modeSelectionGrid
                settingsHeader
                settingsContent
                bottomButtons
                Spacer()
            }
        }
        .onAppear { handleOnAppear() }
        .onChange(of: viewModel.selectedDisplayID) { handleMonitorChange() }
        .onChange(of: shadowBoostLevel) {
            handlePickerChange(code: VCP.Codes.SHADOW_BOOST, newValue: $0)
        }
        .onChange(of: blueLightFilterLevel) {
            handlePickerChange(code: VCP.Codes.BLUE_LIGHT, newValue: $0)
        }
        .onChange(of: colorTempPresetDDCValue) {
            handlePickerChange(code: VCP.Codes.COLOR_TEMP_PRESET, newValue: $0)
        }
        .onChange(of: gammaDDCValue) {
            handlePickerChange(code: VCP.Codes.GAMMA, newValue: $0)
        }
        .fileExporter(
            isPresented: $showFileExporter,
            document: SettingsDocument(data: exportedSettingsData ?? Data()),
            contentType: .json,
            defaultFilename: defaultExportFilename()
        ) { handleExportResult($0) }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { handleImportResult($0) }
            .alert(
                "Enable HDR in System Settings",
                isPresented: $showEnableHDRAlert
            ) {
                Button("Open Display Settings") { openDisplaySettings() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "To use HDR presets, please enable 'High Dynamic Range' for this display in macOS System Settings."
                )
            }
    }
    
    @ViewBuilder private var modeSelectionGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Standard Modes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
            
            LazyVGrid(columns: modeButtonColumns, spacing: 10) {
                ForEach(sdrModes) { mode in
                    ModeButton(
                        iconName: mode.iconName,
                        label: mode.name,
                        isSelected: isModeSelected(mode),
                        action: { handleModeSelection(mode) }
                    )
                    .disabled(isCurrentlyInHDRMode)
                    .opacity(isCurrentlyInHDRMode ? 0.5 : 1.0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if !hdrModes.isEmpty {
                Divider().padding(.vertical, 5)
                
                Text("HDR Modes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
                
                LazyVGrid(columns: modeButtonColumns, spacing: 10) {
                    ForEach(hdrModes) { mode in
                        ModeButton(
                            iconName: mode.iconName,
                            label: mode.name,
                            isSelected: isModeSelected(mode),
                            action: { handleModeSelection(mode) }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.bottom, 5)
    }
    
    @ViewBuilder private var settingsHeader: some View {
        HStack(alignment: .center) {
            Text("\(currentPresetName) Settings").font(.title3)
            Spacer()
            // Color Space Picker REMOVED from here
            Button {
                applyPresetDefaults()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }.help(
                "Reset settings for '\(currentPresetName)' to stored defaults"
            )
            .disabled(isLoadingState || isApplyingStoredSettings)
            Button {
                fetchGameVisualState()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }.help("Refresh all settings from the monitor")
                .disabled(isLoadingState || isApplyingStoredSettings)
        }
        .buttonStyle(.bordered).padding(.bottom, 5)
    }
    
    @ViewBuilder
    private var settingsContent: some View {
        HStack(alignment: .top, spacing: 20) {
            imageSettingsBox
            colorSettingsBox
        }
    }
    
    @ViewBuilder
    private var imageSettingsBox: some View {
        let sliderNeedsDisabling =
        isCurrentlyInHDRMode
        ? (selectedHDRModeIdentifier != "hdr_console"
           && selectedHDRModeIdentifier != "hdr_dolby_console")
        : blueLightFilterLevel == 4
        GroupBox("Image") {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSliderRow(
                    label: "Brightness",
                    value: $brightness,
                    range: 0...100,
                    sendImmediately: true,
                    onValueChanged: { newValue in
                        sendSliderWriteCommand(
                            code: VCP.Codes.BRIGHTNESS,
                            value: newValue
                        )
                    }
                )
                .disabled(sliderNeedsDisabling)
                .opacity(sliderNeedsDisabling ? 0.5 : 1.0)
                if blueLightFilterLevel == 4 {
                    Text("Disabled at Blue Light Level 4").font(.caption)
                        .foregroundColor(.orange)
                }
                
                SettingsSliderRow(
                    label: "Contrast",
                    value: $contrast,
                    range: 0...100,
                    sendImmediately: true,
                    onValueChanged: { newValue in
                        sendSliderWriteCommand(
                            code: VCP.Codes.CONTRAST,
                            value: newValue
                        )
                    }
                )
                .disabled(!areSlidersAdjustable)
                .opacity(!areSlidersAdjustable ? 0.5 : 1.0)
                
                SettingsPickerRow(
                    title: "Blue Light Filter",
                    selection: $blueLightFilterLevel,
                    options: blueLightOptions,
                    optionId: \.id,
                    optionTitle: \.name,
                    isDisabled: isCurrentlyInHDRMode
                    || selectedPresetIdentifier == "srgb"
                )
                .opacity(
                    (isCurrentlyInHDRMode || selectedPresetIdentifier == "srgb")
                    ? 0.5 : 1.0
                )
                
                SettingsPickerRow(
                    title: "Shadow Boost",
                    selection: $shadowBoostLevel,
                    options: shadowBoostOptions,
                    optionId: \.id,
                    optionTitle: \.name,
                    isDisabled: isCurrentlyInHDRMode
                    || selectedPresetIdentifier == "srgb"
                    || selectedPresetIdentifier == "moba"
                )
                .opacity(
                    (isCurrentlyInHDRMode || selectedPresetIdentifier == "srgb"
                     || selectedPresetIdentifier == "moba") ? 0.5 : 1.0
                )
                
                SettingsSliderRow(
                    label: "Vivid Pixel",
                    value: $vividPixelLevel,
                    range: 0...100,
                    decimals: 0,
                    step: 10,
                    sendImmediately: true,
                    onValueChanged: { newValue in
                        sendSliderWriteCommand(
                            code: VCP.Codes.VIVID_PIXEL,
                            value: newValue
                        )
                    }
                )
                .disabled(
                    isCurrentlyInHDRMode || selectedPresetIdentifier == "srgb"
                )
                .opacity(
                    (isCurrentlyInHDRMode || selectedPresetIdentifier == "srgb")
                    ? 0.5 : 1.0
                )
                
                SettingsToggleRow(
                    title: "Adjustable HDR",
                    description:
                        "Allow brightness/color adjustments when an HDR mode is active on the monitor.",
                    isOn: $adjustableHDROn
                ) { newState in
                    sendToggleWriteCommand(
                        code: VCP.Codes.ADJUSTABLE_HDR,
                        enabled: newState
                    )
                }
                .disabled(!isCurrentlyInHDRMode)
                .opacity(!isCurrentlyInHDRMode ? 0.5 : 1.0)
                
                SettingsToggleRow(
                    title: "Variable Refresh Rate",
                    description: "Enable/disable VRR/Adaptive-Sync",
                    isOn: $vrrEnabled
                ) { newState in
                    sendToggleWriteCommand(code: VCP.Codes.VRR, enabled: newState)
                }
            }
            .padding(5).frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private var colorSettingsBox: some View {
        GroupBox("Color") {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSliderRow(
                    label: "Saturation",
                    value: $saturation,
                    range: 0...100,
                    sendImmediately: true,
                    onValueChanged: { newValue in
                        sendSliderWriteCommand(
                            code: VCP.Codes.SATURATION,
                            value: newValue
                        )
                    }
                )
                .disabled(
                    isCurrentlyInHDRMode || selectedPresetIdentifier == "srgb"
                )
                .opacity(
                    (isCurrentlyInHDRMode || selectedPresetIdentifier == "srgb")
                    ? 0.5 : 1.0
                )
                
                SettingsPickerRow(
                    title: "Gamma",
                    selection: $gammaDDCValue,
                    options: gammaOptions,
                    optionId: \.id,
                    optionTitle: \.name
                )
                .disabled(
                    isCurrentlyInHDRMode || selectedPresetIdentifier == "srgb"
                )
                .opacity(
                    (isCurrentlyInHDRMode || selectedPresetIdentifier == "srgb")
                    ? 0.5 : 1.0
                )
                
                // Color Space Picker ADDED here
                HStack {
                    Text("Color Space")
                    Spacer()
                    Picker(
                        "Color Space",
                        selection: $selectedColorSpaceIdentifier
                    ) {
                        ForEach(colorSpaceOptions) { option in
                            Text(option.name).tag(option.identifier)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)  // Consistent width with other pickers in this box
                    .disabled(
                        isCurrentlyInHDRMode
                        || selectedPresetIdentifier == "srgb"
                    )
                    .opacity(
                        isCurrentlyInHDRMode
                        || selectedPresetIdentifier == "srgb" ? 0.5 : 1.0
                    )
                    .onChange(of: selectedColorSpaceIdentifier) {
                        handleColorSpaceChange($0)
                    }
                }
                
                SettingsPickerRow(
                    title: "Color Temp.",
                    selection: $colorTempPresetDDCValue,
                    options: colorTempOptions,
                    optionId: \.id,
                    optionTitle: \.name,
                    isDisabled: selectedPresetIdentifier == "srgb"
                    || !areSlidersAdjustable
                )
                .opacity(
                    (selectedPresetIdentifier == "srgb"
                     || !areSlidersAdjustable) ? 0.5 : 1.0
                )
                
                let rgbDisabled =
                !isUserColorTempSelected || !areSlidersAdjustable
                SettingsSliderRow(
                    label: "R",
                    value: $redValue,
                    range: 0...100,
                    sendImmediately: true,
                    onValueChanged: { newValue in
                        sendSliderWriteCommand(
                            code: VCP.Codes.GAIN_R,
                            value: newValue
                        )
                    }
                )
                .disabled(rgbDisabled).opacity(rgbDisabled ? 0.5 : 1.0)
                SettingsSliderRow(
                    label: "G",
                    value: $greenValue,
                    range: 0...100,
                    sendImmediately: true,
                    onValueChanged: { newValue in
                        sendSliderWriteCommand(
                            code: VCP.Codes.GAIN_G,
                            value: newValue
                        )
                    }
                )
                .disabled(rgbDisabled).opacity(rgbDisabled ? 0.5 : 1.0)
                SettingsSliderRow(
                    label: "B",
                    value: $blueValue,
                    range: 0...100,
                    sendImmediately: true,
                    onValueChanged: { newValue in
                        sendSliderWriteCommand(
                            code: VCP.Codes.GAIN_B,
                            value: newValue
                        )
                    }
                )
                .disabled(rgbDisabled).opacity(rgbDisabled ? 0.5 : 1.0)
            }
            .padding(5).frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private var bottomButtons: some View {
        HStack {
            Spacer()
            Button("Export...") { exportSettings() }
                .disabled(viewModel.selectedDisplayID == nil || isLoadingState)
            Button("Import...") { showFileImporter = true }
                .disabled(viewModel.selectedDisplayID == nil || isLoadingState)
        }
        .buttonStyle(.bordered)
    }
    
    // MARK: - Event Handlers & Logic
    private func handleOnAppear() {
        if viewModel.selectedDisplayID != nil
            && !hasFetchedOnceForCurrentMonitor
        {
            fetchGameVisualState()
        } else if viewModel.selectedDisplayID == nil {
            resetGameVisualStateToDefaults()
            isLoadingState = false
            hasFetchedOnceForCurrentMonitor = false
        }
    }
    
    private func handleMonitorChange() {
        hasFetchedOnceForCurrentMonitor = false
        if viewModel.selectedDisplayID != nil {
            fetchGameVisualState()
        } else {
            resetGameVisualStateToDefaults()
            isLoadingState = false
        }
    }
    
    private func handlePickerChange(code: UInt8, newValue: UInt16) {
        guard !isUpdatingProgrammatically else { return }
        sendPickerWriteCommand(code: code, selectedDDCValue: newValue)
    }
    
    private func handleColorSpaceChange(_ newSpaceId: String) {
        guard !isUpdatingProgrammatically else { return }
        updateColorSpace(newSpaceId)
    }
    
    private func handleModeSelection(_ mode: DisplayablePreset) {
        guard !isLoadingState, !isUpdatingProgrammatically else { return }
        print("Mode Button Clicked: \(mode.name) (ID: \(mode.identifier))")
        
        withAnimation {
            if !mode.isHDRMode {
                selectedPresetIdentifier = mode.identifier
                selectedHDRModeIdentifier = nil
                selectedHDRDDCValue = nil
                if mode.identifier == "srgb" {
                    selectedColorSpaceIdentifier = "srgb"
                }
                sendGameVisualPresetCommand()
            } else {
                selectedPresetIdentifier = mode.mainCategoryIdentifier
                selectedHDRModeIdentifier = mode.identifier
                selectedHDRDDCValue = mode.value
                
                if let hdrData = hdrStandardPresets.first(where: {
                    $0.identifier == mode.identifier
                })
                    ?? hdrDolbyPresets.first(where: {
                        $0.identifier == mode.identifier
                    })
                {
                    handleHDRPresetSelection(hdrData)
                } else {
                    print(
                        "Error: Could not find HdrPreset data for identifier \(mode.identifier)"
                    )
                    fetchGameVisualState()
                }
            }
        }
    }
    
    private func isModeSelected(_ mode: DisplayablePreset) -> Bool {
        if mode.isHDRMode {
            return mode.identifier == selectedHDRModeIdentifier
        } else {
            return mode.identifier == selectedPresetIdentifier
            && selectedHDRModeIdentifier == nil
        }
    }
    
    private func openDisplaySettings() {
        guard
            let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.displays"
            )
        else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func handleHDRPresetSelection(_ hdrPreset: HdrPreset) {
        guard let displayID = viewModel.selectedDisplayID else { return }
        if isSystemHDREnabled(for: displayID) {
            viewModel.writeDDC(
                command: VCP.Codes.HDR_SETTING,
                value: hdrPreset.ddcValue
            ) { success, _ in
                scheduleFetch(delay: 0.8)
            }
        } else {
            displayIDForHDRAlert = displayID
            showEnableHDRAlert = true
            fetchGameVisualState()
        }
    }
    
    private func isSystemHDREnabled(for displayID: CGDirectDisplayID) -> Bool {
        guard
            let screen = NSScreen.screens.first(where: {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                 as? CGDirectDisplayID) == displayID
            })
        else {
            return false
        }
        return AVPlayer.eligibleForHDRPlayback
    }
    
    // MARK: - DDC Send Commands
    private func sendGameVisualPresetCommand() {
        guard let currentDisplayID = viewModel.selectedDisplayID,
              !isLoadingState
        else { return }
        guard !selectedPresetIdentifier.starts(with: "hdr") else {
            print(
                "sendGameVisualPresetCommand skipped (HDR category selected, should select sub-mode)"
            )
            return
        }
        guard
            let preset = gameVisualPresets.first(where: {
                $0.mode.identifier == selectedPresetIdentifier
            })
        else {
            print(
                "Error sending preset: Could not find preset data for \(selectedPresetIdentifier)"
            )
            return
        }
        
        var ddcValue: UInt16?
        let targetSpace =
        (selectedPresetIdentifier == "srgb")
        ? "srgb" : selectedColorSpaceIdentifier
        switch targetSpace {
            case "wide": ddcValue = preset.ddcValueWideGamut
            case "srgb": ddcValue = preset.ddcValueSRGB
            case "p3": ddcValue = preset.ddcValueDCIP3
            default:
                print("Error: Unknown color space \(targetSpace)")
                return
        }
        if selectedPresetIdentifier == "srgb" {
            ddcValue = preset.ddcValueSRGB ?? 3
        }
        
        guard let finalDDCValue = ddcValue else {
            print(
                "Error: No DDC value for preset '\(selectedPresetIdentifier)' in space '\(targetSpace)'"
            )
            return
        }
        
        print(
            "Setting Preset (\(String(format: "0x%02X", VCP.Codes.GAMEVISUAL_PRESET))) -> \(finalDDCValue) (\(selectedPresetIdentifier)/\(targetSpace))"
        )
        viewModel.writeDDC(command: VCP.Codes.HDR_SETTING, value: 0) {
            hdrSuccess,
            _ in
            viewModel.writeDDC(
                command: VCP.Codes.GAMEVISUAL_PRESET,
                value: finalDDCValue
            ) { dcSuccess, _ in
                scheduleFetch(delay: 0.8)
            }
        }
    }
    
    private func updateColorSpace(_ newSpaceId: String) {
        guard viewModel.selectedDisplayID != nil, !isLoadingState else {
            return
        }
        guard selectedPresetIdentifier != "srgb" else {
            if selectedColorSpaceIdentifier != "srgb" {
                isUpdatingProgrammatically = true
                selectedColorSpaceIdentifier = "srgb"
                DispatchQueue.main.async {
                    self.isUpdatingProgrammatically = false
                }
            }
            return
        }
        sendGameVisualPresetCommand()
    }
    
    private func sendPickerWriteCommand(code: UInt8, selectedDDCValue: UInt16) {
        guard let currentDisplayID = viewModel.selectedDisplayID,
              !isLoadingState
        else { return }
        viewModel.writeDDC(command: code, value: selectedDDCValue) {
            success,
            msg in
            if !success {
                fetchGameVisualState()
                return
            }
            let needsRefetch =
            (code == VCP.Codes.COLOR_TEMP_PRESET)
            || (code == VCP.Codes.BLUE_LIGHT && selectedDDCValue == 4)
            if needsRefetch {
                scheduleFetch(delay: 0.3)
            }
        }
    }
    
    private func sendSliderWriteCommand(code: UInt8, value: Double) {
        guard let currentDisplayID = viewModel.selectedDisplayID,
              !isLoadingState, !isUpdatingProgrammatically
        else { return }
        let ddcValue = UInt16(value.rounded())
        viewModel.writeDDC(command: code, value: ddcValue) { success, msg in
            if !success {
                print(
                    "Error setting slider \(String(format: "0x%02X", code)): \(msg)"
                )
            }
        }
    }
    
    private func sendToggleWriteCommand(code: UInt8, enabled: Bool) {
        guard let currentDisplayID = viewModel.selectedDisplayID,
              !isLoadingState, !isUpdatingProgrammatically
        else { return }
        let ddcValue: UInt16 = enabled ? 1 : 0
        let description = (code == VCP.Codes.VRR) ? "VRR" : "Adjustable HDR"
        viewModel.writeDDC(command: code, value: ddcValue) { success, msg in
            if !success {
                fetchGameVisualState()
                return
            }
            if code == VCP.Codes.VRR {
                startMonitorRecoveryAttempt(originalDisplayID: currentDisplayID)
            } else if code == VCP.Codes.ADJUSTABLE_HDR {
                scheduleFetch(delay: 0.3)
            }
        }
    }
    
    // MARK: - Monitor Recovery Logic
    private func startMonitorRecoveryAttempt(
        originalDisplayID: CGDirectDisplayID
    ) {
        let initialDelay: TimeInterval = 1.5
        let maxScanRetries = 5
        let scanRetryDelay: TimeInterval = 1.0
        isLoadingState = true
        viewModel.updateStatus("Reconnecting to monitor after VRR change...")
        scheduleScanRetry(
            originalDisplayID: originalDisplayID,
            retriesLeft: maxScanRetries,
            initialDelay: initialDelay,
            retryDelay: scanRetryDelay
        )
    }
    
    private func scheduleScanRetry(
        originalDisplayID: CGDirectDisplayID,
        retriesLeft: Int,
        initialDelay: TimeInterval,
        retryDelay: TimeInterval
    ) {
        let delayToUse = (retriesLeft == 5) ? initialDelay : retryDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + delayToUse) {
            guard
                viewModel.selectedDisplayID == originalDisplayID
                    || viewModel.selectedDisplayID == nil
            else {
                return
            }
            let attemptNumber = 6 - retriesLeft
            viewModel.updateStatus(
                "Scanning for monitor (Attempt \(attemptNumber))..."
            )
            viewModel.scanMonitors {
                if let currentSelectedID = viewModel.selectedDisplayID,
                   viewModel.matchedServices.contains(where: {
                       $0.displayID == currentSelectedID
                   })
                {
                    viewModel.updateStatus(
                        "Monitor reconnected. Loading settings..."
                    )
                    fetchGameVisualState()
                } else if retriesLeft > 1 {
                    scheduleScanRetry(
                        originalDisplayID: originalDisplayID,
                        retriesLeft: retriesLeft - 1,
                        initialDelay: initialDelay,
                        retryDelay: retryDelay
                    )
                } else {
                    viewModel.updateStatus(
                        "Monitor connection lost after setting change."
                    )
                    resetGameVisualStateToDefaults()
                    isLoadingState = false
                    if viewModel.selectedDisplayID != nil {
                        viewModel.selectedDisplayID = nil
                    }
                }
            }
        }
    }
    
    // MARK: - State Reset & Fetching
    private func resetGameVisualStateToDefaults() {
        isUpdatingProgrammatically = true
        selectedPresetIdentifier = "user"
        selectedColorSpaceIdentifier = "wide"
        selectedHDRModeIdentifier = nil
        selectedHDRDDCValue = nil
        selectedPresetDDCValue = 4
        brightness = 75
        contrast = 80
        blueLightFilterLevel = 0
        shadowBoostLevel = 0
        vividPixelLevel = 50
        saturation = 50
        gammaDDCValue = 120
        colorTempPresetDDCValue = 11
        redValue = 100
        greenValue = 100
        blueValue = 100
        adjustableHDROn = false
        vrrEnabled = false
        DispatchQueue.main.async { self.isUpdatingProgrammatically = false }
    }
    
    private func scheduleFetch(delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            fetchGameVisualState()
        }
    }
    
    func fetchGameVisualState() {
        guard let currentDisplayID = viewModel.selectedDisplayID else {
            if !isLoadingState { resetGameVisualStateToDefaults() }
            isLoadingState = false
            hasFetchedOnceForCurrentMonitor = false
            return
        }
        guard !isLoadingState else { return }
        isLoadingState = true
        isUpdatingProgrammatically = true
        viewModel.updateStatus("Reading GameVisual settings...")
        
        let group = DispatchGroup()
        var fetchedValues: [UInt8: UInt16] = [:]
        var fetchErrors: [String] = []
        let fetchLock = NSLock()
        let codesToRead: [UInt8] = [
            VCP.Codes.BRIGHTNESS, VCP.Codes.CONTRAST, VCP.Codes.GAMEVISUAL_PRESET,
            VCP.Codes.HDR_SETTING,
            VCP.Codes.BLUE_LIGHT, VCP.Codes.SHADOW_BOOST, VCP.Codes.VIVID_PIXEL,
            VCP.Codes.SATURATION,
            VCP.Codes.GAMMA, VCP.Codes.COLOR_TEMP_PRESET, VCP.Codes.GAIN_R,
            VCP.Codes.GAIN_G, VCP.Codes.GAIN_B,
            VCP.Codes.ADJUSTABLE_HDR, VCP.Codes.VRR,
        ]
        for code in codesToRead {
            group.enter()
            viewModel.readDDC(command: code) { current, _, msg in
                guard self.viewModel.selectedDisplayID == currentDisplayID
                else {
                    group.leave()
                    return
                }
                fetchLock.lock()
                if let currentValue = current {
                    fetchedValues[code] = currentValue
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
            guard viewModel.selectedDisplayID == currentDisplayID else {
                self.isLoadingState = false
                self.isUpdatingProgrammatically = false
                return
            }
            updateStateFromFetchedValues(fetchedValues)
            self.hasFetchedOnceForCurrentMonitor = true
            self.isLoadingState = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isUpdatingProgrammatically = false
            }
            if !fetchErrors.isEmpty {
                viewModel.updateStatus(
                    "Error reading some GameVisual settings."
                )
            } else {
                viewModel.updateStatus(
                    "Selected: \(viewModel.selectedMonitorName)"
                )
            }
        }
    }
    
    private func updateStateFromFetchedValues(_ values: [UInt8: UInt16]) {
        let fetchedDCValue = values[VCP.Codes.GAMEVISUAL_PRESET]
        let fetchedE2Value = values[VCP.Codes.HDR_SETTING]
        
        let hdrActive = fetchedE2Value != nil && fetchedE2Value != 0
        let specificHdrId =
        hdrActive ? mapDdcToHdrPresetId(fetchedE2Value!) : nil
        
        selectedHDRDDCValue = fetchedE2Value
        if let dcVal = fetchedDCValue { selectedPresetDDCValue = dcVal }
        
        if hdrActive, let currentSpecificHdrId = specificHdrId {
            selectedHDRModeIdentifier = currentSpecificHdrId
            selectedPresetIdentifier =
            currentSpecificHdrId.contains("dolby") ? "hdr_dolby" : "hdr"
            if let dcValue = fetchedDCValue {
                let (_, spaceId) = mapDdcToPresetAndSpaceIds(dcValue)
                selectedColorSpaceIdentifier = spaceId
            }
        } else {
            selectedHDRModeIdentifier = nil
            if let dcValue = fetchedDCValue {
                let (presetId, spaceId) = mapDdcToPresetAndSpaceIds(dcValue)
                selectedPresetIdentifier = presetId
                selectedColorSpaceIdentifier =
                (presetId == "srgb") ? "srgb" : spaceId
            }
        }
        
        brightness = Double(
            values[VCP.Codes.BRIGHTNESS, default: UInt16(self.brightness)]
        )
        contrast = Double(
            values[VCP.Codes.CONTRAST, default: UInt16(self.contrast)]
        )
        blueLightFilterLevel =
        values[VCP.Codes.BLUE_LIGHT, default: self.blueLightFilterLevel]
        shadowBoostLevel =
        values[VCP.Codes.SHADOW_BOOST, default: self.shadowBoostLevel]
        vividPixelLevel = Double(
            values[VCP.Codes.VIVID_PIXEL, default: UInt16(self.vividPixelLevel)]
        )
        adjustableHDROn =
        (values[
            VCP.Codes.ADJUSTABLE_HDR,
            default: self.adjustableHDROn ? 1 : 0
        ] == 1)
        vrrEnabled =
        (values[VCP.Codes.VRR, default: self.vrrEnabled ? 1 : 0] == 1)
        saturation = Double(
            values[VCP.Codes.SATURATION, default: UInt16(self.saturation)]
        )
        gammaDDCValue = values[VCP.Codes.GAMMA, default: self.gammaDDCValue]
        colorTempPresetDDCValue =
        values[
            VCP.Codes.COLOR_TEMP_PRESET,
            default: self.colorTempPresetDDCValue
        ]
        redValue = Double(
            values[VCP.Codes.GAIN_R, default: UInt16(self.redValue)]
        )
        greenValue = Double(
            values[VCP.Codes.GAIN_G, default: UInt16(self.greenValue)]
        )
        blueValue = Double(
            values[VCP.Codes.GAIN_B, default: UInt16(self.blueValue)]
        )
        print(
            ">>> GameVisualView: UI state update complete. Preset=\(selectedPresetIdentifier), HDRMode=\(selectedHDRModeIdentifier ?? "nil"), SpecificHDRValue=\(String(describing: selectedHDRDDCValue)) Space=\(selectedColorSpaceIdentifier)"
        )
    }
    
    // MARK: - Mapping Functions
    private func mapDdcToPresetAndSpaceIds(_ ddcValue: UInt16) -> (
        presetId: String, spaceId: String
    ) {
        if ddcValue == 3 { return ("srgb", "srgb") }
        for preset in gameVisualPresets where preset.mode.identifier != "srgb" {
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
    
    private func mapDdcToHdrPresetId(_ ddcValue: UInt16) -> String? {
        return hdrStandardPresets.first { $0.ddcValue == ddcValue }?.identifier
        ?? hdrDolbyPresets.first { $0.ddcValue == ddcValue }?.identifier
    }
    
    // MARK: - Import/Export Logic
    private func exportSettings() {
        guard viewModel.selectedDisplayID != nil, !isLoadingState else {
            return
        }
        let currentSettings = GameVisualSettings(
            presetIdentifier: selectedPresetIdentifier,
            colorSpaceIdentifier: selectedColorSpaceIdentifier,
            hdrModeIdentifier: selectedHDRModeIdentifier,
            brightness: brightness,
            contrast: contrast,
            blueLightFilterLevel: blueLightFilterLevel,
            shadowBoostLevel: shadowBoostLevel,
            vividPixelLevel: vividPixelLevel,
            saturation: saturation,
            gammaDDCValue: gammaDDCValue,
            colorTempPresetDDCValue: colorTempPresetDDCValue,
            redValue: redValue,
            greenValue: greenValue,
            blueValue: blueValue,
            adjustableHDROn: adjustableHDROn,
            vrrEnabled: vrrEnabled
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            exportedSettingsData = try encoder.encode(currentSettings)
            showFileExporter = true
        } catch {
            exportedSettingsData = nil
        }
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
            case .success(let url): viewModel.updateStatus("Settings exported.")
            case .failure(let error):
                viewModel.updateStatus(
                    "Error exporting: \(error.localizedDescription)"
                )
        }
        exportedSettingsData = nil
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importSettings(from: url)
            case .failure(let error):
                viewModel.updateStatus(
                    "Error importing: \(error.localizedDescription)"
                )
        }
    }
    
    private func importSettings(from url: URL) {
        guard viewModel.selectedDisplayID != nil else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedSettings = try decoder.decode(
                GameVisualSettings.self,
                from: data
            )
            applyImportedSettings(importedSettings)
        } catch {
            viewModel.updateStatus(
                "Error importing file: \(error.localizedDescription)"
            )
        }
    }
    
    private func applyImportedSettings(_ settings: GameVisualSettings) {
        guard let currentDisplayID = viewModel.selectedDisplayID,
              !isLoadingState
        else { return }
        isLoadingState = true
        isApplyingStoredSettings = true
        isUpdatingProgrammatically = true
        viewModel.updateStatus("Applying imported settings...")
        let group = DispatchGroup()
        var writeErrors: [String] = []
        let writeErrorLock = NSLock()
        func performWrite(description: String, command: UInt8, value: UInt16) {
            group.enter()
            viewModel.writeDDC(command: command, value: value) { success, msg in
                if !success {
                    writeErrorLock.lock()
                    writeErrors.append("\(description): \(msg)")
                    writeErrorLock.unlock()
                }
                group.leave()
            }
        }
        performWrite(
            description: "Brightness",
            command: VCP.Codes.BRIGHTNESS,
            value: UInt16(settings.brightness.rounded())
        )
        performWrite(
            description: "Contrast",
            command: VCP.Codes.CONTRAST,
            value: UInt16(settings.contrast.rounded())
        )
        performWrite(
            description: "Blue Light Filter",
            command: VCP.Codes.BLUE_LIGHT,
            value: settings.blueLightFilterLevel
        )
        performWrite(
            description: "Shadow Boost",
            command: VCP.Codes.SHADOW_BOOST,
            value: settings.shadowBoostLevel
        )
        performWrite(
            description: "Vivid Pixel",
            command: VCP.Codes.VIVID_PIXEL,
            value: UInt16(settings.vividPixelLevel.rounded())
        )
        performWrite(
            description: "Saturation",
            command: VCP.Codes.SATURATION,
            value: UInt16(settings.saturation.rounded())
        )
        performWrite(
            description: "Gamma",
            command: VCP.Codes.GAMMA,
            value: settings.gammaDDCValue
        )
        performWrite(
            description: "Color Temp Preset",
            command: VCP.Codes.COLOR_TEMP_PRESET,
            value: settings.colorTempPresetDDCValue
        )
        if settings.colorTempPresetDDCValue == 11 {
            performWrite(
                description: "Red Gain",
                command: VCP.Codes.GAIN_R,
                value: UInt16(settings.redValue.rounded())
            )
            performWrite(
                description: "Green Gain",
                command: VCP.Codes.GAIN_G,
                value: UInt16(settings.greenValue.rounded())
            )
            performWrite(
                description: "Blue Gain",
                command: VCP.Codes.GAIN_B,
                value: UInt16(settings.blueValue.rounded())
            )
        }
        performWrite(
            description: "Adjustable HDR Toggle",
            command: VCP.Codes.ADJUSTABLE_HDR,
            value: settings.adjustableHDROn ? 1 : 0
        )
        performWrite(
            description: "VRR Toggle",
            command: VCP.Codes.VRR,
            value: settings.vrrEnabled ? 1 : 0
        )
        
        if let hdrId = settings.hdrModeIdentifier,
           let hdrPreset = hdrStandardPresets.first(where: {
               $0.identifier == hdrId
           }) ?? hdrDolbyPresets.first(where: { $0.identifier == hdrId })
        {
            if isSystemHDREnabled(for: currentDisplayID) {
                performWrite(
                    description: "HDR Preset",
                    command: VCP.Codes.HDR_SETTING,
                    value: hdrPreset.ddcValue
                )
                if let gamePreset = gameVisualPresets.first(where: {
                    $0.mode.identifier == settings.presetIdentifier
                }) {
                    var baseDCValue: UInt16?
                    switch settings.colorSpaceIdentifier {
                        case "wide": baseDCValue = gamePreset.ddcValueWideGamut
                        case "srgb": baseDCValue = gamePreset.ddcValueSRGB
                        case "p3": baseDCValue = gamePreset.ddcValueDCIP3
                        default: break
                    }
                    if let dcVal = baseDCValue {
                        performWrite(
                            description: "Base GameVisual (DC)",
                            command: VCP.Codes.GAMEVISUAL_PRESET,
                            value: dcVal
                        )
                    }
                }
            } else {
                writeErrors.append(
                    "HDR Preset (\(hdrId)): System HDR not enabled."
                )
            }
        } else if let preset = gameVisualPresets.first(where: {
            $0.mode.identifier == settings.presetIdentifier
        }) {
            var ddcValue: UInt16?
            let targetSpace =
            (settings.presetIdentifier == "srgb")
            ? "srgb" : settings.colorSpaceIdentifier
            switch targetSpace {
                case "wide": ddcValue = preset.ddcValueWideGamut
                case "srgb": ddcValue = preset.ddcValueSRGB
                case "p3": ddcValue = preset.ddcValueDCIP3
                default: break
            }
            if settings.presetIdentifier == "srgb" {
                ddcValue = preset.ddcValueSRGB ?? 3
            }
            if let finalDDCValue = ddcValue {
                performWrite(
                    description: "HDR Setting (Off)",
                    command: VCP.Codes.HDR_SETTING,
                    value: 0
                )
                performWrite(
                    description: "GameVisual Preset (DC)",
                    command: VCP.Codes.GAMEVISUAL_PRESET,
                    value: finalDDCValue
                )
            } else {
                writeErrors.append(
                    "GameVisual Preset (\(settings.presetIdentifier)): Invalid config."
                )
            }
        } else {
            writeErrors.append(
                "GameVisual Preset: Invalid identifier '\(settings.presetIdentifier)'"
            )
        }
        
        group.notify(queue: .main) {
            if writeErrors.isEmpty {
                viewModel.updateStatus("Imported settings applied.")
            } else {
                viewModel.updateStatus(
                    "Import finished with \(writeErrors.count) error(s)."
                )
            }
            fetchGameVisualState()
            isApplyingStoredSettings = false
        }
    }
    
    private func applyPresetDefaults() {
        guard let currentDisplayID = viewModel.selectedDisplayID,
              !isLoadingState, !isApplyingStoredSettings
        else { return }
        let identifierToReset =
        selectedHDRModeIdentifier ?? selectedPresetIdentifier
        guard let defaults = GameVisualView.presetDefaults[identifierToReset]
        else {
            resetCurrentPresetToMonitorDefaults()
            return
        }
        isLoadingState = true
        isApplyingStoredSettings = true
        isUpdatingProgrammatically = true
        viewModel.updateStatus("Resetting \(currentPresetName)...")
        let group = DispatchGroup()
        var writeErrors: [String] = []
        let writeErrorLock = NSLock()
        var overallSuccess = true
        func performWrite(vcpCode: UInt8, value: UInt16) {
            group.enter()
            viewModel.writeDDC(command: vcpCode, value: value) { success, msg in
                if !success {
                    writeErrorLock.lock()
                    writeErrors.append(
                        "VCP \(String(format: "0x%02X", vcpCode)): \(msg)"
                    )
                    overallSuccess = false
                    writeErrorLock.unlock()
                }
                group.leave()
            }
        }
        for (vcpCode, defaultValue) in defaults {
            performWrite(vcpCode: vcpCode, value: defaultValue)
        }
        group.notify(queue: .main) {
            if overallSuccess {
                viewModel.updateStatus(
                    "\(currentPresetName) reset to stored defaults."
                )
            } else {
                viewModel.updateStatus("Error resetting \(currentPresetName).")
            }
            fetchGameVisualState()
            isApplyingStoredSettings = false
        }
    }
    
    private func resetCurrentPresetToMonitorDefaults() {
        guard let currentDisplayID = viewModel.selectedDisplayID,
              !isLoadingState, !isApplyingStoredSettings
        else { return }
        isLoadingState = true
        isApplyingStoredSettings = true
        isUpdatingProgrammatically = true
        viewModel.updateStatus("Resetting \(currentPresetName)...")
        var commandToSend: UInt8?
        var valueToSend: UInt16?
        if let hdrId = selectedHDRModeIdentifier,
           let hdrPreset = hdrStandardPresets.first(where: {
               $0.identifier == hdrId
           }) ?? hdrDolbyPresets.first(where: { $0.identifier == hdrId })
        {
            commandToSend = VCP.Codes.HDR_SETTING
            valueToSend = hdrPreset.ddcValue
        } else if let preset = gameVisualPresets.first(where: {
            $0.mode.identifier == selectedPresetIdentifier
        }), !preset.mode.identifier.starts(with: "hdr") {
            commandToSend = VCP.Codes.GAMEVISUAL_PRESET
            let targetSpace =
            (selectedPresetIdentifier == "srgb")
            ? "srgb" : selectedColorSpaceIdentifier
            switch targetSpace {
                case "wide": valueToSend = preset.ddcValueWideGamut
                case "srgb": valueToSend = preset.ddcValueSRGB
                case "p3": valueToSend = preset.ddcValueDCIP3
                default: break
            }
            if selectedPresetIdentifier == "srgb" {
                valueToSend = preset.ddcValueSRGB ?? 3
            }
        }
        if let command = commandToSend, let value = valueToSend {
            viewModel.writeDDC(command: command, value: value) { success, msg in
                viewModel.updateStatus(
                    success
                    ? "\(currentPresetName) reset command sent."
                    : "Failed to send reset for \(currentPresetName)."
                )
                scheduleFetch(delay: 0.8)
                isApplyingStoredSettings = false
            }
        } else {
            isLoadingState = false
            isApplyingStoredSettings = false
            isUpdatingProgrammatically = false
            fetchGameVisualState()
        }
    }
    
    private func defaultExportFilename() -> String {
        let presetName = currentPresetName.replacingOccurrences(
            of: "/",
            with: "-"
        ).filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        return "GameVisual_\(presetName)_\(dateFormatter.string(from: Date())).json"
    }
}

// MARK: - Preview Provider
#Preview {
    let previewVM = DDCViewModel()
    return ScrollView {
        GameVisualView()
            .environmentObject(previewVM)
            .padding()
    }
    .frame(width: 750, height: 700)
    .preferredColorScheme(.dark)
}
