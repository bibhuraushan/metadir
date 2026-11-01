//
//  MetadataDetailView.swift
//  MetaDir
//

import AppKit
import MetaDirCore
import SwiftUI

struct MetadataDetailView: View {
    let metadata: MetaDirMetadata
    let folderURL: URL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if !metadata.tags.isEmpty {
                    metadataCard { tags }
                }

                if !detailRows.isEmpty {
                    metadataCard { details }
                }

                if !metadata.links.isEmpty {
                    metadataCard { links }
                }

                if let notes = metadata.notes, !notes.isEmpty {
                    metadataCard(title: "Notes", systemImage: "note.text") {
                        Text(notes)
                            .textSelection(.enabled)
                            .lineSpacing(3)
                    }
                }

                if !metadata.custom.isEmpty {
                    metadataCard(title: "Custom Fields", systemImage: "slider.horizontal.3") {
                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                            ForEach(metadata.custom.keys.sorted(), id: \.self) { key in
                                GridRow {
                                    Text(key.capitalized)
                                        .foregroundStyle(.secondary)
                                    Text(metadata.custom[key, default: ""])
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                }

                HStack {
                    Button(action: revealMetadataFile) {
                        Label("Reveal YAML", systemImage: "magnifyingglass")
                    }
                    Button(action: copyFolderPath) {
                        Label("Copy Path", systemImage: "doc.on.doc")
                    }
                    Spacer()
                    Text(folderURL.path)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(folderURL.path)
                }
            }
            .padding(16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: "folder.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 58, height: 58)
                .background(.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(metadata.title)
                        .font(.largeTitle.weight(.semibold))
                        .textSelection(.enabled)
                    Spacer()
                    if let status = metadata.status, !status.isEmpty {
                        Text(status.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.tint)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.tint.opacity(0.12), in: Capsule())
                    }
                }

                if let summary = metadata.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(22)
        .background(
            LinearGradient(colors: [Color.accentColor.opacity(0.16), Color.purple.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.08)))
    }

    private var tags: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Tags", systemImage: "tag")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                ForEach(metadata.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.callout)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.tint.opacity(0.12), in: Capsule())
                    }
                }
            }
        }
        .accessibilityLabel("Tags: \(metadata.tags.joined(separator: ", "))")
    }

    @ViewBuilder
    private var details: some View {
        let rows = detailRows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Details", systemImage: "list.bullet.rectangle")
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    ForEach(rows, id: \.label) { row in
                        GridRow {
                            Text(row.label)
                                .foregroundStyle(.secondary)
                            Text(row.value)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    private var links: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Links", systemImage: "link")
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(metadata.links.enumerated()), id: \.offset) { _, link in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(link.label)
                                .font(.callout.weight(.medium))
                            Text(link.url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button {
                            copyLink(link.url)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .help("Copy this address without opening it")
                    }
                }
            }
        }
    }

    private var detailRows: [(label: String, value: String)] {
        [
            metadata.owner.map { ("Owner", $0) },
            metadata.status.map { ("Status", $0) },
            metadata.created.map { ("Created", $0) },
            metadata.updated.map { ("Updated", $0) },
            ("Schema Version", String(metadata.version))
        ].compactMap { $0 }
    }

    private func metadataCard<Content: View>(title: String? = nil, systemImage: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title, let systemImage {
                sectionHeader(title, systemImage: systemImage)
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.primary.opacity(0.07)))
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func revealMetadataFile() {
        let metadataURL = folderURL.appendingPathComponent(MetaDirConfiguration.metadataFilename)
        NSWorkspace.shared.activateFileViewerSelecting([metadataURL])
    }

    private func copyFolderPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(folderURL.path, forType: .string)
    }

    private func copyLink(_ link: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(link, forType: .string)
    }
}

struct MetadataErrorView: View {
    let message: String
    let folderURL: URL?
    let chooseFolder: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.orange)
                .frame(width: 76, height: 76)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text("Metadata Unavailable")
                .font(.title2.weight(.semibold))

            VStack(spacing: 8) {
                Text(message)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
                if let folderURL {
                    Text(folderURL.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }
            HStack(spacing: 10) {
                Button("Choose Another Folder…", action: chooseFolder)
                    .buttonStyle(.borderedProminent)
                if let folderURL {
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([folderURL])
                    }
                }
            }
        }
        .padding(30)
        .frame(maxWidth: 560)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.primary.opacity(0.08)))
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
