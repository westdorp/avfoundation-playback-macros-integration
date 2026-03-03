import PlaybackStateMachine

@PlaybackStateMachine
@MainActor
final class LivePlaybackMachine {
    enum LivePosition: Sendable, Hashable {
        case atLiveEdge
        case behindLiveEdge
    }

    enum State: Sendable, Hashable {
        case idle
        case loading(streamID: StreamID)
        case live(streamID: StreamID, position: LivePosition)
        case failed(FailureReason)
    }

    enum Intent: Sendable, Hashable {
        case selectStream(id: StreamID)
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
        case let (.selectStream(id), .idle):
            return .allowed(.loading(streamID: id))
        case let (.selectStream(id), .loading):
            return .allowed(.loading(streamID: id))
        case let (.selectStream(id), .live):
            return .allowed(.loading(streamID: id))
        case let (.selectStream(id), .failed):
            return .allowed(.loading(streamID: id))

        case let (.startLive, .loading(streamID)):
            return .allowed(.live(streamID: streamID, position: .atLiveEdge))
        case (.startLive, .idle):
            return .denied(state: state, intent: intent)
        case (.startLive, .live):
            return .denied(state: state, intent: intent)
        case (.startLive, .failed):
            return .denied(state: state, intent: intent)

        case let (.snapToEdge, .live(streamID, _)):
            return .allowed(.live(streamID: streamID, position: .atLiveEdge))
        case (.snapToEdge, .idle):
            return .denied(state: state, intent: intent)
        case (.snapToEdge, .loading):
            return .denied(state: state, intent: intent)
        case (.snapToEdge, .failed):
            return .denied(state: state, intent: intent)

        case let (.fail(reason), .idle):
            return .allowed(.failed(reason))
        case let (.fail(reason), .loading):
            return .allowed(.failed(reason))
        case let (.fail(reason), .live):
            return .allowed(.failed(reason))
        case let (.fail(reason), .failed):
            return .allowed(.failed(reason))

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
