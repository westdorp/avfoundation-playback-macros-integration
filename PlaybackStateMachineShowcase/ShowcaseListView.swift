import SwiftUI

struct ShowcaseListView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("How To Use This Showcase") {
                    Text("Open a scenario card, use the Guide button for what to observe, then drive inputs and read trace output.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Macro Coverage") {
                    ForEach(ShowcaseFeature.allCases) { feature in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.title)
                                .font(.subheadline.bold())
                            Text(feature.coverage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                ForEach(ScenarioSection.allCases) { section in
                    Section(section.title) {
                        ForEach(section.scenarios) { scenario in
                            NavigationLink(value: scenario) {
                                ScenarioGuideCard(scenario: scenario)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Showcase")
            .navigationDestination(for: Scenario.self) { scenario in
                scenario.destination
            }
        }
    }
}

private struct ScenarioGuideCard: View {
    let scenario: Scenario

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(scenario.title)
                .font(.headline)

            Text(scenario.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                labelRow("Demonstrates", text: scenario.demonstrates.first ?? "")
                labelRow("Try This", text: scenario.howTo.first ?? "")
            }
        }
        .padding(.vertical, 6)
    }

    private func labelRow(_ label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .font(.caption2.monospaced().bold())
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private enum ScenarioSection: Int, CaseIterable, Identifiable {
    case stateMachine
    case strategies
    case endToEnd

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .stateMachine: "@PlaybackStateMachine"
        case .strategies: "PlaybackState Strategies"
        case .endToEnd: "End-to-End"
        }
    }

    var scenarios: [Scenario] {
        switch self {
        case .stateMachine: [.stateMachineBasics, .transitionGuardrails, .eventRouting]
        case .strategies: [.kindCapabilities, .seekingStrategy, .bufferingStall, .compositeState]
        case .endToEnd: [.fullOrchestration]
        }
    }
}

private enum ShowcaseFeature: Int, CaseIterable, Identifiable {
    case playbackStateMachine
    case playbackState
    case playbackDiagnostics

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .playbackStateMachine: "@PlaybackStateMachine"
        case .playbackState: "@PlaybackState"
        case .playbackDiagnostics: "@PlaybackDiagnostics"
        }
    }

    var coverage: String {
        switch self {
        case .playbackStateMachine:
            "Scenarios 1-3 and 8 exercise macro-generated state, intent, transition, and event routing APIs directly."
        case .playbackState:
            "Scenarios 4-7 focus on playback-condition strategy outcomes; direct observer macro usage lives in Shared/ObserverMacroShowcase.swift."
        case .playbackDiagnostics:
            "Scenario 8 demonstrates diagnostics-driven behavior; direct diagnostics macro usage lives in Shared/ObserverMacroShowcase.swift."
        }
    }
}

enum Scenario: Int, CaseIterable, Identifiable, Hashable {
    case stateMachineBasics = 1
    case transitionGuardrails
    case eventRouting
    case kindCapabilities
    case seekingStrategy
    case bufferingStall
    case compositeState
    case fullOrchestration

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .stateMachineBasics: "1. State Machine Basics"
        case .transitionGuardrails: "2. Transition Guardrails"
        case .eventRouting: "3. Event Routing"
        case .kindCapabilities: "4. Kind Capabilities"
        case .seekingStrategy: "5. Seeking Strategy"
        case .bufferingStall: "6. Buffering & Stall Classification"
        case .compositeState: "7. Composite State"
        case .fullOrchestration: "8. Full Orchestration"
        }
    }

    var subtitle: String {
        switch self {
        case .stateMachineBasics: "Core @PlaybackStateMachine — states, intents, transitions"
        case .transitionGuardrails: "Denied transitions with explicit context"
        case .eventRouting: "@PlaybackInput event union and handle(_:) routing"
        case .kindCapabilities: "PlaybackKind and capability profiles"
        case .seekingStrategy: "Seek request normalization per kind"
        case .bufferingStall: "AV-style observation signals and stall classification"
        case .compositeState: "Multi-surface state management"
        case .fullOrchestration: "State machines, diagnostics, and analytics composed end-to-end"
        }
    }

    var demonstrates: [String] {
        switch self {
        case .stateMachineBasics:
            return [
                "Top-level vs nested state clarity (`.session(.playing)` style).",
                "Intent-driven transitions and trace visibility."
            ]
        case .transitionGuardrails:
            return [
                "Denied transition context with state + intent.",
                "Difference between invalid and valid intent paths."
            ]
        case .eventRouting:
            return [
                "External events routed through `handle(_:)`.",
                "State-changing vs internal event handling outcomes."
            ]
        case .kindCapabilities:
            return [
                "Capability dimensions by playback kind.",
                "Ad-role capability differences, including SGAI."
            ]
        case .seekingStrategy:
            return [
                "Seek normalization for VOD vs Live DVR.",
                "Live-edge tolerance effect near DVR upper bound."
            ]
        case .bufferingStall:
            return [
                "Buffering classification from AV-style signals.",
                "Stall class transitions from deterministic inputs."
            ]
        case .compositeState:
            return [
                "Multi-surface registration and activation rules.",
                "Denied reasons when reducer invariants are violated."
            ]
        case .fullOrchestration:
            return [
                "Composed VOD + ad + composite + analytics flows.",
                "Diagnostics-style failures routed into observable state and trace outputs.",
                "Cancellation-safe async ad break simulation."
            ]
        }
    }

    var howTo: [String] {
        switch self {
        case .stateMachineBasics:
            return [
                "Start at `selectMedia`, then `startSession`, then `play` and observe nested session phase text."
            ]
        case .transitionGuardrails:
            return [
                "Trigger a denied intent first, then walk the valid path and compare trace entries."
            ]
        case .eventRouting:
            return [
                "Prime playback with setup intents, then fire external events to compare routed outcomes."
            ]
        case .kindCapabilities:
            return [
                "Switch kind and ad type, then verify how seeking/duration/content role change."
            ]
        case .seekingStrategy:
            return [
                "For Live DVR, try near-edge and far-edge targets while adjusting tolerance."
            ]
        case .bufferingStall:
            return [
                "Toggle buffering flags and tick counts; results update automatically."
            ]
        case .compositeState:
            return [
                "Register surfaces, activate one, then try removing the active surface to inspect denial reason."
            ]
        case .fullOrchestration:
            return [
                "Run Ad Break, then Cancel Ad Break on another run to compare completion vs cancellation traces."
            ]
        }
    }

    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
        case .stateMachineBasics: StateMachineBasicsView()
        case .transitionGuardrails: TransitionGuardrailsView()
        case .eventRouting: EventRoutingView()
        case .kindCapabilities: KindCapabilitiesView()
        case .seekingStrategy: SeekingStrategyView()
        case .bufferingStall: BufferingStallView()
        case .compositeState: CompositeStateView()
        case .fullOrchestration: FullOrchestrationView()
        }
    }
}
