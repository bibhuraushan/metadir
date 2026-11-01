import Foundation

/// Safely edits metadata through an external text editor.
public struct MetadataEditor {
    private let store: MetaDirMetadataStore
    private let environment: [String: String]

    public init(store: MetaDirMetadataStore = MetaDirMetadataStore(), environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.store = store
        self.environment = environment
    }

    /// Opens a temporary copy and commits it only when the result is valid.
    public func edit(folderURL: URL) throws {
        let metadataURL = store.metadataURL(in: folderURL)
        let originalData = try store.readMetadataData(at: metadataURL)
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent("metadir-\(UUID().uuidString).yml")
        try originalData.write(to: temporaryURL, options: .withoutOverwriting)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        let process = try editorProcess(for: temporaryURL)
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw MetaDirError.editorFailed(process.terminationStatus) }

        let editedData = try Data(contentsOf: temporaryURL)
        try store.replace(in: folderURL, with: editedData)
    }

    private func editorProcess(for fileURL: URL) throws -> Process {
        let process = Process()
        if let editor = preferredEditor {
            let components = editor.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard let executable = components.first, !executable.isEmpty else { throw MetaDirError.editorNotFound(editor) }
            process.executableURL = executable.hasPrefix("/") ? URL(fileURLWithPath: executable) : URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = executable.hasPrefix("/") ? Array(components.dropFirst()) + [fileURL.path] : components + [fileURL.path]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-W", "-t", fileURL.path]
        }
        return process
    }

    private var preferredEditor: String? {
        [environment["VISUAL"], environment["EDITOR"]].compactMap { $0 }.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
