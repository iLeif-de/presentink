# PresentInk tools

Run commands from the project root, which contains `PresentInk.xcodeproj`.

## Build

```sh
./Tools/build.sh mac
./Tools/build.sh ipad
./Tools/build.sh simulator
```

Use Xcode 27.2 and install its macOS/iPadOS 27 SDKs. Choose your development team and automatic signing in Xcode first. Both the Mac app and Shortcuts extension need the same team and compatible Keychain entitlements. Physical iPad installation also requires device pairing and Developer Mode.

Optional: `DEVELOPMENT_TEAM=YOUR_TEAM_ID ./Tools/build.sh mac` or `CONFIGURATION=Release ./Tools/build.sh mac`. Products are in `build/<mode>/Build/Products`. These commands do not install, launch, or notarize apps. In Xcode use **PresentInkMac → My Mac** or **PresentInkCompanion → your iPad**, then Command–R.

## Test

```sh
swift test --package-path Packages/PresentInkCore
swift test --package-path Packages/PresentInkLink
```

## Regenerate help

```sh
python3 Tools/render_help.py
```

This renders `Docs/Anleitung.md` and `Docs/UserGuide.md` to offline HTML. Rebuild the Mac app to embed changes.

## Create a source ZIP

```sh
python3 Tools/archive.py
python3 Tools/archive.py --output /tmp/PresentInk-source.zip
```

The default ZIP is created beside the project folder and replaces a previous ZIP at that destination. The archive contains selected source, localized resources, documentation, design assets, and LICENSE. The archive walks only approved source roots and includes the root `.gitignore`. It verifies that every AppleScript example is included. It excludes build products, user-specific Xcode state, credentials, and provisioning profiles; it removes the team ID from the archived Xcode project only. New source roots/file types must be added to the `roots`/`allowed` lists. Review source for embedded secrets; this is not a complete secret scanner. Always build a shared release from a clean extraction of its ZIP.

## Where to make changes

| Change | Location |
|---|---|
| Mac drawer | `Apps/macOS/MacToolDrawer.swift` |
| Mac menus and shortcuts | `Apps/macOS/MacMenus.swift`, `MacAppDelegate.swift` |
| Mac drawing/settings | `MacCanvasView.swift`, `MacSession.swift`, `MacDrawingSettingsView.swift` |
| iPad UI/input | `Apps/iPadOS/ToolDrawerView.swift`, `CompanionView.swift`, `PencilCanvasView.swift` |
| Shared model/geometry/settings | `Packages/PresentInkCore/Sources/PresentInkCore` |
| Pairing, TLS, protocol | `Packages/PresentInkLink/Sources/PresentInkLink` |
| UI translations | `PresentInkCore/Resources/{de,en}.lproj` and `SharedUI/AppShortcuts.xcstrings` |
| Shortcuts / AppleScript | `PresentInkIntents.swift`, `ShortcutEntities.swift`, `PresentInk.sdef`, `AppleScriptSupport.swift`, `MacAutomation.swift` |
| Documentation | `Docs/UserGuide.md` (English), `Docs/Anleitung.md` (German) |

Back up your work before editing. Add new Swift files to the correct Xcode target or local package. Do not edit generated build products. Keep bundle IDs, Keychain groups, and extension identity consistent when creating a fork. Protocol changes need both apps updated. Keep stored IDs/profile names separate from translated labels. Update versions and build evidence for a release, then build and test relevant functionality. Annotation sessions are not persisted; do not close a running app with important drawings merely to update it.

See the root [README](../README.md) for detailed setup, architecture, and licensing. The previous German tools guide is preserved in [Docs/Archive/Tools.de.md](../Docs/Archive/Tools.de.md).
