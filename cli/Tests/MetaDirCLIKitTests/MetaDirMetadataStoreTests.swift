import Foundation
import XCTest
@testable import MetaDirCLIKit

final class MetaDirMetadataStoreTests: XCTestCase {
    func testCreatesAndLoadsMetadata() throws {
        let fixture = try FixtureDirectory()
        let store = MetaDirMetadataStore()
        try store.create(in: fixture.url, title: "Research Project")
        let metadata = try store.load(from: fixture.url)
        XCTAssertEqual(metadata.title, "Research Project")
        XCTAssertEqual(metadata.version, 1)
    }

    func testRefusesToOverwriteMetadata() throws {
        let fixture = try FixtureDirectory()
        let store = MetaDirMetadataStore()
        try store.create(in: fixture.url)
        XCTAssertThrowsError(try store.create(in: fixture.url))
    }

    func testRejectsMalformedYAML() throws {
        let fixture = try FixtureDirectory(yaml: "version: [broken")
        XCTAssertThrowsError(try MetaDirMetadataStore().load(from: fixture.url))
    }

    func testRejectsUnsupportedVersion() throws {
        let fixture = try FixtureDirectory(yaml: "version: 2\ntitle: Future")
        XCTAssertThrowsError(try MetaDirMetadataStore().load(from: fixture.url)) { error in
            XCTAssertEqual(error as? MetaDirError, .unsupportedVersion(2))
        }
    }

    func testRejectsEmptyTitle() throws {
        let fixture = try FixtureDirectory(yaml: "version: 1\ntitle: '   '")
        XCTAssertThrowsError(try MetaDirMetadataStore().load(from: fixture.url)) { error in
            XCTAssertEqual(error as? MetaDirError, .emptyTitle)
        }
    }

    func testReplacesOnlyValidMetadata() throws {
        let fixture = try FixtureDirectory(yaml: "version: 1\ntitle: Original")
        let store = MetaDirMetadataStore()
        XCTAssertThrowsError(try store.replace(in: fixture.url, with: Data("invalid: [".utf8)))
        XCTAssertEqual(try store.load(from: fixture.url).title, "Original")
        try store.replace(in: fixture.url, with: Data("version: 1\ntitle: Updated".utf8))
        XCTAssertEqual(try store.load(from: fixture.url).title, "Updated")
    }

    func testRendersMetadataForTerminal() {
        let metadata = MetaDirMetadata(title: "Example", owner: "Owner", tags: ["swift", "yaml"])
        let output = MetadataRenderer.render(metadata)
        XCTAssertTrue(output.contains("Example"))
        XCTAssertTrue(output.contains("Owner: Owner"))
        XCTAssertTrue(output.contains("Tags: swift, yaml"))
    }

    func testRejectsSymbolicMetadataFile() throws {
        let fixture = try FixtureDirectory()
        let externalFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "version: 1\ntitle: External".write(to: externalFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: externalFile) }
        try FileManager.default.createSymbolicLink(
            at: fixture.url.appendingPathComponent(MetaDirMetadataStore.filename),
            withDestinationURL: externalFile
        )

        XCTAssertThrowsError(try MetaDirMetadataStore().load(from: fixture.url)) { error in
            guard case MetaDirError.symbolicLinkNotAllowed = error else {
                return XCTFail("Expected symbolicLinkNotAllowed, received \(error)")
            }
        }
    }

    func testRejectsOversizedMetadata() throws {
        let fixture = try FixtureDirectory()
        let oversized = Data(repeating: 0x20, count: MetaDirMetadataStore.maximumFileSize + 1)
        try oversized.write(to: fixture.url.appendingPathComponent(MetaDirMetadataStore.filename))
        XCTAssertThrowsError(try MetaDirMetadataStore().load(from: fixture.url)) { error in
            XCTAssertEqual(error as? MetaDirError, .fileTooLarge(MetaDirMetadataStore.maximumFileSize))
        }
    }
}

private final class FixtureDirectory {
    let url: URL

    init(yaml: String? = nil) throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        if let yaml {
            try yaml.write(to: url.appendingPathComponent(MetaDirMetadataStore.filename), atomically: true, encoding: .utf8)
        }
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
