import Foundation
import Observation

/// Append-only trace store for timeline display.
///
/// Traces are append-only within a scenario run. Call ``reset()`` between
/// scenarios to start a fresh timeline.
@Observable
@MainActor
final class TraceStore {
    private(set) var entries: [TraceEntry] = []

    func append(_ entry: TraceEntry) {
        entries.append(entry)
    }

    func append(category: TraceCategory, label: String, detail: String = "") {
        entries.append(TraceEntry(category: category, label: label, detail: detail))
    }

    /// Resets the timeline for a new scenario run.
    func reset() {
        entries.removeAll()
    }
}
