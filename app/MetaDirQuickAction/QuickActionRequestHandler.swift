//
//  QuickActionRequestHandler.swift
//  MetaDirQuickAction
//

import AppKit
import UniformTypeIdentifiers

final class QuickActionRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        guard let item = context.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            cancel(context, message: "MetaDir requires one selected folder.")
            return
        }

        let typeIdentifier: String
        if provider.hasItemConformingToTypeIdentifier(UTType.folder.identifier) {
            typeIdentifier = UTType.folder.identifier
        } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            typeIdentifier = UTType.fileURL.identifier
        } else {
            cancel(context, message: "MetaDir requires one selected folder.")
            return
        }

        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, error in
            guard let self else { return }
            guard error == nil, let folderURL = self.fileURL(from: item) else {
                self.cancel(context, message: error?.localizedDescription ?? "The selected folder could not be opened.")
                return
            }

            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                self.cancel(context, message: "MetaDir works with folders only.")
                return
            }

            self.openMetaDir(for: folderURL, context: context)
        }
    }

    private func openMetaDir(for folderURL: URL, context: NSExtensionContext) {
        let wasAccessing = folderURL.startAccessingSecurityScopedResource()
        defer { if wasAccessing { folderURL.stopAccessingSecurityScopedResource() } }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([folderURL], withApplicationAt: containingAppURL, configuration: configuration) { _, error in
            if let error {
                self.cancel(context, message: error.localizedDescription)
                return
            }
            context.completeRequest(returningItems: nil)
        }
    }

    private func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL { return url }
        if let data = item as? Data { return URL(dataRepresentation: data, relativeTo: nil) }
        if let string = item as? String { return URL(string: string) }
        return nil
    }

    private func cancel(_ context: NSExtensionContext, message: String) {
        let error = NSError(domain: "com.example.MetaDir.QuickAction", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        context.cancelRequest(withError: error)
    }

    private var containingAppURL: URL {
        Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
