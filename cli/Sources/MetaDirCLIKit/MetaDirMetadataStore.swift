import Foundation
import Yams

/// Reads, creates, validates, and safely updates folder metadata.
public struct MetaDirMetadataStore: Sendable {
    public static let filename = ".metadir.yml"
    public static let maximumFileSize = 1_048_576
    public static let supportedVersion = 1

    public init() {}

    /// Resolves and validates a directory supplied by the user.
    public func folderURL(for path: String, currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)) throws -> URL {
        let url = URL(fileURLWithPath: path, isDirectory: true, relativeTo: currentDirectory).standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw MetaDirError.notDirectory(url.path)
        }
        return url
    }

    /// Returns the expected metadata file inside a folder.
    public func metadataURL(in folderURL: URL) -> URL {
        folderURL.appendingPathComponent(Self.filename, isDirectory: false)
    }

    /// Loads and validates metadata from a directory.
    public func load(from folderURL: URL) throws -> MetaDirMetadata {
        let metadataURL = metadataURL(in: folderURL)
        let data = try readMetadataData(at: metadataURL)
        return try decode(data)
    }

    /// Validates a metadata document without writing it.
    public func decode(_ data: Data) throws -> MetaDirMetadata {
        guard data.count <= Self.maximumFileSize else { throw MetaDirError.fileTooLarge(Self.maximumFileSize) }
        guard let yaml = String(data: data, encoding: .utf8) else { throw MetaDirError.invalidUTF8 }

        let metadata: MetaDirMetadata
        do {
            metadata = try YAMLDecoder().decode(MetaDirMetadata.self, from: yaml)
        } catch {
            throw MetaDirError.invalidYAML(error.localizedDescription)
        }

        guard metadata.version == Self.supportedVersion else { throw MetaDirError.unsupportedVersion(metadata.version) }
        guard !metadata.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw MetaDirError.emptyTitle }
        return metadata
    }

    /// Creates a new metadata file and refuses to overwrite an existing one.
    @discardableResult
    public func create(in folderURL: URL, title: String? = nil) throws -> URL {
        let metadataURL = metadataURL(in: folderURL)
        guard !FileManager.default.fileExists(atPath: metadataURL.path) else { throw MetaDirError.fileAlreadyExists(metadataURL.path) }
        let resolvedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadata = MetaDirMetadata(title: resolvedTitle?.isEmpty == false ? resolvedTitle! : folderURL.lastPathComponent)
        let yaml = try YAMLEncoder().encode(metadata)
        guard let data = yaml.data(using: .utf8) else { throw MetaDirError.invalidUTF8 }
        // An exclusive create prevents a concurrent process from overwriting a file
        // created after the existence check. Foundation cannot combine this option
        // with `.atomic`, and atomic replacement is unnecessary for a new file.
        try data.write(to: metadataURL, options: .withoutOverwriting)
        return metadataURL
    }

    /// Replaces metadata only after the proposed YAML passes validation.
    public func replace(in folderURL: URL, with data: Data) throws {
        let metadataURL = metadataURL(in: folderURL)
        try rejectSymbolicLink(at: metadataURL)
        _ = try decode(data)
        try data.write(to: metadataURL, options: .atomic)
    }

    /// Reads a metadata document after applying size and symlink protections.
    public func readMetadataData(at metadataURL: URL) throws -> Data {
        guard FileManager.default.fileExists(atPath: metadataURL.path) else { throw MetaDirError.fileNotFound(metadataURL.path) }
        try rejectSymbolicLink(at: metadataURL)
        let size = try metadataURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= Self.maximumFileSize else { throw MetaDirError.fileTooLarge(Self.maximumFileSize) }
        return try Data(contentsOf: metadataURL, options: .mappedIfSafe)
    }

    private func rejectSymbolicLink(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey, .isRegularFileKey])
        guard values.isSymbolicLink != true else { throw MetaDirError.symbolicLinkNotAllowed(url.path) }
        guard values.isRegularFile == true else { throw MetaDirError.notRegularFile(url.path) }
    }
}

/// User-facing errors returned by the CLI metadata store.
public enum MetaDirError: LocalizedError, Equatable, Sendable {
    case notDirectory(String)
    case fileNotFound(String)
    case fileAlreadyExists(String)
    case fileTooLarge(Int)
    case invalidUTF8
    case invalidYAML(String)
    case unsupportedVersion(Int)
    case emptyTitle
    case symbolicLinkNotAllowed(String)
    case notRegularFile(String)
    case editorFailed(Int32)
    case editorNotFound(String)

    public var errorDescription: String? {
        switch self {
        case let .notDirectory(path): "Not a directory: \(path)"
        case let .fileNotFound(path): "Metadata file not found: \(path)"
        case let .fileAlreadyExists(path): "Metadata already exists: \(path)"
        case let .fileTooLarge(limit): "Metadata exceeds the \(limit)-byte limit."
        case .invalidUTF8: "Metadata is not valid UTF-8 text."
        case let .invalidYAML(message): "Invalid metadata YAML: \(message)"
        case let .unsupportedVersion(version): "Metadata version \(version) is not supported."
        case .emptyTitle: "Metadata title cannot be empty."
        case let .symbolicLinkNotAllowed(path): "Symbolic metadata files are not allowed: \(path)"
        case let .notRegularFile(path): "Metadata path is not a regular file: \(path)"
        case let .editorFailed(status): "The editor exited with status \(status); metadata was not changed."
        case let .editorNotFound(editor): "The configured editor could not be launched: \(editor)"
        }
    }
}
