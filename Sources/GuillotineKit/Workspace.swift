//
//  Workspace.swift
//  
//
//  Created by bytedance on 2021/12/2.
//

import Foundation
import IndexStoreDB

public enum ScanLevel: Hashable, Comparable {
    /// In this scan level, an include is marked as unused when no references to it is found.
    case scanForCompletelyUnusedIncludes
    /// In this scan level, an include is marked as unused when removing it won't cause compilation to fail.
    case scanForAllRemovableIncludes

    /// More aggressive options, may find out more unused includes but could result in build failure.
    /// These options will check the file faster than the stable options.
    case scanWithoutCheckingExtends
    case scanWithoutCheckingContains
    case scanSymbolsInCurrentFileOnly
}

public final class GLTWorkspace {
    
    private let db: IndexStoreDB
    private var logger = GLTLogger.shared()

    public init(
        indexStorePath storePath: String,
        libraryPath libPath: String = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib",
        listenToUnitEvents: Bool = false
    ) throws {
        let lib = try IndexStoreLibrary(dylibPath: libPath)
        let dbPath = NSTemporaryDirectory() + "index_\(getpid())"
        self.db = try IndexStoreDB(
            storePath: URL(fileURLWithPath: storePath).path,
            databasePath: dbPath,
            library: lib,
            listenToUnitEvents: listenToUnitEvents)
        logger.debug("Intializing database at \(dbPath)")
        
        db.pollForUnitChangesAndWait()
    }
    
    /// Manually poll for database changes, mandatory to poll changes if `listenToUnitEvents` is set to `false`.
    public func pollForDBChanges() {
        db.pollForUnitChangesAndWait()
    }
    
    /// Scan a single file for unused include entries.
    ///
    /// - Parameters:
    ///   - filePath: The path to the file to be scanned.
    ///   - scanLevel: The scan level to use, defaults to `scanForAllRemovableIncludes`.
    ///   - deleteUnusedIncludes: If the unused includes should be deleted in the file. This action cannot be undone.
    ///
    /// - returns: An array of unused `includeEntry`
    @discardableResult
    public func scanFile(
        filePath: String,
        scanLevel: ScanLevel = .scanForAllRemovableIncludes,
        deleteUnusedIncludes: Bool = false
    ) -> [IncludeEntry] {
        logger.debug("Scanning file \(filePath)")
        let res = IncludeAnalyzer(database: db, filePath: filePath, scanLevel: scanLevel).findUnusedInclude()
        if deleteUnusedIncludes {
            IncludeRemover(filePath: filePath, unusedEntries: res).asyncExecuteDeletion()
        }
        return res
    }
    
    /// Scan an array of files for unused include entries.
    @discardableResult
    public func scanFiles(
        filePaths: [String],
        scanLevel: ScanLevel = .scanForAllRemovableIncludes,
        deleteUnusedIncludes: Bool = false
    ) -> [IncludeEntry] {
        let group = DispatchGroup()
        var res: [IncludeEntry] = []
        for filePath in filePaths {
            group.enter()
            DispatchQueue.global(qos: .default).async {
                let fileRes = self.scanFile(filePath: filePath, scanLevel: scanLevel, deleteUnusedIncludes: deleteUnusedIncludes)
                res.append(contentsOf: fileRes)
                group.leave()
            }
        }
        group.wait()
        return res
    }
    
    private func filesToScanInFolder(
        folderPath: String,
        matching: String? = nil,
        excluding: String? = nil
    ) -> [String] {
        var filesToScan: [String] = []
        let url = URL(fileURLWithPath: folderPath)
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    // Apply filters
                    let isIncluded = matching == nil ? true : fileURL.path.range(of: matching!, options: .regularExpression) != nil
                    let isExcluded = excluding == nil ? false : fileURL.path.range(of: excluding!, options: .regularExpression) != nil
                    if fileAttributes.isRegularFile! && isIncluded && !isExcluded {
                        filesToScan.append(fileURL.path)
                    }
                } catch {
                    logger.error("\(error)")
                }
            }
        }
        return filesToScan
    }
    
    /// Scan a single file for unused include entries.
    ///
    /// - Parameters:
    ///   - folderPath: The path to the folder to be scanned.
    ///   - matching: A regular expression, will only scan the file matches the regexp. Defaults to `nil` (all files should be included)
    ///   - excluding: A regular expression, will skip the file matches the regexp. Defaults to `nil` (no file should be excluded). Takes higher precdence than `matching`.
    ///   - scanLevel: The scan level to use, defaults to `scanForAllRemovableIncludes`.
    ///   - deleteUnusedIncludes: If the unused includes should be deleted in the file. This action cannot be undone.
    ///
    /// - returns: An array of unused `includeEntry`
    @discardableResult
    public func scanFolder(
        folderPath: String,
        matching: String? = nil,
        excluding: String? = nil,
        scanLevel: ScanLevel = .scanForAllRemovableIncludes,
        deleteUnusedIncludes: Bool = false
    ) -> [IncludeEntry] {
        GLTLogger.tick(key: folderPath)
        let filesToScan = filesToScanInFolder(folderPath: folderPath, matching: matching, excluding: excluding)
        let res = scanFiles(filePaths: filesToScan, scanLevel: scanLevel, deleteUnusedIncludes: deleteUnusedIncludes)
        GLTLogger.tock(key: folderPath)
        return res
    }
    
}
