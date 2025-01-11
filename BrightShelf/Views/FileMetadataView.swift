import SwiftUI
import AppKit
import AVFoundation
import ImageIO

struct FileMetadataView: View {
    let file: FileItem
    @State private var icon: NSImage?
    @State private var fileAttributes: [FileAttributeKey: Any]?
    @State private var mediaDimensions: String?
    @State private var cameraInfo: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header mit Icon und Name
                HStack(spacing: 12) {
                    if let icon = icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.headline)
                        Text(file.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 8)
                
                if let attributes = fileAttributes {
                    VStack(alignment: .leading, spacing: 16) {
                        MetadataSection(title: "Allgemein") {
                            MetadataRow(label: "Größe", value: formatFileSize(attributes[.size] as? Int64 ?? 0))
                            if let created = attributes[.creationDate] as? Date {
                                MetadataRow(label: "Erstellt", value: formatDate(created))
                            }
                            if let modified = attributes[.modificationDate] as? Date {
                                MetadataRow(label: "Geändert", value: formatDate(modified))
                            }
                            if let accessed = attributes[.modificationDate] as? Date {
                                MetadataRow(label: "Zuletzt geändert", value: formatDate(accessed))
                            }
                            if let dimensions = mediaDimensions {
                                MetadataRow(label: "Dimensionen", value: dimensions)
                            }
                            if let camera = cameraInfo {
                                MetadataRow(label: "Kamera", value: camera)
                            }
                            MetadataRow(label: "Erweiterung", value: (file.path as NSString).pathExtension)
                        }
                        
                        MetadataSection(title: "Berechtigungen") {
                            if let posixPermissions = attributes[.posixPermissions] as? Int {
                                MetadataRow(label: "POSIX", value: String(format: "%o", posixPermissions))
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadFileData()
        }
        .onChange(of: file) { _, _ in
            loadFileData()
        }
    }
    
    private func loadFileData() {
        // Icon laden
        icon = NSWorkspace.shared.icon(forFile: file.path)
        
        // Attribute laden
        do {
            fileAttributes = try FileManager.default.attributesOfItem(atPath: file.path)
            
            // Medien-Dimensionen und Kamera-Informationen laden
            Task {
                await loadMediaDimensions()
                await loadCameraInfo(for: URL(fileURLWithPath: file.path))
            }
        } catch {
            print("Fehler beim Laden der Dateiattribute: \(error)")
        }
    }
    
    private func loadMediaDimensions() async {
        let ext = (file.path as NSString).pathExtension.lowercased()
        
        await MainActor.run {
            if ["jpg", "jpeg", "png", "gif", "bmp", "tiff"].contains(ext) {
                // Bild-Dimensionen
                if let image = NSImage(contentsOfFile: file.path) {
                    let size = image.size
                    mediaDimensions = "\(Int(size.width)) × \(Int(size.height))"
                }
            }
        }
        
        if ["mp4", "mov", "m4v", "avi"].contains(ext) {
            // Video-Dimensionen
            let asset = AVAsset(url: URL(fileURLWithPath: file.path))
            if let track = try? await asset.loadTracks(withMediaType: .video).first {
                let size = try? await track.load(.naturalSize)
                if let size = size {
                    await MainActor.run {
                        mediaDimensions = "\(Int(size.width)) × \(Int(size.height))"
                    }
                }
            }
        } else {
            await MainActor.run {
                mediaDimensions = nil
            }
        }
    }
    

    private func loadCameraInfo(for url: URL) async {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            cameraInfo = "Kamera nicht bekannt"
            return
        }

        // Exif- und TIFF-Daten auslesen
        let exif = metadata[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = metadata[kCGImagePropertyTIFFDictionary] as? [CFString: Any]

        // Kamera-Marke und Modell abrufen, indem die entsprechenden Schlüssel direkt als Strings verwenden
        let make = exif?["Make" as CFString] as? String ?? tiff?["Make" as CFString] as? String
        let model = exif?["Model" as CFString] as? String ?? tiff?["Model" as CFString] as? String

        // Kamera-Info zusammenstellen
        if let make = make, let model = model {
            cameraInfo = "\(make) \(model)"
        } else {
            cameraInfo = "Kamera nicht bekannt"
        }
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Hilfviews für die Strukturierung
struct MetadataSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            content
                .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}
