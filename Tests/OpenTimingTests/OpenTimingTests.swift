import XCTest
@testable import OpenTiming

final class OpenTimingTests: XCTestCase {
    var dbManager: DatabaseManager!
    var tempDbPath: String!
    
    override func setUp() {
        super.setUp()
        let tempDir = FileManager.default.temporaryDirectory
        tempDbPath = tempDir.appendingPathComponent("test_\(UUID().uuidString).sqlite").path
        dbManager = DatabaseManager(databasePath: tempDbPath)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: tempDbPath)
        super.tearDown()
    }
    
    func testRuleMatching() {
        let rule = TrackingRule(
            name: "VSCode Rule",
            targetField: .bundleIdentifier,
            matchType: .contains,
            pattern: "com.microsoft.VSCode",
            targetCategoryId: UUID(),
            priority: 10
        )
        
        let match = rule.matches(
            appName: "Code",
            bundleIdentifier: "com.microsoft.VSCode",
            windowTitle: "Package.swift — OpenTiming",
            domain: nil,
            url: nil
        )
        XCTAssertTrue(match)
        
        let noMatch = rule.matches(
            appName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            windowTitle: "Apple",
            domain: "apple.com",
            url: "https://apple.com"
        )
        XCTAssertFalse(noMatch)
    }
    
    func testRuleDomainMatching() {
        let rule = TrackingRule(
            name: "GitHub Rule",
            targetField: .domain,
            matchType: .contains,
            pattern: "github.com",
            targetCategoryId: UUID(),
            priority: 10
        )
        
        let match = rule.matches(
            appName: "Arc",
            bundleIdentifier: "company.thebrowser.Browser",
            windowTitle: "open-timing pull requests",
            domain: "github.com",
            url: "https://github.com/repo"
        )
        XCTAssertTrue(match)
    }
    
    func testDatabaseInsertAndFetch() {
        let catId = UUID()
        let cat = ActivityCategory(id: catId, name: "Coding", colorHex: "#007AFF", iconName: "chevron.left", productivityScore: 2)
        dbManager.saveCategory(cat)
        
        let now = Date()
        let record = ActivityRecord(
            appName: "Xcode",
            bundleIdentifier: "com.apple.dt.Xcode",
            windowTitle: "OpenTiming.xcodeproj",
            url: nil,
            domain: nil,
            startDate: now,
            endDate: now.addingTimeInterval(120),
            duration: 120,
            categoryId: catId,
            isIdle: false
        )
        
        let id = dbManager.insertActivityRecord(record)
        XCTAssertNotNil(id)
        
        let fetched = dbManager.getActivities(from: now.addingTimeInterval(-10), to: now.addingTimeInterval(200))
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.appName, "Xcode")
        XCTAssertEqual(fetched.first?.duration, 120)
        XCTAssertEqual(fetched.first?.categoryId, catId)
    }
    
    func testStatsCalculation() {
        let catId = UUID()
        let cat = ActivityCategory(id: catId, name: "Work", colorHex: "#007AFF", iconName: "bolt", productivityScore: 2)
        dbManager.saveCategory(cat)
        
        let now = Date()
        let r1 = ActivityRecord(
            appName: "Terminal",
            bundleIdentifier: "com.apple.Terminal",
            windowTitle: "zsh",
            url: nil,
            domain: nil,
            startDate: now,
            endDate: now.addingTimeInterval(300),
            duration: 300,
            categoryId: catId,
            isIdle: false
        )
        dbManager.insertActivityRecord(r1)
        
        let stats = dbManager.getStats(from: now.addingTimeInterval(-60), to: now.addingTimeInterval(400))
        XCTAssertEqual(stats.totalTime, 300)
        XCTAssertEqual(stats.productiveTime, 300)
        XCTAssertEqual(stats.productivityScore, 100.0)
        XCTAssertEqual(stats.appBreakdown.count, 1)
        XCTAssertEqual(stats.appBreakdown.first?.appName, "Terminal")
    }
    
    func testCSVExport() {
        let now = Date()
        let record = ActivityRecord(
            appName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            windowTitle: "Open Timing Docs",
            url: "https://timingapp.com",
            domain: "timingapp.com",
            startDate: now,
            endDate: now.addingTimeInterval(60),
            duration: 60
        )
        dbManager.insertActivityRecord(record)
        
        let csv = dbManager.exportActivitiesCSV(from: now.addingTimeInterval(-10), to: now.addingTimeInterval(100))
        XCTAssertTrue(csv.contains("Safari"))
        XCTAssertTrue(csv.contains("timingapp.com"))
    }
}
