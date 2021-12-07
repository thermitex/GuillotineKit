//
//  Logger.swift
//  
//
//  Created by bytedance on 2021/12/5.
//

import Foundation
import Logging

public final class GLTLogger {
    
    private var logger: Logger
    private var timingDict: Dictionary<String, UInt64> = [:]
    
    private static var sharedLogger: GLTLogger = {
        let logger = GLTLogger()
        return logger
    }()
    
    private init() {
        logger = Logger(label: "GLTLogger")
    }
    
    class func shared() -> Logger {
        return sharedLogger.logger
    }
    
    /// Timing functions.
    public class func tick(key: String) {
        sharedLogger.timingDict[key] = DispatchTime.now().uptimeNanoseconds
    }
    
    public class func tock(key: String) {
        let endTime = DispatchTime.now().uptimeNanoseconds
        if let startTime = sharedLogger.timingDict[key] {
            let timeInterval = Double(endTime - startTime) / 1_000_000_000
            shared().debug("Time elapsed: \(timeInterval)s")
            sharedLogger.timingDict.removeValue(forKey: key)
        }
    }
    
    /// Set the log level of GuillotineKit.
    public class func setLogLevel(level: Logger.Level) {
        sharedLogger.logger.logLevel = level
    }
    
}
