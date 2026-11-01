//
//  MonitoredRootRules.swift
//  MetaDirCore
//

import Foundation

/// Path rules used when managing Finder Sync roots.
public enum MonitoredRootRules {
    /// Returns a standardized local file URL.
    public static func normalized(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }

    /// Returns whether `ancestor` contains `descendant` or is the same folder.
    public static func contains(_ ancestor: URL, _ descendant: URL) -> Bool {
        let ancestorComponents = normalized(ancestor).pathComponents
        let descendantComponents = normalized(descendant).pathComponents
        guard ancestorComponents.count <= descendantComponents.count else { return false }
        return Array(descendantComponents.prefix(ancestorComponents.count)) == ancestorComponents
    }
}
