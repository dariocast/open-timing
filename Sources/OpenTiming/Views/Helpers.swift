import SwiftUI
import AppKit

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 100, 100, 100)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    public func toHex() -> String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return "#007AFF" }
        let r = Int(components.redComponent * 255.0)
        let g = Int(components.greenComponent * 255.0)
        let b = Int(components.blueComponent * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

public struct TimeFormatter {
    public static func format(duration: TimeInterval, short: Bool = false) -> String {
        let totalSeconds = Int(max(0, duration))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if short {
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else if minutes > 0 {
                return "\(minutes)m"
            } else {
                return "\(seconds)s"
            }
        } else {
            if hours > 0 {
                return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
            } else {
                return String(format: "%02dm %02ds", minutes, seconds)
            }
        }
    }
    
    public static func formatClock(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    public static func formatFullDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

public struct AppIconView: View {
    public let bundleIdentifier: String
    public let size: CGFloat
    
    public init(bundleIdentifier: String, size: CGFloat = 24) {
        self.bundleIdentifier = bundleIdentifier
        self.size = size
    }
    
    public var body: some View {
        if let icon = getAppIcon(bundleId: bundleIdentifier) {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .cornerRadius(size * 0.22)
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.secondary)
                .frame(width: size, height: size)
        }
    }
    
    private func getAppIcon(bundleId: String) -> NSImage? {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: appUrl.path)
        }
        return nil
    }
}
