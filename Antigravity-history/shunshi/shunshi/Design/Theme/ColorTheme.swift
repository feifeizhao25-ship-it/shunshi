import SwiftUI

// MARK: - App Color Theme
extension Color {
    // MARK: - Primary Colors (宝丽碧 - Jewel Teal)
    static let shunshiPrimary = Color(hexCode: "0D9488")      // Deeper, more vibrant teal
    static let shunshiPrimaryDark = Color(hexCode: "0F766E")  // Shadow teal
    static let shunshiPrimaryLight = Color(hexCode: "CCFBF1") 
    static let shunshiSecondary = Color(hexCode: "99F6E4")    // Light mint
    
    // MARK: - Premium Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [shunshiPrimary, Color(hexCode: "2DD4BF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Seasonal Colors (节气色彩 - Refined)
    static let seasonSpring = Color(hexCode: "65A30D")  // Spring Leaf
    static let seasonSummer = Color(hexCode: "EA580C")  // Summer Sun
    static let seasonAutumn = Color(hexCode: "CA8A04")  // Autumn Gold
    static let seasonWinter = Color(hexCode: "4F46E5")  // Winter Indigo
    
    // MARK: - Semantic Colors
    static let success = Color(hexCode: "16A34A")
    static let warning = Color(hexCode: "D97706")
    static let error = Color(hexCode: "DC2626")
    static let info = Color(hexCode: "2563EB")
}

// MARK: - Background Colors
extension Color {
    enum Background {
        static let dark = Color(hexCode: "0C1F1D")       // 墨绿黑
        static let light = Color(hexCode: "F0FDF9")      // 淡青白
        
        static func adaptive(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? dark : light
        }
    }
    
    enum Surface {
        static let dark = Color(hexCode: "163332")       // 深青
        static let darkLighter = Color(hexCode: "1E3633")
        static let light = Color.white
        
        static func adaptive(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? dark : light
        }
    }
    
    enum Card {
        static let dark = Color(hexCode: "1F4544")
        static let light = Color.white
        
        static func adaptive(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? dark : light
        }
    }
}

// MARK: - Text Colors
extension Color {
    enum AppText {
        static let primaryDark = Color(hexCode: "F0FDF4")
        static let secondaryDark = Color(hexCode: "94A3B8")
        static let mutedDark = Color(hexCode: "64748B")
        
        static let primaryLight = Color(hexCode: "0E1B19")
        static let secondaryLight = Color(hexCode: "475569")
        static let mutedLight = Color(hexCode: "6B7280")
        
        static func primary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? primaryDark : primaryLight
        }
        
        static func secondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? secondaryDark : secondaryLight
        }
        
        static func muted(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? mutedDark : mutedLight
        }
    }
}

// MARK: - Hex Color Initializer
extension Color {
    /// Non-failable initializer for hex strings (returns gray on failure) - short form
    init(hex: String) {
        self.init(hexCode: hex)
    }
    
    /// Non-failable initializer for hex strings (returns gray on failure)
    init(hexCode: String) {
        let cleanHex = hexCode.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128) // Default to gray
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Failable initializer for optional hex strings
    init?(optionalHex: String?) {
        guard let hex = optionalHex else { return nil }
        self.init(hexCode: hex)
    }
}
