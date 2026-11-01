import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct LocalDocument: Identifiable, Hashable {
    let id: String
    let name: String
    let url: URL
    let fileSize: Int64
    let modified: Date
    var fileExtension: String { url.pathExtension.lowercased() }
    var isPDF: Bool { fileExtension == "pdf" }
}

@MainActor
final class LocalDocumentStore: ObservableObject {
    @Published private(set) var documents: [LocalDocument] = []
    @Published var errorMessage: String?
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    init() { refresh() }
    func refresh() {
        do {
            let urls = try fileManager.contentsOfDirectory(at: documentsDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles])
            documents = urls.compactMap { url in
                let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                guard url.lastPathComponent != "Inbox" else { return nil }
                return LocalDocument(id: url.absoluteString, name: url.lastPathComponent, url: url,
                    fileSize: Int64(values?.fileSize ?? 0),
                    modified: values?.contentModificationDate ?? .distantPast)
            }.sorted { $0.modified > $1.modified }
        } catch {
            errorMessage = "Could not read the local document library: (error.localizedDescription)"
        }
    }
    func importFiles(_ urls: [URL]) {
        for source in urls {
            let granted = source.startAccessingSecurityScopedResource()
            defer { if granted { source.stopAccessingSecurityScopedResource() } }
            let destination = uniqueDestination(for: source.lastPathComponent)
            do { try fileManager.copyItem(at: source, to: destination) }
            catch { errorMessage = "Could not import (source.lastPathComponent): (error.localizedDescription)" }
        }
        refresh()
    }
    func saveScannedPDF(data: Data) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let name = "Scan-(formatter.string(from: Date())).pdf"
        do {
            try data.write(to: documentsDirectory.appendingPathComponent(name), options: .atomic)
            refresh()
        } catch { errorMessage = "Could not save scanned PDF: (error.localizedDescription)" }
    }
    func delete(_ document: LocalDocument) {
        do { try fileManager.removeItem(at: document.url); refresh() }
        catch { errorMessage = "Could not delete file: (error.localizedDescription)" }
    }
    private func uniqueDestination(for filename: String) -> URL {
        let base = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: filename).pathExtension
        var candidate = documentsDirectory.appendingPathComponent(filename)
        var index = 2
        while fileManager.fileExists(atPath: candidate.path) {
            let next = ext.isEmpty ? "(base) ((index))" : "(base) ((index)).(ext)"
            candidate = documentsDirectory.appendingPathComponent(next)
            index += 1
        }
        return candidate
    }
}