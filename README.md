# AVFoundation Playback Macros Integration

Integration showcase for the PlaybackStateMachine macro ecosystem. This package
demonstrates how the three macro libraries compose in a single executable:

- [`playback-state-machine-macro`](https://github.com/westdorp/playback-state-machine-macro)
- [`avfoundation-playback-state-macro`](https://github.com/westdorp/avfoundation-playback-state-macro)
- [`avfoundation-playback-diagnostics-macro`](https://github.com/westdorp/avfoundation-playback-diagnostics-macro)

## Purpose

The repository is a contract-focused integration surface:

- Verifies that macro-generated APIs from all three dependencies compose cleanly.
- Demonstrates state-machine, strategy, diagnostics, and orchestration behavior in
  a runnable SwiftUI app.
- Provides executable tests that lock expected behavior before dependency updates.

## Requirements

- Swift toolchain: **Swift 6.2** (`swift-tools-version: 6.2`)
- Platforms declared by package:
  - macOS 26
  - iOS 26

## Repository Layout

- App target: `PlaybackStateMachineShowcase`
- Scenario screens: `PlaybackStateMachineShowcase/Scenarios/`
- Machines: `PlaybackStateMachineShowcase/Machines/`
- Shared integration/runtime components:
  - `PlaybackStateMachineShowcase/Shared/ContractVerification.swift`
  - `PlaybackStateMachineShowcase/Shared/ObserverMacroShowcase.swift`
  - `PlaybackStateMachineShowcase/Shared/FullOrchestrationViewModel.swift`
- Tests: `ShowcaseTests/`

## Scenario Contract Matrix

| Scenario | Primary macro/API surface | Expected observable result | Coverage |
|---|---|---|---|
| 1. State Machine Basics | `@PlaybackStateMachine` transition generation | Intent sends produce allowed/denied transition traces and nested state labels | `ShowcaseTests/VODStateMachineTests.swift` |
| 2. Transition Guardrails | Denied transition context (`state`, `intent`) | Invalid intents produce explicit denied context and no invalid state mutation | `ShowcaseTests/VODStateMachineTests.swift` |
| 3. Event Routing | `@PlaybackInput` + `handle(_:)` routing | External event input either forwards to transition or performs internal state update | `ShowcaseTests/VODStateMachineTests.swift` |
| 4. Kind Capabilities | Playback kind/capability modeling | Capability dimensions are consistent per kind, including ad variants | `ShowcaseTests/StrategyTests.swift` |
| 5. Seeking Strategy | Strategy interfaces (`seekDecision`) | VOD and Live DVR produce deterministic seek decisions | `ShowcaseTests/StrategyTests.swift` |
| 6. Buffering and Stall | Buffering + stall classification strategies | Snapshot/observation inputs map to stable buffering and stall classifications | `ShowcaseTests/StrategyTests.swift` |
| 7. Composite State | Composite reducer/router | Surface registration/activation invariants hold; invalid operations are denied | `ShowcaseTests/CompositeReducerTests.swift` |
| 8. Full Orchestration | VOD + ad + composite + analytics composition | Async ad flow completes/cancels safely and restores primary playback state | `ShowcaseTests/FullOrchestrationInteractionTests.swift` |

## Dependency Provenance

This repository pins dependency revisions in `Package.swift` for deterministic
integration results.

| Dependency | Pinned revision |
|---|---|
| `playback-state-machine-macro` | `5ecab7b6860bb145ec1f41920d586b20061a7e62` |
| `avfoundation-playback-state-macro` | `8040af189d52a0127368a3dce2480fac563d3480` |
| `avfoundation-playback-diagnostics-macro` | `ac96198aa174720da3736013dc3c8ac5bf3bb37c` |

## Build And Verify

```bash
swift package resolve
swift build
swift test
swift run PlaybackStateMachineShowcase
```

Expected verification signal:

- `swift test` reports all suites passing, including orchestration cancellation
  and retention-safety tests.
