//
//  SettingsView.swift
//  MetaDir
//

import AppKit
import SwiftUI

struct SettingsView: View {
    @StateObject private var store = MonitoredFolderStore()
    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Monitored Folders")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Finder Sync will offer MetaDir within these folder trees. Folder contents are not scanned.")
                    .foregroundStyle(.secondary)
            }

            List(store.folders, selection: $selection) { folder in
                HStack(spacing: 12) {
                    Image(systemName: "folder")
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(folder.displayName)
                        Text(folder.url.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .tag(folder.id)
            }
            .overlay {
                if store.folders.isEmpty {
                    ContentUnavailableView("No Monitored Folders", systemImage: "folder.badge.plus", description: Text("Add a folder to prepare it for Finder integration."))
                }
            }

            HStack {
                Button("Add Folder…", action: chooseFolder)
                Button("Remove") {
                    guard let selection else { return }
                    store.remove(id: selection)
                    self.selection = nil
                }
                .disabled(selection == nil)
                Spacer()
                if let statusMessage = store.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 420)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Add Monitored Folder"
        guard panel.runModal() == .OK, let folderURL = panel.url else { return }
        store.add(folderURL)
    }
}
