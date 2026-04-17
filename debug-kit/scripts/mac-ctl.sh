#!/usr/bin/env bash
# mac-ctl.sh - macOS Desktop App debug/test tool for Claude Code
# Uses: Accessibility API (JXA), CGEvent (JXA), xcodebuild, screencapture
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="${MAC_APP:-}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }

# ─── Build & Run ───

cmd_build() {
    local project_dir="${1:-.}"
    local scheme="${2:-}"
    cd "$project_dir"

    local project_flag=""
    if compgen -G "*.xcworkspace" >/dev/null 2>&1; then
        project_flag="-workspace $(echo *.xcworkspace | head -1)"
    elif compgen -G "*.xcodeproj" >/dev/null 2>&1; then
        project_flag="-project $(echo *.xcodeproj | head -1)"
    elif [[ -f project.yml ]]; then
        echo "Running xcodegen..."
        xcodegen generate 2>&1
        project_flag="-project $(echo *.xcodeproj | head -1)"
    elif [[ -f Package.swift ]]; then
        echo "Swift Package detected, building..."
        swift build 2>&1
        return
    else
        fail "No Xcode project found"
        return 1
    fi

    if [[ -z "$scheme" ]]; then
        scheme=$(xcodebuild -list $project_flag 2>/dev/null | grep -A 50 "Schemes:" | grep -v "Schemes:" | head -1 | xargs)
    fi

    echo "Building: $project_flag (scheme: $scheme)"
    xcodebuild build $project_flag -scheme "$scheme" -quiet 2>&1 | tail -5

    # Find built app
    local derived_data="$HOME/Library/Developer/Xcode/DerivedData"
    local app_path
    app_path=$(find "$derived_data" -name "*.app" -path "*/Debug/*" -not -name "*Tests*" -not -name "*Runner*" -not -path "*/iphonesimulator/*" -newer "$(echo *.xcodeproj | head -1)" -type d 2>/dev/null | head -1)

    if [[ -n "$app_path" ]]; then
        echo "$app_path" > /tmp/.macos-debug-app-path
        local app_name
        app_name=$(basename "$app_path" .app)
        echo "$app_name" > /tmp/.macos-debug-app-name
        ok "App: $app_path"
        ok "Name: $app_name"
    fi
}

cmd_launch() {
    local app_path="${1:-$(cat /tmp/.macos-debug-app-path 2>/dev/null)}"
    if [[ -z "$app_path" ]]; then
        fail "No app path. Run 'build' first."
        return 1
    fi
    echo "Launching $app_path..."
    open "$app_path"
    sleep 2
    local app_name
    app_name=$(basename "$app_path" .app)
    echo "$app_name" > /tmp/.macos-debug-app-name
    ok "Launched: $app_name"
}

cmd_terminate() {
    local app_name="${1:-$(cat /tmp/.macos-debug-app-name 2>/dev/null)}"
    if [[ -z "$app_name" ]]; then
        fail "No app name"
        return 1
    fi
    osascript -e "tell application \"$app_name\" to quit" 2>/dev/null || pkill -f "$app_name" 2>/dev/null || true
    ok "Terminated: $app_name"
}

cmd_run() {
    local project_dir="${1:-.}"
    cmd_build "$project_dir" "${2:-}"
    cmd_launch
}

# ─── Accessibility Tree (the core debugging tool for macOS) ───

_get_app_name() {
    local name="${APP_NAME:-$(cat /tmp/.macos-debug-app-name 2>/dev/null)}"
    if [[ -z "$name" ]]; then
        fail "No app name. Set MAC_APP=AppName or run 'build' first."
        exit 1
    fi
    echo "$name"
}

# Activate a running app by process name. Works for both bundled .app
# targets and unbundled dev binaries (e.g. Tauri `cargo run`, Electron dev
# mode). `tell application "X" to activate` fails with -1728 for processes
# LaunchServices doesn't know about, so we go through System Events first.
_activate() {
    local name="$1"
    osascript -e "tell application \"System Events\" to set frontmost of (first process whose name is \"$name\") to true" 2>/dev/null \
        || osascript -e "tell application \"$name\" to activate" 2>/dev/null \
        || true
}

cmd_tree() {
    local app_name
    app_name=$(_get_app_name)
    echo "=== Accessibility Tree: $app_name ==="

    osascript -l JavaScript << JSEOF > /tmp/macos-accessibility-tree.json
var se = Application("System Events");
var proc = se.processes.byName("$app_name");
var wins = proc.windows();

function dumpEl(el, depth) {
    if (depth > 6) return [];
    var result = [];
    try {
        var role = el.role();
        var name = ""; try { name = el.name() || ""; } catch(e) {}
        var val = ""; try { val = "" + (el.value() || ""); } catch(e) {}
        var desc = ""; try { desc = el.description() || ""; } catch(e) {}
        var pos = [0,0]; try { pos = el.position(); } catch(e) {}
        var sz = [0,0]; try { sz = el.size(); } catch(e) {}
        var enabled = true; try { enabled = el.enabled(); } catch(e) {}
        var ident = ""; try { ident = el.help() || ""; } catch(e) {}

        // Skip container-only roles at shallow depths
        var isInteractive = ["AXButton","AXTextField","AXSecureTextField","AXCheckBox",
            "AXRadioButton","AXSlider","AXPopUpButton","AXComboBox","AXTextArea",
            "AXMenuItem","AXLink","AXStaticText","AXImage","AXTable","AXOutline"].indexOf(role) >= 0;

        if (isInteractive || depth <= 1) {
            result.push({
                role: role,
                name: name,
                value: val,
                desc: desc,
                pos: [pos[0], pos[1]],
                size: [sz[0], sz[1]],
                enabled: enabled
            });
        }

        var children = el.uiElements();
        for (var i = 0; i < children.length; i++) {
            result = result.concat(dumpEl(children[i], depth + 1));
        }
    } catch(e) {}
    return result;
}

var allElements = [];
for (var w = 0; w < wins.length; w++) {
    allElements = allElements.concat(dumpEl(wins[w], 0));
}
JSON.stringify(allElements, null, 2);
JSEOF

    ok "Saved to /tmp/macos-accessibility-tree.json"

    # Summary
    /usr/bin/python3 << 'PYEOF'
import json
with open("/tmp/macos-accessibility-tree.json") as f:
    elements = json.load(f)
print(f"  Total elements: {len(elements)}")
roles = {}
for e in elements:
    r = e.get("role","?")
    roles[r] = roles.get(r,0) + 1
for r, c in sorted(roles.items()):
    print(f"    {r}: {c}")
print()
print("  Interactive elements:")
for e in elements:
    r = e.get("role","")
    if r in ("AXButton","AXTextField","AXSecureTextField","AXCheckBox","AXSlider","AXPopUpButton","AXTextArea","AXLink"):
        name = e.get("name") or e.get("desc") or e.get("value") or "-"
        pos = e.get("pos",[0,0])
        sz = e.get("size",[0,0])
        print(f"    [{r.replace('AX','')}] \"{name}\" @ ({pos[0]},{pos[1]} {sz[0]}x{sz[1]})")
PYEOF
}

cmd_read() {
    local app_name
    app_name=$(_get_app_name)

    echo "=== UI State: $app_name ==="
    osascript -l JavaScript << JSEOF
var se = Application("System Events");
var proc = se.processes.byName("$app_name");
var win = proc.windows[0];

function readAll(el, depth) {
    if (depth > 5) return [];
    var result = [];
    try {
        var role = el.role();
        var name = ""; try { name = el.name() || ""; } catch(e) {}
        var val = ""; try { val = "" + (el.value() || ""); } catch(e) {}
        var relevant = ["AXStaticText","AXTextField","AXSecureTextField","AXCheckBox",
            "AXSlider","AXPopUpButton","AXComboBox","AXTextArea"].indexOf(role) >= 0;
        if (relevant && (name || val)) {
            var indent = "";
            for (var i = 0; i < depth; i++) indent += "  ";
            result.push(indent + role.replace("AX","") + ": " + (name || val) + (val && val !== name ? " = \"" + val + "\"" : ""));
        }
        var children = el.uiElements();
        for (var i = 0; i < children.length; i++) {
            result = result.concat(readAll(children[i], depth + 1));
        }
    } catch(e) {}
    return result;
}

var lines = readAll(win, 0);
lines.join("\n");
JSEOF
}

# ─── Interaction ───

cmd_tap() {
    local x="${1:-}"
    local y="${2:-}"
    local app_name
    app_name=$(_get_app_name)

    if [[ -z "$x" || -z "$y" ]]; then
        echo "Usage: mac-ctl tap <x> <y>"
        echo "       mac-ctl tap label <text>"
        echo "       mac-ctl tap desc <description>"
        return 1
    fi

    # Look up by label or description
    if [[ "$x" == "label" || "$x" == "desc" || "$x" == "name" ]]; then
        local search_key="$x"
        local search_value="$y"
        if [[ "$search_key" == "label" ]]; then search_key="name"; fi

        if [[ ! -f /tmp/macos-accessibility-tree.json ]]; then
            warn "No tree data. Running tree first..."
            cmd_tree
        fi

        local coords
        coords=$(/usr/bin/python3 << PYEOF
import json
with open("/tmp/macos-accessibility-tree.json") as f:
    elements = json.load(f)
for e in elements:
    val = e.get("$search_key","") or e.get("name","") or e.get("desc","")
    if "$search_value" in val:
        p = e["pos"]; s = e["size"]
        print("%d %d" % (p[0] + s[0]//2, p[1] + s[1]//2))
        break
PYEOF
)
        if [[ -z "$coords" ]]; then
            fail "Element not found: $search_key='$search_value'"
            return 1
        fi
        x=$(echo "$coords" | cut -d' ' -f1)
        y=$(echo "$coords" | cut -d' ' -f2)
        echo "  Resolved: ($x, $y)"
    fi

    echo "Tapping at ($x, $y)..."
    _activate "$app_name"
    sleep 0.2

    osascript -l JavaScript -e "
        ObjC.import('CoreGraphics');
        var p = \$.CGPointMake($x, $y);
        var d = \$.CGEventCreateMouseEvent(null, \$.kCGEventLeftMouseDown, p, \$.kCGMouseButtonLeft);
        \$.CGEventPost(\$.kCGHIDEventTap, d);
        delay(0.05);
        var u = \$.CGEventCreateMouseEvent(null, \$.kCGEventLeftMouseUp, p, \$.kCGMouseButtonLeft);
        \$.CGEventPost(\$.kCGHIDEventTap, u);
    " 2>&1

    ok "Tap dispatched at ($x, $y)"
}

cmd_type() {
    local text="${1:-}"
    local app_name
    app_name=$(_get_app_name)

    if [[ -z "$text" ]]; then
        echo "Usage: mac-ctl type <text>"
        return 1
    fi

    _activate "$app_name"
    sleep 0.2
    osascript -e "tell application \"System Events\" to keystroke \"$text\"" 2>&1
    ok "Typed: $text"
}

cmd_key() {
    local keyspec="${1:-}"
    local app_name
    app_name=$(_get_app_name)

    if [[ -z "$keyspec" ]]; then
        echo "Usage: mac-ctl key <keyspec>"
        echo "Examples: mac-ctl key return, mac-ctl key cmd+q, mac-ctl key tab"
        return 1
    fi

    _activate "$app_name"
    sleep 0.2

    # Parse modifiers and key
    local key_code=""
    local modifiers=""
    IFS='+' read -ra parts <<< "$keyspec"
    for part in "${parts[@]}"; do
        case "$part" in
            cmd|command) modifiers="${modifiers}command down, " ;;
            ctrl|control) modifiers="${modifiers}control down, " ;;
            alt|option) modifiers="${modifiers}option down, " ;;
            shift) modifiers="${modifiers}shift down, " ;;
            return|enter) key_code="36" ;;
            tab) key_code="48" ;;
            escape|esc) key_code="53" ;;
            delete|backspace) key_code="51" ;;
            space) key_code="49" ;;
            *) key_code="" ;; # Will use keystroke for regular characters
        esac
    done
    modifiers="${modifiers%, }"

    local key_char="${parts[-1]}"

    if [[ -n "$key_code" ]]; then
        if [[ -n "$modifiers" ]]; then
            osascript -e "tell application \"System Events\" to key code $key_code using {$modifiers}" 2>&1
        else
            osascript -e "tell application \"System Events\" to key code $key_code" 2>&1
        fi
    else
        if [[ -n "$modifiers" ]]; then
            osascript -e "tell application \"System Events\" to keystroke \"$key_char\" using {$modifiers}" 2>&1
        else
            osascript -e "tell application \"System Events\" to keystroke \"$key_char\"" 2>&1
        fi
    fi

    ok "Key: $keyspec"
}

# ─── Screenshot ───

cmd_screenshot() {
    local output="${1:-/tmp/macos-app-screenshot.png}"
    local app_name
    app_name=$(_get_app_name)

    # Activate the app
    _activate "$app_name"

    # Method 1: window-targeted capture via `screencapture -l <winID>`.
    # Needs the CGWindowID (not exposed via AppleScript/AX); we find it
    # with a small Swift helper. This is the only method that works
    # reliably across macOS Spaces and for unfocused windows.
    local wid=""
    if command -v swift >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/find-window-id.swift" ]]; then
        wid=$(swift "$SCRIPT_DIR/find-window-id.swift" "$app_name" 2>/dev/null || true)
    fi
    if [[ -n "$wid" ]]; then
        if screencapture -l "$wid" -x "$output" 2>/dev/null && [[ -s "$output" ]]; then
            ok "Screenshot saved to $output (window-targeted, wid=$wid)"
            _screenshot_resize "$output"
            return 0
        fi
        # screencapture -l failed → almost always Screen Recording permission denied.
        warn "screencapture -l failed. This is usually a Screen Recording permission issue."
        warn "Grant it in: System Settings → Privacy & Security → Screen Recording → <your terminal / Claude Code>"
    fi

    # Method 2: compiled ScreenCaptureKit helper (if user pre-built one)
    if [[ -x /tmp/capture-window ]]; then
        /tmp/capture-window "$app_name" "$output" 2>/dev/null && return 0
    fi

    # Method 3: full-screen + crop fallback (cannot cross Spaces; also
    # produces wallpaper pixels when Screen Recording permission is
    # denied, because macOS redacts other apps' window contents).
    local bounds
    bounds=$(osascript -e "
        tell application \"System Events\"
            tell process \"$app_name\"
                set {wx, wy} to position of front window
                set {ww, wh} to size of front window
                return \"\" & wx & \" \" & wy & \" \" & ww & \" \" & wh
            end tell
        end tell
    " 2>/dev/null)

    if [[ -n "$bounds" ]]; then
        read -r wx wy ww wh <<< "$bounds"
        screencapture -x /tmp/_macos_full_tmp.png 2>/dev/null
        # Retina: multiply by 2
        local px=$((wx * 2)) py=$((wy * 2)) pw=$((ww * 2)) ph=$((wh * 2))
        sips -c "$ph" "$pw" --cropOffset "$py" "$px" /tmp/_macos_full_tmp.png --out "$output" 2>/dev/null
        rm -f /tmp/_macos_full_tmp.png
        warn "Screenshot saved to $output (fallback: full-screen crop — may show wallpaper if permission missing)"
    else
        screencapture -x "$output" 2>/dev/null
        warn "Screenshot saved to $output (fallback: full screen)"
    fi
    _screenshot_resize "$output"
}

# Resize to fit Claude's image dimension limit (max 1200px height)
_screenshot_resize() {
    local path="$1" MAX=1900
    local dims w h
    dims=$(sips -g pixelWidth -g pixelHeight "$path" 2>/dev/null)
    w=$(echo "$dims" | awk '/pixelWidth/{print $2}')
    h=$(echo "$dims" | awk '/pixelHeight/{print $2}')
    if [[ -n "$w" && "$w" -gt "$MAX" ]] && [[ -z "$h" || "$w" -ge "$h" ]]; then
        sips --resampleWidth "$MAX" "$path" >/dev/null 2>&1
    elif [[ -n "$h" && "$h" -gt "$MAX" ]]; then
        sips --resampleHeight "$MAX" "$path" >/dev/null 2>&1
    fi
}

# ─── Window Management ───

cmd_window() {
    local action="${1:-info}"
    local app_name
    app_name=$(_get_app_name)

    case "$action" in
        info)
            osascript -l JavaScript << JSEOF
var se = Application("System Events");
var proc = se.processes.byName("$app_name");
var wins = proc.windows();
var result = [];
for (var i = 0; i < wins.length; i++) {
    var w = wins[i];
    result.push("  Window " + i + ": \"" + w.name() + "\" @ (" + w.position() + ") " + w.size()[0] + "x" + w.size()[1] + " focused=" + w.focused());
}
result.join("\n");
JSEOF
            ;;
        move)
            local x="${2:-100}" y="${3:-100}"
            osascript -e "tell application \"System Events\" to tell process \"$app_name\" to set position of front window to {$x, $y}"
            ok "Window moved to ($x, $y)"
            ;;
        resize)
            local w="${2:-800}" h="${3:-600}"
            osascript -e "tell application \"System Events\" to tell process \"$app_name\" to set size of front window to {$w, $h}"
            ok "Window resized to ${w}x${h}"
            ;;
        focus)
            _activate "$app_name"
            ok "App focused"
            ;;
    esac
}

# ─── Logs ───

cmd_log() {
    local seconds="${1:-10}"
    local app_name
    app_name=$(_get_app_name)

    echo "Streaming logs for $app_name (${seconds}s)..."
    timeout "$seconds" log stream --predicate "processImagePath CONTAINS \"$app_name\"" --level=debug 2>/dev/null || true
}

# ─── Health Check ───

cmd_health() {
    local app_name
    app_name=$(_get_app_name)

    echo "=== macOS App Health Check: $app_name ==="

    # Check if running
    if pgrep -f "$app_name" >/dev/null 2>&1; then
        ok "Process running"
        local pid
        pid=$(pgrep -f "$app_name" | head -1)
        local mem
        mem=$(ps -o rss= -p "$pid" | xargs)
        ok "PID: $pid, RSS: $((mem / 1024))MB"
    else
        fail "Process not running"
        return 1
    fi

    # Check window
    local win_count
    win_count=$(osascript -e "tell application \"System Events\" to tell process \"$app_name\" to count of windows" 2>/dev/null || echo "0")
    ok "Windows: $win_count"

    # Quick UI state
    cmd_read

    echo ""
    echo "=== Health check complete ==="
}

# ─── Menu ───

cmd_menu() {
    local menu_path="${1:-}"
    local app_name
    app_name=$(_get_app_name)

    if [[ -z "$menu_path" ]]; then
        # List available menus
        echo "=== Menus for $app_name ==="
        osascript -l JavaScript << JSEOF
var se = Application("System Events");
var proc = se.processes.byName("$app_name");
var menuBar = proc.menuBars[0];
var menus = menuBar.menuBarItems();
var result = [];
for (var i = 0; i < menus.length; i++) {
    var m = menus[i];
    var name = m.name();
    if (!name) continue;
    var items = [];
    try {
        var menuItems = m.menus[0].menuItems();
        for (var j = 0; j < menuItems.length; j++) {
            try {
                var itemName = menuItems[j].name();
                if (itemName) items.push(itemName);
            } catch(e) {}
        }
    } catch(e) {}
    result.push("  " + name + ": " + items.join(", "));
}
result.join("\n");
JSEOF
        return
    fi

    # Click a menu item: "Menu > Item"
    IFS='>' read -ra parts <<< "$menu_path"
    local menu_name="${parts[0]// /}"
    local item_name="${parts[1]// /}"

    _activate "$app_name"
    sleep 0.2
    osascript -e "
        tell application \"System Events\"
            tell process \"$app_name\"
                click menu item \"$item_name\" of menu \"$menu_name\" of menu bar 1
            end tell
        end tell
    " 2>&1
    ok "Clicked menu: $menu_name > $item_name"
}

# ─── Help ───

cmd_help() {
    cat << 'HELP'
mac-ctl - macOS Desktop App debug/test tool for Claude Code

BUILD & RUN:
  build [dir] [scheme]     Build macOS project
  launch [app-path]        Launch built app
  terminate [app-name]     Quit app
  run [dir] [scheme]       Build + Launch in one command

INSPECTION (via Accessibility API - no screen recording needed):
  tree                     Dump full accessibility tree as JSON
  read                     Read current UI state (text values, checkboxes, etc.)
  health                   Health check (process, windows, UI state)

INTERACTION (via CGEvent + AppleScript):
  tap <x> <y>             Click at absolute coordinates
  tap label <text>        Click element by name/label
  tap desc <description>  Click element by description
  type <text>             Type text (element must be focused)
  key <keyspec>           Send key (e.g., return, tab, cmd+s, cmd+q)
  menu                    List available menus
  menu "Menu > Item"      Click a menu item

WINDOW:
  window info             Show window positions and sizes
  window move <x> <y>     Move window
  window resize <w> <h>   Resize window
  window focus             Bring app to front

SCREENSHOT:
  screenshot [path]       Capture app window (needs Screen Recording permission)

LOGS:
  log [seconds]           Stream app console logs

ENV VARS:
  MAC_APP=AppName         Override app name detection
HELP
}

# ─── Main ───

cmd="${1:-help}"
shift 2>/dev/null || true

case "$cmd" in
    build)       cmd_build "$@" ;;
    launch)      cmd_launch "$@" ;;
    terminate)   cmd_terminate "$@" ;;
    run)         cmd_run "$@" ;;
    tree)        cmd_tree "$@" ;;
    read)        cmd_read "$@" ;;
    tap)         cmd_tap "$@" ;;
    type)        cmd_type "$@" ;;
    key)         cmd_key "$@" ;;
    screenshot)  cmd_screenshot "$@" ;;
    window)      cmd_window "$@" ;;
    log)         cmd_log "$@" ;;
    health)      cmd_health "$@" ;;
    menu)        cmd_menu "$@" ;;
    help|--help|-h) cmd_help ;;
    *)           echo "Unknown: $cmd"; cmd_help ;;
esac
