import SwiftUI

/// Reusable timeline view that displays trace entries with colored indicators.
struct TraceTimelineView: View {
    let entries: [TraceEntry]

    @State private var expandedID: UUID?

    var body: some View {
        ScrollViewReader { proxy in
            List(entries) { entry in
                TraceRow(
                    entry: entry,
                    isExpanded: expandedID == entry.id
                )
                .id(entry.id)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.2)) {
                        expandedID = expandedID == entry.id ? nil : entry.id
                    }
                }
            }
            .listStyle(.plain)
            .onAppear {
                guard let latestID = entries.last?.id else { return }
                proxy.scrollTo(latestID, anchor: .bottom)
            }
            .onChange(of: entries.last?.id) { _, latestID in
                guard let latestID else { return }
                withAnimation {
                    proxy.scrollTo(latestID, anchor: .bottom)
                }
            }
        }
    }
}

private struct TraceRow: View {
    let entry: TraceEntry
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(entry.category.color)
                    .frame(width: 8, height: 8)

                Text(entry.category.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(entry.category.color)

                Text(entry.label)
                    .font(.caption)
                    .lineLimit(1)

                Spacer()

                Text(entry.timestamp, format: .dateTime.hour().minute().second().secondFraction(.fractional(2)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if isExpanded, !entry.detail.isEmpty {
                Text(entry.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
            }
        }
        .padding(.vertical, 2)
    }
}
