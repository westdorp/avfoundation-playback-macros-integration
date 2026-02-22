# AVFoundation Playback Macros Integration

Integration workspace that composes the three standalone macro packages:

- `avfoundation-playback-state-macro`
- `avfoundation-playback-diagnostics-macro`
- `playback-state-machine-macro`

This package is intended for end-to-end wiring examples and cross-package integration checks.

## Local Development

```bash
swift build
swift test
swift run PlaybackMacrosIntegrationClient
```

## Dependency Model

Current setup uses local path dependencies to sibling directories. Replace with remote URLs once public repositories are created.
