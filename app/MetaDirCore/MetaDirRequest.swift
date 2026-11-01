//
//  MetaDirRequest.swift
//  MetaDirCore
//

import Foundation

/// A request to show metadata for a selected folder.
public struct MetaDirRequest: Equatable, Sendable {
    public static let scheme = "metadir"
    public let folderURL: URL

    public init(folderURL: URL) {
        self.folderURL = folderURL
    }

    /// Encodes the request as the app's custom URL.
    public var url: URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = "show"
        components.queryItems = [URLQueryItem(name: "path", value: folderURL.path)]
        return components.url
    }

    /// Decodes a custom URL received by MetaDir.
    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == Self.scheme,
              components.host == "show",
              let path = components.queryItems?.first(where: { $0.name == "path" })?.value,
              path.hasPrefix("/") else { return nil }
        folderURL = URL(fileURLWithPath: path, isDirectory: true)
    }
}
