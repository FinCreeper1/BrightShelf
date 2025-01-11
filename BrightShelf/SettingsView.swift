import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 30) {
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
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                
                Spacer()
            }
            .padding(.top, 20)
            
            // Einstellungen
            VStack(alignment: .leading, spacing: 20) {
                // Erscheinungsbild
                GroupBox(label: Text("Erscheinungsbild").bold()) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { newValue in
                            settings.toggleAppearance(isDark: newValue)
                        }
                        .padding(.vertical, 5)
                }
                
                // Systemeinstellungen
                GroupBox(label: Text("System").bold()) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Bei Anmeldung starten", isOn: $settings.launchAtLogin)
                            .onChange(of: settings.launchAtLogin) { newValue in
                                settings.toggleLaunchAtLogin(enable: newValue)
                            }
                        
                        Toggle("Benachrichtigungen erlauben", isOn: $settings.notificationsEnabled)
                            .onChange(of: settings.notificationsEnabled) { newValue in
                                settings.toggleNotifications(enable: newValue)
                            }
                    }
                    .padding(.vertical, 5)
                }
                
                // Über
                GroupBox(label: Text("Über BrightShelf").bold()) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Version: 1.0.0")
                            .foregroundColor(.secondary)
                        Text("© 2024 BrightShelf")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 500, height: 400)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 1, green: 1, blue: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    SettingsView()
} 