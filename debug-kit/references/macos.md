# macOS Debug Reference

**Script**: `MAC_APP=AppName bash ~/.claude/skills/debug-kit/scripts/mac-ctl.sh <command>`
**Tools**: Accessibility API (System Events), JXA + CGEvent, AppleScript
**Env**: `MAC_APP` (required — must match process name in Activity Monitor)

## Key Advantage Over iOS/Electron

macOS apps expose their full UI tree via the **Accessibility API** (System Events). This means:
- **`read`**: Instantly see all text, values, checkbox states, slider positions — no screenshots needed
- **`tree`**: Full element dump with types, positions, sizes — JSON format
- **`tap label "Show Alert"`**: Click by element name — no coordinate math
- **`menu "File > New Window"`**: Directly invoke menu items

This makes macOS the most AI-friendly platform to test — the AI can "see" the app state programmatically.

## Commands

### Build & Run
| Command | Description |
|---------|-------------|
| `build [dir] [scheme]` | Build project (auto-detects xcodeproj/xcworkspace/project.yml/Package.swift) |
| `launch [app-path]` | Launch built app |
| `terminate [app-name]` | Quit app |
| `run [dir] [scheme]` | Build + Launch |

### Inspection (Accessibility API — no Screen Recording needed)
| Command | Description |
|---------|-------------|
| `tree` | Dump full accessibility tree as JSON (buttons, text fields, sliders, etc.) |
| `read` | Read current UI state — shows all text values, checkbox states, slider positions |
| `health` | Process info (PID, memory) + window count + UI state |

### Interaction (CGEvent + AppleScript)
| Command | Description |
|---------|-------------|
| `tap <x> <y>` | Click at absolute screen coordinates |
| `tap label <text>` | Click element by name/label |
| `tap desc <description>` | Click element by accessibility description |
| `type <text>` | Type text (element must be focused) |
| `key <keyspec>` | Send key: `return`, `tab`, `escape`, `cmd+s`, `cmd+q`, `shift+tab` |
| `menu` | List all available menus and items |
| `menu "Menu > Item"` | Click a specific menu item |

### Window Management
| Command | Description |
|---------|-------------|
| `window info` | Show window positions and sizes |
| `window move <x> <y>` | Move window |
| `window resize <w> <h>` | Resize window |
| `window focus` | Bring app to front |

### Other
| Command | Description |
|---------|-------------|
| `screenshot [path]` | Capture window (requires Screen Recording permission) |
| `log [seconds]` | Stream console logs |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MAC_APP` | Auto-detected from build | App name (must match process name in Activity Monitor) |

## Workflow

```bash
P=~/.claude/skills/debug-kit/scripts

# 1. Build and launch
MAC_APP=MyApp bash $P/mac-ctl.sh run /path/to/project

# 2. Read current UI state
MAC_APP=MyApp bash $P/mac-ctl.sh read

# 3. Interact
MAC_APP=MyApp bash $P/mac-ctl.sh tap label "Login"
MAC_APP=MyApp bash $P/mac-ctl.sh tap label "Username"
MAC_APP=MyApp bash $P/mac-ctl.sh type "admin"
MAC_APP=MyApp bash $P/mac-ctl.sh key tab
MAC_APP=MyApp bash $P/mac-ctl.sh type "password"
MAC_APP=MyApp bash $P/mac-ctl.sh key return

# 4. Verify state changed
MAC_APP=MyApp bash $P/mac-ctl.sh read

# 5. Test menu
MAC_APP=MyApp bash $P/mac-ctl.sh menu "File > New Window"

# 6. Quit
MAC_APP=MyApp bash $P/mac-ctl.sh terminate
```

## How `read` Works

Uses JXA (JavaScript for Automation) to traverse the Accessibility tree via `System Events`:
- Queries `AXStaticText` for visible text and labels
- Queries `AXTextField` for input values
- Queries `AXCheckBox` for toggle states (0/1)
- Queries `AXSlider` for slider values (0.0-1.0)
- No screenshots, no screen recording, no external tools

## How `tap` Works

1. If `tap label <text>`, looks up element position from the accessibility tree
2. Uses `CGEventCreateMouseEvent` via JXA to send mouseDown+mouseUp at absolute screen coordinates
3. The target app receives the click as a normal user interaction

## Permissions

| Feature | Permission | How to Grant |
|---------|-----------|--------------|
| `tree`, `read`, `tap`, `type`, `menu` | **Accessibility** | System Settings → Privacy & Security → Accessibility |
| `screenshot` | **Screen Recording** | System Settings → Privacy & Security → Screen Recording |

Grant permissions to **the terminal that hosts Claude Code** — Terminal.app, iTerm2, or whichever shell you run `claude` in. Core debugging (`tree`, `read`, `tap`, `type`, `menu`) only needs Accessibility; `screenshot` additionally needs Screen Recording.

**After toggling a permission, you MUST fully quit (`⌘Q`) and relaunch the terminal.** macOS does not apply permission changes to already-running processes; restarting the Claude Code session alone is not enough.

Quick path to the Screen Recording pane:
```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
```

### The silent-redaction trap

On macOS Sonoma+, when Screen Recording permission is **denied**, `screencapture` does **not error**. Instead:

- `screencapture -x` (full-screen) succeeds, but your own app's windows are rendered normally while **other apps' window contents are replaced with desktop wallpaper pixels** — a privacy guarantee.
- `screencapture -l <windowID>` fails with `could not create image from window`.

The first behavior is especially nasty: a screenshot "succeeds" but shows wallpaper instead of your target app. `mac-ctl.sh screenshot` now uses `screencapture -l <winID>` as the primary path (via `find-window-id.swift`) so the failure mode is a clear error rather than a silent wallpaper image. If you see the "screencapture -l failed" warning, it's almost always this permission issue.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No app name" | Set `MAC_APP=AppName` or run `build` first |
| Tap not working | Grant Accessibility permission to Terminal in System Settings |
| `read` shows nothing | App may not support Accessibility; try `tree` for raw dump |
| Screenshot blank | Grant Screen Recording permission; or use `read` instead |
| Menu click fails | Ensure exact menu item name; use `menu` without args to list items |
| Build fails | Run `xcodegen generate` first if using project.yml |
