import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            Section("Über BrightShelf") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
                LabeledContent("Copyright", value: "© 2024 BrightShelf")
            }
            
            Section("Credits") {
                Text("Entwickelt von Linus-Fin Leupold")
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Link("GitHub Repository", destination: URL(string: "https://github.com/yourusername/BrightShelf")!)
                Link("Fehler melden", destination: URL(string: "https://github.com/yourusername/BrightShelf/issues")!)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
} 