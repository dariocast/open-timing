import Foundation
import SwiftUI
import AppKit
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    // Tracking state
    @Published public var isTracking: Bool = true
    @Published public var currentSession: CurrentSessionSnapshot?
    @Published public var isIdle: Bool = false
    @Published public var accessibilityGranted: Bool = false
    
    // Navigation & Filters
    @Published public var selectedTab: NavigationSection = .dashboard
    @Published public var selectedDate: Date = Date()
    @Published public var searchQuery: String = ""
    
    // Data
    @Published public var categories: [ActivityCategory] = []
    @Published public var projects: [Project] = []
    @Published public var rules: [TrackingRule] = []
    @Published public var todayStats: ActivityStats = ActivityStats()
    @Published public var timelineActivities: [ActivityRecord] = []
    
    // Settings
    @Published public var idleThresholdMinutes: Double = 2.0 {
        didSet {
            ActivityTracker.shared.idleThresholdSeconds = idleThresholdMinutes * 60
            UserDefaults.standard.set(idleThresholdMinutes, forKey: "idleThresholdMinutes")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    public enum NavigationSection: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case timeline = "Timeline"
        case projects = "Projects & Categories"
        case rules = "Rules"
        case settings = "Settings"
        
        public var id: String { rawValue }
        
        public var iconName: String {
            switch self {
            case .dashboard: return "chart.bar.xaxis"
            case .timeline: return "clock.arrow.circlepath"
            case .projects: return "folder"
            case .rules: return "slider.horizontal.3"
            case .settings: return "gearshape"
            }
        }
    }
    
    public init() {
        if let savedIdle = UserDefaults.standard.value(forKey: "idleThresholdMinutes") as? Double {
            self.idleThresholdMinutes = savedIdle
        }
        ActivityTracker.shared.idleThresholdSeconds = idleThresholdMinutes * 60
        
        checkAccessibility()
        loadData()
        
        // Connect tracker callbacks
        ActivityTracker.shared.onSnapshotUpdate = { [weak self] snapshot in
            Task { @MainActor [weak self] in
                self?.currentSession = snapshot
                self?.isIdle = snapshot?.isIdle ?? false
            }
        }
        
        // Periodic UI auto-refresh every 5 seconds for dashboard/timeline stats
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCurrentDateStats()
                self?.checkAccessibility()
            }
        }
    }
    
    public func checkAccessibility() {
        accessibilityGranted = WindowInspector.isAccessibilityTrusted
    }
    
    public func requestAccessibility() {
        WindowInspector.requestAccessibilityPermissions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkAccessibility()
        }
    }
    
    public func toggleTracking() {
        ActivityTracker.shared.toggleTracking()
        isTracking = ActivityTracker.shared.isTracking
        if !isTracking {
            currentSession = nil
        }
    }
    
    public func loadData() {
        categories = DatabaseManager.shared.getCategories()
        projects = DatabaseManager.shared.getProjects()
        rules = DatabaseManager.shared.getRules()
        refreshCurrentDateStats()
    }
    
    public func refreshCurrentDateStats() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        todayStats = DatabaseManager.shared.getStats(from: startOfDay, to: endOfDay)
        
        let allDayActivities = DatabaseManager.shared.getActivities(from: startOfDay, to: endOfDay)
        if searchQuery.isEmpty {
            timelineActivities = allDayActivities
        } else {
            let q = searchQuery.lowercased()
            timelineActivities = allDayActivities.filter {
                $0.appName.lowercased().contains(q) ||
                $0.windowTitle.lowercased().contains(q) ||
                ($0.domain?.lowercased().contains(q) ?? false)
            }
        }
    }
    
    public func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        refreshCurrentDateStats()
    }
    
    public func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        refreshCurrentDateStats()
    }
    
    public func setToday() {
        selectedDate = Date()
        refreshCurrentDateStats()
    }
    
    // MARK: - Category & Project CRUD
    
    public func saveCategory(_ category: ActivityCategory) {
        DatabaseManager.shared.saveCategory(category)
        ActivityTracker.shared.reloadRules()
        loadData()
    }
    
    public func deleteCategory(_ category: ActivityCategory) {
        DatabaseManager.shared.deleteCategory(id: category.id)
        ActivityTracker.shared.reloadRules()
        loadData()
    }
    
    public func saveProject(_ project: Project) {
        DatabaseManager.shared.saveProject(project)
        ActivityTracker.shared.reloadRules()
        loadData()
    }
    
    public func deleteProject(_ project: Project) {
        DatabaseManager.shared.deleteProject(id: project.id)
        ActivityTracker.shared.reloadRules()
        loadData()
    }
    
    public func saveRule(_ rule: TrackingRule) {
        DatabaseManager.shared.saveRule(rule)
        ActivityTracker.shared.reloadRules()
        loadData()
    }
    
    public func deleteRule(_ rule: TrackingRule) {
        DatabaseManager.shared.deleteRule(id: rule.id)
        ActivityTracker.shared.reloadRules()
        loadData()
    }
    
    public func reapplyRules() {
        let updated = DatabaseManager.shared.applyRulesToAllHistory(rules: rules)
        print("Updated \(updated) historical records with current rules.")
        loadData()
    }
    
    public func updateActivityRecordCategory(record: ActivityRecord, categoryId: UUID?) {
        var updated = record
        updated.categoryId = categoryId
        DatabaseManager.shared.updateActivityRecord(updated)
        refreshCurrentDateStats()
    }
    
    public func updateActivityRecordProject(record: ActivityRecord, projectId: UUID?) {
        var updated = record
        updated.projectId = projectId
        DatabaseManager.shared.updateActivityRecord(updated)
        refreshCurrentDateStats()
    }
}
