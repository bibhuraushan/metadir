import Foundation

/// Produces a readable terminal representation of metadata.
public enum MetadataRenderer {
    public static func render(_ metadata: MetaDirMetadata) -> String {
        var lines = [metadata.title, String(repeating: "=", count: max(metadata.title.count, 1))]
        append("Summary", metadata.summary, to: &lines)
        append("Owner", metadata.owner, to: &lines)
        append("Status", metadata.status, to: &lines)
        append("Created", metadata.created, to: &lines)
        append("Updated", metadata.updated, to: &lines)
        if !metadata.tags.isEmpty { lines.append("Tags: \(metadata.tags.joined(separator: ", "))") }
        for link in metadata.links { lines.append("Link: \(link.label) — \(link.url)") }
        append("Notes", metadata.notes, to: &lines)
        for key in metadata.custom.keys.sorted() { lines.append("\(key): \(metadata.custom[key, default: ""])") }
        lines.append("Schema Version: \(metadata.version)")
        return lines.joined(separator: "\n")
    }

    private static func append(_ label: String, _ value: String?, to lines: inout [String]) {
        if let value, !value.isEmpty { lines.append("\(label): \(value)") }
    }
}
