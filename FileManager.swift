import Foundation

class FileSystemManager {
    static let shared = FileSystemManager()
    
    private init() {}
    
    func getVisibleFolders() -> [URL] {
        let fileManager = FileManager.default
        guard let homeURL = fileManager.homeDirectoryForCurrentUser as URL? else {
            return []
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: homeURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            return contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            }
        } catch {
            print("Fehler beim Laden der Ordner: \(error)")
            return []
        }
    }
    
    func getContents(of folder: URL) -> [FileItem] {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            return contents.map { url in
                FileItem(
                    id: UUID(),
                    name: url.lastPathComponent,
                    path: url.path
                )
            }
        } catch {
            print("Fehler beim Laden der Dateien: \(error)")
            return []
        }
    }
}
