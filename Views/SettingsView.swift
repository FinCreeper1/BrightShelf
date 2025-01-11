import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    
    // Farben für Light/Dark Mode
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.16) : Color(red: 0.98, green: 0.98, blue: 0.98)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.2, green: 0.2, blue: 0.3)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color(red: 0.3, green: 0.3, blue: 0.4)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.18) : .white
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.5, blue: 1.0),
                                Color(red: 0.0, green: 0.4, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Einstellungen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(headerBackgroundColor)
            
            // Tab Buttons
            HStack(spacing: 0) {
                ForEach(["Allgemein", "Benachrichtigungen", "Datenschutz", "Über"], id: \.self) { tab in
                    TabButton(
                        title: tab,
                        icon: iconFor(tab: tab),
                        isSelected: selectedTab == indexFor(tab: tab),
                        action: { selectedTab = indexFor(tab: tab) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Content Area
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case 0:
                        AllgemeinTab(isDarkMode: $isDarkMode, settings: settings)
                    case 1:
                        BenachrichtigungenTab(settings: settings)
                    case 2:
                        DatenschutzTab()
                    case 3:
                        UeberTab()
                    default:
                        EmptyView()
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 600, height: 450)
        .background(backgroundColor)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onChange(of: isDarkMode) { newValue in
            settings.toggleAppearance(isDark: newValue)
        }
    }
    
    private func iconFor(tab: String) -> String {
        switch tab {
        case "Allgemein": return "gear"
        case "Benachrichtigungen": return "bell"
        case "Datenschutz": return "lock"
        case "Über": return "info.circle"
        default: return ""
        }
    }
    
    private func indexFor(tab: String) -> Int {
        switch tab {
        case "Allgemein": return 0
        case "Benachrichtigungen": return 1
        case "Datenschutz": return 2
        case "Über": return 3
        default: return 0
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.3, blue: 0.4))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.5, blue: 1.0),
                                Color(red: 0.0, green: 0.4, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.18) : .white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.2, green: 0.2, blue: 0.3)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(textColor)
            
            content
                .padding(16)
                .background(cardBackgroundColor)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct AllgemeinTab: View {
    @Binding var isDarkMode: Bool
    let settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup(title: "Erscheinungsbild") {
                Toggle("Dark Mode", isOn: $isDarkMode)
                    .onChange(of: isDarkMode) { newValue in
                        settings.toggleAppearance(isDark: newValue)
                    }
            }
            
            SettingsGroup(title: "Verhalten") {
                Toggle("Bei Anmeldung starten", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.toggleLaunchAtLogin(enable: $0) }
                ))
            }
        }
    }
}

struct BenachrichtigungenTab: View {
    let settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup(title: "Benachrichtigungen") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Benachrichtigungen erlauben", isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: { settings.toggleNotifications(enable: $0) }
                    ))
                    
                    if settings.notificationsEnabled {
                        Divider()
                        Toggle("Erinnerungen", isOn: .constant(true))
                        Toggle("Updates", isOn: .constant(true))
                    }
                }
            }
        }
    }
}

struct DatenschutzTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup(title: "Datenschutz") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Nutzungsdaten teilen", isOn: .constant(false))
                    Toggle("Crash Reports senden", isOn: .constant(true))
                }
            }
        }
    }
}

struct UeberTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup(title: "Über BrightShelf") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version: 1.0.0")
                        .foregroundColor(.secondary)
                    Text("© 2024 BrightShelf")
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Button("Nach Updates suchen") {
                        // Hier kommt später die Update-Logik
                    }
                }
            }
            
            SettingsGroup(title: "Credits") {
                Text("Entwickelt von Linus-Fin Leupold")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
} 
