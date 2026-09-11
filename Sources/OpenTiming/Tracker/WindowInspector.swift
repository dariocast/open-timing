import Foundation
import AppKit
import ApplicationServices

public struct WindowInfo: Sendable {
    public let appName: String
    public let bundleIdentifier: String
    public let windowTitle: String
    public let url: String?
    public let domain: String?
}

public final class WindowInspector: Sendable {
    public static let shared = WindowInspector()
    
    public init() {}
    
    /// Checks if Accessibility permissions have been granted
    public static var isAccessibilityTrusted: Bool {
        return AXIsProcessTrusted()
    }
    
    /// Requests Accessibility permissions by triggering the macOS system prompt
    public static func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Inspects the frontmost application and active window
    public func inspectActiveWindow() -> WindowInfo? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let appName = frontApp.localizedName ?? "Unknown App"
        let bundleId = frontApp.bundleIdentifier ?? "unknown.bundle"
        let pid = frontApp.processIdentifier
        
        var windowTitle = ""
        var extractedURL: String?
        var extractedDomain: String?
        
        // 1. Query Accessibility API for focused window title
        let appElement = AXUIElementCreateApplication(pid)
        var focusedWindow: AnyObject?
        let axResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        if axResult == .success, let window = focusedWindow {
            var titleValue: AnyObject?
            if AXUIElementCopyAttributeValue(window as! AXUIElement, kAXTitleAttribute as CFString, &titleValue) == .success,
               let titleStr = titleValue as? String {
                windowTitle = titleStr
            }
            
            // Also attempt document URL attribute if available
            var docValue: AnyObject?
            if AXUIElementCopyAttributeValue(window as! AXUIElement, kAXDocumentAttribute as CFString, &docValue) == .success,
               let docStr = docValue as? String {
                if docStr.hasPrefix("http://") || docStr.hasPrefix("https://") {
                    extractedURL = docStr
                }
            }
        }
        
        // 2. If it's a known browser and we haven't extracted a URL yet, try browser AppleScript query
        if extractedURL == nil && isBrowser(bundleId: bundleId) {
            if let browserUrl = getActiveBrowserURL(bundleId: bundleId) {
                extractedURL = browserUrl
            }
        }
        
        // Extract domain from URL or window title
        if let urlStr = extractedURL, let urlObj = URL(string: urlStr), let host = urlObj.host {
            extractedDomain = host.replacingOccurrences(of: "www.", with: "")
        } else {
            extractedDomain = extractDomainFromTitle(windowTitle)
        }
        
        // Fallback title to App Name if empty
        if windowTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            windowTitle = appName
        }
        
        return WindowInfo(
            appName: appName,
            bundleIdentifier: bundleId,
            windowTitle: windowTitle,
            url: extractedURL,
            domain: extractedDomain
        )
    }
    
    private func isBrowser(bundleId: String) -> Bool {
        let browserBundleIds: Set<String> = [
            "com.apple.Safari",
            "com.google.Chrome",
            "company.thebrowser.Browser", // Arc
            "com.brave.Browser",
            "com.microsoft.edgemac",
            "org.mozilla.firefox",
            "com.operasoftware.Opera"
        ]
        return browserBundleIds.contains(bundleId)
    }
    
    private func getActiveBrowserURL(bundleId: String) -> String? {
        let scriptSource: String?
        
        switch bundleId {
        case "com.apple.Safari":
            scriptSource = "tell application \"Safari\" to return URL of current tab of front window"
        case "com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac":
            let appName = bundleId == "com.google.Chrome" ? "Google Chrome" : (bundleId == "com.brave.Browser" ? "Brave Browser" : "Microsoft Edge")
            scriptSource = "tell application \"\(appName)\" to return URL of active tab of front window"
        case "company.thebrowser.Browser": // Arc
            scriptSource = "tell application \"Arc\" to return URL of active tab of front window"
        default:
            scriptSource = nil
        }
        
        guard let script = scriptSource else { return nil }
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            if error == nil, let url = output.stringValue, !url.isEmpty {
                return url
            }
        }
        return nil
    }
    
    private func extractDomainFromTitle(_ title: String) -> String? {
        let commonDomains = ["github.com", "google.com", "youtube.com", "stackoverflow.com", "figma.com", "notion.so", "reddit.com", "x.com", "twitter.com"]
        let lower = title.lowercased()
        for dom in commonDomains {
            if lower.contains(dom) {
                return dom
            }
        }
        return nil
    }
}
