//
//  GLTClient.swift
//  
//
//  Created by bytedance on 2021/12/8.
//

import Foundation

class GLTClient {
    
    private var connection: NSXPCConnection
    
    var match: String = ".*\\.m"
    var service: GLTServiceProtocol?
    
    init() {
        connection = NSXPCConnection(machServiceName: "com.bytedance.GuillotineService")
        connection.remoteObjectInterface = NSXPCInterface(with: GLTServiceProtocol.self)
        connection.resume()

        service = connection.remoteObjectProxyWithErrorHandler { error in
            print("Received error: ", error)
        } as? GLTServiceProtocol
    }
    
    func isServiceReady() -> Bool {
        return service != nil
    }
    
    private func filter(_ files: [String]) -> [String] {
        var filtered: [String] = []
        for file in files {
            if file.range(of: match, options: .regularExpression) != nil {
                filtered.append(file)
            }
        }
        return filtered
    }
    
    func scanFile(filePath: String, indexPath: String, scanLevel: Int, useWarning: Bool) -> String? {
        print("Scanning file \(filePath)...")
        var res: String? = nil
        let group = DispatchGroup()
        group.enter()
        service!.scanFile(filePath: filePath,
                          indexPath: indexPath,
                          scanLevel: scanLevel,
                          useWarning: useWarning) { response in
            res = response
            group.leave()
        }
        group.wait()
        return res
    }
    
    func scanFiles(filePaths: [String], indexPath: String, scanLevel: Int, useWarning: Bool) -> String? {
        let filteredFilePaths = filter(filePaths)
        if filteredFilePaths.isEmpty {
            return nil
        }
        print("Scanning files \(filteredFilePaths.joined(separator: ", "))...")
        var res: String? = nil
        let group = DispatchGroup()
        group.enter()
        service!.scanFiles(filePaths: filteredFilePaths,
                           indexPath: indexPath,
                           scanLevel: scanLevel,
                           useWarning: useWarning) { response in
            res = response
            group.leave()
        }
        group.wait()
        return res
    }
    
}
