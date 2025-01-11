import SwiftUI
import AppKit

// Am Anfang der Datei, nach den imports
private enum NavigationDirection {
    case left, right, up, down
}

// Konstanten für die Fenstergröße
private let kMinWindowHeight: CGFloat = 345  // Minimalhöhe für das Fenster
private let kMaxWindowHeight: CGFloat = 375  // Maximalhöhe für das Fenster
private let kWindowWidth: CGFloat = 300      // Feste Fensterbreite

// PopupDelegate für das Umbenennen von Dateien
private class RenamePopupDelegate: NSObject {
    let textField: NSTextField
    let dateFormatter: DateFormatter
    let creationDate: Date
    let nameWithoutExtension: String
    let previewLabel: NSTextField
    let prefixField: NSTextField
    let fileExtension: String
    let container: NSView
    let extensionLabel: NSTextField
    let popup: NSPopUpButton
    
    init(textField: NSTextField, dateFormatter: DateFormatter, creationDate: Date, nameWithoutExtension: String, previewLabel: NSTextField, prefixField: NSTextField, fileExtension: String, container: NSView, extensionLabel: NSTextField, popup: NSPopUpButton) {
        self.textField = textField
        self.dateFormatter = dateFormatter
        self.creationDate = creationDate
        self.nameWithoutExtension = nameWithoutExtension
        self.previewLabel = previewLabel
        self.prefixField = prefixField
        self.fileExtension = fileExtension
        self.container = container
        self.extensionLabel = extensionLabel
        self.popup = popup
        super.init()
        
        // Initial preview
        updatePreview()
        updatePrefixVisibility(isDateFormat: false)
        
        // Add observers for text changes
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: NSControl.textDidChangeNotification, object: textField)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: NSControl.textDidChangeNotification, object: prefixField)
    }
    
    @objc func textDidChange(_ notification: Notification) {
        updatePreview()
    }
    
    private func updatePrefixVisibility(isDateFormat: Bool) {
        prefixField.isHidden = !isDateFormat
        
        // Anpassen der Positionen und Container-Größe
        if isDateFormat {
            // Layout für Datumsformat mit Präfix
            container.frame.size.height = 180
            textField.frame.origin.y = 144
            extensionLabel.frame.origin.y = 148
            prefixField.frame.origin.y = 104
            popup.frame.origin.y = 62
            previewLabel.frame.origin.y = 22
        } else {
            // Layout für normales Format ohne Präfix
            container.frame.size.height = 150
            textField.frame.origin.y = 114
            extensionLabel.frame.origin.y = 118
            popup.frame.origin.y = 62
            previewLabel.frame.origin.y = 22
        }
        
        // Container-Größe im Alert aktualisieren
        if let alert = container.window as? NSPanel {
            var newHeight = alert.frame.size.height + (isDateFormat ? 30 : -30)
            
            // Größenbegrenzungen anwenden
            newHeight = max(kMinWindowHeight, min(kMaxWindowHeight, newHeight))
            
            let newFrame = NSRect(
                x: alert.frame.origin.x,
                y: alert.frame.origin.y + (alert.frame.size.height - newHeight),
                width: kWindowWidth,
                height: newHeight
            )
            
            alert.setFrame(newFrame, display: true, animate: true)
            
            // Minimale und maximale Größe festlegen
            alert.minSize = NSSize(width: kWindowWidth, height: kMinWindowHeight)
            alert.maxSize = NSSize(width: kWindowWidth, height: kMaxWindowHeight)
        }
    }
    
    private func updatePreview() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let prefix = self.prefixField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseText = self.textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let format = self.dateFormatter.dateFormat, !format.isEmpty {
                let dateString = self.dateFormatter.string(from: self.creationDate)
                if !prefix.isEmpty {
                    self.previewLabel.stringValue = "Vorschau: \(prefix)_\(dateString).\(self.fileExtension)"
                } else {
                    self.previewLabel.stringValue = "Vorschau: \(dateString).\(self.fileExtension)"
                }
            } else {
                if !baseText.isEmpty {
                    if !prefix.isEmpty {
                        self.previewLabel.stringValue = "Vorschau: \(prefix)_\(baseText).\(self.fileExtension)"
                    } else {
                        self.previewLabel.stringValue = "Vorschau: \(baseText).\(self.fileExtension)"
                    }
                } else {
                    self.previewLabel.stringValue = "Vorschau: "
                }
            }
        }
    }
    
    @objc func popupAction(_ sender: NSPopUpButton) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let selectedTitle = sender.selectedItem?.title ?? ""
            
            switch selectedTitle {
            case "Datum (YYYY-MM-DD)":
                self.dateFormatter.dateFormat = "yyyy-MM-dd"
                self.textField.stringValue = self.dateFormatter.string(from: self.creationDate)
                self.updatePrefixVisibility(isDateFormat: true)
                
            case "Datum und Zeit (YYYY-MM-DD HH-mm)":
                self.dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
                self.textField.stringValue = self.dateFormatter.string(from: self.creationDate)
                self.updatePrefixVisibility(isDateFormat: true)
                
            case "Nur Zeit (HH-mm-ss)":
                self.dateFormatter.dateFormat = "HH-mm-ss"
                self.textField.stringValue = self.dateFormatter.string(from: self.creationDate)
                self.updatePrefixVisibility(isDateFormat: true)
                
            case "Benutzerdefiniert":
                self.dateFormatter.dateFormat = ""
                self.textField.stringValue = self.nameWithoutExtension
                self.updatePrefixVisibility(isDateFormat: false)
                
            case "-":  // Separator überspringen
                break
                
            default:  // Custom Formate
                if selectedTitle.isEmpty { break }
                self.dateFormatter.dateFormat = selectedTitle
                self.textField.stringValue = self.dateFormatter.string(from: self.creationDate)
                self.updatePrefixVisibility(isDateFormat: true)
            }
            
            self.updatePreview()
        }
    }
}

// FileItem Struktur Definition
public struct FileItem: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var path: String
    public var isMarked: Bool = false
    
    public init(id: UUID = UUID(), name: String, path: String, isMarked: Bool = false) {
        self.id = id
        self.name = name
        self.path = path
        self.isMarked = isMarked
    }
    
    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id && lhs.path == rhs.path && lhs.name == rhs.name && lhs.isMarked == rhs.isMarked
    }
}

public class RatingManager: ObservableObject {
    public static let shared = RatingManager()
    private let defaults = UserDefaults.standard
    private let ratingKey = "fileRatings"
    @Published public var lastUpdated = Date()
    
    private init() {}
    
    public func getRating(for path: String) -> Int {
        let ratings = defaults.dictionary(forKey: ratingKey) as? [String: Int] ?? [:]
        return ratings[path] ?? 0
    }
    
    public func setRating(_ rating: Int, for path: String) {
        var ratings = defaults.dictionary(forKey: ratingKey) as? [String: Int] ?? [:]
        ratings[path] = rating
        defaults.set(ratings, forKey: ratingKey)
        defaults.synchronize()
        lastUpdated = Date()
    }
}

// FileRatingView Komponente
struct FileRatingView: View {
    let itemSize: CGFloat
    let isHovered: Bool
    @Binding var currentRating: Int
    let onRatingChanged: (Int) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let ratingBackground = colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7)
        let shadowColor = colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.1)
        let scale = itemSize / 200
        
        StarRatingView(
            maximumRating: 5,
            rating: $currentRating,
            onRatingChanged: onRatingChanged
        )
        .scaleEffect(scale)
        .frame(width: itemSize * 0.8, height: 44 * scale * 0.8)
        .background(
            RoundedRectangle(cornerRadius: itemSize * 0.05) //0.02
                .fill(ratingBackground)
                .shadow(
                    color: shadowColor,
                    radius: itemSize * 0.01,
                    x: 0,
                    y: 1
                )
        )
        .opacity(isHovered ? 1 : 0.7)
    }
}

// FileItemView Implementation
struct FileItemView: View {
    let file: FileItem
    let itemSize: CGFloat
    @Binding var markedFiles: Set<UUID>
    @Binding var lastSelectedId: UUID?
    let files: [FileItem]
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    @State private var preview: NSImage?
    @State private var isLoading = false
    @State private var loadingTask: Task<Void, Never>?
    @StateObject private var ratingManager = RatingManager.shared
    @State private var currentRating: Int = 0
    let fileIndex: Int
    let onDoubleClick: (Int) -> Void
    @Binding var selectedFolder: String?
    
    private var isFolder: Bool {
        (try? FileManager.default.attributesOfItem(atPath: file.path)[.type] as? FileAttributeType) == .typeDirectory
    }
    
    private var isCurrentFileVideo: Bool {
        let ext = (file.name as NSString).pathExtension.lowercased()
        return ["mp4", "mov", "m4v", "avi"].contains(ext)
    }
    
    private var isPDF: Bool {
        (file.name as NSString).pathExtension.lowercased() == "pdf"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Container für Preview/Icon
            VStack {
                Spacer()
                ZStack {
                    // Preview oder Icon
                    Group {
                        if shouldShowPreview(for: file) {
                            if let preview = preview {
                                ZStack {
                                    Image(nsImage: preview)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: itemSize * 0.7, height: itemSize * 0.7)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    
                                    if isCurrentFileVideo {
                                        ZStack {
                                            Circle()
                                                .fill(.black.opacity(0.4))
                                                .frame(width: itemSize * 0.2, height: itemSize * 0.2)
                                            
                                            Image(systemName: "play.fill")
                                                .foregroundStyle(.white)
                                                .font(.system(size: itemSize * 0.12))
                                        }
                                    } else if isPDF {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(.black.opacity(0.4))
                                                .frame(width: itemSize * 0.2, height: itemSize * 0.2)
                                            
                                            Image(systemName: "doc.fill")
                                                .foregroundStyle(.white)
                                                .font(.system(size: itemSize * 0.12))
                                        }
                                    }
                                }
                            } else {
                                ProgressView()
                                    .frame(width: itemSize * 0.7, height: itemSize * 0.7)
                                    .opacity(isLoading ? 1 : 0)
                            }
                        } else {
                            Image(systemName: iconForFile(file))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: itemSize * 0.28, height: itemSize * 0.28)
                        }
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .frame(height: itemSize * 0.8)
            
            // Container für Name und Rating
            VStack(spacing: 0) {
                Text(file.name)
                    .font(.system(size: itemSize * 0.11))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .frame(height: itemSize * 0.22)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
                
                FileRatingView(
                    itemSize: itemSize,
                    isHovered: isHovered,
                    currentRating: $currentRating,
                    onRatingChanged: { newRating in
                        ratingManager.setRating(newRating, for: file.path)
                    }
                )
                .animation(.easeInOut(duration: 0.2), value: isHovered)
                
                Spacer()
            }
            .frame(height: itemSize * 0.45)
        }
        .frame(width: itemSize, height: itemSize * 1.2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ?
                      Color(white: 0.2).opacity(isHovered ? 0.5 : 0.3) :
                        Color(white: 1).opacity(isHovered ? 1 : 0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(markedFiles.contains(file.id) ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture(count: 2) {
            if isFolder {
                selectedFolder = file.path
            } else {
                onDoubleClick(fileIndex)
            }
        }
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.command) {
                // Command: Toggle einzelne Auswahl
                if markedFiles.contains(file.id) {
                    markedFiles.remove(file.id)
                } else {
                    markedFiles.insert(file.id)
                }
                lastSelectedId = file.id
            } else if NSEvent.modifierFlags.contains(.shift) && lastSelectedId != nil {
                // Shift: Auswahl von letzter bis aktuelle
                let filesBetween = getFilesBetween(from: lastSelectedId!, to: file.id)
                markedFiles.formUnion(filesBetween)
            } else {
                // Normale Auswahl: Nur diese Datei
                markedFiles = [file.id]
                lastSelectedId = file.id
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onAppear {
            loadPreview()
            currentRating = ratingManager.getRating(for: file.path)
        }
        .onChange(of: ratingManager.lastUpdated) { oldValue, newValue in
            currentRating = ratingManager.getRating(for: file.path)
        }
        .onDisappear {
            loadingTask?.cancel()
            loadingTask = nil
        }
    }
    
    private func getFilesBetween(from: UUID, to: UUID) -> [UUID] {
        guard let fromIndex = files.firstIndex(where: { $0.id == from }),
              let toIndex = files.firstIndex(where: { $0.id == to }) else {
            return []
        }
        
        let range = fromIndex < toIndex ? fromIndex...toIndex : toIndex...fromIndex
        return range.map { files[$0].id }
    }
    
    private func iconForFile(_ file: FileItem) -> String {
        if isFolder {
            return "folder.fill"
        }
        let ext = (file.name as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo.fill"
        case "mp4", "mov", "avi": return "video.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "chart.bar.doc.horizontal.fill"
        case "txt", "rtf": return "doc.text.fill"
        case "zip", "rar": return "doc.zipper"
        case "app": return "app.fill"
        case "dmg": return "externaldrive.fill"
        default: return "doc.fill"
        }
    }
    
    @MainActor
    private func shouldShowPreview(for file: FileItem) -> Bool {
        if isFolder { return false }
        let ext = (file.name as NSString).pathExtension.lowercased()
        return FilePreviewGenerator.shared.supportedTypes.contains(ext)
    }
    
    @MainActor
    private func loadPreview() {
        guard shouldShowPreview(for: file) else { return }
        
        isLoading = true
        preview = nil
        
        // Vorherigen Task abbrechen, falls vorhanden
        loadingTask?.cancel()
        
        // Neuen Task erstellen
        loadingTask = Task {
            defer { isLoading = false }
            
            let size = CGSize(width: itemSize * 0.8, height: itemSize * 0.8)
            
            guard !Task.isCancelled,
                  let previewImage = await FilePreviewGenerator.shared.generatePreview(
                    for: file.path,
                    size: size,
                    thumbnailOnly: true
                  ) else {
                return
            }
            
            // Prüfe nochmal auf Abbruch, bevor wir das UI aktualisieren
            if !Task.isCancelled {
                preview = previewImage
            }
        }
    }
}

// Preview Provider
#Preview {
    FileItemView(
        file: FileItem(id: UUID(), name: "test.jpg", path: "/path/to/test.jpg"),
        itemSize: 120,
        markedFiles: .constant(Set()),
        lastSelectedId: .constant(nil),
        files: [],
        fileIndex: 0,
        onDoubleClick: { index in
            // Handle double-click
        },
        selectedFolder: .constant(nil)
    )
}

enum SortOption: String, CaseIterable {
    case creationDate = "Erstellungsdatum"
    case modificationDate = "Änderungsdatum"
    case lastOpened = "Zuletzt geöffnet"
    case name = "Name"
    case size = "Größe"
    case rating = "Bewertung"
}

struct MainView: View {
    @State private var selectedFolder: String?
    @State private var files: [FileItem] = []
    @State private var markedFiles: Set<UUID> = []
    @State private var itemSize: CGFloat = 100
    @State private var sidebarWidth: CGFloat = 220
    @State private var isSidebarVisible: Bool = true
    @State private var isFullscreenPresented = false
    @State private var fullscreenInitialIndex = 0
    @State private var windowDelegate: FullscreenWindowDelegate?
    @State private var showAllFiles: Bool = false
    @State private var selectedSortOption: SortOption = .name
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var ratingManager = RatingManager.shared
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.98, green: 0.98, blue: 1.0)
    }
    
    private var sidebarColor: Color {
        colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.16) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
    }
    
    private let headerHeight: CGFloat = 44
    private let sidebarMinWidth: CGFloat = 220
    private let contentMinWidth: CGFloat = 580
    private let detailsWidth: CGFloat = 260
    private let minHeight: CGFloat = 400
    
    private func openFullscreenWindow(initialIndex: Int) {
        let controller = NSWindowController(
            window: NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
        )
        
        if let window = controller.window {
            window.center()
            window.contentView = NSHostingView(rootView: 
                FullscreenView(
                    file: files[initialIndex],
                    files: $files,
                    currentIndex: initialIndex,
                    onNavigate: { newIndex in
                        // Speichere den aktuellen Index für die spätere Verwendung
                        fullscreenInitialIndex = newIndex
                    }
                )
            )
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .black
            window.makeKeyAndOrderFront(nil)
            window.toggleFullScreen(nil)
            
            // Füge einen Window Delegate hinzu
            let delegate = FullscreenWindowDelegate()
            delegate.onClose = {
                isFullscreenPresented = false
                // Setze alle Markierungen zurück und markiere nur die zuletzt angezeigte Datei
                markedFiles = [files[fullscreenInitialIndex].id]
            }
            window.delegate = delegate
            
            // Speichere den Delegate, damit er nicht deallokiert wird
            windowDelegate = delegate
            
            NSApp.windows.first?.windowController = controller
        }
    }
    
    private func sortFiles() {
        let fileManager = FileManager.default
        
        switch selectedSortOption {
        case .creationDate:
            files.sort { file1, file2 in
                guard let attr1 = try? fileManager.attributesOfItem(atPath: file1.path),
                      let attr2 = try? fileManager.attributesOfItem(atPath: file2.path),
                      let date1 = attr1[.creationDate] as? Date,
                      let date2 = attr2[.creationDate] as? Date else {
                    return false
                }
                return date1 > date2
            }
        case .modificationDate:
            files.sort { file1, file2 in
                guard let attr1 = try? fileManager.attributesOfItem(atPath: file1.path),
                      let attr2 = try? fileManager.attributesOfItem(atPath: file2.path),
                      let date1 = attr1[.modificationDate] as? Date,
                      let date2 = attr2[.modificationDate] as? Date else {
                    return false
                }
                return date1 > date2
            }
        case .lastOpened:
            files.sort { file1, file2 in
                guard let attr1 = try? fileManager.attributesOfItem(atPath: file1.path),
                      let attr2 = try? fileManager.attributesOfItem(atPath: file2.path),
                      let date1 = attr1[.modificationDate] as? Date,  // Verwende modificationDate statt contentAccessDate
                      let date2 = attr2[.modificationDate] as? Date else {
                    return false
                }
                return date1 > date2
            }
        case .name:
            files.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .size:
            files.sort { file1, file2 in
                guard let attr1 = try? fileManager.attributesOfItem(atPath: file1.path),
                      let attr2 = try? fileManager.attributesOfItem(atPath: file2.path),
                      let size1 = attr1[.size] as? Int64,
                      let size2 = attr2[.size] as? Int64 else {
                    return false
                }
                return size1 > size2
            }
        case .rating:
            files.sort { file1, file2 in
                let rating1 = RatingManager.shared.getRating(for: file1.path)
                let rating2 = RatingManager.shared.getRating(for: file2.path)
                if rating1 == rating2 {
                    // Bei gleicher Bewertung nach Name sortieren
                    return file1.name.localizedStandardCompare(file2.name) == .orderedAscending
                }
                return rating1 > rating2
            }
        }
    }
    
    var body: some View {
        HSplitView {
            // Linke Sidebar
            if isSidebarVisible {
                VStack(spacing: 0) {
                    HStack {
                        Text(NSUserName())
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: headerHeight)
                    .background(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.97))
                    
                    SidebarContentView(selectedFolder: $selectedFolder)
                        .frame(maxHeight: .infinity)
                }
                .frame(minWidth: sidebarMinWidth, maxWidth: sidebarMinWidth * 1.5)
                .background(sidebarColor)
                .transition(.move(edge: .leading))
            }
            
            // Hauptbereich
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button(action: toggleSidebar) {
                        Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isSidebarVisible ? "Sidebar ausblenden" : "Sidebar einblenden")
                    
                    Text("BrightShelf")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    // Sortier-Menü
                    Picker("Sortieren nach", selection: $selectedSortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.3x2")
                            .font(.system(size: 12))
                            .foregroundColor(textColor.opacity(0.6))
                        
                        Slider(value: $itemSize, in: 100...200)
                            .frame(width: 100)
                            .help("Dateigröße anpassen")
                        
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Button(action: openSettings) {
                        Image(systemName: "gear")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Einstellungen")
                }
                .padding(.horizontal, 16)
                .frame(height: headerHeight)
                .background(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.97))
                
                FileGridView(
                    selectedFolder: $selectedFolder,
                    files: $files,
                    markedFiles: $markedFiles,
                    itemSize: itemSize,
                    isFullscreenPresented: $isFullscreenPresented,
                    fullscreenInitialIndex: $fullscreenInitialIndex,
                    selectedSortOption: $selectedSortOption
                )
                .frame(minWidth: contentMinWidth, maxHeight: .infinity)
                .background(backgroundColor)
            }
            .frame(maxHeight: .infinity)
            
            // Rechte Seitenleiste mit Metadaten und Toolbar
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Details")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: headerHeight)
                .background(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.97))
                
                // Metadaten oder Platzhalter
                if !markedFiles.isEmpty {
                    let selectedFiles = files.filter { markedFiles.contains($0.id) }
                    if selectedFiles.count == 1 {
                        // Einzelne Datei ausgewählt
                        FileMetadataView(file: selectedFiles[0])
                            .frame(maxHeight: .infinity)
                            .id(selectedFiles[0].id)
                    } else {
                        // Mehrere Dateien ausgewählt
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(selectedFiles.count) Dateien ausgewählt")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            let totalSize = selectedFiles.compactMap { file -> Int64? in
                                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                                   let size = attributes[.size] as? Int64 {
                                    return size
                                }
                                return nil
                            }.reduce(0, +)
                            
                            MetadataRow(label: "Gesamtgröße", value: ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            if selectedFiles.count > 5 && !showAllFiles {
                                // Erste 5 Dateien
                                ForEach(selectedFiles.prefix(5)) { file in
                                    Text(file.name)
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        showAllFiles.toggle()
                                    }
                                }) {
                                    Text("+ \(selectedFiles.count - 5) weitere anzeigen")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            } else {
                                // Alle Dateien in ScrollView
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(selectedFiles) { file in
                                            Text(file.name)
                                                .lineLimit(1)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                                
                                if selectedFiles.count > 5 {
                                    Button(action: {
                                        withAnimation {
                                            showAllFiles.toggle()
                                        }
                                    }) {
                                        Text("Liste ausblenden")
                                            .foregroundStyle(.blue)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 8)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("Keine Datei ausgewählt")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                }
                
                // Toolbar
                FileToolbarView(markedFiles: $markedFiles, files: $files)
            }
            .frame(minWidth: detailsWidth, maxWidth: detailsWidth, maxHeight: .infinity)
            .background(backgroundColor)
        }
        .frame(minWidth: contentMinWidth + detailsWidth + (isSidebarVisible ? sidebarMinWidth : 0),
               minHeight: minHeight)
        .animation(.easeInOut(duration: 0.2), value: isSidebarVisible)
        .onChange(of: isFullscreenPresented) { _, newValue in
            if newValue {
                openFullscreenWindow(initialIndex: fullscreenInitialIndex)
            }
        }
        .onChange(of: isFullscreenPresented) { _, newValue in
            if !newValue {  // Wenn Fullscreen geschlossen wird
                if selectedSortOption == .rating {
                    // Sortiere die Dateien neu
                    files.sort { file1, file2 in
                        let rating1 = ratingManager.getRating(for: file1.path)
                        let rating2 = ratingManager.getRating(for: file2.path)
                        if rating1 == rating2 {
                            return file1.name.localizedStandardCompare(file2.name) == .orderedAscending
                        }
                        return rating1 > rating2
                    }
                }
            }
        }
    }
    
    private func openSettings() {
        let controller = NSWindowController(
            window: NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
        )
        
        if let window = controller.window {
            window.center()
            window.contentView = NSHostingView(rootView: SettingsView())
            window.titlebarAppearsTransparent = true
            window.title = "Einstellungen"
            window.makeKeyAndOrderFront(nil)
            window.minSize = NSSize(width: 1000, height: 700)
            window.maxSize = NSSize(width: 1200, height: 800)
            NSApp.windows.first?.windowController = controller
        }
    }
    
    private func toggleSidebar() {
        withAnimation {
            isSidebarVisible.toggle()
        }
    }
}
struct SidebarContentView: View {
    @Binding var selectedFolder: String?
    @StateObject private var sidebarManager = SidebarManager.shared
    
    var body: some View {
        List {
            ForEach(sidebarManager.applicationPaths + sidebarManager.sidebarLinks, id: \.self) { path in
                SidebarFolderView(
                    folder: URL(fileURLWithPath: path),
                    isSelected: selectedFolder == path
                )
                .onTapGesture {
                    selectedFolder = path
                }
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(SidebarListStyle())
    }
}

struct SidebarFolderView: View {
    let folder: URL
    let isSelected: Bool
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 16, height: 16)
            
            Text(folder.lastPathComponent)
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(isSelected ? .white : textColor)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .cornerRadius(4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isHovered {
            return colorScheme == .dark ?
                Color.white.opacity(0.1) :
                Color.black.opacity(0.05)
        }
        return .clear
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
    }
}

// Neue ToolbarView erstellen
struct FileToolbarView: View {
    @Binding var markedFiles: Set<UUID>
    @Binding var files: [FileItem]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            
            // Umbenennen-Button
            Button(action: renameFile) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                    Text("")
                        .font(.system(size: 12))
                }
                .foregroundColor(markedFiles.isEmpty ? .gray : .blue)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(markedFiles.isEmpty)
            .help("Datei(en) umbenennen")
            
            // Verschieben-Button
            Button(action: moveFiles) {
                Image(systemName: "folder")
                    .font(.system(size: 16))
                    .foregroundColor(markedFiles.isEmpty ? .gray : .blue)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(markedFiles.isEmpty)
            .help("Dateien verschieben")
            
            // Löschen-Button
            Button(action: deleteFiles) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(markedFiles.isEmpty ? .gray : .red)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(markedFiles.isEmpty)
            .help("Dateien löschen")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            colorScheme == .dark ? 
                Color(white: 0.2).opacity(0.8) : 
                Color(white: 0.95).opacity(0.8)
        )
    }
    
    // PopupDelegate für das Umbenennen von Dateien
    private class RenamePopupDelegate: NSObject {
        let textField: NSTextField
        let dateFormatter: DateFormatter
        let creationDate: Date
        let nameWithoutExtension: String
        let previewLabel: NSTextField
        let prefixField: NSTextField
        let fileExtension: String
        let container: NSView
        let extensionLabel: NSTextField
        let popup: NSPopUpButton
        
        init(textField: NSTextField, dateFormatter: DateFormatter, creationDate: Date, nameWithoutExtension: String, previewLabel: NSTextField, prefixField: NSTextField, fileExtension: String, container: NSView, extensionLabel: NSTextField, popup: NSPopUpButton) {
            self.textField = textField
            self.dateFormatter = dateFormatter
            self.creationDate = creationDate
            self.nameWithoutExtension = nameWithoutExtension
            self.previewLabel = previewLabel
            self.prefixField = prefixField
            self.fileExtension = fileExtension
            self.container = container
            self.extensionLabel = extensionLabel
            self.popup = popup
            super.init()
            
            // Initial preview
            updatePreview()
            updatePrefixVisibility(isDateFormat: false)
            
            // Add observers for text changes
            NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: NSControl.textDidChangeNotification, object: textField)
            NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: NSControl.textDidChangeNotification, object: prefixField)
        }
        
        @objc func textDidChange(_ notification: Notification) {
            updatePreview()
        }
        
        private func updatePrefixVisibility(isDateFormat: Bool) {
            prefixField.isHidden = !isDateFormat
            
            // Anpassen der Positionen und Container-Größe
            if isDateFormat {
                // Layout für Datumsformat mit Präfix
                container.frame.size.height = 180
                textField.frame.origin.y = 144
                extensionLabel.frame.origin.y = 148
                prefixField.frame.origin.y = 104
                popup.frame.origin.y = 62
                previewLabel.frame.origin.y = 22
            } else {
                // Layout für normales Format ohne Präfix
                container.frame.size.height = 150
                textField.frame.origin.y = 114
                extensionLabel.frame.origin.y = 118
                popup.frame.origin.y = 62
                previewLabel.frame.origin.y = 22
            }
            
            // Container-Größe im Alert aktualisieren
            if let alert = container.window as? NSPanel {
                var newHeight = alert.frame.size.height + (isDateFormat ? 30 : -30)
                
                // Größenbegrenzungen anwenden
                newHeight = max(kMinWindowHeight, min(kMaxWindowHeight, newHeight))
                
                let newFrame = NSRect(
                    x: alert.frame.origin.x,
                    y: alert.frame.origin.y + (alert.frame.size.height - newHeight),
                    width: kWindowWidth,
                    height: newHeight
                )
                
                alert.setFrame(newFrame, display: true, animate: true)
                
                // Minimale und maximale Größe festlegen
                alert.minSize = NSSize(width: kWindowWidth, height: kMinWindowHeight)
                alert.maxSize = NSSize(width: kWindowWidth, height: kMaxWindowHeight)
            }
        }
        
        private func updatePreview() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let prefix = self.prefixField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                let baseText = self.textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let format = self.dateFormatter.dateFormat, !format.isEmpty {
                    let dateString = self.dateFormatter.string(from: self.creationDate)
                    if !prefix.isEmpty {
                        self.previewLabel.stringValue = "Vorschau: \(prefix)_\(dateString).\(self.fileExtension)"
                    } else {
                        self.previewLabel.stringValue = "Vorschau: \(dateString).\(self.fileExtension)"
                    }
                } else {
                    if !baseText.isEmpty {
                        if !prefix.isEmpty {
                            self.previewLabel.stringValue = "Vorschau: \(prefix)_\(baseText).\(self.fileExtension)"
                        } else {
                            self.previewLabel.stringValue = "Vorschau: \(baseText).\(self.fileExtension)"
                        }
                    } else {
                        self.previewLabel.stringValue = "Vorschau: "
                    }
                }
            }
        }
        
        @objc func popupAction(_ sender: NSPopUpButton) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let selectedTitle = sender.selectedItem?.title ?? ""
                
                switch selectedTitle {
                case "Datum (YYYY-MM-DD)":
                    self.dateFormatter.dateFormat = "yyyy-MM-dd"
                    self.textField.stringValue = self.dateFormatter.string(from: self.creationDate)
                    self.updatePrefixVisibility(isDateFormat: true)
                    
                case "Datum und Zeit (YYYY-MM-DD HH-mm)":
                    self.dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
                    self.textField.stringValue = self.dateFormatter.string(from: self.creationDate)
                    self.updatePrefixVisibility(isDateFormat: true)
                    
                case "Nur Zeit (HH-mm-ss)":
                    self.dateFormatter.dateFormat = "HH-mm-ss"
                    self.textField.stringValue = self.dateFormatter.string(from: self.creationDate)
                    self.updatePrefixVisibility(isDateFormat: true)
                    
                case "Benutzerdefiniert":
                    self.dateFormatter.dateFormat = ""
                    self.textField.stringValue = self.nameWithoutExtension
                    self.updatePrefixVisibility(isDateFormat: false)
                    
                case "-":  // Separator überspringen
                    break
                    
                default:  // Custom Formate
                    if selectedTitle.isEmpty { break }
                    self.dateFormatter.dateFormat = selectedTitle
                    self.textField.stringValue = self.dateFormatter.string(from: self.creationDate)
                    self.updatePrefixVisibility(isDateFormat: true)
                }
                
                self.updatePreview()
            }
        }
    }
    
    private func renameFile() {
        guard !markedFiles.isEmpty else { return }
        
        let alert = NSAlert()
        alert.messageText = markedFiles.count == 1 ? "Datei umbenennen" : "Dateien umbenennen"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Umbenennen")
        alert.addButton(withTitle: "Abbrechen")
        
        // Container für alle Elemente
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 140))
        
        // Textfeld für den Namen
        let textField = NSTextField(frame: NSRect(x: 0, y: 104, width: 240, height: 24))
        
        // Wenn nur eine Datei ausgewählt ist, zeigen wir den aktuellen Namen
        if markedFiles.count == 1,
           let fileId = markedFiles.first,
           let fileIndex = files.firstIndex(where: { $0.id == fileId }) {
            let currentName = files[fileIndex].name
            let nameWithoutExtension = (currentName as NSString).deletingPathExtension
            textField.stringValue = nameWithoutExtension
        }
        container.addSubview(textField)
        
        // Label für die Endung
        let extensionLabel = NSTextField(labelWithString: markedFiles.count == 1 ? ".\(getFileExtension(for: markedFiles.first!))" : "")
        extensionLabel.frame = NSRect(x: 242, y: 108, width: 58, height: 16)
        extensionLabel.textColor = NSColor.secondaryLabelColor
        extensionLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        container.addSubview(extensionLabel)
        
        // Präfix Textfeld
        let prefixField = NSTextField(frame: NSRect(x: 0, y: 74, width: 240, height: 24))
        prefixField.placeholderString = "Präfix (optional)"
        container.addSubview(prefixField)
        
        // Popup für Datumsformate
        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 42, width: 300, height: 24))
        var menuItems = [
            "Benutzerdefiniert",
            "Datum (YYYY-MM-DD)",
            "Datum und Zeit (YYYY-MM-DD HH-mm)",
            "Nur Zeit (HH-mm-ss)"
        ]
        
        // Gespeicherte Formate aus UserDefaults laden und hinzufügen
        if let customFormatsData = UserDefaults.standard.data(forKey: "customFormats"),
           let customFormats = try? JSONDecoder().decode([String].self, from: customFormatsData) {
            // Trennlinie hinzufügen
            menuItems.append("-")
            // Custom Formate hinzufügen
            menuItems.append(contentsOf: customFormats)
        }
        
        popup.addItems(withTitles: menuItems)
        
        // Vorschau Label
        let previewLabel = NSTextField(labelWithString: "Vorschau: ")
        previewLabel.frame = NSRect(x: 0, y: 12, width: 300, height: 16)
        previewLabel.textColor = NSColor.secondaryLabelColor
        previewLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        previewLabel.lineBreakMode = .byTruncatingMiddle
        container.addSubview(previewLabel)
        
        // Dateiattribute für die erste Datei abrufen (für Preview)
        if let fileId = markedFiles.first,
           let fileIndex = files.firstIndex(where: { $0.id == fileId }) {
            let fileURL = URL(fileURLWithPath: files[fileIndex].path)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let creationDate = attributes[.creationDate] as? Date {
                
                let dateFormatter = DateFormatter()
                let delegate = RenamePopupDelegate(
                    textField: textField,
                    dateFormatter: dateFormatter,
                    creationDate: creationDate,
                    nameWithoutExtension: textField.stringValue,
                    previewLabel: previewLabel,
                    prefixField: prefixField,
                    fileExtension: getFileExtension(for: fileId),
                    container: container,
                    extensionLabel: extensionLabel,
                    popup: popup
                )
                
                popup.target = delegate
                popup.action = #selector(RenamePopupDelegate.popupAction(_:))
                objc_setAssociatedObject(popup, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
        }
        
        container.addSubview(popup)
        alert.accessoryView = container
        
        if alert.runModal() == .alertFirstButtonReturn {
            let newNameBase = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = prefixField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !newNameBase.isEmpty {
                let fileManager = FileManager.default
                let markedFileItems = files.filter { markedFiles.contains($0.id) }
                let dateFormatter = DateFormatter()
                
                // Zähler für Dateinamen bei mehreren Dateien
                var counter = 1
                var duplicateWarnings: [String] = []
                
                for file in markedFileItems {
                    let oldURL = URL(fileURLWithPath: file.path)
                    let fileExtension = (file.name as NSString).pathExtension
                    
                    // Generiere den neuen Namen
                    var newName: String
                    if markedFiles.count == 1 {
                        // Einzelne Datei - verwende direkt den eingegebenen Namen
                        newName = "\(newNameBase).\(fileExtension)"
                    } else {
                        if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                           let creationDate = attributes[.creationDate] as? Date {
                            // Verwende das ausgewählte Datumsformat
                            switch popup.selectedItem?.title {
                            case "Datum (YYYY-MM-DD)":
                                dateFormatter.dateFormat = "yyyy-MM-dd"
                                let dateString = dateFormatter.string(from: creationDate)
                                newName = "\(dateString).\(fileExtension)"
                            case "Datum und Zeit (YYYY-MM-DD HH-mm)":
                                dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
                                let dateString = dateFormatter.string(from: creationDate)
                                newName = "\(dateString).\(fileExtension)"
                            case "Nur Zeit (HH-mm-ss)":
                                dateFormatter.dateFormat = "HH-mm-ss"
                                let dateString = dateFormatter.string(from: creationDate)
                                newName = "\(dateString).\(fileExtension)"
                            case "Benutzerdefiniert":
                                // Bei benutzerdefiniert verwende den Basesnamen mit Zähler
                                newName = "\(newNameBase)_\(String(format: "%03d", counter)).\(fileExtension)"
                                counter += 1
                            default:
                                if let customFormat = popup.selectedItem?.title, !customFormat.isEmpty {
                                    dateFormatter.dateFormat = customFormat
                                    let dateString = dateFormatter.string(from: creationDate)
                                    newName = "\(dateString).\(fileExtension)"
                                } else {
                                    // Wenn kein Format ausgewählt ist, verwende den Basesnamen mit Zähler
                                    newName = "\(newNameBase)_\(String(format: "%03d", counter)).\(fileExtension)"
                                    counter += 1
                                }
                            }
                        } else {
                            // Fallback wenn kein Datum verfügbar ist
                            newName = "\(newNameBase)_\(String(format: "%03d", counter)).\(fileExtension)"
                            counter += 1
                        }
                    }
                    
                    // Präfix am Ende hinzufügen, wenn vorhanden
                    if !prefix.isEmpty {
                        let nameWithoutExtension = (newName as NSString).deletingPathExtension
                        let fileExt = (newName as NSString).pathExtension
                        newName = "\(prefix)_\(nameWithoutExtension).\(fileExt)"
                    }
                    
                    // Überprüfen, ob der Name bereits existiert, und anpassen
                    var finalName = newName
                    var nameCounter = 1
                    let newNameWithoutExtension = (newName as NSString).deletingPathExtension
                    let newNameExtension = (newName as NSString).pathExtension
                    
                    if files.contains(where: { $0.name == finalName && $0.id != file.id }) {
                        duplicateWarnings.append(file.name)
                        repeat {
                            finalName = "\(newNameWithoutExtension) (\(nameCounter)).\(newNameExtension)"
                            nameCounter += 1
                        } while files.contains(where: { $0.name == finalName && $0.id != file.id })
                    }
                    
                    let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(finalName)
                    
                    do {
                        try fileManager.moveItem(at: oldURL, to: newURL)
                        
                        // Update files array
                        if let index = files.firstIndex(where: { $0.id == file.id }) {
                            var updatedFile = files[index]
                            updatedFile.name = finalName
                            updatedFile.path = newURL.path
                            files[index] = updatedFile
                        }
                    } catch {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "Fehler beim Umbenennen"
                        errorAlert.informativeText = "Fehler beim Umbenennen von '\(file.name)': \(error.localizedDescription)"
                        errorAlert.alertStyle = .warning
                        errorAlert.runModal()
                    }
                }
                
                // Nach der for-Schleife: Zeige Warnung für Duplikate
                if !duplicateWarnings.isEmpty {
                    let alert = NSAlert()
                    alert.messageText = "Dateinamen angepasst"
                    alert.alertStyle = .informational
                    
                    if duplicateWarnings.count == 1 {
                        alert.informativeText = "Die Datei '\(duplicateWarnings[0])' existierte bereits und wurde entsprechend nummeriert."
                    } else {
                        alert.informativeText = "\(duplicateWarnings.count) Dateien existierten bereits und wurden entsprechend nummeriert."
                    }
                    
                    alert.runModal()
                }
            }
        }
    }
    
    private func getFileExtension(for fileId: UUID) -> String {
        if let fileIndex = files.firstIndex(where: { $0.id == fileId }) {
            return (files[fileIndex].name as NSString).pathExtension
        }
        return ""
    }
    
    private func moveFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Wähle einen Zielordner"
        panel.prompt = "Verschieben"
        
        if panel.runModal() == .OK {
            guard let targetURL = panel.url else { return }
            
            let fileManager = FileManager.default
            let selectedFiles = files.filter { markedFiles.contains($0.id) }
            
            for file in selectedFiles {
                let sourceURL = URL(fileURLWithPath: file.path)
                let destinationURL = targetURL.appendingPathComponent(file.name)
                
                do {
                    try fileManager.moveItem(at: sourceURL, to: destinationURL)
                } catch {
                    print("Fehler beim Verschieben von \(file.name): \(error)")
                }
            }
            
            // Auswahl zurücksetzen nach dem Verschieben
            markedFiles.removeAll()
        }
    }
    
    private func deleteFiles() {
        let selectedFiles = files.filter { markedFiles.contains($0.id) }
        let fileCount = selectedFiles.count
        
        let alert = NSAlert()
        alert.messageText = "Dateien löschen"
        alert.informativeText = "Möchtest du wirklich \(fileCount) Datei\(fileCount == 1 ? "" : "en") löschen?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let fileManager = FileManager.default
            
            for file in selectedFiles {
                do {
                    try fileManager.removeItem(atPath: file.path)
                } catch {
                    print("Fehler beim Löschen von \(file.name): \(error)")
                }
            }
            
            // Auswahl zurücksetzen nach dem Löschen
            markedFiles.removeAll()
        }
    }
}

// FileGridView anpassen
struct FileGridView: View {
    @Binding var selectedFolder: String?
    @Binding var files: [FileItem]
    @Binding var markedFiles: Set<UUID>
    let itemSize: CGFloat
    @State private var lastSelectedId: UUID? = nil
    @Binding var isFullscreenPresented: Bool
    @Binding var fullscreenInitialIndex: Int
    @Binding var selectedSortOption: SortOption
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var ratingManager = RatingManager.shared
    @State private var columnCount: Int = 0  // Anzahl der Spalten
    @FocusState private var isFocused: Bool
    
    private func getPathComponents(_ path: String) -> [(String, String)] {
        var components: [(String, String)] = []
        let parts = path.split(separator: "/")
        var currentPath = ""
        
        for part in parts {
            currentPath += "/" + part
            components.append((String(part), currentPath))
        }
        
        return components
    }
    
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: itemSize, maximum: itemSize), spacing: 12)]
    }
    
    private func sortFiles() {
        let fileManager = FileManager.default
        let ratingManager = RatingManager.shared
        
        switch selectedSortOption {
        case .rating:
            files.sort { file1, file2 in
                let rating1 = ratingManager.getRating(for: file1.path)
                let rating2 = ratingManager.getRating(for: file2.path)
                if rating1 == rating2 {
                    // Bei gleicher Bewertung nach Name sortieren
                    return file1.name.localizedStandardCompare(file2.name) == .orderedAscending
                }
                return rating1 > rating2
            }
        case .creationDate:
            files.sort { file1, file2 in
                guard let attr1 = try? fileManager.attributesOfItem(atPath: file1.path),
                      let attr2 = try? fileManager.attributesOfItem(atPath: file2.path),
                      let date1 = attr1[.creationDate] as? Date,
                      let date2 = attr2[.creationDate] as? Date else {
                    return false
                }
                return date1 > date2
            }
        case .modificationDate:
            files.sort { file1, file2 in
                guard let attr1 = try? fileManager.attributesOfItem(atPath: file1.path),
                      let attr2 = try? fileManager.attributesOfItem(atPath: file2.path),
                      let date1 = attr1[.modificationDate] as? Date,
                      let date2 = attr2[.modificationDate] as? Date else {
                    return false
                }
                return date1 > date2
            }
        case .lastOpened:
            files.sort { file1, file2 in
                guard let attr1 = try? fileManager.attributesOfItem(atPath: file1.path),
                      let attr2 = try? fileManager.attributesOfItem(atPath: file2.path),
                      let date1 = attr1[.modificationDate] as? Date,
                      let date2 = attr2[.modificationDate] as? Date else {
                    return false
                }
                return date1 > date2
            }
        case .name:
            files.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .size:
            files.sort { file1, file2 in
                guard let attr1 = try? fileManager.attributesOfItem(atPath: file1.path),
                      let attr2 = try? fileManager.attributesOfItem(atPath: file2.path),
                      let size1 = attr1[.size] as? Int64,
                      let size2 = attr2[.size] as? Int64 else {
                    return false
                }
                return size1 > size2
            }
        }
    }
    
    // Berechne die Anzahl der Spalten basierend auf der verfügbaren Breite
    private func updateColumnCount(_ geometry: GeometryProxy) {
        let availableWidth = geometry.size.width - 32  // 32 für Padding (16 links + 16 rechts)
        let columnsWithSpacing = availableWidth / (itemSize + 12)  // 12 ist der Spaltenabstand
        columnCount = max(1, Int(columnsWithSpacing))
    }
    
    // Funktion zum Navigieren zwischen Dateien
    private func navigateFiles(direction: NavigationDirection) {
        guard !files.isEmpty else { return }
        
        if markedFiles.isEmpty {
            // Wenn keine Datei ausgewählt ist, wähle die erste
            markedFiles.insert(files[0].id)
            lastSelectedId = files[0].id
            return
        }
        
        guard let currentIndex = files.firstIndex(where: { markedFiles.contains($0.id) }) else { return }
        var newIndex: Int
        
        switch direction {
        case .left:
            newIndex = currentIndex - 1
        case .right:
            newIndex = currentIndex + 1
        case .up:
            newIndex = currentIndex - columnCount
        case .down:
            newIndex = currentIndex + columnCount
        }
        
        // Prüfe Grenzen und Zeilenumbruch
        if newIndex < 0 {
            switch direction {
            case .left:
                // Am Anfang der Zeile -> gehe zum Ende der vorherigen Zeile
                let currentRow = currentIndex / columnCount
                if currentRow > 0 {
                    let previousRowStart = (currentRow - 1) * columnCount
                    let previousRowEnd = min(previousRowStart + columnCount - 1, files.count - 1)
                    newIndex = previousRowEnd
                } else {
                    newIndex = currentIndex
                }
            case .up:
                newIndex = currentIndex
            default:
                newIndex = currentIndex
            }
        } else if newIndex >= files.count {
            switch direction {
            case .right:
                // Am Ende der Zeile -> gehe zum Anfang der nächsten Zeile
                let nextRowStart = (currentIndex / columnCount + 1) * columnCount
                if nextRowStart < files.count {
                    newIndex = nextRowStart
                } else {
                    newIndex = currentIndex
                }
            case .down:
                newIndex = currentIndex
            default:
                newIndex = currentIndex
            }
        }
        
        // Aktualisiere Auswahl
        if newIndex != currentIndex && newIndex >= 0 && newIndex < files.count {
            markedFiles = [files[newIndex].id]
            lastSelectedId = files[newIndex].id
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Dateipfad
                if let currentPath = selectedFolder {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            Image(systemName: "macwindow")
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    selectedFolder = "/"
                                }
                            
                            ForEach(getPathComponents(currentPath), id: \.0) { name, path in
                                HStack(spacing: 2) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                    
                                    Text(name)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedFolder = path
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95))
                }
                
                // Grid View
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                            FileItemView(
                                file: file,
                                itemSize: itemSize,
                                markedFiles: $markedFiles,
                                lastSelectedId: $lastSelectedId,
                                files: files,
                                fileIndex: index,
                                onDoubleClick: { index in
                                    fullscreenInitialIndex = index
                                    isFullscreenPresented = true
                                },
                                selectedFolder: $selectedFolder
                            )
                        }
                    }
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: markedFiles)
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                updateColumnCount(geometry)
            }
            .onAppear {
                updateColumnCount(geometry)
                isFocused = true
            }
            .focusable()
            .focused($isFocused)
            .onKeyPress { press in
                guard isFocused else { return .ignored }
                
                switch press.key {
                case .leftArrow:
                    navigateFiles(direction: .left)
                    return .handled
                case .rightArrow:
                    navigateFiles(direction: .right)
                    return .handled
                case .upArrow:
                    navigateFiles(direction: .up)
                    return .handled
                case .downArrow:
                    navigateFiles(direction: .down)
                    return .handled
                default:
                    return .ignored
                }
            }
            // Füge die onChange Handler wieder hinzu
            .onChange(of: selectedFolder) { _, newValue in
                if let folder = newValue {
                    loadFiles(from: folder)
                    markedFiles.removeAll()
                }
            }
            .onChange(of: selectedSortOption) { _, _ in
                sortFiles()
            }
        }
    }
    
    private func loadFiles(from path: String) {
        let url = URL(fileURLWithPath: path)
        files = FileSystemManager.shared.getContents(of: url)
        sortFiles()
    }
}

struct FileDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var markedFiles: Set<UUID>
    @Binding var files: [FileItem]
    let selectedFolder: String?
    
    var body: some View {
        VStack {
            Spacer()
            
            if markedFiles.isEmpty {
                // Standardansicht wenn keine Dateien ausgewählt sind
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("Keine Datei ausgewählt")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Einheitliche Toolbar
            HStack(spacing: 10) {    //24
                Spacer()
                
                // Umbenennen-Button
                Button(action: renameFile) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                        Text("")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(markedFiles.isEmpty ? .gray : .blue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(markedFiles.isEmpty)
                .help("Datei(en) umbenennen")
                
                Divider()
                    .frame(height: 16)
                    .opacity(0.5)
                
                // Verschieben-Button
                Button(action: moveFiles) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                        Text("")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(markedFiles.isEmpty ? .gray : .blue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(markedFiles.isEmpty)
                .help("Dateien verschieben")
                
                Divider()
                    .frame(height: 16)
                    .opacity(0.5)
                
                // Löschen-Button
                Button(action: deleteFiles) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(markedFiles.isEmpty ? .gray : .red)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(markedFiles.isEmpty)
                .help("Dateien löschen")
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? 
                        Color(white: 0.2) : 
                        Color(white: 0.95))
            )
            
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colorScheme == .dark ? 
                        Color.white.opacity(0.1) : 
                        Color.black.opacity(0.05),
                        lineWidth: 1)
            )
            .padding(12)
        }
    }
    
    private func renameFile() {
        guard markedFiles.count == 1,
              let fileId = markedFiles.first,
              let fileIndex = files.firstIndex(where: { $0.id == fileId }) else { return }
        
        let currentName = files[fileIndex].name
        let fileExtension = (currentName as NSString).pathExtension
        let nameWithoutExtension = (currentName as NSString).deletingPathExtension
        
        let alert = NSAlert()
        alert.messageText = "Datei umbenennen"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Umbenennen")
        alert.addButton(withTitle: "Abbrechen")
        
        // Container für alle Elemente
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))
        
        // Textfeld für den Namen
        let textField = NSTextField(frame: NSRect(x: 0, y: 44, width: 240, height: 24))
        textField.stringValue = nameWithoutExtension
        container.addSubview(textField)
        
        // Label für die Endung
        let extensionLabel = NSTextField(labelWithString: ".\(fileExtension)")
        extensionLabel.frame = NSRect(x: 242, y: 48, width: 58, height: 16)
        extensionLabel.textColor = NSColor.secondaryLabelColor
        extensionLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        container.addSubview(extensionLabel)
        
        // Popup für Datumsformate
        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 12, width: 300, height: 24))
        var menuItems = [
            "Benutzerdefiniert",
            "Datum (YYYY-MM-DD)",
            "Datum und Zeit (YYYY-MM-DD HH-mm)",
            "Nur Zeit (HH-mm-ss)"
        ]
        
        // Gespeicherte Formate aus UserDefaults laden und hinzufügen
        if let customFormatsData = UserDefaults.standard.data(forKey: "customFormats"),
           let customFormats = try? JSONDecoder().decode([String].self, from: customFormatsData) {
            // Trennlinie hinzufügen
            menuItems.append("-")
            // Custom Formate hinzufügen
            menuItems.append(contentsOf: customFormats)
        }
        
        popup.addItems(withTitles: menuItems)
        
        // Dateiattribute abrufen
        let fileURL = URL(fileURLWithPath: files[fileIndex].path)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let creationDate = attributes[.creationDate] as? Date {
            
            let dateFormatter = DateFormatter()
            let delegate = RenamePopupDelegate(
                textField: textField,
                dateFormatter: dateFormatter,
                creationDate: creationDate,
                nameWithoutExtension: nameWithoutExtension,
                previewLabel: NSTextField(labelWithString: "Vorschau: "),
                prefixField: NSTextField(frame: NSRect(x: 0, y: 44, width: 240, height: 24)),
                fileExtension: fileExtension,
                container: container,
                extensionLabel: extensionLabel,
                popup: popup
            )
            
            popup.target = delegate
            popup.action = #selector(RenamePopupDelegate.popupAction(_:))
            objc_setAssociatedObject(popup, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
        
        container.addSubview(popup)
        alert.accessoryView = container
        
        if alert.runModal() == .alertFirstButtonReturn {
            let newNameWithoutExtension = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !newNameWithoutExtension.isEmpty && newNameWithoutExtension != nameWithoutExtension {
                let newName = "\(newNameWithoutExtension).\(fileExtension)"
                
                let fileManager = FileManager.default
                let oldURL = URL(fileURLWithPath: files[fileIndex].path)
                let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(newName)
                
                do {
                    try fileManager.moveItem(at: oldURL, to: newURL)
                    
                    // Update files array
                    var updatedFile = files[fileIndex]
                    updatedFile.name = newName
                    updatedFile.path = newURL.path
                    files[fileIndex] = updatedFile
                    
                } catch {
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Fehler beim Umbenennen"
                    errorAlert.informativeText = error.localizedDescription
                    errorAlert.alertStyle = .warning
                    errorAlert.runModal()
                }
            }
        }
    }
    
    private func moveFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Wähle einen Zielordner"
        panel.prompt = "Verschieben"
        
        if panel.runModal() == .OK {
            guard let targetURL = panel.url else { return }
            
            let fileManager = FileManager.default
            let selectedFiles = files.filter { markedFiles.contains($0.id) }
            
            for file in selectedFiles {
                let sourceURL = URL(fileURLWithPath: file.path)
                let destinationURL = targetURL.appendingPathComponent(file.name)
                
                do {
                    try fileManager.moveItem(at: sourceURL, to: destinationURL)
                } catch {
                    print("Fehler beim Verschieben von \(file.name): \(error)")
                }
            }
            
            // Auswahl zurücksetzen nach dem Verschieben
            markedFiles.removeAll()
        }
    }
    
    private func deleteFiles() {
        let selectedFiles = files.filter { markedFiles.contains($0.id) }
        let fileCount = selectedFiles.count
        
        let alert = NSAlert()
        alert.messageText = "Dateien löschen"
        alert.informativeText = "Möchtest du wirklich \(fileCount) Datei\(fileCount == 1 ? "" : "en") löschen?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let fileManager = FileManager.default
            
            for file in selectedFiles {
                do {
                    try fileManager.removeItem(atPath: file.path)
                } catch {
                    print("Fehler beim Löschen von \(file.name): \(error)")
                }
            }
            
            // Auswahl zurücksetzen nach dem Löschen
            markedFiles.removeAll()
        }
    }
}

// Füge eine Klasse für den Window Delegate hinzu
private class FullscreenWindowDelegate: NSObject, NSWindowDelegate {
    var onClose: () -> Void = {}
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

class FileSystemWatcher {
    static let shared = FileSystemWatcher()
    let fileManager = FileManager.default
    var timer: Timer?
    var lastKnownFiles: [String: [String]] = [:]
    var observers: [String: [(URL) -> Void]] = [:]
    
    private init() {}
    
    func startWatching(folder: String, onChange: @escaping (URL) -> Void) {
        observers[folder] = (observers[folder] ?? []) + [onChange]
        
        if timer == nil {
            lastKnownFiles[folder] = try? fileManager.contentsOfDirectory(atPath: folder)
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.checkForChanges()
            }
        }
    }
    
    func stopWatching(folder: String) {
        observers.removeValue(forKey: folder)
        lastKnownFiles.removeValue(forKey: folder)
        
        if observers.isEmpty {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func checkForChanges() {
        for (folder, callbacks) in observers {
            if let currentFiles = try? fileManager.contentsOfDirectory(atPath: folder),
               lastKnownFiles[folder] != currentFiles {
                lastKnownFiles[folder] = currentFiles
                let url = URL(fileURLWithPath: folder)
                callbacks.forEach { $0(url) }
            }
        }
    }
}

