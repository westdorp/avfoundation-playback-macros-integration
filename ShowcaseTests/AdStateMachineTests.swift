import Testing
@testable import PlaybackStateMachineShowcase
import PlaybackStateMachine

@Suite("Ad State Machine")
@MainActor
struct AdStateMachineTests {

    @Test("Happy path: idle -> loading -> playing -> completed")
    func happyPath() {
        let machine = AdPlaybackMachine(initialState: .idle)

        let start = machine.send(.startAd(id: "ad-001", type: .midroll))
        #expect(start.isAllowed)
        #expect(machine.state == .loading(adID: "ad-001", type: .midroll))

        let play = machine.send(.play)
        #expect(play.isAllowed)
        #expect(machine.state == .playing(adID: "ad-001", type: .midroll))

        let complete = machine.send(.complete)
        #expect(complete.isAllowed)
        #expect(machine.state == .completed(adID: "ad-001"))
    }

    @Test("Denied: play from idle")
    func playFromIdleDenied() {
        let machine = AdPlaybackMachine(initialState: .idle)
        let transition = machine.send(.play)
        #expect(transition.isDenied)
        #expect(machine.state == .idle)
    }

    @Test("Denied: startAd while already playing")
    func startAdWhilePlayingDenied() {
        let machine = AdPlaybackMachine(initialState: .idle)
        _ = machine.send(.startAd(id: "ad-001", type: .preroll))
        _ = machine.send(.play)

        let denied = machine.send(.startAd(id: "ad-002", type: .midroll))
        #expect(denied.isDenied)
        #expect(machine.state == .playing(adID: "ad-001", type: .preroll))
    }

    @Test("reset always returns to idle")
    func resetAlwaysReturnsIdle() {
        let completed = AdPlaybackMachine(initialState: .completed(adID: "ad-001"))
        #expect(completed.send(.reset).isAllowed)
        #expect(completed.state == .idle)

        let loading = AdPlaybackMachine(initialState: .loading(adID: "ad-002", type: .postroll))
        #expect(loading.send(.reset).isAllowed)
        #expect(loading.state == .idle)
    }
}
