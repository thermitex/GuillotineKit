//
//  DiffFilesCollector.swift
//  
//
//  Created by bytedance on 2021/12/9.
//

import Foundation

class DiffFilesCollector {
    
    private var srcRoot: String
    private var scanAllDiff: Bool
    
    init(srcRoot: String, scanAllDiff: Bool) {
        self.srcRoot = srcRoot
        self.scanAllDiff = scanAllDiff
    }
    
    func diff() -> [String] {
        var res: [String] = []
        if let diffScriptURL = Bundle.module.url(forResource: "diff", withExtension: "py") {
            let bash: CommandExecuting = Bash()
            if let diffOutput = try? bash.run(commandName: "python3", arguments: [diffScriptURL.path, srcRoot, scanAllDiff ? "scanall" : "-"]) {
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

