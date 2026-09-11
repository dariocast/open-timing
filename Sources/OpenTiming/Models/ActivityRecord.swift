import Foundation

public struct ActivityRecord: Identifiable, Codable, Hashable, Sendable {
    public var id: Int64?
    public var appName: String
    public var bundleIdentifier: String
    public var windowTitle: String
    public var url: String?
    public var domain: String?
    public var startDate: Date
    public var endDate: Date
    public var duration: TimeInterval
    public var categoryId: UUID?
    public var projectId: UUID?
    public var isIdle: Bool
    public var createdAt: Date
    
    public init(
        id: Int64? = nil,
        appName: String,
        bundleIdentifier: String,
        windowTitle: String,
        url: String? = nil,
        domain: String? = nil,
        startDate: Date = Date(),
        endDate: Date = Date(),
        duration: TimeInterval = 0,
        categoryId: UUID? = nil,
        projectId: UUID? = nil,
        isIdle: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.windowTitle = windowTitle
        self.url = url
        self.domain = domain
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.categoryId = categoryId
        self.projectId = projectId
        self.isIdle = isIdle
        self.createdAt = createdAt
    }
}

public struct ActivityStats: Sendable {
    public let totalTime: TimeInterval
    public let productiveTime: TimeInterval
    public let neutralTime: TimeInterval
    public let distractingTime: TimeInterval
    public let idleTime: TimeInterval
    public let productivityScore: Double // 0 to 100%
    public let appBreakdown: [AppTimeBreakdown]
    public let categoryBreakdown: [CategoryTimeBreakdown]
    public let projectBreakdown: [ProjectTimeBreakdown]
    public let hourlyBreakdown: [HourlyTimeBreakdown]
    
    public init(
        totalTime: TimeInterval = 0,
        productiveTime: TimeInterval = 0,
        neutralTime: TimeInterval = 0,
        distractingTime: TimeInterval = 0,
        idleTime: TimeInterval = 0,
        productivityScore: Double = 0,
        appBreakdown: [AppTimeBreakdown] = [],
        categoryBreakdown: [CategoryTimeBreakdown] = [],
        projectBreakdown: [ProjectTimeBreakdown] = [],
        hourlyBreakdown: [HourlyTimeBreakdown] = []
    ) {
        self.totalTime = totalTime
        self.productiveTime = productiveTime
        self.neutralTime = neutralTime
        self.distractingTime = distractingTime
        self.idleTime = idleTime
        self.productivityScore = productivityScore
        self.appBreakdown = appBreakdown
        self.categoryBreakdown = categoryBreakdown
        self.projectBreakdown = projectBreakdown
        self.hourlyBreakdown = hourlyBreakdown
    }
}

public struct AppTimeBreakdown: Identifiable, Sendable {
    public var id: String { bundleIdentifier }
    public let appName: String
    public let bundleIdentifier: String
    public let totalDuration: TimeInterval
    public let percentage: Double
    public let categoryId: UUID?
    public let categoryColorHex: String?
}

public struct CategoryTimeBreakdown: Identifiable, Sendable {
    public var id: UUID { categoryId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
    public let categoryId: UUID?
    public let name: String
    public let colorHex: String
    public let iconName: String
    public let totalDuration: TimeInterval
    public let percentage: Double
    public let productivityScore: Int
}

public struct ProjectTimeBreakdown: Identifiable, Sendable {
    public var id: UUID { projectId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
    public let projectId: UUID?
    public let name: String
    public let colorHex: String
    public let totalDuration: TimeInterval
    public let percentage: Double
}

public struct HourlyTimeBreakdown: Identifiable, Sendable {
    public var id: Int { hour }
    public let hour: Int // 0 to 23
    public let date: Date
    public let totalDuration: TimeInterval
    public let productiveDuration: TimeInterval
    public let distractingDuration: TimeInterval
    public let neutralDuration: TimeInterval
}
