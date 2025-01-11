import SwiftUI
import AppKit

struct ContentView: View {
    @State private var isMainViewPresented = false
    @State private var username: String = NSUserName()
    
    var body: some View {
        ZStack {
            // Gradient Hintergrund
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 1, green: 1, blue: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header mit Logo und Schatten
                HStack {
                    Image(systemName: "books.vertical.fill")
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
                    
                    Text("BrightShelf")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Willkommenstext mit Animation
                Text("Willkommen zurück,")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.4))
                Text(username + "!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                    .padding(.top, 1)
                
                Spacer()
                
                // Buttons mit verbessertem Hover-Effekt
                HStack(spacing: 20) {
                    CustomButton(text: "BrightShelf öffnen", action: {
                        openMainWindow()
                    })
                    
                    CustomButton(text: "Einstellungen", action: {
                        openSettings()
                    })
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func openMainWindow() {
        let controller = NSWindowController(
            window: NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
        )
        
        if let window = controller.window {
            window.center()
            window.contentView = NSHostingView(rootView: MainView())
            window.titlebarAppearsTransparent = true
            window.title = "BrightShelf"
            window.makeKeyAndOrderFront(nil)
            
            // Fenster-Einstellungen
            window.isOpaque = false
            window.hasShadow = true
            window.styleMask.insert(.fullSizeContentView)
            
            // Behalte eine Referenz auf den Controller
            NSApp.windows.first?.windowController = controller
        }
    }
    
    private func openSettings() {
        let controller = NSWindowController(
            window: NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
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
            window.minSize = NSSize(width: 1000, height: 700)
            window.maxSize = NSSize(width: 1200, height: 800)
            NSApp.windows.first?.windowController = controller
        }
    }
}

// Neuer Custom Button mit Hover-Effekt
struct CustomButton: View {
    let text: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isHovered ? Color(red: 0.1, green: 0.6, blue: 1.0) : Color(red: 0.0, green: 0.5, blue: 1.0),
                            isHovered ? Color(red: 0.1, green: 0.5, blue: 0.9) : Color(red: 0.0, green: 0.4, blue: 0.9)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(
                    color: Color.blue.opacity(isHovered ? 0.4 : 0.3),
                    radius: isHovered ? 10 : 8,
                    x: 0,
                    y: isHovered ? 6 : 4
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .hover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// Hilfserweiterung für Hover-Effekte
extension View {
    func hover(_ mouseIsInside: @escaping (Bool) -> Void) -> some View {
        self.onHover { inside in
            mouseIsInside(inside)
        }
    }
}

#Preview {
    ContentView()
}
