//
//  DiffFilesCollector.swift
//  
//
//  Created by bytedance on 2021/12/9.
//

import Foundation

class DiffFilesCollector {
    
    var inputFiles: [String]
    
    private var customScriptPath: String?
    
    init(_ customScriptPath: String?) {
        self.customScriptPath = customScriptPath
        inputFiles = []
        if let fileCountStr = ProcessInfo.processInfo.environment["SCRIPT_INPUT_FILE_COUNT"] {
            if let fileCount = Int(fileCountStr) {
                for i in 0..<fileCount {
                    if let file = ProcessInfo.processInfo.environment["SCRIPT_INPUT_FILE_\(i)"] {
                        inputFiles.append(file)
                    }
                }
            }
        } else {
            print("SCRIPT_INPUT_FILE_COUNT not set.")
        }
    }
    
    func diff() -> [String] {
        var res: [String] = []
        res.append(contentsOf: inputFiles)
        if customScriptPath == nil { return res }
        if let customScriptPath = customScriptPath {
            let bash: CommandExecuting = Bash()
            let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"]
            if let diffOutput = try? bash.run(commandName: "python3", arguments: [customScriptPath, srcRoot == nil ? "" : srcRoot!]) {
                let files = diffOutput.replacingOccurrences(of: "\n", with: "").components(separatedBy: ",")
                res.append(contentsOf: files)
            }
        }
        return res
    }
    
}

protocol CommandExecuting {
    func run(commandName: String, arguments: [String]) throws -> String
}

enum BashError: Error {
    case commandNotFound(name: String)
}

struct Bash: CommandExecuting {
    func run(commandName: String, arguments: [String] = []) throws -> String {
        return try run(resolve(commandName), with: arguments)
    }

    private func resolve(_ command: String) throws -> String {
        guard var bashCommand = try? run("/bin/bash" , with: ["-l", "-c", "which \(command)"]) else {
            throw BashError.commandNotFound(name: command)
        }
        bashCommand = bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        return bashCommand
    }

    private func run(_ command: String, with arguments: [String] = []) throws -> String {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.launch()
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        return output
    }
}

