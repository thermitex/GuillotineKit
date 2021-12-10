//
//  File.swift
//  
//
//  Created by bytedance on 2021/12/8.
//

import Foundation
import GuillotineKit

@objc
class GLTService: NSObject, GLTServiceProtocol {
    
    private var workspaceDict: [String: GLTWorkspace] = [:]
    private static var enabled: Bool = true
    
    private func getWorkspace(_ indexPath: String, _ reply: @escaping (String) -> Void) -> GLTWorkspace? {
        if let workspace = workspaceDict[indexPath] {
            return workspace
        } else {
            do {
                let workspace = try GLTWorkspace(indexStorePath: indexPath)
                workspaceDict[indexPath] = workspace
                return workspace
            } catch {
                reply("Error initing workspace: \(error)")
                return nil
            }
        }
    }
    
    private func prepareForScan(_ indexPath: String, _ reply: @escaping (String) -> Void) -> GLTWorkspace? {
        if !GLTService.enabled {
            reply("The service has been disabled. Enable it by executing `gltc --enable`.")
            return nil
        }
        let workspace = getWorkspace(indexPath, reply)
        guard let workspace = workspace else {
            reply("Failed setting up workspace")
            return nil
        }
        workspace.pollForDBChanges()
        return workspace
    }
    
    private func convertScanLevel(_ intLevel: Int) -> ScanLevel {
        switch intLevel {
        case 0:
            return .scanForCompletelyUnusedIncludes
        case 1:
            return .scanForAllRemovableIncludes
        case 2:
            return .scanSymbolsInCurrentFileOnly
        default:
            return .scanForAllRemovableIncludes
        }
    }
    
    func scanFile(filePath: String, indexPath: String, scanLevel: Int, useWarning: Bool, withReply reply: @escaping (String) -> Void) {
        let workspace = prepareForScan(indexPath, reply)
        if workspace == nil { return }
        let includeWarnings = workspace!.scanFile(filePath: filePath, scanLevel: convertScanLevel(scanLevel)).map {
            useWarning ? $0.warningText : $0.errorText
        }
        reply(includeWarnings.joined(separator: "\n"))
    }
    
    func scanFiles(filePaths: [String], indexPath: String, scanLevel: Int, useWarning: Bool, withReply reply: @escaping (String) -> Void) {
        let workspace = prepareForScan(indexPath, reply)
        if workspace == nil { return }
        let includeWarnings = workspace!.scanFiles(filePaths: filePaths, scanLevel: convertScanLevel(scanLevel)).map {
            useWarning ? $0.warningText : $0.errorText
        }
        reply(includeWarnings.joined(separator: "\n"))
    }
    
    func disableService() {
        GLTService.enabled = false
    }
    
    func enableService() {
        GLTService.enabled = true
    }
}
