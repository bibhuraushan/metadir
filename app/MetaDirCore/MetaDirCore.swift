//
//  MetaDirCore.swift
//  MetaDirCore
//

import Foundation

/// Shared constants used by the MetaDir app and extensions.
public enum MetaDirConfiguration {
    /// The shared application group identifier.
    public static let appGroupIdentifier = "group.com.example.MetaDir"

    /// The metadata filename expected inside a folder.
    public static let metadataFilename = ".metadir.yml"

    /// Preferences domain used for monitored-folder bookmarks.
    public static let preferencesSuiteIdentifier = "com.example.MetaDir"

    /// Notification sent after the monitored-root list changes.
    public static let monitoredRootsDidChangeNotification = Notification.Name("com.example.MetaDir.monitoredRootsDidChange")

    /// Key containing security-scoped bookmarks for monitored roots.
    public static let monitoredFolderBookmarksKey = "monitoredFolderBookmarks"
}
