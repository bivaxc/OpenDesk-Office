import SwiftUI
import UniformTypeIdentifiers
import VisionKit

private enum AppTab: String, CaseIterable {
    case home = "Home"
    case tools = "Tools"
    case me = "Me"
    var symbol: String {
        switch self {
        case .home: return "house"
        case .tools: return "square.grid.2x2"
        case .me: return "person.crop.circle"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: LocalDocumentStore
    @State private var selectedTab: AppTab = .home
    @State private var showingImporter = false
    @State private var showingScanner = false
    @State private var searchText = ""
    @State private var selectedDocument: LocalDocument?
    private let background = Color(red: 0.055, green: 0.063, blue: 0.078)
    private let panel = Color(red: 0.13, green: 0.145, blue: 0.17)
    private var filteredDocuments: [LocalDocument] {
        guard !searchText.isEmpty else { return store.documents }
        return store.documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    var body: some View {
        TabView(selection: $selectedTab) {
            home.tag(AppTab.home).tabItem { Label("Home", systemImage: AppTab.home.symbol) }
            tools.tag(AppTab.tools).tabItem { Label("Tools", systemImage: AppTab.tools.symbol) }
            profile.tag(AppTab.me).tabItem { Label("Me", systemImage: AppTab.me.symbol) }
        }
        .tint(Color(red: 0.30, green: 0.55, blue: 1.0))
        .preferredColorScheme(.dark)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls): store.importFiles(urls)
            case .failure(let error): store.errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScanner { pdfData in
                store.saveScannedPDF(data: pdfData)
                showingScanner = false
            }
        }
        .sheet(item: $selectedDocument) { document in DocumentPreviewScreen(document: document) }
        .alert("OpenDesk Office", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }
    private var home: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OpenDesk").font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Your documents. Your device.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Search documents", text: $searchText).textInputAutocapitalization(.never)
                    }
                    .padding(14).background(panel, in: RoundedRectangle(cornerRadius: 14))
                    Button { showingScanner = true } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "viewfinder").font(.system(size: 32, weight: .medium))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scan documents").font(.headline)
                                Text("Capture paper and save as PDF").font(.caption).opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))
                        .padding(18)
                        .background(Color(red: 0.78, green: 0.86, blue: 1.0), in: RoundedRectangle(cornerRadius: 18))
                    }
                    HStack(spacing: 12) {
                        moduleCard("Word", symbol: "doc.text", tint: .blue)
                        moduleCard("Sheets", symbol: "tablecells", tint: .green)
                        moduleCard("Slides", symbol: "rectangle.on.rectangle", tint: .orange)
                    }
                    HStack {
                        Text("Recent files").font(.title3.bold())
                        Spacer()
                        Button("Import") { showingImporter = true }.font(.subheadline.weight(.semibold))
                    }
                    if filteredDocuments.isEmpty {
                        ContentUnavailableView("No documents yet", systemImage: "folder",
                            description: Text("Import a document or scan a paper page to get started."))
                            .padding(.top, 12)
                    } else {
                        LazyVStack(spacing: 10) { ForEach(filteredDocuments) { document in documentRow(document) } }
                    }
                }.padding(20)
            }
            .background(background)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingImporter = true } label: { Image(systemName: "plus") }
                }
            }
        }
    }
    private var tools: some View {
        NavigationStack {
            List {
                toolRow("Scan to PDF", symbol: "viewfinder") { showingScanner = true }
                toolRow("Import documents", symbol: "square.and.arrow.down") { showingImporter = true }
                Label("Merge PDF", systemImage: "doc.on.doc")
                Label("Split PDF", systemImage: "scissors")
                Label("Convert documents", systemImage: "arrow.triangle.2.circlepath")
                Label("Sign PDF", systemImage: "signature")
                Label("Extract text (OCR)", systemImage: "text.viewfinder")
            }.navigationTitle("Tools")
        }
    }
    private var profile: some View {
        NavigationStack {
            List {
                Section("Storage") {
                    LabeledContent("Local documents", value: "(store.documents.count)")
                    Text("Documents are stored on this iPhone. Nothing is uploaded.")
                }
                Section("Preferences") {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                    Label("Privacy", systemImage: "hand.raised")
                    Label("About OpenDesk Office", systemImage: "info.circle")
                }
            }.navigationTitle("Me")
        }
    }
    private func moduleCard(_ title: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol).font(.title2).foregroundStyle(tint)
            Text(title).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(14).background(panel, in: RoundedRectangle(cornerRadius: 16))
    }
    private func documentRow(_ document: LocalDocument) -> some View {
        Button { selectedDocument = document } label: {
            HStack(spacing: 13) {
                Image(systemName: document.isPDF ? "doc.richtext" : "doc")
                    .font(.title2).foregroundStyle(document.isPDF ? .red : .blue)
                    .frame(width: 42, height: 48).background(panel, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(12).background(panel.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { store.delete(document) } label: { Label("Delete", systemImage: "trash") }
        }
    }
    private func toolRow(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: symbol) }
    }
}

private struct DocumentPreviewScreen: View {
    let document: LocalDocument
    var body: some View {
        NavigationStack {
            Group {
                if document.isPDF { PDFPreview(url: document.url) }
                else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass").font(.largeTitle)
                        Text(document.name).font(.headline)
                        Text("This file is imported and stored locally. Its format-specific viewer will be added in a later phase.")
                            .multilineTextAlignment(.center).foregroundStyle(.secondary)
                    }.padding()
                }
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}