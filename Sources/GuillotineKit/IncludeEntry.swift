//
//  IncludeEntry.swift
//  
//
//  Created by bytedance on 2021/12/3.
//

import Foundation
import IndexStoreDB

public struct IncludeEntry: Equatable {
    
    public var sourcePath: String
    public var targetPath: String
    public var line: Int
    
    public init(sourcePath: String, targetPath: String, line: Int) {
        self.sourcePath = sourcePath
        self.targetPath = targetPath
        self.line = line
    }
    
    /// Convert from an internal unit include entry
    init(_ unitIncludeEntry: IndexStoreDB.UnitIncludeEntry) {
        self.sourcePath = unitIncludeEntry.sourcePath
        self.targetPath = unitIncludeEntry.targetPath
        self.line = unitIncludeEntry.line
    }
    
}

extension IncludeEntry {
    
    public var targetFilename: String {
        let fileURL = URL(fileURLWithPath: targetPath)
        return fileURL.lastPathComponent
    }
    
    public var sourceFilename: String {
        let fileURL = URL(fileURLWithPath: sourcePath)
        return fileURL.lastPathComponent
    }
    
    public var richWarningText: String {
        return "⚠️ \(self.sourceFilename): The import for \"\(self.targetFilename)\" on line \(line) could be removed"
    }
    
    public var warningText: String {
        return "\(self.sourcePath):\(line): warning: The import for \"\(self.targetFilename)\" could be removed"
    }
    
    public var errorText: String {
        return "\(self.sourcePath):\(line): error: The import for \"\(self.targetFilename)\" could be removed"
    }
    
}

extension IncludeEntry: CustomStringConvertible {
    
    public var description: String {
        return "\(sourcePath):\(line) -> \(targetPath)"
    }
    
}
