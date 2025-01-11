import SwiftUI
import Cocoa
import AVFoundation
import PDFKit
import UniformTypeIdentifiers

@MainActor
class FilePreviewGenerator {
    static let shared = FilePreviewGenerator()
    private let imageCache = NSCache<NSString, NSImage>()
    private let workQueue = DispatchQueue(label: "com.brightshelf.thumbnails", qos: .userInitiated)
    
    let supportedTypes: Set<String> = ["jpg", "jpeg", "png", "gif", "heic", "webp", "mp4", "mov", "m4v", "pdf"]
    
    private init() {
        imageCache.countLimit = 500
    }
    
    // Hilfsfunktion zum Berechnen der korrekten Größe
    private func calculateAspectFitSize(imageSize: CGSize, boundingSize: CGSize) -> CGSize {
        let widthRatio = boundingSize.width / imageSize.width
        let heightRatio = boundingSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        
        return CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
    }
    
    private func generateVideoThumbnail(for url: URL, size: CGSize) async -> NSImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let time = CMTime(value: 0, timescale: 600)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            
            // Berechne das korrekte Seitenverhältnis
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let targetSize = calculateAspectFitSize(imageSize: imageSize, boundingSize: size)
            
            let thumbnail = NSImage(cgImage: cgImage, size: targetSize)
            
            // Erstelle ein neues Bild mit der vollen Zielgröße
            let finalImage = NSImage(size: size)
            finalImage.lockFocus()
            defer { finalImage.unlockFocus() }
            
            // Fülle den Hintergrund
            NSColor.clear.set()
            NSRect(origin: .zero, size: size).fill()
            
            // Berechne die Position für das zentrierte Bild
            let xOffset = (size.width - targetSize.width) / 2
            let yOffset = (size.height - targetSize.height) / 2
            
            // Zeichne das Thumbnail
            thumbnail.draw(in: NSRect(x: xOffset, y: yOffset,
                                    width: targetSize.width, height: targetSize.height),
                         from: NSRect(origin: .zero, size: targetSize),
                         operation: .copy,
                         fraction: 1.0)
            
            // Play-Symbol zeichnen
            if let playSymbol = NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: nil) {
                let symbolSize = min(targetSize.width, targetSize.height) * 0.3
                let symbolRect = NSRect(
                    x: (size.width - symbolSize) / 2,
                    y: (size.height - symbolSize) / 2,
                    width: symbolSize,
                    height: symbolSize
                )
                playSymbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 0.8)
            }
            
            return finalImage
        } catch {
            print("Video-Thumbnail-Generierung fehlgeschlagen: \(error)")
            return nil
        }
    }
    
    private func generatePDFPreview(for url: URL, size: CGSize) -> NSImage? {
        guard let pdfDocument = PDFDocument(url: url) else { return nil }
        guard let pdfPage = pdfDocument.page(at: 0) else { return nil }
        
        // PDF-Seitengröße ermitteln
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let imageSize = CGSize(width: pageRect.width, height: pageRect.height)
        let targetSize = calculateAspectFitSize(imageSize: imageSize, boundingSize: size)
        
        // Erstelle das finale Bild
        let finalImage = NSImage(size: size)
        finalImage.lockFocus()
        defer { finalImage.unlockFocus() }
        
        // Fülle den Hintergrund
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        
        // Berechne die Position für das zentrierte Bild
        let xOffset = (size.width - targetSize.width) / 2
        let yOffset = (size.height - targetSize.height) / 2
        
        // PDF-Seite rendern
        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            
            // Korrigierte Transformation
            context.translateBy(x: xOffset, y: yOffset)
            context.scaleBy(x: targetSize.width / pageRect.width, 
                           y: targetSize.height / pageRect.height)
            
            pdfPage.draw(with: .mediaBox, to: context)
            context.restoreGState()
            
            // PDF-Symbol hinzufügen
            if let pdfSymbol = NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil) {
                let symbolSize = min(targetSize.width, targetSize.height) * 0.2
                let symbolRect = NSRect(
                    x: xOffset + targetSize.width - symbolSize - 8,  // Rechts ausgerichtet
                    y: yOffset + 8,                                  // Unten ausgerichtet
                    width: symbolSize,
                    height: symbolSize
                )
                pdfSymbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 0.8)
            }
        }
        
        return finalImage
    }
    
    private func generateImagePreview(from path: String, size: CGSize) -> NSImage? {
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        
        let sourceSize = image.size
        let targetSize = calculateAspectFitSize(imageSize: sourceSize, boundingSize: size)
        let finalImage = NSImage(size: size)
        
        finalImage.lockFocus()
        defer { finalImage.unlockFocus() }
        
        // Fülle den Hintergrund
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        
        // Berechne die Position für das zentrierte Bild
        let xOffset = (size.width - targetSize.width) / 2
        let yOffset = (size.height - targetSize.height) / 2
        
        if let ctx = NSGraphicsContext.current {
            ctx.imageInterpolation = .high
            image.draw(in: NSRect(x: xOffset, y: yOffset,
                                width: targetSize.width, height: targetSize.height),
                      from: NSRect(origin: .zero, size: sourceSize),
                      operation: .copy,
                      fraction: 1.0)
        }
        
        return finalImage
    }
    
    func generatePreview(
        for path: String,
        size: CGSize,
        thumbnailOnly: Bool = false
    ) async -> NSImage? {
        let cacheKey = "\(path)_\(size.width)x\(size.height)" as NSString
        
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension.lowercased()
        
        let preview: NSImage?
        
        switch ext {
        case "mp4", "mov", "m4v":
            preview = await generateVideoThumbnail(for: url, size: size)
            
        case "pdf":
            preview = await Task.detached {
                return self.generatePDFPreview(for: url, size: size)
            }.value
            
        default:
            preview = await Task.detached {
                return self.generateImagePreview(from: path, size: size)
            }.value
        }
        
        if let preview = preview {
            imageCache.setObject(preview, forKey: cacheKey)
        }
        
        return preview
    }
} 