import SwiftUI

enum Theme {
    static let primary       = Color(hex: "2D6A4F")
    static let accent        = Color(hex: "F4A261")
    static let background    = Color(hex: "FAFAF7")
    static let surface       = Color.white
    static let textPrimary   = Color(hex: "1A1A2E")
    static let planned       = Color(hex: "A8DADC")
    static let eaten         = Color(hex: "52B788")
    static let warning       = Color(hex: "E76F51")

    static let cardShadow = Color.black.opacity(0.08)
}

extension Font {
    static func fooyouTitle() -> Font   { .system(.title2, design: .rounded, weight: .bold) }
    static func fooyouHeadline() -> Font { .system(.headline, design: .rounded, weight: .semibold) }
    static func fooyouBody() -> Font    { .system(.body, design: .rounded) }
    static func fooyouCaption() -> Font { .system(.caption, design: .rounded) }
    static func fooyouMono() -> Font    { .system(.body, design: .monospaced) }
}
