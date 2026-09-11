import SwiftUI
import AppKit

public struct MenuBarView: View {
    @ObservedObject var appState: AppState
    let onOpenDashboard: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header / Current App Status
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    appState.toggleTracking()
                }) {
                    Image(systemName: appState.isTracking ? "pause.circle.fill" : "play.circle.fill")
                        .foregroundColor(appState.isTracking ? .orange : .green)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help(appState.isTracking ? "Pause Tracking" : "Resume Tracking")
            }
            
            Divider()
            
            // Current Active Window & App
            if let current = appState.currentSession, appState.isTracking {
                HStack(spacing: 10) {
                    AppIconView(bundleIdentifier: current.bundleIdentifier, size: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.appName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(current.windowTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(TimeFormatter.format(duration: current.currentDuration, short: true))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: appState.isTracking ? "hourglass" : "pause.fill")
                        .foregroundColor(.secondary)
                    Text(appState.isTracking ? "Detecting activity..." : "Tracking is paused")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // Today's Quick Summary
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(TimeFormatter.format(duration: appState.todayStats.totalTime, short: true))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Productivity")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(appState.todayStats.productivityScore))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                }
            }
            .padding(.horizontal, 4)
            
            Divider()
            
            // Action Buttons
            HStack {
                Button(action: onOpenDashboard) {
                    Label("Open Dashboard", systemImage: "macwindow")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .help("Quit OpenTiming")
            }
        }
        .padding(14)
        .frame(width: 300)
    }
    
    private var statusColor: Color {
        guard appState.isTracking else { return .red }
        if appState.isIdle { return .gray }
        return .green
    }
    
    private var statusText: String {
        guard appState.isTracking else { return "PAUSED" }
        if appState.isIdle { return "IDLE" }
        return "TRACKING ACTIVE"
    }
    
    private var scoreColor: Color {
        let s = appState.todayStats.productivityScore
        if s >= 70 { return .green }
        if s >= 40 { return .orange }
        return .red
    }
}
