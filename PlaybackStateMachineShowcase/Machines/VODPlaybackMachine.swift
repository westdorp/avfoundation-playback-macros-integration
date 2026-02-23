import PlaybackStateMachine

@PlaybackStateMachine
@MainActor
final class VODPlaybackMachine {
    enum State: Sendable, Hashable {
        case idle
        case loading(mediaID: String)
        case session(Session)
        case failed(FailureReason)

        enum Session: Sendable, Hashable {
            case playing(mediaID: String)
            case paused(mediaID: String)
            case buffering(mediaID: String)
        }
    }

    enum Intent: Sendable, Hashable {
        case selectMedia(id: String)
        case startSession
        case play
        case pause
        case buffer(BufferCause)
        case resumeFromBuffering
        case stop
        case fail(FailureReason)
    }

    @PlaybackInput
    enum Event: Sendable, Hashable {
        case intent(Intent)
        case bufferingCompleted
        case playbackStalled
        case playbackError(FailureReason)
    }

    enum FailureReason: Sendable, Hashable, CustomStringConvertible {
        case networkUnavailable
        case decodingFailed
        case unknown

        var description: String {
            switch self {
            case .networkUnavailable: "networkUnavailable"
            case .decodingFailed: "decodingFailed"
            case .unknown: "unknown"
            }
        }
    }

    enum BufferCause: Sendable, Hashable, CustomStringConvertible {
        case initialLoad
        case rebuffering

        var description: String {
            switch self {
            case .initialLoad: "initialLoad"
            case .rebuffering: "rebuffering"
            }
        }
    }

    private static func validate(_ intent: Intent, from state: State) -> Transition {
        switch (intent, state) {
        // selectMedia — always allowed, resets to loading
        case let (.selectMedia(id), .idle):
            return .allowed(.loading(mediaID: id))
        case let (.selectMedia(id), .loading):
            return .allowed(.loading(mediaID: id))
        case let (.selectMedia(id), .session):
            return .allowed(.loading(mediaID: id))
        case let (.selectMedia(id), .failed):
            return .allowed(.loading(mediaID: id))

        // startSession — only from loading
        case let (.startSession, .loading(mediaID)):
            return .allowed(.session(.playing(mediaID: mediaID)))
        case (.startSession, .idle):
            return .denied(state: state, intent: intent)
        case (.startSession, .session):
            return .denied(state: state, intent: intent)
        case (.startSession, .failed):
            return .denied(state: state, intent: intent)

        // play — only from session states
        case (.play, .idle):
            return .denied(state: state, intent: intent)
        case (.play, .loading):
            return .denied(state: state, intent: intent)
        case let (.play, .session(.playing(mediaID))):
            return .allowed(.session(.playing(mediaID: mediaID)))
        case let (.play, .session(.paused(mediaID))):
            return .allowed(.session(.playing(mediaID: mediaID)))
        case let (.play, .session(.buffering(mediaID))):
            return .allowed(.session(.playing(mediaID: mediaID)))
        case (.play, .failed):
            return .denied(state: state, intent: intent)

        // pause — only from session states
        case (.pause, .idle):
            return .denied(state: state, intent: intent)
        case (.pause, .loading):
            return .denied(state: state, intent: intent)
        case let (.pause, .session(.playing(mediaID))):
            return .allowed(.session(.paused(mediaID: mediaID)))
        case let (.pause, .session(.paused(mediaID))):
            return .allowed(.session(.paused(mediaID: mediaID)))
        case let (.pause, .session(.buffering(mediaID))):
            return .allowed(.session(.paused(mediaID: mediaID)))
        case (.pause, .failed):
            return .denied(state: state, intent: intent)

        // buffer — only from session states
        case (.buffer, .idle):
            return .denied(state: state, intent: intent)
        case (.buffer, .loading):
            return .denied(state: state, intent: intent)
        case let (.buffer, .session(.playing(mediaID))):
            return .allowed(.session(.buffering(mediaID: mediaID)))
        case let (.buffer, .session(.paused(mediaID))):
            return .allowed(.session(.buffering(mediaID: mediaID)))
        case let (.buffer, .session(.buffering(mediaID))):
            return .allowed(.session(.buffering(mediaID: mediaID)))
        case (.buffer, .failed):
            return .denied(state: state, intent: intent)

        // resumeFromBuffering — only from buffering
        case (.resumeFromBuffering, .idle):
            return .denied(state: state, intent: intent)
        case (.resumeFromBuffering, .loading):
            return .denied(state: state, intent: intent)
        case (.resumeFromBuffering, .session(.playing)):
            return .denied(state: state, intent: intent)
        case (.resumeFromBuffering, .session(.paused)):
            return .denied(state: state, intent: intent)
        case let (.resumeFromBuffering, .session(.buffering(mediaID))):
            return .allowed(.session(.playing(mediaID: mediaID)))
        case (.resumeFromBuffering, .failed):
            return .denied(state: state, intent: intent)

        // stop — always returns to idle
        case (.stop, .idle):
            return .allowed(.idle)
        case (.stop, .loading):
            return .allowed(.idle)
        case (.stop, .session):
            return .allowed(.idle)
        case (.stop, .failed):
            return .allowed(.idle)

        // fail — always transitions to failed
        case let (.fail(reason), .idle):
            return .allowed(.failed(reason))
        case let (.fail(reason), .loading):
            return .allowed(.failed(reason))
        case let (.fail(reason), .session):
            return .allowed(.failed(reason))
        case let (.fail(reason), .failed):
            return .allowed(.failed(reason))
        }
    }

    private func handle(_ event: Event) {
        switch event {
        case .intent:
            break
        case .bufferingCompleted:
            _ = send(.resumeFromBuffering)
        case .playbackStalled:
            _ = send(.buffer(.rebuffering))
        case let .playbackError(reason):
            _ = send(.fail(reason))
        }
    }
}
