//
//  MetaDirMetadata.swift
//  MetaDirCore
//

import Foundation

/// Metadata stored in a folder's `.metadir.yml` file.
public struct MetaDirMetadata: Codable, Equatable, Sendable {
    public let version: Int
    public let title: String
    public let summary: String?
    public let owner: String?
    public let status: String?
    public let created: String?
    public let updated: String?
    public let tags: [String]
    public let links: [MetaDirMetadataLink]
    public let notes: String?
    public let custom: [String: String]

    public init(version: Int, title: String, summary: String? = nil, owner: String? = nil, status: String? = nil, created: String? = nil, updated: String? = nil, tags: [String] = [], links: [MetaDirMetadataLink] = [], notes: String? = nil, custom: [String: String] = [:]) {
        self.version = version
        self.title = title
        self.summary = summary
        self.owner = owner
        self.status = status
        self.created = created
        self.updated = updated
        self.tags = tags
        self.links = links
        self.notes = notes
        self.custom = custom
    }

    private enum CodingKeys: String, CodingKey {
        case version, title, summary, owner, status, created, updated, tags, links, notes, custom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        owner = try container.decodeIfPresent(String.self, forKey: .owner)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        created = try container.decodeIfPresent(String.self, forKey: .created)
        updated = try container.decodeIfPresent(String.self, forKey: .updated)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        links = try container.decodeIfPresent([MetaDirMetadataLink].self, forKey: .links) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        custom = try container.decodeIfPresent([String: String].self, forKey: .custom) ?? [:]
    }
}

/// A named web link included in folder metadata.
public struct MetaDirMetadataLink: Codable, Equatable, Sendable {
    public let label: String
    public let url: String

    public init(label: String, url: String) {
        self.label = label
        self.url = url
    }

}
