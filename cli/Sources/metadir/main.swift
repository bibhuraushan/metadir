import MetaDirCLIKit
import Foundation

private let usage = """
Usage:
  metadir init <folder> [--title <title>]
  metadir edit <folder>
  metadir validate <folder>
  metadir show <folder>
  metadir help

Commands:
  init      Create a new .metadir.yml without overwriting an existing file.
  edit      Edit a temporary copy and save only if the result is valid.
  validate  Validate size, UTF-8, YAML, schema version, and required fields.
  show      Print validated metadata in a readable terminal format.
"""

private func titleOption(in arguments: [String]) throws -> String? {
    guard let index = arguments.firstIndex(of: "--title") else { return nil }
    guard arguments.indices.contains(index + 1) else { throw CLIError.missingTitle }
    return arguments[index + 1]
}

private enum CLIError: LocalizedError {
    case missingCommand
    case missingFolder
    case missingTitle
    case unknownCommand(String)

    var errorDescription: String? {
        switch self {
        case .missingCommand: "A command is required."
        case .missingFolder: "A folder path is required."
        case .missingTitle: "--title requires a value."
        case let .unknownCommand(command): "Unknown command: \(command)"
        }
    }
}

private func run() throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard let command = arguments.first else { throw CLIError.missingCommand }
    if ["help", "--help", "-h"].contains(command) {
        print(usage)
        return
    }

    guard arguments.indices.contains(1) else { throw CLIError.missingFolder }
    let store = MetaDirMetadataStore()
    let folderURL = try store.folderURL(for: arguments[1])

    switch command {
    case "init":
        let metadataURL = try store.create(in: folderURL, title: titleOption(in: arguments))
        print("Created \(metadataURL.path)")
    case "edit":
        try MetadataEditor(store: store).edit(folderURL: folderURL)
        print("Updated \(store.metadataURL(in: folderURL).path)")
    case "validate":
        let metadata = try store.load(from: folderURL)
        print("Valid metadata: \(metadata.title)")
    case "show":
        print(MetadataRenderer.render(try store.load(from: folderURL)))
    default:
        throw CLIError.unknownCommand(command)
    }
}

do {
    try run()
} catch {
    FileHandle.standardError.write(Data("metadir: \(error.localizedDescription)\n\n\(usage)\n".utf8))
    exit(EXIT_FAILURE)
}
