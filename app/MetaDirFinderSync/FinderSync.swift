//
//  FinderSync.swift
//  MetaDirFinderSync
//

import Cocoa
import FinderSync
import MetaDirCore
import OSLog

final class FinderSync: FIFinderSync {
    private let controller = FIFinderSyncController.default()
    private let logger = Logger(subsystem: "com.example.MetaDir.FinderSync", category: "FinderSync")
    private var contextualFolderURL: URL?

    override init() {
        super.init()
        reloadMonitoredRoots()
        logger.notice("MetaDir Finder Sync initialized")
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(monitoredRootsDidChange), name: MetaDirConfiguration.monitoredRootsDidChangeNotification, object: nil)
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "MetaDir")
        guard let folderURL = selectedFolderURL(for: menuKind) else {
            logger.notice("Menu requested without one selected folder; kind=\(menuKind.rawValue)")
            return menu
        }
        logger.notice("Providing MetaDir menu for a selected folder")
        contextualFolderURL = folderURL
        let item = menu.addItem(withTitle: "Show in MetaDir", action: #selector(showMetadata(_:)), keyEquivalent: "")
        item.target = self
        return menu
    }

    override func beginObservingDirectory(at url: URL) {
        logger.notice("Finder began observing a configured directory")
    }

    override func endObservingDirectory(at url: URL) {
        logger.notice("Finder stopped observing a configured directory")
    }

    @objc private func showMetadata(_ sender: NSMenuItem) {
        guard let folderURL = contextualFolderURL else {
            logger.error("Could not create a metadata request for the Finder selection")
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([folderURL], withApplicationAt: containingAppURL, configuration: configuration) { _, error in
            if let error {
                self.logger.error("Could not open MetaDir: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    @objc private func monitoredRootsDidChange() {
        reloadMonitoredRoots()
    }

    private func reloadMonitoredRoots() {
        controller.directoryURLs = GeneratedLocalRoots.urls
        logger.notice("Registered \(self.controller.directoryURLs?.count ?? 0) Finder root(s)")
    }

    private func selectedFolderURL(for menuKind: FIMenuKind) -> URL? {
        let candidate: URL?
        switch menuKind {
        case .contextualMenuForItems:
            let selectedURLs = controller.selectedItemURLs() ?? []
            candidate = selectedURLs.count == 1 ? selectedURLs.first : nil
        case .contextualMenuForContainer, .contextualMenuForSidebar:
            candidate = controller.targetedURL()
        default:
            candidate = nil
        }

        guard let candidate, (try? candidate.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return nil }
        return candidate
    }

    private var containingAppURL: URL {
        Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
