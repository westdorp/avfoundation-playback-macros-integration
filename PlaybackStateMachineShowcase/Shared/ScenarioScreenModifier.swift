import SwiftUI

struct ScenarioScreenModifier: ViewModifier {
    let scenario: Scenario
    @State private var isGuidePresented = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: trailingToolbarPlacement) {
                    Button {
                        isGuidePresented = true
                    } label: {
                        Label("Guide", systemImage: "questionmark.circle")
                    }
                    .accessibilityLabel("Open scenario guide")
                }
            }
            .sheet(isPresented: $isGuidePresented) {
                ScenarioGuideSheet(scenario: scenario)
            }
    }
}

private struct ScenarioGuideSheet: View {
    let scenario: Scenario
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Scenario") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(scenario.title)
                            .font(.headline)
                        Text(scenario.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                Section("Demonstrates") {
                    ForEach(scenario.demonstrates, id: \.self) { line in
                        Text(line)
                    }
                }

                Section("How To Try It") {
                    ForEach(scenario.howTo, id: \.self) { line in
                        Text(line)
                    }
                }
            }
            .navigationTitle("Scenario Guide")
            .toolbar {
                ToolbarItem(placement: trailingToolbarPlacement) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private var trailingToolbarPlacement: ToolbarItemPlacement {
    #if os(macOS)
    .automatic
    #else
    .topBarTrailing
    #endif
}

extension View {
    func scenarioScreen(_ scenario: Scenario) -> some View {
        modifier(ScenarioScreenModifier(scenario: scenario))
    }
}
