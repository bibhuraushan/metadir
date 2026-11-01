//
//  MonitoredFolderStore.swift
//  MetaDir
//

import Combine
import Foundation
import MetaDirCore

@MainActor
final class MonitoredFolderStore: ObservableObject {
    @Published private(set) var folders: [MonitoredFolder] = []
    @Published private(set) var statusMessage: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        let sharedDefaults = defaults ?? UserDefaults(suiteName: MetaDirConfiguration.preferencesSuiteIdentifier) ?? .standard
        if sharedDefaults.array(forKey: MetaDirConfiguration.monitoredFolderBookmarksKey) == nil,
           let existingBookmarks = UserDefaults.standard.array(forKey: MetaDirConfiguration.monitoredFolderBookmarksKey) {
            sharedDefaults.set(existingBookmarks, forKey: MetaDirConfiguration.monitoredFolderBookmarksKey)
        }
        self.defaults = sharedDefaults
        restoreBookmarks()
    }

    func add(_ folderURL: URL) {
        let normalizedURL = MonitoredRootRules.normalized(folderURL)
        if folders.contains(where: { MonitoredRootRules.contains($0.url, normalizedURL) }) {
            statusMessage = "That folder is already covered by a monitored root."
            return
        }

        do {
            let bookmark = try normalizedURL.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
            folders.removeAll(where: { MonitoredRootRules.contains(normalizedURL, $0.url) })
            folders.append(MonitoredFolder(url: normalizedURL, bookmark: bookmark))
            folders.sort { $0.url.path.localizedStandardCompare($1.url.path) == .orderedAscending }
            persistBookmarks()
            statusMessage = "Monitored root saved."
        } catch {
            statusMessage = "Could not save access to that folder: \(error.localizedDescription)"
        }
    }

    func remove(id: String) {
        folders.removeAll { $0.id == id }
        persistBookmarks()
        statusMessage = "Monitored root removed. No folder contents were changed."
    }

    private func restoreBookmarks() {
        let storedBookmarks = defaults.array(forKey: MetaDirConfiguration.monitoredFolderBookmarksKey) as? [Data] ?? []
        var validFolders: [MonitoredFolder] = []
        var refreshedBookmarks: [Data] = []

        for bookmark in storedBookmarks {
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &isStale) else { continue }
            let normalizedURL = MonitoredRootRules.normalized(url)
            let restoredBookmark: Data
            if isStale {
                guard let refreshed = try? normalizedURL.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil) else { continue }
                restoredBookmark = refreshed
            } else {
                restoredBookmark = bookmark
            }
            validFolders.append(MonitoredFolder(url: normalizedURL, bookmark: restoredBookmark))
            refreshedBookmarks.append(restoredBookmark)
        }

        folders = validFolders.sorted { $0.url.path.localizedStandardCompare($1.url.path) == .orderedAscending }
        if refreshedBookmarks.count != storedBookmarks.count || zip(refreshedBookmarks, storedBookmarks).contains(where: { pair in pair.0 != pair.1 }) {
            defaults.set(refreshedBookmarks, forKey: MetaDirConfiguration.monitoredFolderBookmarksKey)
        }
    }

    private func persistBookmarks() {
        defaults.set(folders.map(\.bookmark), forKey: MetaDirConfiguration.monitoredFolderBookmarksKey)
        DistributedNotificationCenter.default().post(name: MetaDirConfiguration.monitoredRootsDidChangeNotification, object: nil)
    }
}

struct MonitoredFolder: Identifiable, Equatable {
    let url: URL
    let bookmark: Data

    var id: String { url.path }
    var displayName: String { url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent }
}
