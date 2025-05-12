//
//  VCPCodes.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

// Centralized VCP Code Definitions
struct VCP {
    struct Codes {
        // GameVisual & Color Settings
        static let BRIGHTNESS: UInt8 = 0x10
        static let CONTRAST: UInt8 = 0x12
        static let GAMEVISUAL_PRESET: UInt8 = 0xDC
        static let HDR_SETTING: UInt8 = 0xE2
        static let SHADOW_BOOST: UInt8 = 0xE5
        static let BLUE_LIGHT: UInt8 = 0xE6
        static let VIVID_PIXEL: UInt8 = 0x87
        static let SATURATION: UInt8 = 0x8A
        static let GAMMA: UInt8 = 0x72
        static let COLOR_TEMP_PRESET: UInt8 = 0x14
        static let GAIN_R: UInt8 = 0x16
        static let GAIN_G: UInt8 = 0x18
        static let GAIN_B: UInt8 = 0x1A
        static let ADJUSTABLE_HDR: UInt8 = 0x5F
        static let VRR: UInt8 = 0xFD
        
        // GamePlus Settings
        static let GAMEPLUS_CROSSHAIR: UInt8 = 0xE3
        static let GAMEPLUS_TIMER: UInt8 = 0xE4
        static let GAMEPLUS_FPS_COUNTER: UInt8 = 0xEA
        static let GAMEPLUS_POSITION_CONTROL: UInt8 = 0xEB
        
        // OSD Settings
        static let OSD_CONTROL: UInt8 = 0xEB
        static let OSD_SETTINGS: UInt8 = 0xE9
        
        // System Settings
        static let POWER_MODE: UInt8 = 0xE1
        static let AURA_LIGHT: UInt8 = 0xF2
        static let PROXIMITY_SENSOR: UInt8 = 0xED
        static let POWER_INDICATOR: UInt8 = 0xFC
        
        // OLED Care Settings
        static let OLED_CARE_FLAGS: UInt8 = 0xFD
        static let OLED_TARGET_MODE: UInt8 = 0xE7
        static let OLED_CLEANING_REMINDER: UInt8 = 0xF8
        static let OLED_SCREEN_MOVE: UInt8 = 0xF9
        
        // Pip Settings
        static let PIP_MODE_LAYOUT: UInt8 = 0xF4
        
        // Debug & Other
        static let CAPABILITIES_REQUEST: UInt8 = 0xF3
        static let PIP_CONTROL: UInt8 = 0xF5
    }
    
    struct Values {
        // GamePlusView
        struct Crosshair {
            static let OFF: UInt16 = 0
            static let BLUE_DOT: UInt16 = 1
            static let BLUE_DOT_ALT: UInt16 = 7
            static let GREEN_DOT: UInt16 = 2
            static let GREEN_DOT_ALT: UInt16 = 8
            static let BLUE_MINI: UInt16 = 3
            static let BLUE_MINI_ALT: UInt16 = 9
            static let GREEN_MINI: UInt16 = 4
            static let GREEN_MINI_ALT: UInt16 = 10
            static let BLUE_HEAVY: UInt16 = 5
            static let BLUE_HEAVY_ALT: UInt16 = 11
            static let GREEN_HEAVY: UInt16 = 6
            static let GREEN_HEAVY_ALT: UInt16 = 12
        }
        struct OSDPositions {
            static let UP: UInt16 = 2
            static let DOWN: UInt16 = 3
            static let LEFT: UInt16 = 5
            static let RIGHT: UInt16 = 4
        }
        struct TimerOptions {
            static let OFF: UInt16 = 0
            static let THIRTY_MINUTES: UInt16 = 1
            static let FOURTY_MINUTES: UInt16 = 2
            static let FIFTY_MINUTES: UInt16 = 3
            static let SIXTY_MINUTES: UInt16 = 4
            static let NINETY_MINUTES: UInt16 = 5
        }
        struct FPSOptions {
            static let OFF: UInt16 = 0
            static let NUMBER_ONLY: UInt16 = 1
            static let NUMBER_AND_GRAPH: UInt16 = 2
        }
        struct DisplayAlignment {
            static let OFF: UInt16 = 0
            static let ON: UInt16 = 1
        }
        
        // GameVisualView
        struct VisualPresets {
            struct HDR {
                struct STANDARD {
                    static let CINEMA: UInt16 = 257
                    static let GAMING: UInt16 = 258
                    static let CONSOLE: UInt16 = 259
                    static let HDR_400: UInt16 = 269
                }
                struct DOLBY {
                    static let CINEMA: UInt16 = 513
                    static let GAMING: UInt16 = 514
                    static let CONSOLE: UInt16 = 515
                    static let TRUEBLACK: UInt16 = 516
                }
                
            }
            struct SDR {
                static let CINEMA_WG: UInt16 = 1
                static let CINEMA_SRGB: UInt16 = 257
                static let CINEMA_DCIP3: UInt16 = 513
                static let SCENERY_WG: UInt16 = 2
                static let SCENERY_SRGB: UInt16 = 258
                static let SCENERY_DCIP3: UInt16 = 514
                static let USER_WG: UInt16 = 4
                static let USER_SRGB: UInt16 = 260
                static let USER_DCIP3: UInt16 = 516
                static let RACING_WG: UInt16 = 5
                static let RACING_SRGB: UInt16 = 261
                static let RACING_DCIP3: UInt16 = 517
                static let RTS_WG: UInt16 = 6
                static let RTS_SRGB: UInt16 = 262
                static let RTS_DCIP3: UInt16 = 518
                static let FPS_WG: UInt16 = 7
                static let FPS_SRGB: UInt16 = 263
                static let FPS_DCIP3: UInt16 = 519
                static let MOBA_WG: UInt16 = 8
                static let MOBA_SRGB: UInt16 = 264
                static let MOBA_DCIP3: UInt16 = 520
                static let NIGHT_VISION_WG: UInt16 = 9
                static let NIGHT_VISION_SRGB: UInt16 = 265
                static let NIGHT_VISION_DCIP3: UInt16 = 521
                static let SRGB: UInt16 = 3
            }
        }
        
        /* Shadow boost and bluelight options are 0-4 values
         * that we won't turn into constants because mapping
         * is more concise as is
         */
        
        struct ColorTemp {
            static let FOUR_THOUSAND_K: UInt16 = 3
            static let FIVE_THOUSAND_K: UInt16 = 4
            static let SIXTYFIVE_THOUSAND_K: UInt16 = 5
            static let SEVENTYFIVE_THOUSAND_K: UInt16 = 6
            static let EIGHTYTWO_THOUSAND_K: UInt16 = 7
            static let NINETYTHREE_THOUSAND_K: UInt16 = 8
            static let TEN_THOUSAND_K: UInt16 = 9
            static let USER: UInt16 = 11
        }
        
        /* Vivid pixels is a standard 0-100 slider that goes by 10,
         * useless to turn as constants */
        
        struct Gamma {
            static let ONE_DOT_EIGHT: UInt16 = 80
            static let TWO_DOT_ZERO: UInt16 = 100
            static let TWO_DOT_TWO: UInt16 = 120
            static let TWO_DOT_FOUR: UInt16 = 140
            static let TWO_DOT_SIX: UInt16 = 160
        }
        
        /* User color temp follows the same logic of vivid pixels */
        
        // OLED Care
        struct CareFeatures {
            static let SCREEN_DIMMING = OLEDCareFlags(rawValue: 1 << 3)  // Bit 3: 8
            static let LOGO_DETECTION = OLEDCareFlags(rawValue: 1 << 5)  // Bit 5: 32
            static let UNIFORM_BRIGHTNESS = OLEDCareFlags(rawValue: 1 << 6)  // Bit 6: 64
            static let TASKBAR_DETECTION = OLEDCareFlags(rawValue: 1 << 11)  // Bit 11: 2048
            static let BOUNDARY_DETECTION = OLEDCareFlags(rawValue: 1 << 12)  // Bit 12: 4096
            static let OUTER_DIMMING = OLEDCareFlags(rawValue: 1 << 13)  // Bit 13: 8192
            static let GLOBAL_DIMMING = OLEDCareFlags(rawValue: 1 << 14)  // Bit 14: 16384
            static let PIXEL_CLEANING: UInt16 = 20824
            static let REMINDER_NEVER: UInt16 = 0
            static let REMINDER_TWO_HOURS: UInt16 = 2
            static let REMINDER_FOUR_HOURS: UInt16 = 4
            static let REMINDER_EIGHT_HOURS: UInt16 = 8
            static let SCREEN_MOVE_OFF: UInt16 = 0
            static let SCREEN_MOVE_LIGHT: UInt16 = 1
            static let SCREEN_MOVE_MIDDLE: UInt16 = 2
            static let SCREEN_MOVE_STRONG: UInt16 = 3
        }
        
        // PIP
        struct PIP {
            static let OFF: UInt16 = 0
            static let SOURCE_USB_C: UInt16 = 6682
            static let SOURCE_HDMI_1: UInt16 = 4378
            static let SOURCE_HDMI_2: UInt16 = 4634
            static let TOP_RIGHT: UInt16 = 1
            static let TOP_LEFT: UInt16 = 2
            static let BOTTOM_RIGHT: UInt16 = 3
            static let BOTTOM_LEFT: UInt16 = 4
            static let VERTICAL_SPLIT: UInt16 = 5
        }
        
        // OSD
        /* OSD Timeout range is a slider 0-120
         * OSD transparency is a slider 0-100 with 20 as step */
        
        // System Settings
        /* I'm skipping AURA, I have the values, but they work oddly, needs more
         * playing around with the monitor, but honestly, I'm too tired for this
         * It doesn't make a lot of sense to my eyes and I don't care too much about the
         * lights on the back to waste more hours on them.
         * Will report observed values in this repository README */
        
        struct OSD {
            static let INDICATOR_OFF: UInt16 = 0
            static let INDICATOR_ON: UInt16 = 1
            static let POWER_SYNC_ON: UInt16 = 2048
            static let POWER_SYNC_ON_INDICATOR_ON: UInt16 = 2049
            static let POWER_SYNC_ON_INDICATOR_ON_KEY_LOCK: UInt16 = 2055
        }
        
        struct KVM_USB {
            static let USB_C: UInt16 = 3
            static let USB_A: UInt16 = 2
        }
        
        struct ProximityCombo {
            static let OFF_10_MIN: UInt16 = 1280
            static let SIXTY_CM_5_MIN: UInt16 = 259
            static let SIXTY_CM_10_MIN: UInt16 = 1283
            static let SIXTY_CM_15_MIN: UInt16 = 2563
            static let NINETY_CM_5_MIN: UInt16 = 258
            static let NINETY_CM_10_MIN: UInt16 = 1282
            static let NINETY_CM_15_MIN: UInt16 = 2562
            static let ONEHUNDREDTWENTY_CM_5_MIN: UInt16 = 257
            static let ONEHUNDREDTWENTY_CM_10_MIN: UInt16 = 1281
            static let ONEHUNDREDTWENTY_CM_15_MIN: UInt16 = 2561
            static let TAILORED_CM_5_MIN: UInt16 = 511
            static let TAILORED_CM_10_MIN: UInt16 = 1535
            static let TAILORED_CM_15_MIN: UInt16 = 2815
        }
        
        enum OSDNavCommand: UInt16 {
            case exit = 0
            case up = 2
            case down = 3
            case left = 5
            case right = 4
            case open = 1
            case select = 6
        }
        
        struct KeyCodes {
            static let kVK_UpArrow: CGKeyCode = 126
            static let kVK_DownArrow: CGKeyCode = 125
            static let kVK_LeftArrow: CGKeyCode = 123
            static let kVK_RightArrow: CGKeyCode = 124
            static let kVK_ANSI_0: CGKeyCode = 29
            static let kVK_Return: CGKeyCode = 36
            static let kVK_ANSI_KeypadEnter: CGKeyCode = 76
            static let kVK_Escape: CGKeyCode = 53
        }
    }
}
