# GlassPulse v2 (iOS 26 Native SwiftUI App)

A full-featured native **iOS 26** SwiftUI application built with Apple's **Liquid Glass** APIs, **Metal Shaders**, **CoreMotion**, **SwiftData + Swift Charts**, **AVAudioEngine** procedural soundscapes, and custom **`glasspulse://`** URL schemes—configured with **GitHub Actions** (`macos-26` + Xcode 26) to compile an unsigned `.ipa` ready to sideload in **LiveContainer**.

## What's Included
- **Pulse Focus & Pomodoro Engine**:
  - Automatic **Focus → Short Break → Long Break** 4-round Pomodoro cycle with distinct haptics and colors.
  - Custom duration preset builder + session categories (*Code*, *Study*, *Workout*, *Design*).
  - **Procedural Ambient Soundscapes** (`AVAudioEngine`): real-time synthesized **Brown Noise**, **Soft Rain**, and **40Hz Binaural Focus** tones with background audio playback enabled.
- **Floating Mini-Timer (`.tabViewBottomAccessory`)**:
  - Stays pinned above the tab bar across other tabs when a session or soundscape is active, with a smooth `.navigationTransition(.zoom)` quick-control sheet.
- **Liquid Lab (`Metal` + `CoreMotion`)**:
  - Custom `LiquidShaders.metal` (`liquidRipple` distortion & `chromaticPrism` layer effect) driven by live touch gestures.
  - Real-time gyroscope/accelerometer `MeshGradient` light tilt (`CoreMotion`) + `GlassEffectContainer` orb morphing.
- **Stats (`SwiftData` + `Swift Charts`)**:
  - Persistent session database, streak counter, and 7-day stacked category bar chart.
- **Runtime & LiveContainer Tools**:
  - **JSON Export & Restore** (`.fileExporter` / `.fileImporter`) to back up your `SwiftData` history before updating the `.ipa` in LiveContainer.
  - **Custom URL Scheme (`glasspulse://`)** for iOS Shortcuts automation (e.g., `glasspulse://start?minutes=25&category=Code&sound=rain`).
