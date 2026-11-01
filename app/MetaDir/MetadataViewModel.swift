//
//  MetadataViewModel.swift
//  MetaDir
//

import AppKit
import Combine
import Foundation
import MetaDirCore

@MainActor
final class MetadataViewModel: NSObject, ObservableObject {
    @Published private(set) var selectedFolderURL: URL?
    @Published private(set) var metadata: MetaDirMetadata?
    @Published private(set) var errorMessage: String?

    override init() {
        super.init()
    }

    func open(folderURL: URL, bookmarkData: Data? = nil) {
        selectedFolderURL = folderURL
        let scopedRoot = startAccessingRequestBookmark(bookmarkData) ?? startAccessingDirectly(folderURL) ?? startAccessingRoot(containing: folderURL)
        defer { scopedRoot?.stopAccessingSecurityScopedResource() }

        do {
            metadata = try MetaDirMetadataLoader().load(from: folderURL)
            errorMessage = nil
        } catch {
            metadata = nil
            errorMessage = error.localizedDescription
        }
    }

    private func startAccessingRequestBookmark(_ bookmarkData: Data?) -> URL? {
        guard let bookmarkData else { return nil }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &isStale),
              url.startAccessingSecurityScopedResource() else { return nil }
        return url
    }

    func open(requestURL: URL) {
        guard requestURL.isFileURL else {
            metadata = nil
            errorMessage = "MetaDir received an invalid folder request."
            return
        }
        open(folderURL: requestURL)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func startAccessingDirectly(_ folderURL: URL) -> URL? {
        folderURL.startAccessingSecurityScopedResource() ? folderURL : nil
    }

    private func startAccessingRoot(containing folderURL: URL) -> URL? {
        let defaults = UserDefaults(suiteName: MetaDirConfiguration.preferencesSuiteIdentifier) ?? .standard
        let bookmarks = defaults.array(forKey: MetaDirConfiguration.monitoredFolderBookmarksKey) as? [Data] ?? []

        for bookmark in bookmarks {
            var isStale = false
            guard let rootURL = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &isStale),
                  MonitoredRootRules.contains(rootURL, folderURL),
                  rootURL.startAccessingSecurityScopedResource() else { continue }
            return rootURL
        }
        return nil
    }
}
