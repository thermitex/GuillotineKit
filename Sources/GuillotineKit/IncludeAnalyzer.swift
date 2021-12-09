//
//  IncludeAnalyzer.swift
//  
//
//  Created by bytedance on 2021/12/3.
//

import Foundation
import IndexStoreDB

class IncludeAnalyzer {
    
    private let db: IndexStoreDB
    private let indexPath: String
    private let scanLevel: ScanLevel
    private let filePath: String
    private let fileContent: String?
    
    /// Cache
    private var singleFileVisitedCache: [String] = []
    private var singleFileFullSearchSymbolUSRCache: [String] = []
    private var singleFileContSearchSymbolUSRCache: [String] = []
    
    init(
        database: IndexStoreDB,
        indexPath: String,
        filePath: String,
        scanLevel: ScanLevel
    ) {
        db = database
        self.scanLevel = scanLevel
        self.filePath = filePath
        self.indexPath = indexPath
        do {
            fileContent = try String(contentsOf: URL(fileURLWithPath: filePath), encoding: .utf8)
        } catch {
            fileContent = nil
        }
    }
    
    private func unitModificationDate(unitName: String) -> Date? {
        let fullPath = indexPath + "/v5/units/" + unitName
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: fullPath)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    /// Construct an include tree for a file.
    private func constructIncludeTree(forFile filePath: String) -> IncludeTree {
        let includeTree = IncludeTree(filePath: filePath)
        var latestUnitName: String? = nil
        var latestDate: Date? = nil
        db.forEachUnitNameContainingFile(path: filePath) { unitName in
            let date = self.unitModificationDate(unitName: unitName)
            if latestUnitName == nil {
                latestUnitName = unitName
            }
            if latestDate == nil {
                latestDate = date
            } else {
                guard let date = date else { return true }
                if date > latestDate! {
                    latestDate = date
                    latestUnitName = unitName
                }
            }
            return true
        }
        guard let latestUnitName = latestUnitName else {
            return includeTree
        }
        self.db.includesOfUnit(unitName: latestUnitName).forEach { include in
            includeTree.addToIncludeTree(includeEntry: IncludeEntry(include))
        }
        includeTree.retryConnectDiscreteNodes()
        return includeTree
    }
    
    /// Get all symbols in a file.
    private func getAllSymbols(forFile filePath: String) -> [Symbol] {
        db.symbols(inFilePath: filePath)
    }
    
    private func getExtraSymbolNames(forFile filePath: String, _ pattern: String, _ procedure: (String) -> String) -> [String] {
        guard let fileContent = fileContent else { return [] }
        let matches = fileContent.checkMatches(for: pattern)
        return matches.map { procedure($0) };
    }

}

// MARK: - Find unused include & utilities

extension IncludeAnalyzer {
    
    /// Check if the extension conforms to a protocol that may be referenced somewhere related to the scanned file.
    private func shouldCalculateExtendOccurrence(_ occurrence: SymbolOccurrence) -> Bool {
        if scanLevel == .scanWithoutCheckingExtends || scanLevel > .scanWithoutCheckingContains { return false }
        var isExtendValid = false
        if occurrence.roles.contains(.extendedBy) {
            for extendRelation in occurrence.relations {
                db.forEachRelatedSymbolOccurrence(byUSR: extendRelation.symbol.usr, roles: .baseOf) { _ in
                    isExtendValid = true
                    return false
                }
                if isExtendValid { break }
            }
        } else {
            return true
        }
        return isExtendValid
    }
    
    
    /// Check the symbols inside the declaration occurrence, mainly for return values.
    /// Where these symbols are declared will also be considered used because there may be an inheritance declaration.
    private func checkSymbolsInDeclOccurrence(_ occurrence: SymbolOccurrence, _ includeTree: IncludeTree) {
        if scanLevel >= .scanWithoutCheckingContains { return }
        if !occurrence.roles.contains(.declaration) {
            return
        }
        db.forEachRelatedSymbolOccurrence(byUSR: occurrence.symbol.usr, roles: .containedBy) { occurrence in
            let symbol = occurrence.symbol
            if self.singleFileFullSearchSymbolUSRCache.contains(symbol.usr)
                || self.singleFileContSearchSymbolUSRCache.contains(symbol.usr) { return true }
            
            // Contained methods should not be counted
            if occurrence.symbol.kind == .instanceMethod ||
                occurrence.symbol.kind == .classMethod ||
                occurrence.symbol.kind == .staticMethod {
                return true
            }
            
            self.db.forEachSymbolOccurrence(byUSR: symbol.usr, roles: [.declaration, .extendedBy]) { occurrence in
                if !self.shouldCalculateExtendOccurrence(occurrence) {
                    return true
                }
                self.markIncludePathUsed(includeTree, occurrence.location.path)
                return true
            }
            
            self.singleFileContSearchSymbolUSRCache.append(symbol.usr)
            return true
        }
    }
    
    private func markIncludePathUsed(_ includeTree: IncludeTree, _ path: String) {
        if path == filePath || singleFileVisitedCache.contains(path) {
            return
        }
        // Get root include nodes
        var rootIncludeNodes: [IncludeNode] = []
        if scanLevel == .scanForCompletelyUnusedIncludes {
            rootIncludeNodes = includeTree.traceAllIncludedByRootIncludes(includePath: path)
        } else {
            if let rootIncludeNode = includeTree.traceSingleRootInclude(includePath: path) {
                rootIncludeNodes = [rootIncludeNode]
            }
        }
        // Mark the root include and its subtree as used
        for rootIncludeNode in rootIncludeNodes {
            includeTree.markIncludeSubtreeUsed(rootNode: rootIncludeNode)
        }
        singleFileVisitedCache.append(path)
    }
    
    /// Find unused root include entries.
    func findUnusedInclude() -> [IncludeEntry] {
        // Construct include tree and obtain symbols
        let includeTree = constructIncludeTree(forFile: filePath)
        let symbols = getAllSymbols(forFile: filePath)
        let extraSymbols = getExtraSymbolNames(forFile: filePath, "@selector\\(.*\\)") { rawName in
            return rawName.slice(from: "(", to: ")")!
        }
        
        for symbol in symbols {
            // Find decl and canon of each symbol
            if singleFileFullSearchSymbolUSRCache.contains(symbol.usr) { continue }
            db.forEachSymbolOccurrence(byUSR: symbol.usr, roles: [.declaration, .canonical, .extendedBy]) { occurrence in
                if !self.shouldCalculateExtendOccurrence(occurrence) {
                    return true
                }
                self.checkSymbolsInDeclOccurrence(occurrence, includeTree)
                self.markIncludePathUsed(includeTree, occurrence.location.path)
                return true
            }
            singleFileFullSearchSymbolUSRCache.append(symbol.usr)
        }
        
        // Check symbols not counted in index-db
        for extraSymbol in extraSymbols {
            db.forEachCanonicalSymbolOccurrence(byName: extraSymbol) { occurrence in
                if self.singleFileFullSearchSymbolUSRCache.contains(occurrence.symbol.usr) { return true }
                self.markIncludePathUsed(includeTree, occurrence.location.path)
                self.singleFileFullSearchSymbolUSRCache.append(occurrence.symbol.usr)
                return true
            }
        }
        
        includeTree.checkCandidates()
        // For remaining candidate batches, choose the first node in the batch
        for candidateBatch in includeTree.candidateBatches {
            let rootIncludeNode = includeTree.traceRootInclude(fromNode: candidateBatch[0])
            includeTree.markIncludeSubtreeUsed(rootNode: rootIncludeNode)
        }
        
        // Filter unused root includes
        return includeTree.unusedRootIncludes()
    }
    
}


// MARK: - Utilities

extension String {
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    func checkMatches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            GLTLogger.shared().error("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
}
