import SwiftUI

public struct MainDashboardView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        NavigationSplitView {
            List(AppState.NavigationSection.allCases, id: \.self, selection: $appState.selectedTab) { section in
                NavigationLink(value: section) {
                    Label(section.rawValue, systemImage: section.iconName)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
            
            // Bottom Sidebar Live Widget
            VStack(alignment: .leading, spacing: 6) {
                Divider()
                HStack(spacing: 8) {
                    Circle()
                        .fill(appState.isTracking ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(appState.isTracking ? "Live Tracker Active" : "Tracker Paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        appState.toggleTracking()
                    }) {
                        Image(systemName: appState.isTracking ? "pause.fill" : "play.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        } detail: {
            switch appState.selectedTab {
            case .dashboard:
                DashboardOverviewView(appState: appState)
            case .timeline:
                TimelineView(appState: appState)
            case .projects:
                CategoriesProjectsView(appState: appState)
            case .rules:
                RulesView(appState: appState)
            case .settings:
                SettingsView(appState: appState)
            }
        }
        .frame(minWidth: 850, minHeight: 560)
    }
}
