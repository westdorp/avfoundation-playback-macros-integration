import SwiftUI

/// Semantic category for trace timeline entries.
enum TraceCategory: Sendable, Hashable, CaseIterable {
    case intent
    case event
    case transitionAllowed
    case transitionDenied
    case compositeEvent
    case compositeDenied
    case strategyDecision
    case diagnosticEvent
    case info

    var label: String {
        switch self {
        case .intent: "Intent"
        case .event: "Event"
        case .transitionAllowed: "Allowed"
        case .transitionDenied: "Denied"
        case .compositeEvent: "Composite"
        case .compositeDenied: "Composite Denied"
        case .strategyDecision: "Strategy"
        case .diagnosticEvent: "Diagnostic"
        case .info: "Info"
        }
    }

    var color: Color {
        switch self {
        case .intent: .indigo
        case .event: .cyan
        case .transitionAllowed: .green
        case .transitionDenied: .orange
        case .compositeEvent: .teal
        case .compositeDenied: .pink
        case .strategyDecision: .mint
        case .diagnosticEvent: .red
        case .info: .gray
        }
    }
}

/// Immutable trace event for the timeline.
struct TraceEntry: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let category: TraceCategory
    let label: String
    let detail: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: TraceCategory,
        label: String,
        detail: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.label = label
        self.detail = detail
    }
}
