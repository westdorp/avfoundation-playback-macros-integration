import PlaybackDiagnostics
import PlaybackState
import PlaybackStateMachine

@main
struct PlaybackMacrosIntegrationClient {
    static func main() {
        print("Integration package loaded:")
        print("- \(PlaybackStateModule.name)")
        print("- \(PlaybackDiagnosticsModule.name)")

        let transition: PlaybackStateMachineTransitionOutcome<String, String> = .allowed("ok")
        switch transition {
        case let .allowed(value):
            print("- PlaybackStateMachine outcome: allowed(\(value))")
        case let .denied(state, intent):
            print("- PlaybackStateMachine outcome: denied(\(intent) from \(state))")
        }
    }
}
