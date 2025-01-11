@MainActor
class FilePreviewGenerator {
    static let shared = FilePreviewGenerator()
    private var cache = NSCache<NSString, NSImage>()
    private var tasks: [String: Task<NSImage?, Never>] = [:]
    
    private init() {}
    
    func generatePreview(for path: String, size: CGSize) async -> NSImage? {
        // Prüfe Cache
        if let cachedImage = cache.object(forKey: path as NSString) {
            return cachedImage
        }
        
        // Prüfe existierende Task
        if let existingTask = tasks[path] {
            return await existingTask.value
        }
        
        // Erstelle neue Task
        let task = Task { @MainActor in
            let preview = await generatePreviewInternal(for: path, size: size)
            if let preview = preview {
                await MainActor.run {
                    self.cache.setObject(preview, forKey: path as NSString)
                }
            }
            await MainActor.run {
                self.tasks[path] = nil
            }
            return preview
        }
        
        await MainActor.run {
            tasks[path] = task
        }
        return await task.value
    }
    
    private func generatePreviewInternal(for path: String, size: CGSize) async -> NSImage? {
        await MainActor.run {
            if let image = NSImage(contentsOfFile: path) {
                let targetSize = size
                let newImage = NSImage(size: targetSize)
                
                newImage.lockFocus()
                NSGraphicsContext.current?.imageInterpolation = .high
                image.draw(in: NSRect(origin: .zero, size: targetSize),
                          from: NSRect(origin: .zero, size: image.size),
                          operation: .copy,
                          fraction: 1.0)
                newImage.unlockFocus()
                
                return newImage
            }
            return nil
        }
    }
} 