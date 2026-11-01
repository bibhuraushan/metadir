//
//  MetaDirMetadataLoader.swift
//  MetaDirCore
//

import Foundation
import Yams

/// Loads and validates folder metadata on demand.
public struct MetaDirMetadataLoader: Sendable {
    public static let maximumFileSize = 1_048_576
    public static let supportedVersion = 1

    public init() {}

    /// Reads `.metadir.yml` from the supplied folder.
    ///
    /// - Parameter folderURL: Folder whose metadata should be read.
    /// - Returns: Validated folder metadata.
    /// - Throws: ``MetaDirMetadataError`` when the file cannot be loaded.
    public func load(from folderURL: URL) throws -> MetaDirMetadata {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw MetaDirMetadataError.notDirectory
        }

        let metadataURL = folderURL.appendingPathComponent(MetaDirConfiguration.metadataFilename, isDirectory: false)
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            throw MetaDirMetadataError.fileNotFound
        }

        let fileSize = try metadataURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard fileSize <= Self.maximumFileSize else {
            throw MetaDirMetadataError.fileTooLarge(maximumBytes: Self.maximumFileSize)
        }

        let data = try Data(contentsOf: metadataURL, options: .mappedIfSafe)
        guard let yaml = String(data: data, encoding: .utf8) else {
            throw MetaDirMetadataError.invalidUTF8
        }

        return try load(yaml: yaml)
    }

    /// Parses and validates metadata that has already been read by an extension.
    public func load(yaml: String) throws -> MetaDirMetadata {
        guard yaml.utf8.count <= Self.maximumFileSize else {
            throw MetaDirMetadataError.fileTooLarge(maximumBytes: Self.maximumFileSize)
        }

        let metadata: MetaDirMetadata
        do {
            metadata = try YAMLDecoder().decode(MetaDirMetadata.self, from: yaml)
        } catch {
            throw MetaDirMetadataError.invalidYAML(description: error.localizedDescription)
        }

        guard metadata.version == Self.supportedVersion else {
            throw MetaDirMetadataError.unsupportedVersion(metadata.version)
        }

        return metadata
    }
}

/// Errors produced while reading folder metadata.
public enum MetaDirMetadataError: LocalizedError, Equatable, Sendable {
    case notDirectory
    case fileNotFound
    case fileTooLarge(maximumBytes: Int)
    case invalidUTF8
    case invalidYAML(description: String)
    case unsupportedVersion(Int)

    public var errorDescription: String? {
        switch self {
        case .notDirectory:
            "The selected item is not a folder."
        case .fileNotFound:
            "This folder does not contain a .metadir.yml file."
        case let .fileTooLarge(maximumBytes):
            "The metadata file is larger than the \(maximumBytes)-byte limit."
        case .invalidUTF8:
            "The metadata file is not valid UTF-8 text."
        case let .invalidYAML(description):
            "The metadata file contains invalid YAML: \(description)"
        case let .unsupportedVersion(version):
            "Metadata version \(version) is not supported."
        }
    }
}
