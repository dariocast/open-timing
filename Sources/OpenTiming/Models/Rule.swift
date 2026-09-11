import Foundation

public enum RuleField: String, Codable, CaseIterable, Sendable {
    case appName = "App Name"
    case bundleIdentifier = "Bundle ID"
    case windowTitle = "Window Title"
    case domain = "Web Domain"
    case url = "Full URL"
}

public enum RuleMatchType: String, Codable, CaseIterable, Sendable {
    case contains = "Contains"
    case exact = "Equals"
    case startsWith = "Starts With"
    case endsWith = "Ends With"
    case regex = "Regex"
}

public struct TrackingRule: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var targetField: RuleField
    public var matchType: RuleMatchType
    public var pattern: String
    public var targetCategoryId: UUID?
    public var targetProjectId: UUID?
    public var priority: Int
    public var isEnabled: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        targetField: RuleField,
        matchType: RuleMatchType,
        pattern: String,
        targetCategoryId: UUID? = nil,
        targetProjectId: UUID? = nil,
        priority: Int = 0,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.targetField = targetField
        self.matchType = matchType
        self.pattern = pattern
        self.targetCategoryId = targetCategoryId
        self.targetProjectId = targetProjectId
        self.priority = priority
        self.isEnabled = isEnabled
    }
    
    public func matches(
        appName: String,
        bundleIdentifier: String,
        windowTitle: String,
        domain: String?,
        url: String?
    ) -> Bool {
        guard isEnabled else { return false }
        
        let valueToTest: String
        switch targetField {
        case .appName:
            valueToTest = appName
        case .bundleIdentifier:
            valueToTest = bundleIdentifier
        case .windowTitle:
            valueToTest = windowTitle
        case .domain:
            valueToTest = domain ?? ""
        case .url:
            valueToTest = url ?? ""
        }
        
        if valueToTest.isEmpty && !pattern.isEmpty {
            return false
        }
        
        let needle = pattern.lowercased()
        let haystack = valueToTest.lowercased()
        
        switch matchType {
        case .contains:
            return haystack.contains(needle)
        case .exact:
            return haystack == needle
        case .startsWith:
            return haystack.hasPrefix(needle)
        case .endsWith:
            return haystack.hasSuffix(needle)
        case .regex:
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: valueToTest.utf16.count)
                return regex.firstMatch(in: valueToTest, options: [], range: range) != nil
            } catch {
                return false
            }
        }
    }
}
