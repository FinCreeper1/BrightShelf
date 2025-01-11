import SwiftUI

struct MainView: View {
    @State private var selectedFolder: String?
    @State private var files: [FileItem] = []
    @Environment(\.colorScheme) var colorScheme
    
    // Farben für Light/Dark Mode mit verbessertem Kontrast
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.98, green: 0.98, blue: 1.0)
    }
    
    private var sidebarColor: Color {
        colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.16) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Neue Titelleiste
            HStack {
                Text("BrightShelf")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(textColor)
                
                Spacer()
                
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
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.97))
            
            // Bestehende HSplitView
            HSplitView {
                // Linke Spalte (Sidebar)
                SidebarView(selectedFolder: $selectedFolder)
                    .frame(minWidth: 220, maxWidth: 300)
                    .background(sidebarColor)
                
                // Mittlere Spalte (Dateianzeige)
                FileGridView(selectedFolder: $selectedFolder, files: $files)
                    .frame(minWidth: 580)
                    .background(backgroundColor)
                
                // Rechte Spalte (Detailansicht)
                FileDetailView()
                    .frame(width: 320)
                    .background(backgroundColor)
            }
        }
    }
    private func openSettings() {
        let controller = NSWindowController(
            window: NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
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
            
            // Behalte eine Referenz auf den Controller
            NSApp.windows.first?.windowController = controller
        }
    }
    struct SidebarView: View {
        @Binding var selectedFolder: String?
        @State private var userFolders: [URL] = []
        @State private var username: String = ""
        @Environment(\.colorScheme) var colorScheme
        
        private var textColor: Color {
            colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Benutzer-Header
                HStack {
                    Text(username)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.97))
                
                // Kompaktere Ordnerliste
                List(userFolders, id: \.path) { folder in
                    FolderItemView(folder: folder, isSelected: selectedFolder == folder.path)
                        .onTapGesture {
                            selectedFolder = folder.path
                        }
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .listRowSeparator(.hidden)
                }
                .listStyle(SidebarListStyle())
            }
            .onAppear {
                loadUsername()
                loadUserFolders()
            }
        }
        
        private func loadUsername() {
            username = NSUserName()
        }
        
        private func loadUserFolders() {
            userFolders = FileSystemManager.shared.getVisibleFolders()
        }
    }
    
    struct FolderItemView: View {
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
        
        // Hintergrundfarbe basierend auf Zustand
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
        
        // Textfarbe
        private var textColor: Color {
            colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
        }
    }
    
    struct FileGridView: View {
        @Binding var selectedFolder: String?
        @Binding var files: [FileItem]
        
        // Optimierte Grid-Layout für bessere Lesbarkeit
        let columns = [
            GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
        ]
        
        var body: some View {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(files) { file in
                        FileItemView(file: file)
                    }
                }
                .padding(20)
            }
            .onChange(of: selectedFolder) { newFolder in
                if let folder = newFolder {
                    loadFiles(from: folder)
                }
            }
        }
        
        private func loadFiles(from path: String) {
            if let url = URL(string: "file://" + path) {
                files = FileSystemManager.shared.getContents(of: url)
            }
        }
    }
    
    struct FileItemView: View {
        let file: FileItem
        @Environment(\.colorScheme) var colorScheme
        @State private var isHovered = false
        
        var body: some View {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: iconForFile(file))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundColor(.blue)
                    .padding(.top, 12)
                
                // Filename
                Text(file.name)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ?
                          Color(white: 0.2).opacity(isHovered ? 0.5 : 0.3) :
                            Color(white: 1).opacity(isHovered ? 1 : 0.8))
                    .shadow(color: Color.black.opacity(0.1), radius: isHovered ? 4 : 2, x: 0, y: 1)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        
        private func iconForFile(_ file: FileItem) -> String {
            let ext = (file.name as NSString).pathExtension.lowercased()
            switch ext {
            case "pdf": return "doc.fill"
            case "jpg", "jpeg", "png": return "photo.fill"
            case "mp4", "mov": return "video.fill"
            case "doc", "docx": return "doc.text.fill"
            case "xls", "xlsx": return "chart.bar.doc.horizontal.fill"
            case "txt": return "doc.text.fill"
            default: return "doc"
            }
        }
    }
    
    struct FileDetailView: View {
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                
                Text("Keine Datei ausgewählt")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    struct FileItem: Identifiable {
        let id: UUID
        let name: String
        let path: String
    }
    
    #Preview {
        MainView()
    }
}
