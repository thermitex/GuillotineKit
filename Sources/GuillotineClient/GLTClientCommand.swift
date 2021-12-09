//
//  GLTClientCommand.swift
//  
//
//  Created by bytedance on 2021/12/8.
//

import Foundation
import ArgumentParser

struct GLTClientCommand: ParsableCommand {
    
    @Flag(name: .long, help: "Disable service globally.") var disable = false
    @Flag(name: .long, help: "Enable service globally.") var enable = false
    @Flag(name: .long, help: "Clean database caches.") var clean = false
    
    @Option(name: .long, help:"A custom regular expression that defines what kind of files should be scanned. Defaults to .m files.") var customMatch: String?
    @Option(name: .long, help:"Scan a file apart from default files.") var scanFile: String?
    @Option(name: .long, help:"Scan files apart from default files, separated by \",\".") var scanFiles: String?
    
    @Flag(name: .customShort("0"), help: "Use loose scan level.") var useLooseMode = false
    @Flag(name: .customShort("1"), help: "Use normal scan level.") var useNormalMode = false
    @Flag(name: .customShort("2"), help: "Use strict scan level (could result in false positive results).") var useStrictMode = false
    @Flag(name: [.customShort("w"), .long], help: "Display warnings instead of errors.") var useWarning = false
    
    private func getScanLevel() -> Int {
        var scanLevel = 1
        if useLooseMode { scanLevel = 0 }
        if useNormalMode { scanLevel = 1 }
        if useStrictMode { scanLevel = 2 }
        return scanLevel
    }
    
    func run() throws {
        let client = GLTClient()
        if !client.isServiceReady() { return }
        
        // Service switches
        if disable {
            client.service!.disableService()
            return
        }
        if enable {
            client.service!.enableService()
            return
        }
        if clean {
            client.service!.cleanWorkspaces()
            return
        }
        
        if customMatch != nil { client.match = customMatch! }
        var indexPath: String? = nil
        
        // Check environment
        if let buildDir = ProcessInfo.processInfo.environment["BUILD_DIR"] {
            indexPath = buildDir.replacingOccurrences(of: "Build/Products", with: "Index/DataStore")
            var isDir:ObjCBool = true
            if !FileManager.default.fileExists(atPath: indexPath!, isDirectory: &isDir) {
                print("Index data store folder is missing.")
                return
            }
        } else {
            print("Please run gltc in a build phase script.")
            return
        }
        
        // Scanning process
        if let indexPath = indexPath {
            
            if let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
                if let diffRes = client.scanFiles(filePaths: DiffFilesCollector(srcRoot: srcRoot).diff(),
                                                  indexPath: indexPath,
                                                  scanLevel: getScanLevel(),
                                                  useWarning: useWarning) {
                    if diffRes != "" { print(diffRes) }
                }
            } else {
                print("SRCROOT not set.")
            }
            
            // Extra scan file
            if scanFile != nil {
                if let res = client.scanFile(filePath: scanFile!,
                                             indexPath: indexPath,
                                             scanLevel: getScanLevel(),
                                             useWarning: useWarning) {
                    if res != "" { print(res) }
                }
            }
            
            // Extra scan files
            if scanFiles != nil {
                if let res = client.scanFiles(filePaths: scanFiles!.components(separatedBy: ","),
                                              indexPath: indexPath,
                                              scanLevel: getScanLevel(),
                                              useWarning: useWarning) {
                    if res != "" { print(res) }
                }
            }
        }
        
    }
    
}
