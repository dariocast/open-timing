import Foundation

public struct ActivityCategory: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    public var iconName: String
    public var productivityScore: Int // -2: Very Distracting, -1: Distracting, 0: Neutral, 1: Productive, 2: Very Productive
    public var isDefault: Bool
    public var sortOrder: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        iconName: String,
        productivityScore: Int = 0,
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.productivityScore = productivityScore
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
    
    public var productivityLabel: String {
        switch productivityScore {
        case 2: return "Very Productive"
        case 1: return "Productive"
        case 0: return "Neutral"
        case -1: return "Distracting"
        case -2: return "Very Distracting"
        default: return "Neutral"
        }
    }
}

public struct Project: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var categoryId: UUID?
    public var colorHex: String
    public var iconName: String
    public var isArchived: Bool
    public var hourlyRate: Double?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        categoryId: UUID? = nil,
        colorHex: String = "#007AFF",
        iconName: String = "folder.fill",
        isArchived: Bool = false,
        hourlyRate: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.categoryId = categoryId
        self.colorHex = colorHex
        self.iconName = iconName
        self.isArchived = isArchived
        self.hourlyRate = hourlyRate
        self.createdAt = createdAt
    }
}
