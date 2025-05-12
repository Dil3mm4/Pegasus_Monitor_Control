//
//  ContentView.swift
//
//  Created by Francesco Manzo on 12/05/25.
//

import CoreGraphics
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    @State private var systemSettingsClickCount: Int = 0
    @State private var showDebugView: Bool = false
    @State private var clickResetTimer: Timer? = nil
    
    private let targetMonitorName = "PG27UCDM"
    
    let sidebarItems: [SidebarItem] = [
        SidebarItem(
            name: "GameVisual",
            iconName: "display",
            viewIdentifier: "GameVisual"
        ),
        SidebarItem(
            name: "GamePlus",
            iconName: "gamecontroller",
            viewIdentifier: "GamePlus"
        ),
        SidebarItem(
            name: "OLED Care",
            iconName: "shield.lefthalf.filled",
            viewIdentifier: "OLED"
        ),
        SidebarItem(
            name: "Pip",
            iconName: "pip",
            viewIdentifier: "Pip"
        ),
        SidebarItem(
            name: "OSD",
            iconName: "slider.horizontal.below.rectangle",
            viewIdentifier: "OSD"
        ),
        SidebarItem(
            name: "System Settings",
            iconName: "gearshape",
            viewIdentifier: "SystemSettings"
        ),
    ]
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                sidebarItems: sidebarItems,
                selectedSidebarIdentifier: $viewModel.selectedSidebarIdentifier,
                systemSettingsAction: handleSystemSettingsTap
            )
        } detail: {
            ZStack(alignment: .bottomLeading) {
                // Main scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if viewModel.isTargetMonitorConnected {
                            Group {
                                if showDebugView {
                                    DebugView().padding()
                                } else {
                                    switch viewModel.selectedSidebarIdentifier {
                                        case "GameVisual":
                                            GameVisualView().padding()
                                        case "GamePlus":
                                            GamePlusView().padding()
                                        case "OLED":
                                            OLEDCareView().padding()
                                        case "OSD":
                                            OSDView().padding()
                                        case "Pip":
                                            PipView().padding()
                                        case "SystemSettings":
                                            SystemSettingsView().padding()
                                        default:
                                            Text(
                                                "Select an option from the sidebar"
                                            )
                                            .font(.title).foregroundColor(
                                                .secondary
                                            )
                                            .frame(
                                                maxWidth: .infinity,
                                                maxHeight: .infinity
                                            )
                                    }
                                }
                            }
                            .environmentObject(viewModel)
                        } else {
                            monitorNotConnectedView
                        }
                    }
                    .padding(.bottom, 30)
                }
                statusBar
            }
            .frame(minWidth: 550)
        }
        .preferredColorScheme(.dark)
        .frame(minWidth: 850, minHeight: 600)
        .onAppear {
            if viewModel.matchedServices.isEmpty && !viewModel.isScanning {
                viewModel.scanMonitors()
            }
        }
    }
    
    // MARK: - Subviews
    private var monitorNotConnectedView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding(.bottom)
            Text("\(targetMonitorName) Not Detected")
                .font(.title2).fontWeight(.medium)
            Text(
                "Please ensure the \(targetMonitorName) monitor is connected and powered on."
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            Button("Rescan Monitors") {
                viewModel.scanMonitors()
            }
            .padding(.top)
            .disabled(viewModel.isScanning)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var statusBar: some View {
        Text("Status: \(viewModel.statusMessage)")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            .background(Color(.windowBackgroundColor))  // Match window color
    }
    private func handleSystemSettingsTap() {
        systemSettingsClickCount += 1
        clickResetTimer?.invalidate()
        if systemSettingsClickCount >= 7 {
            showDebugView.toggle()
            systemSettingsClickCount = 0
            if showDebugView {
                viewModel.selectedSidebarIdentifier = nil
            } else if viewModel.selectedSidebarIdentifier == nil {
                viewModel.selectedSidebarIdentifier = "SystemSettings"
            }
        } else {
            clickResetTimer = Timer.scheduledTimer(
                withTimeInterval: 1.5,
                repeats: false
            ) { _ in
                if !showDebugView { systemSettingsClickCount = 0 }
            }
        }
    }
}

// SidebarView remains largely the same, but the Picker will be affected by DDCViewModel changes
struct SidebarView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    let sidebarItems: [SidebarItem]
    @Binding var selectedSidebarIdentifier: String?
    let systemSettingsAction: () -> Void
    private let targetMonitorName = "PG27UCDM"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Display")
                .font(.title3).fontWeight(.medium)
                .padding(.horizontal).padding(.top).padding(.bottom, 5)
            
            Picker("Monitor", selection: $viewModel.selectedDisplayID) {
                if viewModel.matchedServices.isEmpty && !viewModel.isScanning {
                    Text("\(targetMonitorName) Not Found").tag(
                        nil as CGDirectDisplayID?
                    )
                } else if viewModel.isScanning {
                    Text("Scanning...").tag(nil as CGDirectDisplayID?)
                }
                ForEach(viewModel.matchedServices) { service in
                    Text(
                        service.serviceDetails.productName.isEmpty
                        ? "\(targetMonitorName) (ID: \(service.displayID))"
                        : service.serviceDetails.productName
                    )
                    .tag(service.displayID as CGDirectDisplayID?)
                }
            }
            .labelsHidden()
            .padding(.horizontal)
            .padding(.bottom, 10)
            .disabled(
                viewModel.isScanning || viewModel.matchedServices.count <= 1
            )
            
            List(selection: $selectedSidebarIdentifier) {
                ForEach(sidebarItems) { item in
                    if item.viewIdentifier == "SystemSettings" {
                        Button {
                            selectedSidebarIdentifier = item.viewIdentifier
                            systemSettingsAction()
                        } label: {
                            Label(item.name, systemImage: item.iconName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain).tag(item.viewIdentifier)
                    } else {
                        Label(item.name, systemImage: item.iconName)
                            .tag(item.viewIdentifier)
                    }
                }
            }
            .listStyle(.sidebar)
            .disabled(
                viewModel.isScanning || !viewModel.isTargetMonitorConnected
            )
            .opacity(
                viewModel.isScanning || !viewModel.isTargetMonitorConnected
                ? 0.5 : 1.0
            )
        }
        .frame(minWidth: 200, idealWidth: 230, maxWidth: 350)
    }
}

#Preview {
    let previewVM = DDCViewModel()
    return ContentView().environmentObject(previewVM)
}
