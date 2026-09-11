import SwiftUI

public struct TimelineView: View {
    @ObservedObject var appState: AppState
    @State private var selectedActivityId: Int64?
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header: Date switcher & Search
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timeline")
                        .font(.system(size: 24, weight: .bold))
                    Text("\(appState.timelineActivities.count) activity events recorded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search app, title, or domain...", text: $appState.searchQuery)
                        .textFieldStyle(.plain)
                        .onChange(of: appState.searchQuery) { _, _ in
                            appState.refreshCurrentDateStats()
                        }
                    if !appState.searchQuery.isEmpty {
                        Button(action: {
                            appState.searchQuery = ""
                            appState.refreshCurrentDateStats()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(width: 260)
                
                // Date switcher
                HStack(spacing: 4) {
                    Button(action: { appState.previousDay() }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Today") {
                        appState.setToday()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { appState.nextDay() }) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            // Visual Timeline Ribbon (24-hour visual bar)
            VStack(alignment: .leading, spacing: 6) {
                Text("24h Activity Distribution")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                
                VisualTimelineRibbon(activities: appState.timelineActivities, categories: appState.categories)
                    .frame(height: 36)
                    .padding(.horizontal, 24)
                
                // Hour markings
                HStack {
                    Text("00:00")
                    Spacer()
                    Text("06:00")
                    Spacer()
                    Text("12:00")
                    Spacer()
                    Text("18:00")
                    Spacer()
                    Text("23:59")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Activity Log Stream
            if appState.timelineActivities.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No activities found for this date")
                        .font(.headline)
                    Text("Open other apps and OpenTiming will automatically record your activity.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(appState.timelineActivities.reversed()) { activity in
                        ActivityRowView(
                            activity: activity,
                            categories: appState.categories,
                            projects: appState.projects,
                            onCategoryChange: { newCatId in
                                appState.updateActivityRecordCategory(record: activity, categoryId: newCatId)
                            },
                            onProjectChange: { newProjId in
                                appState.updateActivityRecordProject(record: activity, projectId: newProjId)
                            }
                        )
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

// MARK: - Visual Ribbon

struct VisualTimelineRibbon: View {
    let activities: [ActivityRecord]
    let categories: [ActivityCategory]
    
    private var categoryMap: [UUID: ActivityCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.12))
                
                // Segments
                ForEach(activities) { act in
                    let startRatio = ratio(for: act.startDate)
                    let endRatio = ratio(for: act.endDate)
                    let width = max(2, (endRatio - startRatio) * geo.size.width)
                    let offset = startRatio * geo.size.width
                    let color = act.categoryId.flatMap { categoryMap[$0]?.colorHex }.map { Color(hex: $0) } ?? (act.isIdle ? Color.gray : Color.orange)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: width, height: geo.size.height)
                        .offset(x: offset)
                        .help("\(act.appName) - \(act.windowTitle) (\(TimeFormatter.format(duration: act.duration, short: true)))")
                }
            }
        }
    }
    
    private func ratio(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let totalSeconds = (hour * 3600) + (minute * 60) + second
        return CGFloat(totalSeconds) / 86400.0
    }
}

// MARK: - Activity Row

struct ActivityRowView: View {
    let activity: ActivityRecord
    let categories: [ActivityCategory]
    let projects: [Project]
    let onCategoryChange: (UUID?) -> Void
    let onProjectChange: (UUID?) -> Void
    
    private var categoryMap: [UUID: ActivityCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    
    private var currentCategory: ActivityCategory? {
        activity.categoryId.flatMap { categoryMap[$0] }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            AppIconView(bundleIdentifier: activity.bundleIdentifier, size: 30)
            
            // App Name & Window Title & Domain
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(activity.appName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let domain = activity.domain, !domain.isEmpty {
                        Text("• \(domain)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if activity.isIdle {
                        Text("IDLE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.secondary)
                            .cornerRadius(4)
                    }
                }
                
                Text(activity.windowTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time Range (e.g. 14:02 - 14:15)
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(TimeFormatter.formatClock(date: activity.startDate)) - \(TimeFormatter.formatClock(date: activity.endDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(TimeFormatter.format(duration: activity.duration, short: true))
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .frame(width: 110, alignment: .trailing)
            
            // Category Selector Menu
            Menu {
                Button("None (Uncategorized)") {
                    onCategoryChange(nil)
                }
                Divider()
                ForEach(categories) { cat in
                    Button(action: { onCategoryChange(cat.id) }) {
                        Label(cat.name, systemImage: cat.iconName)
                    }
                }
            } label: {
                if let cat = currentCategory {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: cat.colorHex))
                            .frame(width: 8, height: 8)
                        Text(cat.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: cat.colorHex).opacity(0.15))
                    .cornerRadius(6)
                } else {
                    Text("Uncategorized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .menuStyle(.borderlessButton)
            .frame(width: 140, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
