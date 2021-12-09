//
//  main.swift
//  
//
//  Created by bytedance on 2021/12/8.
//

import Foundation

// Configure XPC
let delegate = GLTServiceDelegate()
let listener = NSXPCListener(machServiceName: "com.bytedance.GuillotineService")
listener.delegate = delegate
listener.resume()

// Run
RunLoop.main.run()
