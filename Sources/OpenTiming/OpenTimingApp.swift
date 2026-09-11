import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        ActivityTracker.shared.startTrackingEngine()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}

@main
struct OpenTimingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        WindowGroup("OpenTiming Dashboard", id: "main_dashboard") {
            MainDashboardView(appState: appState)
        }
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
        }
        
        MenuBarExtra {
            MenuBarView(appState: appState) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title.contains("OpenTiming") }) {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    openWindow(id: "main_dashboard")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                if let curr = appState.currentSession, appState.isTracking {
                    Text(TimeFormatter.format(duration: curr.currentDuration, short: true))
                        .font(.system(size: 11, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
