# Workflow Skills

Two Claude Code skills for AI-assisted software development: a cross-platform debug toolkit and a team development workflow with enforced quality gates.

## Skills

### debug-kit

Cross-platform app debug toolkit. Build, launch, screenshot, tap, type, inspect, and monitor applications across **7 platforms**.

| Platform | Protocol / API | Key Capability |
|----------|---------------|----------------|
| **Electron** | Chrome DevTools Protocol | Zero-dep WebSocket CDP client, main+renderer console |
| **iOS** | xcrun simctl + JXA CGEvent | Touch simulation, accessibility tree dump via XCUITest |
| **macOS** | Accessibility API + CGEvent | Read UI state programmatically (no screenshot needed) |
| **Web** | CDP (reuses Electron client) | Chrome/Edge/Brave control, responsive viewport testing |
| **Flutter** | Flutter CLI + Dart VM Service | Auto-detect device, hot reload, delegates to iOS/Web/macOS |
| **React Native** | Metro + RN CLI / Expo | Bare RN and Expo Go support, delegates to iOS for interaction |
| **Android** | adb + uiautomator + gradle | Emulator management, UI hierarchy dump, input simulation |

#### Quick Start

```bash
P=~/.claude/skills/debug-kit/scripts

# Auto-detect platform and run
bash $P/pilot.sh auto screenshot /tmp/screen.png

# Or use platform-specific scripts directly
bash $P/ios-ctl.sh run /path/to/project
bash $P/ios-ctl.sh screenshot /tmp/ios.png
bash $P/ios-ctl.sh tap 200 400

CDP_PORT=9222 node $P/cdp-client.mjs launch dev
CDP_PORT=9222 node $P/cdp-client.mjs screenshot

bash $P/web-ctl.sh serve /path/to/project
bash $P/web-ctl.sh click "#submit"
```

#### Architecture

```
Electron  ─── cdp-client.mjs (zero-dep RFC 6455 WebSocket + CDP)
Web       ─── web-ctl.sh ──── cdp-client.mjs (reuses same client)
iOS       ─── ios-ctl.sh (simctl + CGEvent touch simulation)
macOS     ─── mac-ctl.sh (Accessibility API + CGEvent)
Flutter   ─── flutter-ctl.sh ──┬── ios-ctl.sh
                               ├── cdp-client.mjs
                               └── mac-ctl.sh
React Native ─ rn-ctl.sh ──── ios-ctl.sh
Android   ─── android-ctl.sh (adb + uiautomator)
```

---

### team-flow

Team development workflow with **enforced state machine**. Defines roles, card lifecycle, quality gates, and strict transition rules.

#### Roles

| Role | Responsibility |
|------|---------------|
| **PM** | Requirements, acceptance criteria, priorities |
| **Design** | Design system (DESIGN.md), UI specs, design review |
| **Dev** | Implementation, self-testing, bug fixes |
| **QA** | Testing (logic/UI/interaction/security), bug reports |

#### Card State Machine

```
PLAN ──①──> TODO ──②──> DEVING ──③──> DEV DONE ──④──> QA ──⑤──> QA DONE ──⑥──> COMPLETE
                          ↑                         ↑
                          └──── BLOCK ──────────────┘
```

Every state transition is a **gate** — AI must verify a checklist, provide evidence, and get user confirmation before proceeding. Illegal transitions (e.g., DEVING→QA skipping self-test) are explicitly forbidden.

| Gate | Transition | What's Verified |
|------|-----------|----------------|
| ① | PLAN→TODO | Card fields complete, PM+Design+Dev agree |
| ② | TODO→DEVING | Dev confirms understanding, no open questions |
| ③ | DEVING→DEV DONE | Self-test with debug-kit screenshots + logs as evidence |
| ④ | DEV DONE→QA | PM functional review + Design visual review + Dev demo |
| ⑤ | QA→QA DONE | Test report complete, all bug cards closed |
| ⑥ | QA DONE→COMPLETE | QA sign-off, no remaining issues |

#### Design System Integration

- Project maintains a `DESIGN.md` following industry standards (Stripe, Linear, Vercel, etc.)
- Reference 58 design systems via `npx getdesign@latest add <name>` ([awesome-design-md](https://github.com/VoltAgent/awesome-design-md))
- Use Pencil MCP to create actual design files (.pen)
- Design deliverables required per card: layout, component specs, interaction states, edge cases

#### QA Testing Coverage

| Dimension | Method |
|-----------|--------|
| Logic | Positive/negative/boundary flows with debug-kit tap+screenshot |
| UI | Screenshot comparison against DESIGN.md specs |
| Interaction | Click/input/scroll/navigation verification |
| Security | XSS/injection testing, console/network monitoring |
| Performance | Load time, memory, resource analysis |

---

## Installation

Copy the skills to your Claude Code skills directory:

```bash
# Clone
git clone git@github.com:dxiongya/workflow-skills.git

# Install globally (available in all projects)
cp -r workflow-skills/debug-kit ~/.claude/skills/
cp -r workflow-skills/team-flow ~/.claude/skills/
```

## Project Structure

```
workflow-skills/
├── debug-kit/
│   ├── SKILL.md                    Platform router + index
│   ├── references/                 Per-platform docs (loaded on demand)
│   │   ├── electron.md
│   │   ├── ios.md
│   │   ├── macos.md
│   │   ├── web.md
│   │   ├── flutter.md
│   │   ├── react-native.md
│   │   └── android.md
│   └── scripts/                    Executable tools
│       ├── pilot.sh                Unified router + platform auto-detect
│       ├── cdp-client.mjs          Zero-dep CDP client (Electron + Web)
│       ├── ios-ctl.sh              iOS Simulator control
│       ├── mac-ctl.sh              macOS Accessibility control
│       ├── web-ctl.sh              Chrome browser control
│       ├── flutter-ctl.sh          Flutter CLI wrapper
│       ├── rn-ctl.sh               React Native + Expo wrapper
│       └── android-ctl.sh          Android adb wrapper
│
└── team-flow/
    ├── SKILL.md                    Roles, state machine, stage overview
    └── references/
        ├── transitions.md          State transition gates (core enforcement)
        ├── plan.md                 Sprint planning (card creation)
        ├── dev.md                  Dev lifecycle (开卡→执行→结卡)
        ├── design.md               Design system + Pencil MCP + DESIGN.md
        ├── qa.md                   QA testing guide (logic/UI/interaction/security)
        └── integration.md          Integration testing (phase completion)
```

## Requirements

- **macOS** (for iOS Simulator, Accessibility API, CGEvent)
- **Node.js** (for CDP client, Metro bundler)
- **Xcode** (for iOS/macOS builds)
- **Chrome** (for Web debugging)
- **Flutter SDK** (for Flutter projects)
- **Android SDK** (for Android projects, optional)

## License

MIT
