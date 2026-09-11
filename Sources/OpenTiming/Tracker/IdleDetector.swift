import Foundation
import CoreGraphics

public final class IdleDetector: Sendable {
    public static let shared = IdleDetector()
    
    public init() {}
    
    /// Returns the number of seconds since the last user input (mouse move, click, keyboard stroke)
    public func getIdleTimeSeconds() -> TimeInterval {
        // CGEventType(rawValue: ~0)! represents any event type
        let anyEvent = CGEventType(rawValue: ~0)!
        let idleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
        return max(0, idleTime)
    }
    
    /// Checks if the user is currently idle given a threshold in seconds (default 120s / 2m)
    public func isIdle(thresholdSeconds: TimeInterval = 120) -> Bool {
        return getIdleTimeSeconds() >= thresholdSeconds
    }
}
