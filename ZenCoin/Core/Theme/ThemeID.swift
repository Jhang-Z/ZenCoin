import SwiftUI

enum ThemeID: String, CaseIterable, Identifiable, Codable {
    case claude
    case cursor
    case zapier
    case elevenlabs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude:     return "Claude"
        case .cursor:     return "Cursor"
        case .zapier:     return "Zapier"
        case .elevenlabs: return "ElevenLabs"
        }
    }

    var caption: String {
        switch self {
        case .claude:     return "羊皮纸 · 衬线"
        case .cursor:     return "奶油 · 哥特"
        case .zapier:     return "米白 · 无衬线"
        case .elevenlabs: return "深色 · 薄荷"
        }
    }
}
