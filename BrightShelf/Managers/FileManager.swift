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
            print("Lade Inhalt von: \(folder.path)")
            let contents = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey, .isApplicationKey],
                options: [.skipsHiddenFiles]
            )
            
            return contents.compactMap { url -> FileItem? in
                print("Prüfe: \(url.path)")
                
                // Ignoriere .localized Ordner
                if url.lastPathComponent.hasSuffix(".localized") {
                    return nil
                }
                
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let isPackage = (try? url.resourceValues(forKeys: [.isPackageKey]).isPackage) ?? false
                let isApplication = (try? url.resourceValues(forKeys: [.isApplicationKey]).isApplication) ?? false
                
                print("  isDirectory: \(isDirectory)")
                print("  isPackage: \(isPackage)")
                print("  isApplication: \(isApplication)")
                
                // Prüfe auf App-Bundle oder .app Endung
                if isApplication || url.pathExtension.lowercased() == "app" {
                    print("App gefunden: \(url.lastPathComponent)")
                    return FileItem(
                        id: UUID(),
                        name: url.deletingPathExtension().lastPathComponent,
                        path: url.path
                    )
                }
                
                // Für normale Dateien und Ordner
                if !isDirectory || (isDirectory && !isPackage && !isApplication) {
                    return FileItem(
                        id: UUID(),
                        name: url.lastPathComponent,
                        path: url.path
                    )
                }
                
                return nil
            }
        } catch {
            print("Fehler beim Laden der Dateien: \(error)")
            return []
        }
    }
} 