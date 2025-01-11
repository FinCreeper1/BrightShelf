import SwiftUI
import AVKit
import PDFKit
import AVFoundation

struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .floating
        playerView.showsFullScreenToggleButton = false
        playerView.showsTimecodes = true
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

public struct FullscreenView: View {
    @Environment(\.dismiss) private var dismiss
    let file: FileItem
    @Binding var files: [FileItem]
    @State private var currentIndex: Int
    let onNavigate: (Int) -> Void
    @StateObject private var ratingManager = RatingManager.shared
    @State private var currentRating: Int = 0
    @State private var showMetadata: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var loadedImage: NSImage?
    @State private var isLoading = false
    @State private var eventMonitor: Any?
    @State private var player: AVPlayer?
    @State private var pdfDocument: PDFDocument?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    @State private var viewSize: CGSize = .zero
    @State private var zoomPoint: UnitPoint = .center
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    private func calculateZoomPoint(from event: NSEvent, in geometry: GeometryProxy) -> UnitPoint {
        let window = NSApp.keyWindow
        let contentView = window?.contentView
        let location = event.locationInWindow
        
        // Konvertiere die Fensterkoordinaten in View-Koordinaten
        if let contentView = contentView {
            let viewLocation = contentView.convert(location, from: nil)
            let viewFrame = geometry.frame(in: .global)
            
            // Berechne die relative Position innerhalb des Views
            let x = (viewLocation.x - viewFrame.minX) / viewFrame.width
            let y = 1.0 - ((viewLocation.y - viewFrame.minY) / viewFrame.height)
            
            return UnitPoint(x: max(0, min(1, x)), y: max(0, min(1, y)))
        }
        
        return .center
    }
    
    private var isCurrentFileVideo: Bool {
        let ext = (files[currentIndex].name as NSString).pathExtension.lowercased()
        return ["mp4", "mov", "m4v", "avi"].contains(ext)
    }
    
    private var isPDF: Bool {
        (files[currentIndex].name as NSString).pathExtension.lowercased() == "pdf"
    }
    
    public init(file: FileItem, files: Binding<[FileItem]>, currentIndex: Int, onNavigate: @escaping (Int) -> Void) {
        self.file = file
        self._files = files
        self._currentIndex = State(initialValue: currentIndex)
        self.onNavigate = onNavigate
    }
    
    private func cleanupAndDismiss() {
        // Erst Event Monitor entfernen
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        // Player stoppen
        DispatchQueue.main.async {
            self.player?.pause()
            self.player = nil
        }
        
        // View schließen
        dismiss()
    }
    
    private func calculateImageSize(for image: NSImage, in geometry: GeometryProxy) -> CGSize {
        let originalSize = image.size
        let viewSize = geometry.size
        
        // Berechne das Seitenverhältnis
        let imageRatio = originalSize.width / originalSize.height
        let viewRatio = viewSize.width / viewSize.height
        
        // Bestimme die Anpassungsgröße
        var fitSize: CGSize
        if imageRatio > viewRatio {
            // Bild ist breiter als der View
            fitSize = CGSize(
                width: viewSize.width,
                height: viewSize.width / imageRatio
            )
        } else {
            // Bild ist höher als der View
            fitSize = CGSize(
                width: viewSize.height * imageRatio,
                height: viewSize.height
            )
        }
        
        return fitSize
    }
    
    public var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Toolbar
                HStack {
                    Button(action: { cleanupAndDismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) von \(files.count)")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(action: { showMetadata.toggle() }) {
                        Image(systemName: "sidebar.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("i", modifiers: .command)
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 16)
                
                // Content
                GeometryReader { geometry in
                    ZStack {
                        if isLoading {
                            ProgressView()
                        } else if let image = loadedImage {
                            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                                ZStack {
                                    Color.clear
                                        .frame(
                                            width: max(imageSize.width * scale, geometry.size.width),
                                            height: max(imageSize.height * scale, geometry.size.height)
                                        )
                                    
                                    Image(nsImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: imageSize.width, height: imageSize.height)
                                        .scaleEffect(scale, anchor: zoomPoint)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            if scale <= 1.0 {
                                                if let event = NSApp.currentEvent {
                                                    zoomPoint = calculateZoomPoint(from: event, in: geometry)
                                                }
                                            }
                                            let delta = value / lastScale
                                            lastScale = value
                                            let newScale = scale * delta
                                            scale = min(max(newScale, 0.5), 10.0)
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                            if scale <= 1.0 {
                                                zoomPoint = .center
                                            }
                                        }
                                )
                                .gesture(
                                    TapGesture(count: 2)
                                        .onEnded {
                                            if scale <= 1.0 {
                                                if let event = NSApp.currentEvent {
                                                    zoomPoint = calculateZoomPoint(from: event, in: geometry)
                                                }
                                            } else {
                                                zoomPoint = .center
                                            }
                                            
                                            withAnimation(.spring()) {
                                                if scale > 1.1 {
                                                    scale = 1.0
                                                } else {
                                                    scale = 2.0
                                                }
                                            }
                                        }
                                )
                            }
                            .coordinateSpace(name: "scroll")
                            .scrollDisabled(scale <= 1.0)
                            .onChange(of: geometry.size) { newSize in
                                viewSize = newSize
                                imageSize = calculateImageSize(for: image, in: geometry)
                            }
                            .onAppear {
                                viewSize = geometry.size
                                imageSize = calculateImageSize(for: image, in: geometry)
                            }
                        } else if isPDF, let pdfDocument = pdfDocument {
                            PDFKitView(document: pdfDocument)
                        } else if isCurrentFileVideo {
                            if let player = player {
                                VideoPlayerView(player: player)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: iconForFile(files[currentIndex]))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 200, height: 200)
                                    .foregroundStyle(.secondary)
                                
                                Text(files[currentIndex].name)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 40)
            }
            
            // Metadata Sidebar
            if showMetadata {
                HStack {
                    Spacer()
                    VStack {
                        FileMetadataView(file: files[currentIndex])
                            .frame(maxHeight: .infinity)
                            .id(files[currentIndex].id)
                        Spacer()
                    }
                    .frame(width: 300)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .trailing))
                }
            }
            
            // Star Rating (Always on top)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    StarRatingView(maximumRating: 5, rating: $currentRating) { newRating in
                        ratingManager.setRating(newRating, for: files[currentIndex].path)
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(20)
                }
            }
        }
        .onAppear {
            currentRating = ratingManager.getRating(for: files[currentIndex].path)
            setupKeyboardShortcuts()
            loadContent()
        }
        .onDisappear {
            cleanupAndDismiss()
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            loadContent()
            currentRating = ratingManager.getRating(for: files[currentIndex].path)
            onNavigate(currentIndex)
            scale = 1.0
        }
        .onChange(of: currentRating) { oldValue, newValue in
            ratingManager.setRating(newValue, for: files[currentIndex].path)
        }
        .onChange(of: ratingManager.lastUpdated) { oldValue, newValue in
            currentRating = ratingManager.getRating(for: files[currentIndex].path)
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private func setupKeyboardShortcuts() {
        // Erst alten Monitor entfernen, falls vorhanden
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        // Neuen Monitor erstellen
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC-Taste
                self.cleanupAndDismiss()
                return nil
            } else if event.keyCode == 49 && self.isCurrentFileVideo { // Leertaste für Video
                DispatchQueue.main.async {
                    if let player = self.player {
                        if player.timeControlStatus == .playing {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }
                }
                return nil
            } else if event.keyCode == 123 { // Pfeil links
                if event.modifierFlags.contains(.option) && self.isCurrentFileVideo {
                    // Video zurückspulen
                    DispatchQueue.main.async {
                        if let player = self.player {
                            let currentTime = player.currentTime()
                            let newTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(-10, preferredTimescale: 1))
                            player.seek(to: newTime)
                        }
                    }
                } else {
                    // Vorherige Datei
                    if self.currentIndex > 0 {
                        self.previousFile()
                    }
                }
                return nil
            } else if event.keyCode == 124 { // Pfeil rechts
                if event.modifierFlags.contains(.option) && self.isCurrentFileVideo {
                    // Video vorspulen
                    DispatchQueue.main.async {
                        if let player = self.player {
                            let currentTime = player.currentTime()
                            let newTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(10, preferredTimescale: 1))
                            player.seek(to: newTime)
                        }
                    }
                } else {
                    // Nächste Datei
                    if self.currentIndex < self.files.count - 1 {
                        self.nextFile()
                    }
                }
                return nil
            } else if event.keyCode == 51 { // Delete-Taste
                self.deleteCurrentFile()
                return nil
            } else if let number = event.characters?.first,
                      let rating = Int(String(number)),
                      rating >= 0 && rating <= 5 {
                self.currentRating = rating
                self.ratingManager.setRating(rating, for: self.files[self.currentIndex].path)
                return nil
            }
            return event
        }
    }
    
    private func showNotification(message: String) {
        let notification = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 40),
            styleMask: [.nonactivatingPanel, .titled],
            backing: .buffered,
            defer: false
        )
        
        notification.backgroundColor = .clear
        notification.isOpaque = false
        notification.hasShadow = true
        notification.level = .floating
        notification.isFloatingPanel = true
        notification.becomesKeyOnlyIfNeeded = true
        notification.ignoresMouseEvents = true
        notification.title = ""  // Leerer Titel für Panel mit .titled
        
        let visualEffect = NSVisualEffectView(frame: notification.contentView!.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        notification.contentView?.addSubview(visualEffect)
        
        let label = NSTextField(frame: NSRect(x: 20, y: 10, width: 360, height: 20))
        label.stringValue = message
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 13)
        label.alignment = .center
        visualEffect.addSubview(label)
        
        // Positioniere das Fenster am oberen Bildschirmrand
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            notification.setFrameOrigin(NSPoint(
                x: screenFrame.midX - notification.frame.width / 2,
                y: screenFrame.maxY - notification.frame.height - 20
            ))
        }
        
        notification.orderFront(nil)
        
        // Schließe die Benachrichtigung nach 1.5 Sekunden
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                notification.animator().alphaValue = 0
            }, completionHandler: {
                notification.close()
                notification.orderOut(nil)
            })
        }
    }
    
    private func deleteCurrentFile() {
        @AppStorage("requireDeleteConfirmation") var requireDeleteConfirmation = true
        
        func performDelete() {
            let fileManager = FileManager.default
            let url = URL(fileURLWithPath: files[currentIndex].path)
            let fileName = files[currentIndex].name
            
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
                
                // Datei aus der Liste entfernen
                files.remove(at: currentIndex)
                
                // Wenn es die letzte Datei war, schließen wir die Vollbildansicht
                if files.isEmpty {
                    cleanupAndDismiss()
                } else {
                    // Wenn wir am Ende der Liste sind, gehen wir einen zurück
                    if currentIndex >= files.count {
                        currentIndex = files.count - 1
                    }
                    // Lade explizit den neuen Content
                    loadContent()
                    onNavigate(currentIndex)
                    
                    // Zeige Benachrichtigung nur wenn keine Bestätigung erforderlich war
                    if !requireDeleteConfirmation {
                        showNotification(message: "'\(fileName)' wurde in den Papierkorb verschoben")
                    }
                }
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Fehler beim Löschen"
                errorAlert.informativeText = error.localizedDescription
                errorAlert.alertStyle = .warning
                errorAlert.runModal()
            }
        }
        
        if requireDeleteConfirmation {
            let alert = NSAlert()
            alert.messageText = "Datei löschen"
            alert.informativeText = "Möchtest du wirklich '\(files[currentIndex].name)' in den Papierkorb verschieben?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Löschen")
            alert.addButton(withTitle: "Abbrechen")
            
            if alert.runModal() == .alertFirstButtonReturn {
                performDelete()
            }
        } else {
            performDelete()
        }
    }
    
    private func loadContent() {
        isLoading = true
        loadedImage = nil
        pdfDocument = nil
        
        // Cleanup vorheriges Video
        if let player = player {
            DispatchQueue.main.async {
                player.pause()
                self.player = nil
            }
        }
        
        if isCurrentFileVideo {
            DispatchQueue.main.async {
                let url = URL(fileURLWithPath: self.files[self.currentIndex].path)
                self.player = AVPlayer(url: url)
                self.player?.play()
                self.isLoading = false
            }
        } else if isPDF {
            if let document = PDFDocument(url: URL(fileURLWithPath: files[currentIndex].path)) {
                pdfDocument = document
                isLoading = false
            } else {
                isLoading = false
            }
        } else {
            Task {
                if let image = await FilePreviewGenerator.shared.generatePreview(
                    for: files[currentIndex].path,
                    size: NSSize(width: 1920, height: 1080)
                ) {
                    await MainActor.run {
                        loadedImage = image
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }
            }
        }
    }
    
    private func previousFile() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
            }
        }
    }
    
    private func nextFile() {
        if currentIndex < files.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        }
    }
    
    private func iconForFile(_ file: FileItem) -> String {
        // Prüfe zuerst, ob es ein Ordner ist
        if (try? FileManager.default.attributesOfItem(atPath: file.path)[.type] as? FileAttributeType) == .typeDirectory {
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
    
    private func loadVideo() {
        guard currentIndex >= 0, currentIndex < files.count else { return }
        
        DispatchQueue.main.async {
            let url = URL(fileURLWithPath: files[currentIndex].path)
            self.player = AVPlayer(url: url)
            self.player?.play()
        }
    }
    
    private func cleanupVideo() {
        DispatchQueue.main.async {
            self.player?.pause()
            self.player = nil
        }
    }
    
    private func togglePlayPause() {
        DispatchQueue.main.async {
            if let player = self.player {
                if player.timeControlStatus == .playing {
                    player.pause()
                } else {
                    player.play()
                }
            }
        }
    }
    
    private func seekVideo(by seconds: Float64) {
        DispatchQueue.main.async {
            guard let player = self.player else { return }
            let currentTime = player.currentTime()
            let newTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(seconds, preferredTimescale: 1))
            player.seek(to: newTime)
        }
    }
}

// Erweitere die StarRatingView um einen Tooltip
struct StarRatingView: View {
    let maximumRating: Int
    @Binding var rating: Int
    let onRatingChanged: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maximumRating, id: \.self) { number in
                Image(systemName: number <= rating ? "star.fill" : "star")
                    .foregroundStyle(number <= rating ? .yellow : .gray)
                    .font(.title2)
                    .onTapGesture {
                        rating = number
                        onRatingChanged(number)
                    }
            }
        }
        .help("Bewertung: Klicken oder Tasten 0-5 drücken")
    }
}

struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument?
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous // Kontinuierliches Scrollen
        pdfView.displayDirection = .vertical // Vertikales Scrollen
        pdfView.backgroundColor = .clear
        pdfView.maxScaleFactor = 4.0 // Maximaler Zoom
        pdfView.minScaleFactor = 0.25 // Minimaler Zoom
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
} 
