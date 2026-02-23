import Testing
@testable import PlaybackStateMachineShowcase
import PlaybackStateMachine

@Suite("VOD State Machine")
@MainActor
struct VODStateMachineTests {

    @Test("Happy path: idle → loading → playing → paused → idle")
    func happyPath() {
        let machine = VODPlaybackMachine(initialState: .idle)

        let t1 = machine.send(.selectMedia(id: "ep-001"))
        #expect(t1.isAllowed)
        #expect(machine.state == .loading(mediaID: "ep-001"))

        let t2 = machine.send(.startSession)
        #expect(t2.isAllowed)
        #expect(machine.state == .session(.playing(mediaID: "ep-001")))

        let t3 = machine.send(.pause)
        #expect(t3.isAllowed)
        #expect(machine.state == .session(.paused(mediaID: "ep-001")))

        let t4 = machine.send(.stop)
        #expect(t4.isAllowed)
        #expect(machine.state == .idle)
    }

    @Test("Denied: startSession from idle")
    func startSessionFromIdle() {
        let machine = VODPlaybackMachine(initialState: .idle)
        let t = machine.send(.startSession)
        #expect(t.isDenied)
        #expect(machine.state == .idle)
    }

    @Test("Denied: play from idle")
    func playFromIdle() {
        let machine = VODPlaybackMachine(initialState: .idle)
        let t = machine.send(.play)
        #expect(t.isDenied)
    }

    @Test("Denied: pause from loading")
    func pauseFromLoading() {
        let machine = VODPlaybackMachine(initialState: .idle)
        _ = machine.send(.selectMedia(id: "ep-001"))
        let t = machine.send(.pause)
        #expect(t.isDenied)
    }

    @Test("Event routing: playbackStalled triggers buffer")
    func playbackStalledEvent() {
        let machine = VODPlaybackMachine(initialState: .idle)
        _ = machine.send(.selectMedia(id: "ep-001"))
        _ = machine.send(.startSession)
        #expect(machine.state == .session(.playing(mediaID: "ep-001")))

        let eventTransition = machine.send(event: .playbackStalled)
        #expect(eventTransition.isInvalid)
        #expect(machine.state == .session(.buffering(mediaID: "ep-001")))
    }

    @Test("Event routing: bufferingCompleted resumes from buffering")
    func bufferingCompletedEvent() {
        let machine = VODPlaybackMachine(initialState: .idle)
        _ = machine.send(.selectMedia(id: "ep-001"))
        _ = machine.send(.startSession)
        _ = machine.send(.buffer(.rebuffering))
        #expect(machine.state == .session(.buffering(mediaID: "ep-001")))

        _ = machine.send(event: .bufferingCompleted)
        #expect(machine.state == .session(.playing(mediaID: "ep-001")))
    }

    @Test("Event routing: playbackError transitions to failed")
    func playbackErrorEvent() {
        let machine = VODPlaybackMachine(initialState: .idle)
        _ = machine.send(.selectMedia(id: "ep-001"))
        _ = machine.send(.startSession)

        let eventTransition = machine.send(event: .playbackError(.networkUnavailable))
        #expect(eventTransition.isInvalid)
        #expect(machine.state == .failed(.networkUnavailable))
    }

    @Test("Event routing: intent wrapper returns direct transition")
    func intentWrapperEvent() {
        let machine = VODPlaybackMachine(initialState: .idle)
        let eventTransition = machine.send(event: .intent(.play))
        #expect(eventTransition.isValid)

        guard case let .valid(intentTransition) = eventTransition else {
            Issue.record("Expected valid transition for intent wrapper event.")
            return
        }
        #expect(intentTransition.isDenied)
        #expect(machine.state == .idle)
    }

    @Test("Fail from any state transitions to failed")
    func failFromAnyState() {
        let machine = VODPlaybackMachine(initialState: .idle)
        let t = machine.send(.fail(.decodingFailed))
        #expect(t.isAllowed)
        #expect(machine.state == .failed(.decodingFailed))
    }

    @Test("Stop from any state returns to idle")
    func stopFromAnyState() {
        let machine = VODPlaybackMachine(initialState: .idle)
        _ = machine.send(.selectMedia(id: "ep-001"))
        _ = machine.send(.startSession)
        _ = machine.send(.fail(.networkUnavailable))
        #expect(machine.state == .failed(.networkUnavailable))

        let t = machine.send(.stop)
        #expect(t.isAllowed)
        #expect(machine.state == .idle)
    }

    @Test("Transition summary describes outcome")
    func transitionSummary() {
        let machine = VODPlaybackMachine(initialState: .idle)
        let allowed = machine.send(.selectMedia(id: "ep-001"))
        #expect(allowed.summary.hasPrefix("allowed:"))

        let denied = machine.send(.play)
        #expect(denied.summary.hasPrefix("denied:"))
    }
}
