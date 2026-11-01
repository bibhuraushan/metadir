//
//  ContentView.swift
//  MetaDir
//

import SwiftUI
import AppKit
import MetaDirCore

struct ContentView: View {
    @ObservedObject var viewModel: MetadataViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.badge.gearshape")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 1) {
                            Text("MetaDir")
                                .font(.headline)
                            Text("On-demand folder context")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Button(action: chooseFolder) {
                            Label("Choose Folder", systemImage: "folder.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.bar)

                    Divider()

                    if let metadata = viewModel.metadata, let selectedFolderURL = viewModel.selectedFolderURL {
                        MetadataDetailView(metadata: metadata, folderURL: selectedFolderURL)
                    } else if let errorMessage = viewModel.errorMessage {
                        MetadataErrorView(message: errorMessage, folderURL: viewModel.selectedFolderURL, chooseFolder: chooseFolder)
                    } else {
                        emptyState
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .frame(minWidth: 540, idealWidth: 540, maxWidth: 540, minHeight: 500, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "folder")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.tint)
                .frame(width: 88, height: 88)
                .background(.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 7) {
                Text("Open folder metadata")
                    .font(.title2.weight(.semibold))
                Text("Choose a folder containing .metadir.yml, or use Show in MetaDir from Finder.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 430)
            }

            Button(action: chooseFolder) {
                Label("Choose a Folder", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Show Metadata"

        guard panel.runModal() == .OK, let folderURL = panel.url else { return }
        viewModel.open(folderURL: folderURL)
    }
}


