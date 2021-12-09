//
//  File.swift
//  
//
//  Created by bytedance on 2021/12/8.
//

import Foundation

class GLTServiceDelegate : NSObject, NSXPCListenerDelegate {
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        let exportedObject = GLTService()
        newConnection.exportedInterface = NSXPCInterface(with: GLTServiceProtocol.self)
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
    
}
