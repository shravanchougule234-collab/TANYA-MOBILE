TANYA ANDROID VEHICLE DEMO — CLOUD BUILD EDITION
================================================

This is a small Godot 4.3 playable prototype, not a complete GTA-sized game.
It includes a basic 3D test area, a player, one drivable vehicle, enter/exit,
speed display, and touch controls.

PROJECT CONTENTS
----------------
- scenes/main.tscn: test area and scene composition
- scenes/player.tscn + scripts/player.gd: walking, jump, mobile controls
- scenes/vehicle.tscn + scripts/tanya_vehicle.gd: vehicle physics and HUD
- export_presets.cfg: Android ARM64 debug APK export preset
- .github/workflows/android-apk.yml: cloud Android build workflow

CORRECTIONS IN THIS EDITION
---------------------------
- Player touch controls are explicitly hidden while driving and restored
  when exiting the vehicle.
- Reverse speed is limited relative to the configured vehicle speed.
- Android export preset and cloud build workflow are included.
- Compatibility renderer is retained for wider Android device support.

BUILD WITHOUT A PC (USING GITHUB CLOUD RUNNER)
----------------------------------------------
A GitHub-hosted Linux runner is configured to act as the Android build
environment. It uses the Godot 4.3 CI image, which supplies the engine,
Android export templates and Android build dependencies.

1. On your Android phone, sign in to GitHub in a browser.
2. Create a new repository named TANYA-Android.
3. Upload the CONTENTS of this project folder to the repository root
   (including the hidden .github folder and export_presets.cfg).
4. Open the repository's Actions tab.
5. Select "Build TANYA Android APK", then tap "Run workflow".
   A push to main/master also starts a build automatically.
6. When the run finishes successfully, open that workflow run.
7. Under Artifacts, download "TANYA-Android-APK".
8. Extract the artifact ZIP and install TANYA-debug.apk on your Android phone.
   Android may ask you to allow installation from that browser/file manager.

IMPORTANT
---------
- The GitHub workflow is a configured cloud build environment; it cannot
  start until this project is uploaded to a GitHub repository under your
  account. This package does not contain a compiled APK yet.
- The APK is a debug-signed ARM64 build intended for testing, not Play Store
  release distribution.
- Runtime physics and touch interaction still require a real-device test.
- The prototype is not a full open-world game: no large map, missions,
  traffic, pedestrians, save system, or advanced assets are included.
- If Godot's Android export settings change in a later engine version,
  keep the workflow image and project export templates on matching versions.
