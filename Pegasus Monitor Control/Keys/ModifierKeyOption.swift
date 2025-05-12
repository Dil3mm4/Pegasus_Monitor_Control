//
//  ModifierKeyOption.swift
//
//  Created by Francesco Manzo on 12/05/25.
//
import SwiftUI

enum ModifierKeyOption: String, CaseIterable, Identifiable {
    case none = "None"
    case shift = "Shift"
    case control = "Control"
    case option = "Option"
    case command = "Command"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
            case .none: return "None"
            case .shift: return "⇧ Shift"
            case .control: return "⌃ Control"
            case .option: return "⌥ Option"
            case .command: return "⌘ Command"
        }
    }
    
    var keyMask: EventModifiers? {
        switch self {
            case .none: return nil
            case .shift: return .shift
            case .control: return .control
            case .option: return .option
            case .command: return .command
        }
    }
    var cgEventFlag: CGEventFlags? {
        switch self {
            case .shift: return .maskShift
            case .control: return .maskControl
            case .option: return .maskAlternate  // .maskAlternate is for Option key
            case .command: return .maskCommand
            case .none: return nil
        }
    }
}
