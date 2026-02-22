import PlaybackDiagnostics
import PlaybackState
import PlaybackStateMachine
import Testing

@Test("All three macro packages link in integration target")
func allModulesLink() {
    #expect(PlaybackStateModule.name == "PlaybackState")
    #expect(PlaybackDiagnosticsModule.name == "PlaybackDiagnostics")

    let transition: PlaybackStateMachineTransitionOutcome<String, String> = .allowed("state")
    switch transition {
    case let .allowed(value):
        #expect(value == "state")
    case .denied:
        Issue.record("Expected allowed transition outcome")
    }
}
