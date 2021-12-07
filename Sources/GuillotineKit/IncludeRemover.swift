//
//  IncludeRemover.swift
//  
//
//  Created by bytedance on 2021/12/3.
//

import Foundation

class IncludeRemover {
    
    var file: URL?
    var entries: [IncludeEntry]
    
    init(filePath: String, unusedEntries entries: [IncludeEntry]) {
        file = URL(fileURLWithPath: filePath)
        self.entries = entries.sorted { $0.line > $1.line }
    }
    
    func executeDeletion() {
        guard let file = file else {
            return
        }

        do {
            var content = try String(contentsOf: file, encoding: .utf8)
            var contentLines = content.components(separatedBy: "\n")
            for entry in entries {
                let line = entry.line
                if line <= contentLines.count && line > 0 &&
                    contentLines[line - 1].contains(entry.targetFilename) {
                    contentLines.remove(at: line - 1)
                }
            }
            content = contentLines.joined(separator: "\n")
            do {
                try content.write(to: file, atomically: false, encoding: .utf8)
            } catch {
                GLTLogger.shared().error("\(error)", metadata: ["filePath": "\(file.path)"])
            }
        } catch {
            GLTLogger.shared().error("\(error)", metadata: ["filePath": "\(file.path)"])
        }
    }
    
    func asyncExecuteDeletion() {
        DispatchQueue.global(qos: .default).async {
            self.executeDeletion()
        }
    }
    
}
