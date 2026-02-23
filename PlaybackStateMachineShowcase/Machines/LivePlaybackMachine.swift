import PlaybackStateMachine

@PlaybackStateMachine
@MainActor
final class LivePlaybackMachine {
    enum State: Sendable, Hashable {
        case idle
        case loading(streamID: String)
        case live(streamID: String, atEdge: Bool)
        case failed(FailureReason)
    }

    enum Intent: Sendable, Hashable {
        case selectStream(id: String)
        case startLive
        case snapToEdge
        case fail(FailureReason)
        case stop
    }

    enum FailureReason: Sendable, Hashable, CustomStringConvertible {
        case streamUnavailable
        case networkError

        var description: String {
            switch self {
            case .streamUnavailable: "streamUnavailable"
            case .networkError: "networkError"
            }
        }
    }

    private static func validate(_ intent: Intent, from state: State) -> Transition {
        switch (intent, state) {
        // selectStream — always allowed
        case let (.selectStream(id), .idle):
            return .allowed(.loading(streamID: id))
        case let (.selectStream(id), .loading):
            return .allowed(.loading(streamID: id))
        case let (.selectStream(id), .live):
            return .allowed(.loading(streamID: id))
        case let (.selectStream(id), .failed):
            return .allowed(.loading(streamID: id))

        // startLive — only from loading
        case let (.startLive, .loading(streamID)):
            return .allowed(.live(streamID: streamID, atEdge: true))
        case (.startLive, .idle):
            return .denied(state: state, intent: intent)
        case (.startLive, .live):
            return .denied(state: state, intent: intent)
        case (.startLive, .failed):
            return .denied(state: state, intent: intent)

        // snapToEdge — only from live
        case let (.snapToEdge, .live(streamID, _)):
            return .allowed(.live(streamID: streamID, atEdge: true))
        case (.snapToEdge, .idle):
            return .denied(state: state, intent: intent)
        case (.snapToEdge, .loading):
            return .denied(state: state, intent: intent)
        case (.snapToEdge, .failed):
            return .denied(state: state, intent: intent)

        // fail — always transitions to failed
        case let (.fail(reason), .idle):
            return .allowed(.failed(reason))
        case let (.fail(reason), .loading):
            return .allowed(.failed(reason))
        case let (.fail(reason), .live):
            return .allowed(.failed(reason))
        case let (.fail(reason), .failed):
            return .allowed(.failed(reason))

        // stop — always returns to idle
        case (.stop, .idle):
            return .allowed(.idle)
        case (.stop, .loading):
            return .allowed(.idle)
        case (.stop, .live):
            return .allowed(.idle)
        case (.stop, .failed):
            return .allowed(.idle)
        }
    }
}
