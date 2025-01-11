import SwiftUI

struct SettingsView: View {
    private let tabs = ["Allgemein", "Seitenleiste", "Formate", "Über"]
    @State private var selectedTab = "Allgemein"
    
    var body: some View {
        HSplitView {
            List(tabs, id: \.self, selection: $selectedTab) { tab in
                HStack {
                    Image(systemName: iconFor(tab: tab))
                    Text(tab)
                }
                .tag(tab)
            }
            .listStyle(SidebarListStyle())
            .frame(width: 150)
            
            Group {
                switch selectedTab {
                case "Allgemein":
                    GeneralSettingsView()
                case "Seitenleiste":
                    SidebarSettingsView()
                case "Formate":
                    FormatBuilderView()
                case "Über":
                    AboutView()
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func iconFor(tab: String) -> String {
        switch tab {
        case "Allgemein": return "gear"
        case "Seitenleiste": return "sidebar.left"
        case "Formate": return "textformat"
        case "Über": return "info.circle"
        default: return ""
        }
    }
}

#Preview {
    SettingsView()
} 