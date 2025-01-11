import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("requireDeleteConfirmation") private var requireDeleteConfirmation = true
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section("Erscheinungsbild") {
                Toggle("Dark Mode", isOn: $isDarkMode)
                    .onChange(of: isDarkMode) { oldValue, newValue in
                        settings.toggleAppearance(isDark: newValue)
                    }
            }
            
            Section("System") {
                Toggle("Bei Anmeldung starten", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { oldValue, newValue in
                        settings.toggleLaunchAtLogin(enable: newValue)
                    }
                
                Toggle("Benachrichtigungen erlauben", isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { oldValue, newValue in
                        settings.toggleNotifications(enable: newValue)
                    }
            }
            
            Section("Dateiverwaltung") {
                Toggle("Löschen bestätigen", isOn: $requireDeleteConfirmation)
                    .help("Wenn aktiviert, wird vor dem Löschen einer Datei eine Bestätigung angefordert")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
} 