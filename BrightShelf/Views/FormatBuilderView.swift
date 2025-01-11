import SwiftUI
import Foundation

struct FormatBuilderView: View {
    @AppStorage("customFormats") private var customFormats = Data()
    @State private var currentFormat: String = ""
    @State private var showingPreview: Bool = false
    @State private var previewDate = Date()
    @State private var storedFormats: [String] = []
    
    private let formatBlocks = [
        FormatBlock(name: "Jahr", format: "yyyy"),
        FormatBlock(name: "Monat", format: "MM"),
        FormatBlock(name: "Tag", format: "dd"),
        FormatBlock(name: "Stunde", format: "HH"),
        FormatBlock(name: "Minute", format: "mm"),
        FormatBlock(name: "Sekunde", format: "ss"),
        FormatBlock(name: "-", format: "-"),
        FormatBlock(name: "_", format: "_"),
        FormatBlock(name: ":", format: ":"),
        FormatBlock(name: ".", format: "."),
        FormatBlock(name: " ", format: " ")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Format-Builder Header - reduziertes Padding
            Text("Format-Builder")
                .font(.title2)  // Kleinere Schriftgröße
                .padding(.bottom, 8)  // Reduziertes Padding
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // Hauptbereich - reduzierte Abstände
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {  // Reduzierter Abstand zwischen Elementen
                    // Verfügbare Bausteine
                    GroupBox("Verfügbare Bausteine") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {  // Reduzierter Abstand
                                ForEach(formatBlocks) { block in
                                    Button(action: {
                                        withAnimation {
                                            currentFormat += block.format
                                        }
                                    }) {
                                        Text(block.name)
                                            .font(.system(size: 12))  // Kleinere Schrift
                                            .padding(.horizontal, 8)  // Reduziertes Padding
                                            .padding(.vertical, 4)    // Reduziertes Padding
                                    }
                                    .buttonStyle(.borderless)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)  // Kleinerer Radius
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                            }
                            .padding(6)  // Reduziertes Padding
                        }
                    }
                    
                    // Aktuelles Format - ähnliche Anpassungen
                    GroupBox("Aktuelles Format") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                if currentFormat.isEmpty {
                                    Text("Leer")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                } else {
                                    let formatParts = parseFormat(currentFormat)
                                    ForEach(Array(formatParts.enumerated()), id: \.element) { index, part in
                                        Text(part)
                                            .font(.system(size: 12))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.blue.opacity(0.1))
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                withAnimation {
                                                    removeFormatPart(at: index)
                                                }
                                            }
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(6)
                        }
                    }
                    
                    // Vorschau - kompakter
                    GroupBox("Vorschau:") {
                        VStack(alignment: .leading, spacing: 8) {  // Reduzierter Abstand
                            HStack {
                                Text("Format:")
                                    .foregroundColor(.secondary)
                                Text(currentFormat.isEmpty ? "-" : currentFormat)
                            }
                            .font(.system(size: 12))
                            HStack {
                                Text("Beispiel:")
                                    .foregroundColor(.secondary)
                                Text(formatPreview)
                            }
                            .font(.system(size: 12))
                        }
                        .padding(8)  // Reduziertes Padding
                    }
                    
                    // Aktionen - kompakter
                    HStack(spacing: 12) {  // Reduzierter Abstand
                        Button(action: {
                            withAnimation {
                                currentFormat = ""
                            }
                        }) {
                            HStack(spacing: 6) {  // Reduzierter Abstand
                                Image(systemName: "arrow.counterclockwise")
                                Text("Zurücksetzen")
                            }
                            .font(.system(size: 12))
                            .frame(minWidth: 32, minHeight: 32)  // Kleinere Mindestgröße
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                if !currentFormat.isEmpty && !storedFormats.contains(currentFormat) {
                                    storedFormats.append(currentFormat)
                                    saveFormats()
                                    currentFormat = ""
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Format speichern")
                            }
                            .font(.system(size: 12))
                            .frame(minWidth: 32, minHeight: 32)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentFormat.isEmpty)
                        .help("Aktuelles Format zur Liste hinzufügen")
                    }
                    .padding(.vertical, 4)
                    
                    // Gespeicherte Formate - kompakter
                    if !storedFormats.isEmpty {
                        GroupBox("Gespeicherte Formate") {
                            ScrollView {
                                VStack(spacing: 2) {  // Reduzierter Abstand
                                    ForEach(storedFormats, id: \.self) { format in
                                        HStack {
                                            Text(format)
                                                .font(.system(size: 12))
                                            Spacer()
                                            Button(action: {
                                                withAnimation {
                                                    if let index = storedFormats.firstIndex(of: format) {
                                                        storedFormats.remove(at: index)
                                                        saveFormats()
                                                    }
                                                }
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 12))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(4)
                            }
                            .frame(maxHeight: 120)  // Reduzierte maximale Höhe
                        }
                    }
                }
                .padding(16)  // Reduziertes Padding
            }
        }
        .onAppear {
            loadFormats()
        }
    }
    
    private func loadFormats() {
        if let decoded = try? JSONDecoder().decode([String].self, from: customFormats) {
            storedFormats = decoded
        }
    }
    
    private func saveFormats() {
        if let encoded = try? JSONEncoder().encode(storedFormats) {
            customFormats = encoded
        }
    }
    
    private var formatPreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = currentFormat
        return formatter.string(from: previewDate)
    }
    
    // Hilfsfunktion zum Parsen des Formats in einzelne Blöcke
    private func parseFormat(_ format: String) -> [String] {
        var parts: [String] = []
        var currentPart = ""
        
        for char in format {
            switch char {
            case "y":
                if currentPart.first == "y" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "M":
                if currentPart.first == "M" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "d":
                if currentPart.first == "d" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "H":
                if currentPart.first == "H" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "m":
                if currentPart.first == "m" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "s":
                if currentPart.first == "s" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            default:
                if !currentPart.isEmpty { parts.append(currentPart) }
                currentPart = String(char)
            }
        }
        
        if !currentPart.isEmpty {
            parts.append(currentPart)
        }
        
        return parts.map { part in
            switch part {
            case "yyyy": return "Jahr"
            case "MM": return "Monat"
            case "dd": return "Tag"
            case "HH": return "Stunde"
            case "mm": return "Minute"
            case "ss": return "Sekunde"
            default: return part
            }
        }
    }
    
    // Neue Funktion zum Entfernen eines Format-Teils
    private func removeFormatPart(at index: Int) {
        let originalParts = getOriginalParts(currentFormat)
        
        if index < originalParts.count {
            var newParts = originalParts
            newParts.remove(at: index)
            currentFormat = newParts.joined()
        }
    }
    
    // Hilfsfunktion zum Erhalten der originalen Format-Teile
    private func getOriginalParts(_ format: String) -> [String] {
        var parts: [String] = []
        var currentPart = ""
        
        for char in format {
            switch char {
            case "y":
                if currentPart.first == "y" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "M":
                if currentPart.first == "M" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "d":
                if currentPart.first == "d" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "H":
                if currentPart.first == "H" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "m":
                if currentPart.first == "m" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            case "s":
                if currentPart.first == "s" {
                    currentPart.append(char)
                } else {
                    if !currentPart.isEmpty { parts.append(currentPart) }
                    currentPart = String(char)
                }
            default:
                if !currentPart.isEmpty { parts.append(currentPart) }
                currentPart = String(char)
            }
        }
        
        if !currentPart.isEmpty {
            parts.append(currentPart)
        }
        
        return parts
    }
}

struct FormatBlock: Identifiable {
    let id = UUID()
    let name: String
    let format: String
} 
