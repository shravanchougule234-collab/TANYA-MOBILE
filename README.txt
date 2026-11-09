TANYA ANDROID VEHICLE DEMO — GITHUB CLOUD BUILD

This repository layout is intentionally FLAT for easy upload from a phone.
Keep all listed project files in the repository root. Keep the workflow at:
.github/workflows/android-apk.yml

Files: project.godot, main.tscn, player.tscn, vehicle.tscn, player.gd,
tanya_vehicle.gd, export_presets.cfg.

Build: GitHub > Actions > Build TANYA Android APK > Run workflow.
After a successful run, download the TANYA-Android-APK artifact, extract it,
and install TANYA-debug.apk. It is a debug ARM64 APK for device testing.

This is a small 3D vehicle prototype, not a full GTA-scale open-world game.
The cloud workflow must complete before an APK exists. Device installation
and gameplay still need a real Android phone test.
