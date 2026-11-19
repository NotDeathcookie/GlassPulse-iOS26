# GlassPulse (iOS 26 Native SwiftUI App)

A native **iOS 26** SwiftUI application built with Apple's **Liquid Glass** APIs (`glassEffect`, `GlassEffectContainer`, morphing transitions, and `.glass` / `.glassProminent` button styles), configured with a **GitHub Actions** workflow that compiles an unsigned `.ipa` ready to sideload in **LiveContainer**.

## Features
- **Pulse Focus Timer**: Interactive circular focus & breathwork timer with morphing Liquid Glass duration pills and haptics.
- **Liquid Lab**: Real-time playground to experiment with `.regular` vs `.clear` glass variants, tints, `.interactive()` touch refraction, and `GlassEffectContainer` orb merging.
- **Runtime Inspector**: Displays iOS version, active bundle ID, CPU/RAM metrics, thermal state, and a `UserDefaults` persistence test for LiveContainer.

---

## 1. Push to GitHub
1. Create a new repository on GitHub (public or private).
2. Unzip `GlassPulse-iOS26.zip` and upload all files (including the hidden `.github/workflows/build-ipa.yml` folder) to your repository:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: GlassPulse iOS 26 app"
   git branch -M main
   git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
   git push -u origin main
   ```

## 2. Build the `.ipa` on GitHub Actions
1. Open your repository on GitHub and click the **Actions** tab.
2. Select **Build iOS 26 IPA** on the left (it runs automatically on push, or click **Run workflow**).
3. Wait ~2–3 minutes for the `macos-26` runner to generate the Xcode project via `XcodeGen`, compile the Release build with Xcode 26, and package `GlassPulse-iOS26.ipa`.
4. Scroll down to **Artifacts** on the completed workflow run and download **`GlassPulse-iOS26-IPA`**. Unzip it to get `GlassPulse-iOS26.ipa`.

## 3. Sideload with LiveContainer
1. Transfer `GlassPulse-iOS26.ipa` to your iPhone (AirDrop, Files, or iCloud Drive).
2. Open **LiveContainer** on your iOS 26 device.
3. Tap **+** (top left/right) → **Install from File** and select `GlassPulse-iOS26.ipa`.
4. *(If using JIT-less mode)* Ensure your signing certificate is imported in LiveContainer Settings (**Import Certificate from SideStore** or `.p12`), or tap **Sign** on the app entry if prompted.
5. Tap **GlassPulse** in LiveContainer to launch!
