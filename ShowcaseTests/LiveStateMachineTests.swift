import Testing
@testable import PlaybackStateMachineShowcase

@Suite("Live State Machine")
@MainActor
struct LiveStateMachineTests {

    @Test("Happy path: idle -> loading -> live")
    func happyPath() {
        let machine = LivePlaybackMachine(initialState: .idle)

        let t1 = machine.send(.selectStream(id: "live-001"))
        #expect(t1.isAllowed)
        #expect(machine.state == .loading(streamID: "live-001"))

        let t2 = machine.send(.startLive)
        #expect(t2.isAllowed)
        #expect(machine.state == .live(streamID: "live-001", atEdge: true))
    }

    @Test("Denied: startLive from idle")
    func startLiveFromIdleDenied() {
        let machine = LivePlaybackMachine(initialState: .idle)
        let transition = machine.send(.startLive)
        #expect(transition.isDenied)
        #expect(machine.state == .idle)
    }

    @Test("snapToEdge from live marks atEdge true")
    func snapToEdgeFromLive() {
        let machine = LivePlaybackMachine(initialState: .live(streamID: "live-001", atEdge: false))
        let transition = machine.send(.snapToEdge)
        #expect(transition.isAllowed)
        #expect(machine.state == .live(streamID: "live-001", atEdge: true))
    }

    @Test("stop always returns to idle")
    func stopAlwaysReturnsIdle() {
        let liveMachine = LivePlaybackMachine(initialState: .live(streamID: "live-001", atEdge: true))
        #expect(liveMachine.send(.stop).isAllowed)
        #expect(liveMachine.state == .idle)

        let failedMachine = LivePlaybackMachine(initialState: .failed(.networkError))
        #expect(failedMachine.send(.stop).isAllowed)
        #expect(failedMachine.state == .idle)
    }

    @Test("fail transitions to failed from loading")
    func failFromLoading() {
        let machine = LivePlaybackMachine(initialState: .loading(streamID: "live-001"))
        let transition = machine.send(.fail(.streamUnavailable))
        #expect(transition.isAllowed)
        #expect(machine.state == .failed(.streamUnavailable))
    }
}
