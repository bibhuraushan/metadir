//
//  MetaDirCoreTests.swift
//  MetaDirTests
//

import Testing
import Foundation

struct MetaDirCoreTests {
    @Test func metadataFilenameIsStable() {
        #expect(MetaDirConfiguration.metadataFilename == ".metadir.yml")
        #expect(MetaDirConfiguration.monitoredFolderBookmarksKey == "monitoredFolderBookmarks")
    }

    @Test func loadsValidMetadata() throws {
        let fixture = try FixtureFolder(yaml: """
        version: 1
        title: Test Project
        tags:
          - swift
          - metadata
        """)

        let metadata = try MetaDirMetadataLoader().load(from: fixture.url)

        #expect(metadata.title == "Test Project")
        #expect(metadata.tags == ["swift", "metadata"])
    }

    @Test func reportsMissingFile() throws {
        let fixture = try FixtureFolder()

        #expect(throws: MetaDirMetadataError.fileNotFound) {
            try MetaDirMetadataLoader().load(from: fixture.url)
        }
    }

    @Test func rejectsMalformedYAML() throws {
        let fixture = try FixtureFolder(yaml: "version: [broken")

        #expect(throws: MetaDirMetadataError.self) {
            try MetaDirMetadataLoader().load(from: fixture.url)
        }
    }

    @Test func rejectsUnsupportedVersion() throws {
        let fixture = try FixtureFolder(yaml: "version: 2\ntitle: Future")

        #expect(throws: MetaDirMetadataError.unsupportedVersion(2)) {
            try MetaDirMetadataLoader().load(from: fixture.url)
        }
    }

    @Test func parsesTransferredYAML() throws {
        let yaml = "version: 1\ntitle: Transferred Metadata\nstatus: active"
        let metadata = try MetaDirMetadataLoader().load(yaml: yaml)
        #expect(metadata.title == "Transferred Metadata")
        #expect(metadata.status == "active")
    }

    @Test func rejectsOversizedTransferredYAML() {
        let yaml = String(repeating: "x", count: MetaDirMetadataLoader.maximumFileSize + 1)
        #expect(throws: MetaDirMetadataError.fileTooLarge(maximumBytes: MetaDirMetadataLoader.maximumFileSize)) {
            try MetaDirMetadataLoader().load(yaml: yaml)
        }
    }

    @Test func detectsNestedMonitoredRoots() {
        let root = URL(fileURLWithPath: "/Users/example/Projects")
        let child = URL(fileURLWithPath: "/Users/example/Projects/MetaDir")
        let sibling = URL(fileURLWithPath: "/Users/example/ProjectArchive")
        #expect(MonitoredRootRules.contains(root, child))
        #expect(!MonitoredRootRules.contains(root, sibling))
    }

    @Test func roundTripsFolderRequest() throws {
        let folderURL = URL(fileURLWithPath: "/Users/example/Project Files/データ", isDirectory: true)
        let encodedURL = try #require(MetaDirRequest(folderURL: folderURL).url)
        let request = try #require(MetaDirRequest(url: encodedURL))
        #expect(request.folderURL.path == folderURL.path)
    }

}

private final class FixtureFolder {
    let url: URL

    init(yaml: String? = nil) throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        if let yaml {
            try yaml.write(to: url.appendingPathComponent(MetaDirConfiguration.metadataFilename), atomically: true, encoding: .utf8)
        }
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
