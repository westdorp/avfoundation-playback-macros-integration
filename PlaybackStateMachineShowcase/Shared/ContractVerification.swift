/// Compile-time contract verification for the macro ecosystem.
///
/// This file imports all three macro modules and references key types
/// to catch linker regressions after the repo split. If any module
/// fails to build or link, this file will produce a compile error.

import PlaybackStateMachine
import PlaybackState
import PlaybackDiagnostics

/// Namespace for compile-time type assertions.
///
/// These functions are never called at runtime — their purpose is to
/// ensure the type signatures remain stable across module boundaries.
enum ContractVerification {

    // MARK: - PlaybackStateMachine

    @MainActor
    static func verifyStateMachineTypes() {
        // Transition protocol surface
        func checkTransition<T: PlaybackStateMachineTransition>(_ t: T) where T.State: CustomStringConvertible, T.Intent: CustomStringConvertible {
            _ = t.isAllowed
            _ = t.isDenied
            _ = t.allowedState
            _ = t.deniedContext
            _ = t.outcomeLabel
            _ = t.outcomeDetails
            _ = t.summary
            _ = t.fold(onAllowed: { _ in 1 }, onDenied: { _ in 0 })
        }

        // Kind and capability types
        func checkKinds() {
            let kinds: [PlaybackKind] = [.vod, .live, .liveDVR, .ad(.midroll)]
            for kind in kinds {
                let caps = kind.capabilities
                _ = caps.seeking
                _ = caps.duration
                _ = caps.liveEdge
                _ = caps.contentRole
                _ = caps.supportsSeeking
                _ = caps.supportsFiniteDuration
                _ = caps.supportsLiveEdge
                _ = caps.isAdKind
                _ = caps.adType
            }
        }

        // Surface types
        func checkSurfaces() {
            let surfaces: [PlaybackSurface] = [
                .live(id: "l"), .content(id: "k"), .ad(id: "a", type: .preroll),
            ]
            for s in surfaces {
                _ = s.id
                _ = s.kind
                _ = s.capabilities
            }
        }

        // Composite types
        func checkComposite() {
            let state = PlaybackCompositeState(activeSurface: .content(id: "v"))
            _ = state.activeSurface
            _ = state.activeKind
            _ = state.activeCapabilities
            _ = state.surfaceIDs
            _ = state.allSurfaces
            _ = state.surface(id: "v")
            _ = PlaybackCompositeReducer.apply(.registerSurface(.live(id: "l")), to: state)
            _ = PlaybackCompositeStrategyRouter.activeRoute(in: state)
        }

        // Strategy types
        func checkStrategies() {
            _ = PlaybackPositionSeconds.zero
            _ = PlaybackSeekRequest(target: .zero)
            _ = PlaybackStrategies.vodSeeking()
            _ = PlaybackStrategies.vodBuffering()
            _ = PlaybackStrategies.vodStall()
            _ = PlaybackStrategies.vodAnalytics()
            _ = PlaybackStrategies.adBuffering(SGAIAdSpec.self)
            _ = PlaybackStrategies.adAnalytics(SGAIAdSpec.self)
        }

        func checkAdSpecs() {
            _ = SGAIAdSpec.adType
            _ = AdKindSpec<SGAIAdSpec>.playerKind
        }
    }

    // MARK: - PlaybackState & PlaybackDiagnostics

    static func verifyObserverModuleSymbols() {
        _ = PlaybackStateModule.name
        _ = PlaybackDiagnosticsModule.name
    }
}

/// Forces observer-module symbol references to remain in the final binary.
///
/// This prevents dead stripping from removing the contract-verification references
/// in optimized builds.
private let forceObserverModuleSymbolVerification: Void = {
    ContractVerification.verifyObserverModuleSymbols()
}()
