---
name: debug-kit
description: >
  Cross-platform app debug and testing skill for Claude Code.
  Build, launch, screenshot, tap, type, inspect, and monitor applications
  across 7 platforms: Electron, iOS, macOS, Web, Flutter, React Native, Android.
  Auto-detects project type from package.json, pubspec.yaml, xcodeproj, build.gradle.
  TRIGGER when: user says "run the app", "test the app", "take screenshot", "tap button",
  "debug", "launch", "check if it works", "hot reload", "monitor console", "check logs",
  or is working on ANY app project and wants to build, run, test, or verify changes.
  Also trigger when the user asks to interact with a running app, inspect UI elements,
  check performance, run accessibility audits, or simulate user input.
license: MIT
metadata:
  author: daxiongya
  version: "1.0.0"
  type: utility
  mode: assistive
---

# Debug Kit

Cross-platform app debug toolkit. One skill to build, launch, interact with, and inspect apps across 7 platforms.

## Step 1: Determine Platform

Use `pilot.sh detect` or check project files manually:

| Marker File | Platform | Reference |
|-------------|----------|-----------|
| `pubspec.yaml` | **Flutter** | `references/flutter.md` |
| `package.json` + `react-native` dep | **React Native** | `references/react-native.md` |
| `package.json` + `electron` dep | **Electron** | `references/electron.md` |
| `package.json` (other) or `*.html` | **Web** | `references/web.md` |
| `*.xcodeproj` / `project.yml` (iOS) | **iOS** | `references/ios.md` |
| `*.xcodeproj` / `project.yml` (macOS) | **macOS** | `references/macos.md` |
| `build.gradle` / `settings.gradle` | **Android** | `references/android.md` |

**After identifying the platform, read the corresponding `references/<platform>.md` for full command documentation.**

## Step 2: Use the Right Script

```bash
P=~/.claude/skills/debug-kit/scripts

# Electron (CDP protocol)
CDP_PORT=9222 node $P/cdp-client.mjs <command>

# iOS (xcrun simctl + CGEvent)
bash $P/ios-ctl.sh <command>

# macOS (Accessibility API + CGEvent)
MAC_APP=AppName bash $P/mac-ctl.sh <command>

# Web (CDP via Chrome)
bash $P/web-ctl.sh <command>

# Flutter (delegates to ios/web/macos)
bash $P/flutter-ctl.sh <command>

# React Native (delegates to ios)
bash $P/rn-ctl.sh <command>

# Android (adb + uiautomator)
bash $P/android-ctl.sh <command>
```

Or use the unified router: `bash $P/pilot.sh <platform> <command>` / `bash $P/pilot.sh auto <command>`

## Universal Capabilities

Every platform supports these core operations (read platform reference for exact command names):

| Capability | Description |
|-----------|-------------|
| **Run** | Build and launch the app |
| **Stop** | Stop the running app |
| **Screenshot** | Capture current state as PNG |
| **Tap / Click** | Simulate touch/click at coordinates or by element identifier |
| **Type** | Input text into focused element |
| **Health** | Check environment, dependencies, running state |
| **Logs** | Stream or read app output |
| **Test** | Run platform test suite (Jest / XCTest / flutter test / etc.) |

## Composition

Scripts share infrastructure and delegate across platforms:

```
Electron  ─── cdp-client.mjs (zero-dep WebSocket + CDP)
Web       ─── web-ctl.sh ──── cdp-client.mjs (reuses same CDP)
iOS       ─── ios-ctl.sh (simctl + JXA CGEvent)
macOS     ─── mac-ctl.sh (Accessibility API + JXA CGEvent)
Flutter   ─── flutter-ctl.sh ──┬── ios-ctl.sh (iOS target)
                               ├── cdp-client.mjs (Web target)
                               └── mac-ctl.sh (macOS target)
React Native ─ rn-ctl.sh ──── ios-ctl.sh (iOS interaction)
Android   ─── android-ctl.sh (adb + uiautomator)
```
