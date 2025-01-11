import SwiftUI
import Foundation

class SidebarManager: ObservableObject {
    static let shared = SidebarManager()
    
    @AppStorage("applicationPaths") private var applicationPathsJSON: String = "[\"/Applications\"]"
    @AppStorage("sidebarLinksJSON") private var sidebarLinksJSON: String = "[]"
    @Published var applicationPaths: [String] = []
    @Published var sidebarLinks: [String] = []
    
    private init() {
        loadData()
    }
    
    func loadData() {
        // Lade Applications
        if let data = applicationPathsJSON.data(using: .utf8),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            applicationPaths = paths
        }
        
        // Lade Sidebar-Links
        if let data = sidebarLinksJSON.data(using: .utf8),
           let links = try? JSONDecoder().decode([String].self, from: data) {
            sidebarLinks = links
        }
    }
    
    func saveApplicationPaths() {
        if let data = try? JSONEncoder().encode(applicationPaths),
           let json = String(data: data, encoding: .utf8) {
            applicationPathsJSON = json
            objectWillChange.send()
        }
    }
    
    func saveSidebarLinks() {
        if let data = try? JSONEncoder().encode(sidebarLinks),
           let json = String(data: data, encoding: .utf8) {
            sidebarLinksJSON = json
            objectWillChange.send()
        }
    }
} 