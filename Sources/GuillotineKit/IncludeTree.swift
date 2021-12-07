//
//  IncludeTree.swift
//  
//
//  Created by bytedance on 2021/12/3.
//

import Foundation

// MARK: - Include Node

class IncludeNode {
    var includeEntry: IncludeEntry
    
    var including: [IncludeNode] = []
    weak var includedBy: IncludeNode?
    
    var used: Bool = false
    
    init(includeEntry entry: IncludeEntry) {
        self.includeEntry = entry
    }
    
    /// Add an including child to this node.
    func addIncluding(child: IncludeNode) {
        including.append(child)
        child.includedBy = self
    }
}

extension IncludeNode: Equatable {
    static func == (lhs: IncludeNode, rhs: IncludeNode) -> Bool {
        return lhs.includeEntry == rhs.includeEntry
    }
}


// MARK: - Include Tree

class IncludeTree {
    
    /// Root of the tree.
    var root: IncludeNode
    
    /// Nodes with the same target path and remain unused at the time of search are considered as a batch of candidates.
    var candidateBatches: [[IncludeNode]] = []
    
    /// Nodes in BFS sequence.
    private var allNodes: [IncludeNode] = []
    /// Nodes that cannot connect to the tree.
    private var discreteNodes: [IncludeNode] = []
    /// A hashtable for targetPath -> IncludeNodes, used for efficient search.
    private var nodeSearchTable: [String: [IncludeNode]] = [:]
    /// Current leaf nodes, they should be searched first to speed up construction.
    private var unresolvedNodes: [IncludeNode] = []
    
    init(filePath: String) {
        let dummyIncludeEntry = IncludeEntry(sourcePath: filePath, targetPath: filePath, line: 0)
        root = IncludeNode(includeEntry: dummyIncludeEntry)
        unresolvedNodes.append(self.root)
        allNodes.append(self.root)
    }
    
    func addToIncludeTree(includeEntry entry: IncludeEntry) {
        let newNode = IncludeNode(includeEntry: entry)
        for node in unresolvedNodes {
            if node.includeEntry.targetPath == entry.sourcePath {
                node.addIncluding(child: newNode)
                addToNodeSearchTable(newNode)
                unresolvedNodes = unresolvedNodes.filter {
                    $0.includeEntry != node.includedBy?.includedBy?.includeEntry
                }
                unresolvedNodes.append(newNode)
                allNodes.append(newNode)
                return
            }
        }
        if allNodesSearchAndAdd(newNode) { return }
        discreteNodes.append(newNode)
    }
    
    private func addToNodeSearchTable(_ node:IncludeNode) {
        var nodeList = nodeSearchTable[node.includeEntry.targetPath]
        if nodeList != nil {
            nodeList!.append(node)
            nodeSearchTable[node.includeEntry.targetPath] = nodeList
        } else {
            nodeSearchTable[node.includeEntry.targetPath] = [node];
        }
    }
    
    func searchNodes(forIncludePath path: String?) -> [IncludeNode]? {
        guard let path = path else { return nil }
        return nodeSearchTable[path]
    }
    
    private func allNodesSearchAndAdd(_ newNode: IncludeNode) -> Bool {
        var addToNode: IncludeNode?
        for node in allNodes {
            if node.includeEntry == newNode.includeEntry {
                return true
            } else if node.includeEntry.sourcePath == newNode.includeEntry.sourcePath &&
                        node.includeEntry.targetPath != newNode.includeEntry.targetPath {
                addToNode = node
            }
        }
        if let addToNode = addToNode {
            addToNode.addIncluding(child: newNode)
            addToNodeSearchTable(newNode)
            allNodes.append(newNode)
            return true
        }
        return false
    }
    
    func retryConnectDiscreteNodes() {
        unresolvedNodes.removeAll()
        var discreteCount = discreteNodes.count
        while discreteCount > 0 {
            for (i, _) in discreteNodes.enumerated().reversed() {
                if (allNodesSearchAndAdd(discreteNodes[i])) {
                    discreteNodes.remove(at: i)
                }
            }
            if discreteCount == discreteNodes.count { return }
            discreteCount = discreteNodes.count
        }
    }
    
    func traceRootInclude(fromNode node: IncludeNode) -> IncludeNode {
        var currNode = node
        while currNode.includedBy?.includedBy != nil {
            currNode = currNode.includedBy!
        }
        return currNode
    }
    
}


// MARK: - Unused includes

extension IncludeTree {
    
    func markIncludeSubtreeUsed(rootNode root: IncludeNode) {
        if root.used { return }
        root.used = true
        for node in root.including {
            markIncludeSubtreeUsed(rootNode: node)
        }
    }
    
    func unusedRootIncludes() -> [IncludeEntry] {
        var unused: [IncludeEntry] = []
        for rootInclude in root.including {
            if !rootInclude.used {
                unused.append(rootInclude.includeEntry)
            }
        }
        return unused
    }
    
    func checkCandidates() {
        for (i, _) in candidateBatches.enumerated().reversed() {
            let candidates = candidateBatches[i]
            for candidate in candidates {
                if candidate.used {
                    candidateBatches.remove(at: i)
                    break
                }
            }
        }
    }
    
    func findUsedNode(includePath path: String) -> IncludeNode? {
        checkCandidates()
        var candidates: [IncludeNode] = [];
        if let nodes = searchNodes(forIncludePath: path) {
            for node in nodes {
                if node.used { return nil }
                candidates.append(node)
            }
        }
        if (candidates.count == 0) {
            return nil
        } else if (candidates.count == 1) {
            return candidates[0]
        } else {
            candidateBatches.append(candidates)
            return nil
        }
    }
    
    func traceSingleRootInclude(includePath path: String) -> IncludeNode? {
        if let node = findUsedNode(includePath: path) {
            return traceRootInclude(fromNode: node)
        }
        return nil
    }
    
    func traceAllIncludedByRootIncludes(includePath path: String) -> [IncludeNode] {
        var res: [IncludeNode] = []
        guard let nodes = searchNodes(forIncludePath: path) else { return res }
        for node in nodes {
            let rootInclude = traceRootInclude(fromNode: node)
            if !res.contains(rootInclude) {
                res.append(rootInclude)
            }
        }
        return res
    }
     
}
