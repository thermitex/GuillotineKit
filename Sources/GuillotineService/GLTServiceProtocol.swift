//
//  File.swift
//  
//
//  Created by bytedance on 2021/12/8.
//

import Foundation

@objc(GLTServiceProtocol)
protocol GLTServiceProtocol {
    
    func scanFile(filePath: String, indexPath: String, scanLevel: Int, useWarning: Bool, withReply reply: @escaping (String) -> Void)
    func scanFiles(filePaths: [String], indexPath: String, scanLevel: Int, useWarning: Bool, withReply reply: @escaping (String) -> Void)

    func disableService()
    func enableService()
    func cleanWorkspaces()
    
}
