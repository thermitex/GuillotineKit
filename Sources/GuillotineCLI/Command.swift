//
//  Command.swift
//  
//
//  Created by bytedance on 2021/12/7.
//

import Foundation
import ArgumentParser
import GuillotineKit

struct GuillotineCmd: ParsableCommand {
    
    // Arguments
    @Argument(help: "The path to the raw index store data") var indexStorePath: String
    @Argument(help: "Scan path") var path: String
    
    @Option(name: .long, help: "Scan the files match the pattern (only works with --folder)") var match: String?
    @Option(name: .long, help: "Exclude the files match the pattern (only works with --folder)") var exclude: String?
    @Flag(name: .shortAndLong, help: "If the scan path is a folder") var folder = false
    @Flag(name: .shortAndLong, help: "Silent mode") var silent = false
    @Flag(name: .shortAndLong, help: "Should delete includes") var delete = false
    @Flag(name: .long, help: "Print debug logs") var debug = false
    
    func run() throws {
        if debug {
            GLTLogger.setLogLevel(level: .debug)
        }
        
        let workspace = try GLTWorkspace(indexStorePath: indexStorePath)
        
        var includes: [IncludeEntry]
        if folder {
            includes = workspace.scanFolder(folderPath: path,
                                            matching: match,
                                            excluding: exclude,
                                            scanLevel: .scanForAllRemovableIncludes,
                                            deleteUnusedIncludes: delete)
        } else {
            includes = workspace.scanFile(filePath: path,
                                          scanLevel: .scanForAllRemovableIncludes,
                                          deleteUnusedIncludes: delete)
        }
        
        if !silent {
            for include in includes {
                print(include.richWarningText)
            }
        }
    }
    
}
