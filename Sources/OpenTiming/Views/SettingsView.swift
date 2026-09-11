import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var showExportSuccess = false
    @State private var exportedFilePath = ""
    @State private var showClearConfirm = false
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings & Privacy")
                        .font(.system(size: 26, weight: .bold))
                    Text("Configure tracking preferences, offline storage, and data exports.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Privacy & Offline Promise Banner
                HStack(spacing: 14) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("100% Offline & Private")
                            .font(.headline)
                        Text("OpenTiming stores all activity logs in a local SQLite database on your Mac. No network requests, telemetry, or third-party servers are ever used.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.25), lineWidth: 1)
                )
                
                // macOS Permissions
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Permissions")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility Permissions (AXUIElement)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Required to inspect active window titles, document names, and browser URLs.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if appState.accessibilityGranted {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Granted")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        } else {
                            Button("Grant Access") {
                                appState.requestAccessibility()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
                
                // Tracking & Idle Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tracking Behavior")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Idle Detection Timeout")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(appState.idleThresholdMinutes)) minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $appState.idleThresholdMinutes, in: 1...15, step: 1)
                        
                        Text("If no mouse movement or keystrokes occur for \(Int(appState.idleThresholdMinutes)) minutes, the activity is marked as Idle and excluded from productive metrics.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
                
                // Export Data
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Export")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Button(action: exportCSV) {
                            Label("Export CSV (Excel / Numbers)", systemImage: "tablecells")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Button(action: exportJSON) {
                            Label("Export JSON (Raw Data)", systemImage: "curlybraces")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
                
                // Danger Zone
                VStack(alignment: .leading, spacing: 12) {
                    Text("Danger Zone")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear All Activity History")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Permanently deletes all recorded activity logs from the local database.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive, action: { showClearConfirm = true }) {
                            Text("Clear History")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(24)
        }
        .alert("Data Exported Successfully", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) { }
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(exportedFilePath, inFileViewerRootedAtPath: "")
            }
        } message: {
            Text("File saved to:\n\(exportedFilePath)")
        }
        .confirmationDialog("Clear All Activity Logs?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Delete All Logs", role: .destructive) {
                DatabaseManager.shared.clearAllActivities()
                appState.refreshCurrentDateStats()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All timeline logs will be erased.")
        }
    }
    
    private func exportCSV() {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let csv = DatabaseManager.shared.exportActivitiesCSV(from: start, to: Date())
        
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileURL = downloads.appendingPathComponent("OpenTiming_Export_\(Int(Date().timeIntervalSince1970)).csv")
        
        try? csv.write(to: fileURL, atomically: true, encoding: .utf8)
        exportedFilePath = fileURL.path
        showExportSuccess = true
    }
    
    private func exportJSON() {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        guard let data = DatabaseManager.shared.exportActivitiesJSON(from: start, to: Date()) else { return }
        
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileURL = downloads.appendingPathComponent("OpenTiming_Export_\(Int(Date().timeIntervalSince1970)).json")
        
        try? data.write(to: fileURL)
        exportedFilePath = fileURL.path
        showExportSuccess = true
    }
}
