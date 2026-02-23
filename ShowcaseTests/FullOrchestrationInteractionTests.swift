import Synchronization
import Testing
@testable import PlaybackStateMachineShowcase

@Suite("Full Orchestration Interactions")
struct FullOrchestrationInteractionTests {

    @Test("Async ad break completes and restores primary playback", .timeLimit(.minutes(1)))
    @MainActor
    func asyncAdBreakCompletion() async {
        let viewModel = FullOrchestrationViewModel(
            adBreakPause: {},
            makeAdID: { "midroll-test" }
        )

        viewModel.startVOD()
        viewModel.simulateAdBreak()

        let completed = await waitUntilAdBreakStops(viewModel)
        #expect(completed)
        #expect(viewModel.compositeState.activeSurface.id == "vod-main")
        #expect(viewModel.compositeState.surface(id: "midroll-test") == nil)
        #expect(viewModel.adMachine == nil)
    }

    @Test("Ad break cancellation safely restores primary playback", .timeLimit(.minutes(1)))
    @MainActor
    func asyncAdBreakCancellation() async {
        let viewModel = FullOrchestrationViewModel(
            adBreakPause: {
                while true {
                    try Task.checkCancellation()
                    await Task.yield()
                }
            },
            makeAdID: { "midroll-cancel" }
        )

        viewModel.startVOD()
        viewModel.simulateAdBreak()
        viewModel.cancelAdBreak()

        let completed = await waitUntilAdBreakStops(viewModel)
        #expect(completed)
        #expect(viewModel.compositeState.activeSurface.id == "vod-main")
        #expect(viewModel.compositeState.surface(id: "midroll-cancel") == nil)
        #expect(viewModel.adMachine == nil)
    }

    @Test("simulateAdBreak ignores duplicate requests while running", .timeLimit(.minutes(1)))
    @MainActor
    func simulateAdBreakIgnoresDuplicateRequests() async {
        let generatedIDCount = Mutex(0)
        let viewModel = FullOrchestrationViewModel(
            adBreakPause: {
                while true {
                    try Task.checkCancellation()
                    await Task.yield()
                }
            },
            makeAdID: {
                generatedIDCount.withLock {
                    $0 += 1
                    return "midroll-\($0)"
                }
            }
        )

        viewModel.startVOD()
        viewModel.simulateAdBreak()
        viewModel.simulateAdBreak()
        #expect(generatedIDCount.withLock { $0 } == 1)
        #expect(viewModel.isAdBreakRunning)

        viewModel.cancelAdBreak()
        let completed = await waitUntilAdBreakStops(viewModel)
        #expect(completed)
        #expect(!viewModel.isAdBreakRunning)
    }

    @Test("Pending ad break does not retain view model after release", .timeLimit(.minutes(1)))
    @MainActor
    func pendingAdBreakDoesNotRetainViewModel() async {
        weak var weakViewModel: FullOrchestrationViewModel?

        do {
            var viewModel: FullOrchestrationViewModel? = FullOrchestrationViewModel(
                adBreakPause: {
                    while true {
                        try Task.checkCancellation()
                        await Task.yield()
                    }
                },
                makeAdID: { "midroll-deinit" }
            )

            viewModel?.startVOD()
            viewModel?.simulateAdBreak()
            #expect(viewModel?.isAdBreakRunning == true)
            weakViewModel = viewModel
            viewModel = nil
        }

        let released = await waitUntil(maxYields: 20_000) {
            weakViewModel == nil
        }
        #expect(released)
    }
}

@MainActor
private func waitUntilAdBreakStops(
    _ viewModel: FullOrchestrationViewModel
) async -> Bool {
    await waitUntil(maxYields: 20_000) {
        !viewModel.isAdBreakRunning
    }
}

@MainActor
private func waitUntil(
    maxYields: Int = 10_000,
    _ condition: @MainActor () -> Bool
) async -> Bool {
    for _ in 0..<maxYields {
        if condition() {
            return true
        }
        await Task.yield()
    }

    return condition()
}
