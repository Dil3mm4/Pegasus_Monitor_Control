//
//  HelperViews.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

import Combine
import SwiftUI

// Reusable Row for Picker Settings
struct SettingsPickerRow<Option: Hashable & Identifiable>: View {
    let title: String
    let description: String?
    @Binding var selection: Option.ID
    
    let options: [Option]
    let optionId: (Option) -> Option.ID
    let optionTitle: (Option) -> String
    let action: (Option) -> Void
    let isDisabled: Bool
    
    init(
        title: String,
        description: String? = nil,
        selection: Binding<Option.ID>,
        options: [Option],
        optionId: @escaping (Option) -> Option.ID,
        optionTitle: @escaping (Option) -> String,
        action: @escaping (Option) -> Void = { _ in },
        isDisabled: Bool = false
    ) {
        self.title = title
        self.description = description
        self._selection = selection
        self.options = options
        self.optionId = optionId
        self.optionTitle = optionTitle
        self.action = action
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(title).fontWeight(.medium)
                if let desc = description, !desc.isEmpty {
                    Text(desc).font(.caption).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Picker(title, selection: $selection) {
                ForEach(options) { option in
                    Text(optionTitle(option)).tag(optionId(option))
                }
            }
            .labelsHidden()
            .frame(maxWidth: 150)
            .onChange(of: selection) { newId in
                if !isDisabled,
                   let selectedOption = options.first(where: {
                       optionId($0) == newId
                   })
                {
                    action(selectedOption)  // Perform the action only if enabled
                }
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// Reusable Row for Toggle Settings
struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let action: (Bool) -> Void  // Action performed on toggle change
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(title).fontWeight(.medium)
                if !description.isEmpty {
                    Text(description).font(.caption).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { newValue in action(newValue) }  // Perform action on change
        }
    }
}

// Reusable Selectable Button (for Mode Grids)
struct ModeButton: View {
    let iconName: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 30)
                Text(label)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(minWidth: 80, maxWidth: 120, minHeight: 65)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                        ? Color.accentColor.opacity(0.6)
                        : Color(nsColor: .controlColor).opacity(0.3)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// Reusable Row for Slider Settings
struct SettingsSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var decimals: Int
    let step: Double?
    var sendImmediately: Bool
    let onValueChanged: ((Double) -> Void)?
    let onEditingChanged: ((Bool) -> Void)?
    
    @State private var hasChangedSinceEditingBegan: Bool = false
    
    init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        decimals: Int = 0,
        step: Double? = nil,
        sendImmediately: Bool = true,
        onValueChanged: ((Double) -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.decimals = decimals
        self.step = step
        self.sendImmediately = sendImmediately
        self.onValueChanged = onValueChanged
        self.onEditingChanged = onEditingChanged
    }
    
    var body: some View {
        HStack {
            Text(label)
                .frame(minWidth: 100, alignment: .leading)
            
            if let stepValue = step {
                Slider(
                    value: $value,
                    in: range,
                    step: stepValue,
                    onEditingChanged: { editing in
                        handleEditingChanged(editing)
                    }
                )
            } else {
                Slider(
                    value: $value,
                    in: range,
                    onEditingChanged: { editing in
                        handleEditingChanged(editing)
                    }
                )
            }
            
            Text(String(format: "%.\(decimals)f", value))
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 45, alignment: .trailing)
        }
        .onChange(of: value) { newValue in
            handleValueChanged(newValue)
        }
    }
    
    private func handleValueChanged(_ newValue: Double) {
        if sendImmediately {
            onValueChanged?(newValue)
        } else {
            hasChangedSinceEditingBegan = true
        }
    }
    
    private func handleEditingChanged(_ editing: Bool) {
        onEditingChanged?(editing)
        
        if editing {
            hasChangedSinceEditingBegan = false
        } else {
            if !sendImmediately && hasChangedSinceEditingBegan {
                onValueChanged?(value)
            }
            hasChangedSinceEditingBegan = false
        }
    }
}

struct KeyCap: View {
    let keyName: String
    var body: some View {
        Text(keyName)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlColor).opacity(0.5))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4).stroke(
                    Color.gray.opacity(0.5)
                )
            )
    }
}
