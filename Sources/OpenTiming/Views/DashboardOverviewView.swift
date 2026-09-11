import SwiftUI
import Charts

public struct DashboardOverviewView: View {
    @ObservedObject var appState: AppState
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Bar with Date Switcher
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Overview")
                            .font(.system(size: 26, weight: .bold))
                        Text(TimeFormatter.formatFullDate(date: appState.selectedDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
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
                
                // Accessibility Warning Banner if not granted
                if !appState.accessibilityGranted {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility Permissions Required")
                                .font(.headline)
                            Text("OpenTiming needs Accessibility permission to detect window titles, active documents, and browser tabs.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Grant Permission") {
                            appState.requestAccessibility()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Top Metrics Cards
                HStack(spacing: 16) {
                    MetricCard(
                        title: "Total Tracked",
                        value: TimeFormatter.format(duration: appState.todayStats.totalTime, short: true),
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Productive",
                        value: TimeFormatter.format(duration: appState.todayStats.productiveTime, short: true),
                        icon: "bolt.fill",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Neutral",
                        value: TimeFormatter.format(duration: appState.todayStats.neutralTime, short: true),
                        icon: "minus.circle.fill",
                        color: .secondary
                    )
                    
                    MetricCard(
                        title: "Distracting",
                        value: TimeFormatter.format(duration: appState.todayStats.distractingTime, short: true),
                        icon: "flame.fill",
                        color: .red
                    )
                    
                    ProductivityScoreCard(score: appState.todayStats.productivityScore)
                }
                
                // Hourly Activity Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hourly Activity")
                        .font(.headline)
                    
                    Chart {
                        ForEach(appState.todayStats.hourlyBreakdown) { item in
                            BarMark(
                                x: .value("Hour", "\(item.hour):00"),
                                y: .value("Productive", item.productiveDuration / 60.0)
                            )
                            .foregroundStyle(Color.green)
                            
                            BarMark(
                                x: .value("Hour", "\(item.hour):00"),
                                y: .value("Neutral", item.neutralDuration / 60.0)
                            )
                            .foregroundStyle(Color.gray.opacity(0.7))
                            
                            BarMark(
                                x: .value("Hour", "\(item.hour):00"),
                                y: .value("Distracting", item.distractingDuration / 60.0)
                            )
                            .foregroundStyle(Color.red)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { val in
                            AxisValueLabel {
                                if let min = val.as(Double.self) {
                                    Text("\(Int(min))m")
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Two Columns: Top Applications & Top Categories
                HStack(alignment: .top, spacing: 16) {
                    // Top Apps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Applications")
                            .font(.headline)
                        
                        if appState.todayStats.appBreakdown.isEmpty {
                            EmptyStateCard(text: "No applications recorded today.")
                        } else {
                            VStack(spacing: 8) {
                                ForEach(appState.todayStats.appBreakdown.prefix(6)) { app in
                                    HStack(spacing: 10) {
                                        AppIconView(bundleIdentifier: app.bundleIdentifier, size: 28)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(app.appName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                            
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.secondary.opacity(0.15))
                                                        .frame(height: 6)
                                                    Capsule()
                                                        .fill(app.categoryColorHex.map { Color(hex: $0) } ?? Color.blue)
                                                        .frame(width: max(4, geo.size.width * CGFloat(app.percentage / 100.0)), height: 6)
                                                }
                                            }
                                            .frame(height: 6)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(TimeFormatter.format(duration: app.totalDuration, short: true))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("\(Int(app.percentage))%")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Top Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.headline)
                        
                        if appState.todayStats.categoryBreakdown.isEmpty {
                            EmptyStateCard(text: "No categories recorded today.")
                        } else {
                            VStack(spacing: 8) {
                                ForEach(appState.todayStats.categoryBreakdown) { cat in
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: cat.colorHex).opacity(0.2))
                                                .frame(width: 28, height: 28)
                                            Image(systemName: cat.iconName)
                                                .foregroundColor(Color(hex: cat.colorHex))
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(cat.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.secondary.opacity(0.15))
                                                        .frame(height: 6)
                                                    Capsule()
                                                        .fill(Color(hex: cat.colorHex))
                                                        .frame(width: max(4, geo.size.width * CGFloat(cat.percentage / 100.0)), height: 6)
                                                }
                                            }
                                            .frame(height: 6)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(TimeFormatter.format(duration: cat.totalDuration, short: true))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("\(Int(cat.percentage))%")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Components

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct ProductivityScoreCard: View {
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Productivity")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundColor(scoreColor)
                    .font(.system(size: 14))
            }
            
            Text("\(Int(score))%")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var scoreColor: Color {
        if score >= 70 { return .green }
        if score >= 40 { return .orange }
        return .red
    }
}

struct EmptyStateCard: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}
