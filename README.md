# AVFoundation Playback Macros Integration

Public integration showcase that composes:

- [`playback-state-machine-macro`](https://github.com/westdorp/playback-state-machine-macro)
- [`avfoundation-playback-state-macro`](https://github.com/westdorp/avfoundation-playback-state-macro)
- [`avfoundation-playback-diagnostics-macro`](https://github.com/westdorp/avfoundation-playback-diagnostics-macro)

This repo is where strategy and composite behavior are shown together in an end-to-end example app.

## What is showcased

- `@PlaybackStateMachine`:
  - state/intent/reducer transitions
  - event routing through `handle(_:)`
  - guardrail diagnostics around denied transitions
- `@PlaybackState`:
  - playback condition derivation and observation-driven state surfaces
  - strategy outcomes used by buffering/seeking scenarios
- `@PlaybackDiagnostics`:
  - diagnostics stream and latest context surfaces
  - orchestration scenario wiring into trace/analytics state

## Example app structure

- App target: `PlaybackStateMachineShowcase`
- Scenario screens: `PlaybackStateMachineShowcase/Scenarios/`
- Strategy/composition logic:
  - `PlaybackStateMachineShowcase/Scenarios/SeekingStrategyView.swift`
  - `PlaybackStateMachineShowcase/Scenarios/BufferingStallView.swift`
  - `PlaybackStateMachineShowcase/Scenarios/CompositeStateView.swift`
  - `PlaybackStateMachineShowcase/Scenarios/FullOrchestrationView.swift`
- Macro observer examples:
  - `PlaybackStateMachineShowcase/Shared/ObserverMacroShowcase.swift`

## Run locally

```bash
swift package resolve
swift build
swift test
swift run PlaybackStateMachineShowcase
```

## Notes

- Dependencies currently track `main` branches of the three macro repos.
- Move to tagged versions for stronger reproducibility once release tags are published.
