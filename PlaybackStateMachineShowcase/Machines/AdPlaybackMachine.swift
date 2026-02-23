import PlaybackStateMachine

@PlaybackStateMachine
@MainActor
final class AdPlaybackMachine {
    enum State: Sendable, Hashable {
        case idle
        case loading(adID: String, type: PlaybackAdType)
        case playing(adID: String, type: PlaybackAdType)
        case completed(adID: String)
    }

    enum Intent: Sendable, Hashable {
        case startAd(id: String, type: PlaybackAdType)
        case play
        case complete
        case reset
    }

    private static func validate(_ intent: Intent, from state: State) -> Transition {
        switch (intent, state) {
        // startAd — from idle or completed
        case let (.startAd(id, type), .idle):
            return .allowed(.loading(adID: id, type: type))
        case let (.startAd(id, type), .completed):
            return .allowed(.loading(adID: id, type: type))
        case (.startAd, .loading):
            return .denied(state: state, intent: intent)
        case (.startAd, .playing):
            return .denied(state: state, intent: intent)

        // play — from loading
        case let (.play, .loading(adID, type)):
            return .allowed(.playing(adID: adID, type: type))
        case (.play, .idle):
            return .denied(state: state, intent: intent)
        case (.play, .playing):
            return .denied(state: state, intent: intent)
        case (.play, .completed):
            return .denied(state: state, intent: intent)

        // complete — from playing
        case let (.complete, .playing(adID, _)):
            return .allowed(.completed(adID: adID))
        case (.complete, .idle):
            return .denied(state: state, intent: intent)
        case (.complete, .loading):
            return .denied(state: state, intent: intent)
        case (.complete, .completed):
            return .denied(state: state, intent: intent)

        // reset — always returns to idle
        case (.reset, .idle):
            return .allowed(.idle)
        case (.reset, .loading):
            return .allowed(.idle)
        case (.reset, .playing):
            return .allowed(.idle)
        case (.reset, .completed):
            return .allowed(.idle)
        }
    }
}
