import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Ensure the app runs as a standard regular macOS GUI app with Dock icon and windows
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        ActivityTracker.shared.startTrackingEngine()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            // Ensure first window is brought to front
            for window in NSApp.windows where !(window.className.contains("StatusBar") || window.className.contains("Popover")) {
                window.makeKeyAndOrderFront(nil)
                window.center()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        if !flag {
            for window in sender.windows where !(window.className.contains("StatusBar") || window.className.contains("Popover")) {
                window.makeKeyAndOrderFront(nil)
                return true
            }
        }
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in the Menu Bar even when the Dashboard window is closed
        return false
    }
}

@main
struct OpenTimingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        Window("OpenTiming", id: "main_dashboard") {
            MainDashboardView(appState: appState)
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1000, height: 680)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("Open Dashboard") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main_dashboard")
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
        
        MenuBarExtra {
            MenuBarView(appState: appState) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main_dashboard")
                for window in NSApp.windows where !(window.className.contains("StatusBar") || window.className.contains("Popover")) {
                    window.makeKeyAndOrderFront(nil)
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
