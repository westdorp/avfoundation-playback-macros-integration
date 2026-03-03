import Testing
@testable import PlaybackStateMachineShowcase

@Suite("Navigation Routes")
struct NavigationRouteTests {

    @Test("All eight scenarios are enumerated")
    func allScenarios() {
        #expect(Scenario.allCases.count == 8)
    }

    @Test("Scenario raw values are sequential 1–8")
    func sequentialRawValues() {
        let expected = Array(1...8)
        let actual = Scenario.allCases.map(\.rawValue)
        #expect(actual == expected)
    }

    @Test("Each scenario has non-empty navigation and guide metadata")
    func scenarioMetadata() {
        for scenario in Scenario.allCases {
            #expect(!scenario.title.isEmpty, "Scenario \(scenario.rawValue) has empty title")
            #expect(!scenario.subtitle.isEmpty, "Scenario \(scenario.rawValue) has empty subtitle")
            #expect(!scenario.demonstrates.isEmpty, "Scenario \(scenario.rawValue) has empty demonstrates metadata")
            #expect(!scenario.howTo.isEmpty, "Scenario \(scenario.rawValue) has empty howTo metadata")
            #expect(!scenario.demonstrates.contains(where: { $0.isEmpty }), "Scenario \(scenario.rawValue) has blank demonstrates copy")
            #expect(!scenario.howTo.contains(where: { $0.isEmpty }), "Scenario \(scenario.rawValue) has blank howTo copy")
        }
    }
}
