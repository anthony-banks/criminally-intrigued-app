import Foundation

/// The three top-level content categories. Raw value is stored in SwiftData.
enum Category: String, CaseIterable, Identifiable, Codable, Sendable {
    case serialKiller
    case coldCase
    case strange

    var id: String { rawValue }

    /// Title shown on the tab and list header.
    var title: String {
        switch self {
        case .serialKiller: return "Serial Killers"
        case .coldCase: return "Cold Cases"
        case .strange: return "Strange / Unsolved"
        }
    }

    /// SF Symbol used for the tab item and row placeholder.
    var symbolName: String {
        switch self {
        case .serialKiller: return "person.fill.questionmark"
        case .coldCase: return "magnifyingglass"
        case .strange: return "questionmark.circle"
        }
    }
}
