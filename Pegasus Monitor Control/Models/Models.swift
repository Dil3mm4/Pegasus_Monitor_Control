//
//  Models.swift
//
//  Created by Francesco Manzo on 12/05/25.
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Data Structures

// Represents items in the sidebar list
struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String
    let viewIdentifier: String
}

// Represents styles in the GamePlus Crosshair grid
struct CrosshairStyle: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String
    let identifier: String
}

// Represents Picker Options for OLED Care Cleaning Reminder
struct ReminderOption: Identifiable, Hashable {
    let label: String
    let tagValue: UInt16
    let ddcValue: UInt16
    var id: UInt16 { tagValue }
}

// Represents Picker Options for OLED Care Screen Move
struct ScreenMoveOption: Identifiable, Hashable {
    let label: String
    let tagValue: UInt16
    let ddcValue: UInt16
    var id: UInt16 { tagValue }
}

// Represents KVM hotkey parts (simplified, if needed elsewhere)
struct HotkeyPart: Identifiable, Equatable {
    let id = UUID()
    let keyName: String
}

// Represents Multi-Frame Layouts (if needed elsewhere)
struct MultiFrameLayout: Identifiable, Hashable {
    let id = UUID()
    let iconName: String
    let identifier: String
}

// Generic struct for modes selectable via buttons (GamePlus, Proximity, etc.)
struct SelectableMode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String
    let identifier: String
}

// Holds Preset name/icon/id  DDC values for that preset in different color spaces
struct GameVisualPreset: Identifiable, Hashable {
    let mode: SelectableMode
    let ddcValueWideGamut: UInt16?
    let ddcValueSRGB: UInt16?
    let ddcValueDCIP3: UInt16?
    var id: String { mode.identifier }
}

// Separate struct for HDR presets using VCP E2
struct HdrPreset: Identifiable, Hashable {
    let name: String
    let identifier: String
    let ddcValue: UInt16
    var id: String { identifier }
}

// Generic struct for Pickers mapping Name <-> DDC Value
struct VCPickerOption: Identifiable, Hashable {
    let name: String
    let ddcValue: UInt16
    var id: UInt16 { ddcValue }
}

// Struct for Color Space Picker Options
struct ColorSpaceOption: Identifiable, Hashable {
    let name: String
    let identifier: String
    var id: String { identifier }
}

// Struct for Power Indicator Picker Options (System Settings)
struct PowerIndicatorOption: Identifiable, Hashable {
    let id: UInt16
    let title: String
    let description: String?
    let ddcValue: UInt16
}

// Struct to combine Preset/HDR info for the unified mode grid in GameVisualView
struct DisplayablePreset: Identifiable, Hashable {
    let name: String
    let iconName: String
    let identifier: String
    let isHDRMode: Bool
    let command: UInt8
    let value: UInt16
    let mainCategoryIdentifier: String
    var id: String { identifier }
}

// Structure for exporting/importing GameVisual settings
struct GameVisualSettings: Codable {
    // Identifiers
    var presetIdentifier: String
    var colorSpaceIdentifier: String
    var hdrModeIdentifier: String?
    
    // Direct Values
    var brightness: Double
    var contrast: Double
    var blueLightFilterLevel: UInt16
    var shadowBoostLevel: UInt16
    var vividPixelLevel: Double
    var saturation: Double
    var gammaDDCValue: UInt16
    var colorTempPresetDDCValue: UInt16
    var redValue: Double
    var greenValue: Double
    var blueValue: Double
    var adjustableHDROn: Bool
    var vrrEnabled: Bool
    
    // Metadata
    var appVersion: String? =
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    var sourceApp: String? = "Pegasus Monitor Control"
}

// Required Document type for fileExporter/fileImporter
struct SettingsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    
    init(data: Data = Data()) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = fileData
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// Represents Picker Options for PiP Mode/Layout (VCP F4)
struct PipModeOption: Identifiable, Hashable {
    let id: UInt16
    let name: String
    let iconName: String
}

// Represents Picker Options for PiP Source (VCP F5 / PIP_CONTROL)
struct PipSourceOption: Identifiable, Hashable {
    let id: UInt16
    let name: String
    let iconName: String
}
