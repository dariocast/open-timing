import Foundation

public final class RuleEngine: Sendable {
    public static let shared = RuleEngine()
    
    public init() {}
    
    /// Evaluates a window/app context against an ordered list of rules and returns matching category and project
    public func match(
        appName: String,
        bundleIdentifier: String,
        windowTitle: String,
        domain: String?,
        url: String?,
        rules: [TrackingRule]
    ) -> (categoryId: UUID?, projectId: UUID?) {
        for rule in rules where rule.isEnabled {
            if rule.matches(
                appName: appName,
                bundleIdentifier: bundleIdentifier,
                windowTitle: windowTitle,
                domain: domain,
                url: url
            ) {
                return (rule.targetCategoryId, rule.targetProjectId)
            }
        }
        return (nil, nil)
    }
}
