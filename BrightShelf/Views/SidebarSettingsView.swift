import SwiftUI
import UniformTypeIdentifiers

struct SidebarSettingsView: View {
    @StateObject private var sidebarManager = SidebarManager.shared
    @State private var showingDeleteAlert = false
    @State private var pathToDelete: String?
    @State private var draggingPath: String?
    @State private var dropPosition: DropPosition = .none
    
    enum DropPosition {
        case none
        case before(String)
        case after(String)
    }
    
    var body: some View {
        Form {
            Section {
                Text("Verwalte die Ordner, die in der Seitenleiste angezeigt werden.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            
            Section("Seitenleiste") {
                let allPaths = sidebarManager.applicationPaths + sidebarManager.sidebarLinks
                if allPaths.isEmpty {
                    ContentUnavailableView(
                        "Keine Ordner",
                        systemImage: "folder",
                        description: Text("Füge Ordner hinzu, um sie in der Seitenleiste anzuzeigen.")
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(allPaths, id: \.self) { path in
                            VStack(spacing: 0) {
                                if case .before(let targetPath) = dropPosition, targetPath == path {
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(height: 2)
                                        .padding(.vertical, 8)
                                }
                                
                                SidebarFolderItemView(
                                    path: path,
                                    icon: "folder",
                                    onDelete: {
                                        pathToDelete = path
                                        showingDeleteAlert = true
                                    }
                                )
                                .opacity(path == draggingPath ? 0.5 : 1.0)
                                .onDrag {
                                    draggingPath = path
                                    return NSItemProvider(object: path as NSString)
                                }
                                .onDrop(of: [.text], delegate: FolderDropDelegate(
                                    item: path,
                                    items: allPaths,
                                    draggedItem: $draggingPath,
                                    dropPosition: $dropPosition,
                                    sidebarManager: sidebarManager
                                ))
                                
                                if case .after(let targetPath) = dropPosition, targetPath == path {
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(height: 2)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
                
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.message = "Ordner auswählen"
                    panel.prompt = "Hinzufügen"
                    
                    if panel.runModal() == .OK {
                        if let path = panel.url?.path {
                            withAnimation {
                                sidebarManager.sidebarLinks.append(path)
                                sidebarManager.saveSidebarLinks()
                            }
                        }
                    }
                }) {
                    Label("Ordner hinzufügen", systemImage: "plus")
                }
            }
        }
        .formStyle(.grouped)
        .alert("Ordner entfernen", isPresented: $showingDeleteAlert, presenting: pathToDelete) { path in
            Button("Abbrechen", role: .cancel) {}
            Button("Entfernen", role: .destructive) {
                withAnimation {
                    if let index = sidebarManager.applicationPaths.firstIndex(of: path) {
                        sidebarManager.applicationPaths.remove(at: index)
                        sidebarManager.saveApplicationPaths()
                    } else if let index = sidebarManager.sidebarLinks.firstIndex(of: path) {
                        sidebarManager.sidebarLinks.remove(at: index)
                        sidebarManager.saveSidebarLinks()
                    }
                }
            }
        } message: { path in
            Text("Möchtest du '\(URL(fileURLWithPath: path).lastPathComponent)' wirklich aus der Seitenleiste entfernen?")
        }
    }
}

struct FolderDropDelegate: DropDelegate {
    let item: String
    let items: [String]
    @Binding var draggedItem: String?
    @Binding var dropPosition: SidebarSettingsView.DropPosition
    let sidebarManager: SidebarManager
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem,
              draggedItem != item else { return }
        
        let dropPoint = info.location.y
        let threshold: CGFloat = 20 // Bereich für oben/unten Erkennung
        
        withAnimation(.easeInOut(duration: 0.15)) {
            if dropPoint < threshold {
                dropPosition = .before(item)
            } else {
                dropPosition = .after(item)
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if case .before(let target) = dropPosition, target == item {
                dropPosition = .none
            } else if case .after(let target) = dropPosition, target == item {
                dropPosition = .none
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = self.draggedItem else { return false }
        
        withAnimation {
            let fromIndex = items.firstIndex(of: draggedItem)!
            let toIndex = items.firstIndex(of: item)!
            let targetIndex: Int
            
            if case .after = dropPosition {
                targetIndex = toIndex + 1
            } else {
                targetIndex = toIndex
            }
            
            // Erstelle neue Arrays basierend auf der Bewegung
            var newApplicationPaths = sidebarManager.applicationPaths
            var newSidebarLinks = sidebarManager.sidebarLinks
            
            // Entferne das Element aus der ursprünglichen Liste
            if newApplicationPaths.contains(draggedItem) {
                newApplicationPaths.removeAll { $0 == draggedItem }
            } else {
                newSidebarLinks.removeAll { $0 == draggedItem }
            }
            
            // Füge das Element an der neuen Position ein
            if newApplicationPaths.contains(item) {
                let adjustedIndex = min(targetIndex, newApplicationPaths.count)
                newApplicationPaths.insert(draggedItem, at: adjustedIndex)
            } else {
                let adjustedIndex = min(targetIndex, newSidebarLinks.count)
                newSidebarLinks.insert(draggedItem, at: adjustedIndex)
            }
            
            // Aktualisiere die Listen
            sidebarManager.applicationPaths = newApplicationPaths
            sidebarManager.sidebarLinks = newSidebarLinks
            sidebarManager.saveApplicationPaths()
            sidebarManager.saveSidebarLinks()
        }
        
        self.draggedItem = nil
        self.dropPosition = .none
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct SidebarFolderItemView: View {
    let path: String
    let icon: String
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(URL(fileURLWithPath: path).lastPathComponent)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
                    .opacity(isHovered ? 1 : 0)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.blue.opacity(0.5), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.blue.opacity(0.1) : Color.clear)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
} 
