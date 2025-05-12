//
//  DebugView.swift
//
//  Created by Francesco Manzo on 12/05/25.
//
import Combine
import SwiftUI


struct VCPCommand: Identifiable {
    let id = UUID()
    var vcpCodeString: String = ""  
    var valueString: String = ""  
    var isReadCommand: Bool = false  
}

struct DebugView: View {
    @EnvironmentObject var viewModel: DDCViewModel
    
    // MARK: - State Properties
    
    @State private var commands: [VCPCommand] = [VCPCommand()]  
    @State private var commandStatus: String = ""  
    @State private var isSendingBatch: Bool = false  
    
    
    @State private var readResults: [String] = []  
    @State private var vcpCapabilitiesString: String =
    "Press 'Read Capabilities' to query monitor..."
    @State private var isFetchingCaps: Bool = false
    
    
    @State private var vcpSnapshot: [UInt8: (current: UInt16, max: UInt16)]?  
    @State private var isTakingSnapshot: Bool = false
    @State private var comparisonResult: String = ""  
    @State private var snapshotProgress: Double = 0  
    @State private var capturedCodesCount: Int = 0  
    @State private var snapshotOperationQueue: OperationQueue?  
    
    
    @State private var pipBruteResults: [String] = []  
    @State private var isBruteforcingPiP: Bool = false
    @State private var currentPiPBatch: [UInt16] = []  
    @State private var successfulPiPValue: UInt16?  
    @State private var bruteforceQueue: [UInt16] = []  
    @State private var showPiPFeedbackAlert: Bool = false  
    
    
    @State private var spamVCPCodeString: String = ""
    @State private var spamStartValueString: String = ""
    @State private var spamEndValueString: String = ""
    @State private var spamDelayString: String = "50"  
    @State private var isSpammingActive: Bool = false
    @State private var spamLog: [String] = []
    @State private var spamTask: Task<Void, Never>? = nil
    
    
    private let pipTestValues: [UInt16] = [UInt16](100...0x1F1A)  
    private let pipBatchSize = 20  
    
    // MARK: - Main View
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            headerSection
            warningSection
            commandInputSection
            Divider()
            readResultsSection
            Divider()
            capabilitiesSection
            Divider()
            fullSnapshotSection
            Divider()
            vcpSpamSection  
            Divider()
            pipBruteforceSection
            Spacer()  
        }
        .padding()
        .onAppear(perform: resetCapabilitiesString)  
        .onChange(of: viewModel.selectedDisplayID) { _ in resetUI() }  
        .onDisappear(perform: cancelOperations)  
        
        .alert("Did PiP activate?", isPresented: $showPiPFeedbackAlert) {
            Button("Yes") { handlePiPSuccess() }
            Button("No") { continuePiPBruteforce() }
        } message: {
            Text(
                "Check if Picture-in-Picture mode turned on after testing values \(currentPiPBatch.first ?? 0)...\(currentPiPBatch.last ?? 0)."
            )
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        HStack {
            Text("Debug DDC")
                .font(.title).fontWeight(.medium)
            Spacer()
            Button {
                viewModel.scanMonitors()
            } label: {
                Label("Rescan Monitors", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(isLoadingActive)  
        }
    }
    
    private var warningSection: some View {
        Text(
            "WARNING: Sending incorrect VCP codes or values can potentially cause unexpected monitor behavior or instability. Use with caution."
        )
        .font(.caption).italic().foregroundColor(.orange)
    }
    
    private var commandInputSection: some View {
        VStack(alignment: .leading) {
            Text("Manual VCP Commands").font(.headline)
            ForEach($commands) { $command in
                commandRow(command: $command)
            }
            commandControls
            if !commandStatus.isEmpty {
                Text(commandStatus).font(.caption).foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
    }
    
    @ViewBuilder
    private func commandRow(command: Binding<VCPCommand>) -> some View {
        HStack {
            Picker("", selection: command.isReadCommand) {
                Text("Read").tag(true)
                Text("Write").tag(false)
            }
            .pickerStyle(.segmented).frame(width: 120)
            
            Text("VCP Code:")
            TextField("Hex (00-FF)", text: command.vcpCodeString)
                .textFieldStyle(.roundedBorder).frame(width: 80)
                .font(.system(.body, design: .monospaced))
                .onChange(of: command.vcpCodeString.wrappedValue) { newValue in
                    let filtered = newValue.uppercased().filter {
                        "0123456789ABCDEF".contains($0)
                    }
                    command.wrappedValue.vcpCodeString = String(
                        filtered.prefix(2)
                    )
                }
            
            if !command.isReadCommand.wrappedValue {
                Text("Value:")
                TextField("Dec or 0xHex", text: command.valueString)
                    .textFieldStyle(.roundedBorder).frame(width: 100)
                    .font(.system(.body, design: .monospaced))
            }
            
            if commands.count > 1 {
                Button {
                    removeCommand(id: command.id)
                } label: {
                    Image(systemName: "trash").foregroundColor(.red)
                }
                .buttonStyle(.borderless).padding(.leading, 5)
            } else {
                Spacer().frame(width: 30)
            }
        }
    }
    
    @ViewBuilder
    private var commandControls: some View {
        HStack {
            Button {
                addCommand()
            } label: {
                Label("Add Command", systemImage: "plus")
            }
            Spacer()
            Button("Execute All") { executeAllCommands() }
                .buttonStyle(.borderedProminent)
                .disabled(
                    isSendingBatch || viewModel.selectedDisplayID == nil
                    || commands.isEmpty
                    || commands.allSatisfy { $0.vcpCodeString.isEmpty }
                    || isLoadingActive
                )
        }
        .padding(.top, 5)
    }
    
    private var readResultsSection: some View {
        Group {
            if !readResults.isEmpty {
                VStack(alignment: .leading) {
                    Text("Read Results").font(.headline)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(readResults, id: \.self) { result in
                                Text(result)
                                    .font(
                                        .system(size: 14, design: .monospaced)
                                    )
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                }
            }
        }
    }
    
    private var capabilitiesSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("VCP Capabilities (0xF3)").font(.headline)
                Spacer()
                Button {
                    fetchCapabilities()
                } label: {
                    Label("Read", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedDisplayID == nil || isLoadingActive)
            }
            
            if isFetchingCaps {
                ProgressView().padding(.vertical).frame(maxWidth: .infinity)
            } else {
                ScrollView(.vertical) {
                    Text(vcpCapabilitiesString)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                }
                .frame(height: 100)
                .background(Color(nsColor: .controlColor).opacity(0.1))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5).stroke(
                        Color.gray.opacity(0.3)
                    )
                )
            }
        }
    }
    
    private var fullSnapshotSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Full VCP Scan (0x00 - 0xFF)").font(.headline)
                Spacer()
                Button(action: takeFullSnapshot) {
                    VStack {
                        Text(
                            vcpSnapshot == nil
                            ? "Scan All VCP Codes" : "Rescan & Compare"
                        )
                        if isTakingSnapshot {
                            Text("\(Int(snapshotProgress))/256")
                                .font(.caption2).opacity(0.7)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingActive)
            }
            
            if isTakingSnapshot {
                VStack(alignment: .center) {
                    ProgressView(value: snapshotProgress, total: 256)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                    Text("Found \(capturedCodesCount) supported codes")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            
            if !comparisonResult.isEmpty {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text(comparisonResult)
                            .font(.system(size: 14, design: .monospaced))
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
            }
        }
    }
    
    // MARK: - VCP Spam Section
    private var vcpSpamSection: some View {
        VStack(alignment: .leading) {
            Text("VCP Value Spamming").font(.headline)
            
            HStack {
                Text("VCP Code:")
                TextField("Hex (00-FF)", text: $spamVCPCodeString)
                    .textFieldStyle(.roundedBorder).frame(width: 80)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: spamVCPCodeString) { newValue in
                        let filtered = newValue.uppercased().filter {
                            "0123456789ABCDEF".contains($0)
                        }
                        spamVCPCodeString = String(filtered.prefix(2))
                    }
                    .disabled(isSpammingActive)
                
                Text("Delay (ms):")
                TextField("e.g., 50", text: $spamDelayString)
                    .textFieldStyle(.roundedBorder).frame(width: 60)
                    .onChange(of: spamDelayString) { newValue in
                        spamDelayString = newValue.filter {
                            "0123456789".contains($0)
                        }
                    }
                    .disabled(isSpammingActive)
            }
            .disabled(isSpammingActive)
            
            HStack {
                Text("Start Value:")
                TextField("Dec or 0xHex", text: $spamStartValueString)
                    .textFieldStyle(.roundedBorder).frame(width: 100)
                    .font(.system(.body, design: .monospaced))
                
                Text("End Value:")
                TextField("Dec or 0xHex", text: $spamEndValueString)
                    .textFieldStyle(.roundedBorder).frame(width: 100)
                    .font(.system(.body, design: .monospaced))
            }
            .disabled(isSpammingActive)
            
            HStack {
                Button(action: isSpammingActive ? stopSpamming : startSpamming)
                {
                    Label(
                        isSpammingActive ? "Stop Spamming" : "Start Spamming",
                        systemImage: isSpammingActive
                        ? "stop.circle.fill" : "play.circle.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(isSpammingActive ? .red : .blue)
                .disabled(
                    (isSpammingActive
                     ? false
                     : (isLoadingActive
                        || viewModel.selectedDisplayID == nil))
                )
                
                if isSpammingActive {
                    ProgressView().padding(.leading)
                }
            }
            .padding(.top, 5)
            
            if !spamLog.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(spamLog.indices, id: \.self) { index in
                                Text(spamLog[index])
                                    .font(
                                        .system(size: 12, design: .monospaced)
                                    )
                                    .textSelection(.enabled)
                                    .id(index)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: spamLog.count) { _ in
                        if let lastIndex = spamLog.indices.last {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
                .frame(maxHeight: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
                .padding(.top, 5)
            }
        }
    }
    
    private var pipBruteforceSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("PiP Bruteforce Test (0xF5)").font(.headline)
                Spacer()
                Button(action: startPiPBruteforce) {
                    Label(
                        isBruteforcingPiP ? "Testing..." : "Start Test",
                        systemImage: "play.circle"
                    )
                }
                .buttonStyle(.bordered)
                .tint(isBruteforcingPiP ? .orange : .blue)
                .disabled(isLoadingActive)
            }
            
            if !pipBruteResults.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(pipBruteResults, id: \.self) { result in
                            Text(result)
                                .font(.system(size: 14, design: .monospaced))
                                .textSelection(.enabled)
                                .background(
                                    result.contains("✅")
                                    ? Color.green.opacity(0.3) : Color.clear
                                )
                                .cornerRadius(3)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
            }
        }
    }
    
    
    private var isLoadingActive: Bool {
        viewModel.isScanning || isTakingSnapshot || isBruteforcingPiP
        || isSendingBatch || isFetchingCaps || isSpammingActive
    }
    
    // MARK: - VCP Spam Functions
    private func startSpamming() {
        guard !isSpammingActive else { return }  
        guard viewModel.selectedDisplayID != nil else {
            spamLog.append("Error: No monitor selected.")
            return
        }
        
        guard let vcpCode = UInt8(spamVCPCodeString, radix: 16) else {
            spamLog.append(
                "Error: Invalid VCP Code '\(spamVCPCodeString)'. Must be Hex (00-FF)."
            )
            return
        }
        guard let startValue = parseValue(spamStartValueString) else {
            spamLog.append(
                "Error: Invalid Start Value '\(spamStartValueString)'."
            )
            return
        }
        guard let endValue = parseValue(spamEndValueString) else {
            spamLog.append("Error: Invalid End Value '\(spamEndValueString)'.")
            return
        }
        guard let delayMs = UInt64(spamDelayString), delayMs > 0 else {
            spamLog.append(
                "Error: Invalid Delay '\(spamDelayString)'. Must be a positive number > 0 (ms)."
            )
            return
        }
        
        if startValue > endValue {
            spamLog.append(
                "Error: Start Value (\(startValue)) cannot be greater than End Value (\(endValue))."
            )
            return
        }
        
        spamLog.removeAll()  
        isSpammingActive = true
        viewModel.updateStatus(
            "Spamming VCP 0x\(String(format: "%02X", vcpCode))..."
        )
        spamLog.append(
            "Starting spam: VCP 0x\(String(format: "%02X", vcpCode)), Range \(startValue)-\(endValue), Delay \(delayMs)ms"
        )
        
        spamTask = Task {
            for currentValue in stride(
                from: startValue,
                through: endValue,
                by: 1
            ) {
                if Task.isCancelled { break }
                
                let valueToSend = UInt16(currentValue)
                
                await MainActor.run {
                    spamLog.append(
                        "Sending 0x\(String(format: "%02X", vcpCode)) = \(valueToSend) (0x\(String(format: "%04X", valueToSend)))..."
                    )
                }
                
                await Task.yield()  
                
                let writeSuccess: Bool = await withCheckedContinuation {
                    continuation in
                    Task { @MainActor in
                        viewModel.writeDDC(command: vcpCode, value: valueToSend)
                        { success, _ in
                            continuation.resume(returning: success)
                        }
                    }
                }
                
                await MainActor.run {
                    let status = writeSuccess ? "OK" : "FAIL"
                    spamLog.append("  -> Result: \(status)")
                }
                
                do {
                    try await Task.sleep(nanoseconds: delayMs * 1_000_000)
                } catch {  
                    break  
                }
            }
            
            await MainActor.run {
                let finalMessage =
                Task.isCancelled
                ? "Spamming stopped by user." : "Spamming finished range."
                spamLog.append(finalMessage)
                viewModel.updateStatus(finalMessage)
                isSpammingActive = false
                spamTask = nil
            }
        }
    }
    
    private func stopSpamming() {
        spamTask?.cancel()
        
    }
    
    // MARK: - PiP Bruteforce Functions
    private func startPiPBruteforce() {
        guard !isLoadingActive else { return }
        pipBruteResults = [
            "Starting PiP bruteforce (VCP Code \(String(format: "0x%02X", VCP.Codes.PIP_CONTROL))) values \(pipTestValues.first!) to \(pipTestValues.last!)..."
        ]
        isBruteforcingPiP = true
        successfulPiPValue = nil
        bruteforceQueue = pipTestValues
        currentPiPBatch = []
        testNextPiPBatch()
    }
    
    private func testNextPiPBatch() {
        guard isBruteforcingPiP, !bruteforceQueue.isEmpty else {
            endPiPBruteforce()
            return
        }
        
        let batch = Array(bruteforceQueue.prefix(pipBatchSize))
        bruteforceQueue.removeFirst(batch.count)
        currentPiPBatch = batch
        
        let group = DispatchGroup()
        var batchResults: [String] = []
        let resultLock = NSLock()
        
        viewModel.updateStatus(
            "Testing PiP values \(batch.first!)...\(batch.last!)"
        )
        
        for value in batch {
            group.enter()
            viewModel.writeDDC(command: VCP.Codes.PIP_CONTROL, value: value) {
                success,
                message in
                let hexValue = String(format: "0x%04X", value)
                let resultString =
                "Tested \(value) (\(hexValue)): \(success ? "OK" : "FAIL")"
                resultLock.lock()
                batchResults.append(resultString)
                resultLock.unlock()
                group.leave()
                usleep(50000)  
            }
        }
        
        group.notify(queue: .main) {
            self.pipBruteResults.append(contentsOf: batchResults.sorted())
            if isBruteforcingPiP {
                self.showPiPFeedbackAlert = true
            }
        }
    }
    
    private func continuePiPBruteforce() {
        guard isBruteforcingPiP else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            testNextPiPBatch()
        }
    }
    
    private func handlePiPSuccess() {
        guard let value = currentPiPBatch.last else {
            isBruteforcingPiP = false
            viewModel.updateStatus(
                "PiP Success reported, but couldn't identify value."
            )
            return
        }
        successfulPiPValue = value
        let hexValue = String(format: "0x%04X", value)
        
        if let index = pipBruteResults.lastIndex(where: {
            $0.contains("Tested \(value) (\(hexValue))")
        }) {
            pipBruteResults[index] =
            "✅ \(pipBruteResults[index]) - PiP ACTIVATED!"
        } else {
            pipBruteResults.append(
                "✅ Success reported for value \(value) (\(hexValue)) - PiP ACTIVATED!"
            )
        }
        
        viewModel.updateStatus(
            "PiP success found! Value: \(value) (\(hexValue))"
        )
        isBruteforcingPiP = false
        bruteforceQueue.removeAll()
    }
    
    private func endPiPBruteforce() {
        if isBruteforcingPiP {
            pipBruteResults.append(
                "Bruteforce complete."
                + (successfulPiPValue == nil
                   ? " No working PiP value confirmed." : "")
            )
            viewModel.updateStatus("PiP bruteforce finished.")
        }
        isBruteforcingPiP = false
        bruteforceQueue.removeAll()
        currentPiPBatch = []
    }
    
    // MARK: - Command Management
    private func addCommand() {
        commands.append(VCPCommand())
    }
    
    private func removeCommand(id: UUID) {
        commands.removeAll { $0.id == id }
    }
    
    // MARK: - Core DDC Execution Functions
    private func executeAllCommands() {
        guard !isSendingBatch, let displayID = viewModel.selectedDisplayID
        else { return }
        isSendingBatch = true
        commandStatus = "Executing \(commands.count) command(s)..."
        readResults.removeAll()
        
        let dispatchGroup = DispatchGroup()
        let commandQueue = OperationQueue()
        commandQueue.maxConcurrentOperationCount = 1
        
        for (index, command) in commands.enumerated() {
            dispatchGroup.enter()
            commandQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                var operationResult = ""
                let commandIndexDescription = "Cmd \(index + 1)"
                
                guard let vcpCode = UInt8(command.vcpCodeString, radix: 16)
                else {
                    operationResult =
                    "\(commandIndexDescription): Invalid VCP Code '\(command.vcpCodeString)'"
                    self.appendResultOnMain(result: operationResult)
                    semaphore.signal()
                    dispatchGroup.leave()
                    return
                }
                
                if command.isReadCommand {
                    DispatchQueue.main.async {
                        self.viewModel.readDDC(command: vcpCode) {
                            current,
                            max,
                            message in
                            operationResult = self.formatReadResult(
                                index: index + 1,
                                code: vcpCode,
                                current: current,
                                max: max,
                                message: message
                            )
                            self.appendResultOnMain(result: operationResult)
                            semaphore.signal()
                            dispatchGroup.leave()
                        }
                    }
                } else {
                    guard let value = parseValue(command.valueString) else {
                        operationResult =
                        "\(commandIndexDescription): Invalid Value '\(command.valueString)' for VCP 0x\(String(format: "%02X", vcpCode))"
                        self.appendResultOnMain(result: operationResult)
                        semaphore.signal()
                        dispatchGroup.leave()
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.viewModel.writeDDC(command: vcpCode, value: value)
                        { success, message in
                            operationResult =
                            "\(commandIndexDescription): Write 0x\(String(format: "%02X", vcpCode))=\(value) - \(success ? "OK" : "FAIL")"
                            DispatchQueue.main.async {
                                self.commandStatus = operationResult
                            }
                            semaphore.signal()
                            dispatchGroup.leave()
                        }
                    }
                }
                semaphore.wait()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isSendingBatch = false
            self.commandStatus = "Completed \(self.commands.count) command(s)."
        }
    }
    
    private func appendResultOnMain(result: String) {
        DispatchQueue.main.async {
            self.readResults.append(result)
        }
    }
    
    private func parseValue(_ input: String) -> UInt16? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.lowercased().hasPrefix("0x") {
            return UInt16(String(cleaned.dropFirst(2)), radix: 16)
        }
        return UInt16(cleaned)
    }
    
    private func formatReadResult(
        index: Int,
        code: UInt8,
        current: UInt16?,
        max: UInt16?,
        message: String
    ) -> String {
        let codeHex = String(format: "0x%02X", code)
        guard let currentVal = current, let maxVal = max else {
            return "Cmd \(index): Read \(codeHex) FAILED - \(message)"
        }
        let currentHex = String(format: "0x%04X", currentVal)
        let maxHex = String(format: "0x%04X", maxVal)
        return
        "Cmd \(index): Read \(codeHex) OK - Current: \(currentVal) (\(currentHex)), Max: \(maxVal) (\(maxHex))"
    }
    
    private func fetchCapabilities() {
        guard !isFetchingCaps, let displayID = viewModel.selectedDisplayID
        else { return }
        isFetchingCaps = true
        vcpCapabilitiesString = "Reading capabilities (0xF3)..."
        viewModel.updateStatus("Reading capabilities...")
        
        viewModel.readCapabilities { data, message in
            if let data = data {
                let hexString = data.map { String(format: "%02X", $0) }.joined(
                    separator: " "
                )
                let asciiString =
                String(data: data, encoding: .ascii)?.filter {
                    $0.isASCII
                    && ($0.isLetter || $0.isNumber || $0.isPunctuation
                        || $0 == " ")
                } ?? ""
                vcpCapabilitiesString =
                "Read OK (\(data.count) bytes):\nHex: \(hexString)\nASCII: \(asciiString)"
                viewModel.updateStatus("Capabilities read OK.")
            } else {
                vcpCapabilitiesString = "Read FAILED: \(message)"
                viewModel.updateStatus("Failed to read capabilities.")
            }
            isFetchingCaps = false
        }
    }
    
    private func takeFullSnapshot() {
        guard !isTakingSnapshot, let displayID = viewModel.selectedDisplayID
        else { return }
        resetSnapshotState()
        viewModel.updateStatus("Starting full VCP scan...")
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 4
        self.snapshotOperationQueue = queue
        
        var newSnapshot = [UInt8: (current: UInt16, max: UInt16)]()
        let snapshotLock = NSLock()
        let allVCPCodes: [UInt8] = Array(0x00...0xFF)
        let dispatchGroup = DispatchGroup()
        
        for code in allVCPCodes {
            if queue.isSuspended {
                dispatchGroup.leave()
                continue
            }
            
            dispatchGroup.enter()
            queue.addOperation {
                guard !queue.isSuspended else {
                    dispatchGroup.leave()
                    return
                }
                
                let semaphore = DispatchSemaphore(value: 0)
                var readCurrent: UInt16? = nil
                var readMax: UInt16? = nil
                
                DispatchQueue.main.async {
                    guard !queue.isSuspended else {
                        semaphore.signal()
                        dispatchGroup.leave()
                        return
                    }
                    self.viewModel.readDDC(command: code) { c, m, _ in
                        readCurrent = c
                        readMax = m
                        semaphore.signal()
                    }
                }
                semaphore.wait()
                
                DispatchQueue.main.async {
                    if let current = readCurrent, let max = readMax {
                        snapshotLock.lock()
                        newSnapshot[code] = (current, max)
                        snapshotLock.unlock()
                        self.capturedCodesCount += 1
                    }
                    self.snapshotProgress += 1
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            guard !queue.isSuspended else {
                print("Snapshot cancelled before processing results.")
                viewModel.updateStatus("Full VCP scan cancelled.")
                self.isTakingSnapshot = false
                self.snapshotOperationQueue = nil
                return
            }
            self.processSnapshotResults(newSnapshot: newSnapshot)
            self.snapshotOperationQueue = nil
            viewModel.updateStatus(
                "Full VCP scan complete. Found \(self.capturedCodesCount) codes."
            )
        }
    }
    
    private func processSnapshotResults(
        newSnapshot: [UInt8: (current: UInt16, max: UInt16)]
    ) {
        let sortedNewKeys = newSnapshot.keys.sorted()
        
        if let previousSnapshot = vcpSnapshot {
            var changes = [String]()
            var newCodes = [String]()
            var removedCodes = [String]()
            
            let allKeys = Set(previousSnapshot.keys).union(Set(sortedNewKeys))
            
            for code in allKeys.sorted() {
                let prevValue = previousSnapshot[code]
                let newValue = newSnapshot[code]
                
                if let new = newValue, let prev = prevValue {
                    if prev != new {
                        changes.append(
                            "0x\(String(format: "%02X", code)): \(prev.current)->\(new.current) (Max: \(prev.max)->\(new.max))"
                        )
                    }
                } else if let new = newValue {
                    newCodes.append(
                        "0x\(String(format: "%02X", code)): \(new.current) (Max: \(new.max))"
                    )
                } else if let prev = prevValue {
                    removedCodes.append(
                        "0x\(String(format: "%02X", code)): Was \(prev.current) (Max: \(prev.max))"
                    )
                }
            }
            
            var resultLines = [
                "Comparison Result (\(newSnapshot.count) codes found):"
            ]
            if !changes.isEmpty {
                resultLines.append(
                    " Changes (\(changes.count)):\n"
                    + changes.joined(separator: "\n")
                )
            }
            if !newCodes.isEmpty {
                resultLines.append(
                    " New Codes (\(newCodes.count)):\n"
                    + newCodes.joined(separator: "\n")
                )
            }
            if !removedCodes.isEmpty {
                resultLines.append(
                    " Removed/Failed Codes (\(removedCodes.count)):\n"
                    + removedCodes.joined(separator: "\n")
                )
            }
            if changes.isEmpty && newCodes.isEmpty && removedCodes.isEmpty {
                resultLines.append(" No changes detected.")
            }
            comparisonResult = resultLines.joined(separator: "\n")
            
        } else {
            comparisonResult =
            "Initial Scan Results (\(newSnapshot.count) codes found):\n"
            + sortedNewKeys.map { code in
                let val = newSnapshot[code]!
                return
                "0x\(String(format: "%02X", code)): \(val.current) (Max: \(val.max))"
            }.joined(separator: "\n")
        }
        vcpSnapshot = newSnapshot
        isTakingSnapshot = false
    }
    
    // MARK: - UI Reset and Cleanup
    private func resetUI() {
        cancelOperations()
        resetCapabilitiesString()
        commands = [VCPCommand()]
        commandStatus = ""
        readResults.removeAll()
        vcpSnapshot = nil
        comparisonResult = ""
        pipBruteResults.removeAll()
        bruteforceQueue.removeAll()
        spamVCPCodeString = ""
        spamStartValueString = ""
        spamEndValueString = ""
        spamDelayString = "50"
        spamLog.removeAll()
        
    }
    
    private func resetCapabilitiesString() {
        vcpCapabilitiesString =
        viewModel.selectedDisplayID == nil
        ? "No monitor selected"
        : "Press 'Read Capabilities' to query monitor..."
    }
    
    private func resetSnapshotState() {
        isTakingSnapshot = true
        comparisonResult = ""
        capturedCodesCount = 0
        snapshotProgress = 0
        snapshotOperationQueue?.cancelAllOperations()
        snapshotOperationQueue = nil
    }
    
    private func cancelOperations() {
        snapshotOperationQueue?.cancelAllOperations()
        snapshotOperationQueue = nil
        isTakingSnapshot = false
        isSendingBatch = false
        isFetchingCaps = false
        
        if isBruteforcingPiP {
            isBruteforcingPiP = false
            bruteforceQueue.removeAll()
            currentPiPBatch = []
            pipBruteResults.append("PiP Bruteforce Cancelled.")
            viewModel.updateStatus("PiP bruteforce cancelled.")
        }
        
        if isSpammingActive {
            stopSpamming()  
            
        }
        
        snapshotProgress = 0
        capturedCodesCount = 0
    }
}

// MARK: - Preview
#Preview {
    DebugView()
        .environmentObject(DDCViewModel())
        .padding()
        .frame(width: 600, height: 850)
        .preferredColorScheme(.dark)
}
