import Foundation
import AppKit

public struct CurrentSessionSnapshot: Sendable {
    public let appName: String
    public let bundleIdentifier: String
    public let windowTitle: String
    public let url: String?
    public let domain: String?
    public let startDate: Date
    public let currentDuration: TimeInterval
    public let categoryId: UUID?
    public let projectId: UUID?
    public let isIdle: Bool
}

public final class ActivityTracker: @unchecked Sendable {
    public static let shared = ActivityTracker()
    
    public private(set) var isTracking: Bool = true
    public var idleThresholdSeconds: TimeInterval = 120 // 2 minutes default
    
    private var timer: Timer?
    private var currentRecord: ActivityRecord?
    private var cachedRules: [TrackingRule] = []
    
    private let queue = DispatchQueue(label: "com.opentiming.tracker", qos: .utility)
    
    public var onSnapshotUpdate: (@Sendable (CurrentSessionSnapshot?) -> Void)?
    
    public init() {
        reloadRules()
        setupWorkspaceObservers()
    }
    
    public func reloadRules() {
        cachedRules = DatabaseManager.shared.getRules()
    }
    
    public func start() {
        guard !isTracking else { return }
        isTracking = true
        startTimer()
    }
    
    public func pause() {
        isTracking = false
        stopTimer()
        flushCurrentRecord()
        onSnapshotUpdate?(nil)
    }
    
    public func toggleTracking() {
        if isTracking {
            pause()
        } else {
            start()
        }
    }
    
    public func startTrackingEngine() {
        reloadRules()
        startTimer()
    }
    
    private func startTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.heartbeat()
            }
        }
    }
    
    private func stopTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            self?.timer = nil
        }
    }
    
    private func setupWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            self?.queue.async {
                self?.heartbeat()
            }
        }
        
        center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.queue.async {
                self?.handleScreenSleep()
            }
        }
        
        center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.queue.async {
                self?.heartbeat()
            }
        }
    }
    
    private func handleScreenSleep() {
        flushCurrentRecord()
        onSnapshotUpdate?(nil)
    }
    
    public func flushCurrentRecord() {
        queue.sync {
            guard let record = currentRecord else { return }
            if record.duration >= 1.0 {
                if let _ = record.id {
                    DatabaseManager.shared.updateActivityRecord(record)
                } else {
                    _ = DatabaseManager.shared.insertActivityRecord(record)
                }
            }
            currentRecord = nil
        }
    }
    
    private func heartbeat() {
        guard isTracking else { return }
        
        let now = Date()
        let isUserIdle = IdleDetector.shared.isIdle(thresholdSeconds: idleThresholdSeconds)
        
        guard let windowInfo = WindowInspector.shared.inspectActiveWindow() else {
            return
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let matched = RuleEngine.shared.match(
                appName: windowInfo.appName,
                bundleIdentifier: windowInfo.bundleIdentifier,
                windowTitle: windowInfo.windowTitle,
                domain: windowInfo.domain,
                url: windowInfo.url,
                rules: self.cachedRules
            )
            
            // Check if current active session matches previous one
            if var record = self.currentRecord {
                let sameApp = record.bundleIdentifier == windowInfo.bundleIdentifier
                let sameTitle = record.windowTitle == windowInfo.windowTitle
                let sameDomain = record.domain == windowInfo.domain
                let sameIdle = record.isIdle == isUserIdle
                
                if sameApp && sameTitle && sameDomain && sameIdle {
                    // Extend current session
                    record.endDate = now
                    record.duration = max(1.0, record.endDate.timeIntervalSince(record.startDate))
                    self.currentRecord = record
                    
                    // Periodically persist long running activity every 10 seconds
                    if Int(record.duration) % 10 == 0 {
                        if record.id != nil {
                            DatabaseManager.shared.updateActivityRecord(record)
                        } else {
                            record.id = DatabaseManager.shared.insertActivityRecord(record)
                            self.currentRecord = record
                        }
                    }
                    
                    let snapshot = CurrentSessionSnapshot(
                        appName: record.appName,
                        bundleIdentifier: record.bundleIdentifier,
                        windowTitle: record.windowTitle,
                        url: record.url,
                        domain: record.domain,
                        startDate: record.startDate,
                        currentDuration: record.duration,
                        categoryId: record.categoryId,
                        projectId: record.projectId,
                        isIdle: record.isIdle
                    )
                    self.onSnapshotUpdate?(snapshot)
                    return
                } else {
                    // Session changed! Flush old record
                    if record.duration >= 1.0 {
                        if record.id != nil {
                            DatabaseManager.shared.updateActivityRecord(record)
                        } else {
                            _ = DatabaseManager.shared.insertActivityRecord(record)
                        }
                    }
                }
            }
            
            // Start brand new record
            var newRecord = ActivityRecord(
                appName: windowInfo.appName,
                bundleIdentifier: windowInfo.bundleIdentifier,
                windowTitle: windowInfo.windowTitle,
                url: windowInfo.url,
                domain: windowInfo.domain,
                startDate: now,
                endDate: now.addingTimeInterval(1.0),
                duration: 1.0,
                categoryId: matched.categoryId,
                projectId: matched.projectId,
                isIdle: isUserIdle,
                createdAt: now
            )
            
            let id = DatabaseManager.shared.insertActivityRecord(newRecord)
            newRecord.id = id
            self.currentRecord = newRecord
            
            let snapshot = CurrentSessionSnapshot(
                appName: newRecord.appName,
                bundleIdentifier: newRecord.bundleIdentifier,
                windowTitle: newRecord.windowTitle,
                url: newRecord.url,
                domain: newRecord.domain,
                startDate: newRecord.startDate,
                currentDuration: 1.0,
                categoryId: newRecord.categoryId,
                projectId: newRecord.projectId,
                isIdle: newRecord.isIdle
            )
            self.onSnapshotUpdate?(snapshot)
        }
    }
}
