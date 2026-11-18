# PresentInk

**Show what you mean.**

Live screen annotations for macOS, with an Apple Pencil companion for iPad.

Draw over a presentation, website, or software demo without changing the underlying content. Use your Mac's keyboard and trackpad, or draw on an iPad while viewing the selected Mac display.

**Version 0.9.2 (build 18)** uses the same version number for Mac, iPad Companion, and the Mac Shortcuts extension. German and US English are included. PresentInk remains a development release. Annotation sessions are not saved when the app quits. Finish or capture important annotations before restarting or installing an update.

Existing annotations can be dragged directly without a separate selection tool: move from the middle, adjust line endpoints, rotate rectangles/ellipses from bounding-box corners, and resize from edge midpoints. Shift on Mac or the iPad proportions/grid control preserves aspect ratio. Both finger and Pencil input are available, with Pencil priority and a palm-contact filter. Mac/iPad slide arrows navigate and clear annotations after successful native Keynote/PowerPoint automation; macOS asks for target-app Automation permission on first use. Both apps must be updated together (wire protocol 9).


See the [0.9.2 release notes](Docs/ReleaseNotes-0.9.2.md), [documentation index](Docs/README.md), and [validation status](BUILD-STATUS.md).

## Features

- Pen, highlighter, line, arrow, rectangle, ellipse, whole-stroke eraser, and text.
- Hold Shift when drawing shapes on the Mac to constrain proportions or angles.
- A reusable About view with a website placeholder, GitHub link, software direction credit, copyright, and the complete offline MIT License.
- Floating drawers with direct undoable clearing, quick tool, color, and width selection. Hide annotations and hide the Mac drawer independently.
- Central drawing preferences on the Mac: palettes, opacity, width limits, quick widths, Pencil pressure, and named profiles.
- Select a target display. Automatic display geometry changes preserve annotations and undo history; a deliberately requested display switch requires confirmation before clearing existing work.
- Native Apple Shortcuts actions with selectable output properties, plus an AppleScript dictionary.
- A native iPad companion with Pencil input, an authenticated local connection, and an optional Mac screen preview.
- Keynote presentation-window layering support. The user has confirmed iPad-to-Mac annotations, direct Mac drawing, drawer tool selection, and Control–Option–A in Keynote; this is not a blanket certification of all fullscreen/display combinations.

## Known issues and TODO

**LibreOffice Impress fullscreen is not working in the reported presentation setup in 0.9.2 (build 18).** The Mac drawer and annotations sent from the iPad may remain invisible over the slideshow. Window detection is implemented, but it has not resolved the on-device failure; LibreOffice fullscreen support is not verified.

- [ ] **TODO — Fix LibreOffice Impress fullscreen overlays:** reproduce window/Space ordering on the actual presentation displays, restore the Mac drawer and iPad-to-Mac annotations, and verify mouse/trackpad input before marking this supported.

## Requirements

- A Mac running **macOS 27 or later**.
- **Xcode 27.2** with the macOS and iPadOS 27 SDKs for the tested build environment.
- For the companion: an iPad running **iPadOS 27 or later**; Apple Pencil is recommended.
- An Apple development team and suitable signing/provisioning for the Mac app, its Shortcuts extension, and a physical iPad installation.
- Python 3 for generating the offline help and source ZIP. No Python dependency is needed to run the apps.

The two Swift packages are included locally. Building does not require an OpenAI API key, cloud service, or third-party package download.

## Build and run in Xcode

1. Download/clone the source and open **`PresentInk.xcodeproj`**.
2. Under **Signing & Capabilities**, choose your own team. Enable automatic signing. Use the same team for **PresentInkMac** and **PresentInkShortcuts**, which share a dedicated Keychain access group.
3. Select the appropriate scheme and destination:

| App | Scheme | Destination |
| --- | --- | --- |
| Mac | `PresentInkMac` | **My Mac** |
| iPad, physical device | `PresentInkCompanion` | Your connected iPad |
| iPad simulator | `PresentInkCompanion` | An installed iPad simulator |

4. Press **Command–R**.

`PresentInk` is also available as a legacy alias for the Mac scheme. **Do not select an iPad destination for the Mac scheme.** “Mismatched platform” means the scheme and device do not match; changing the Mac target's Base SDK is not the solution.

For a physical iPad, pair/trust the device in Xcode, enable Developer Mode when prompted, and install the iPadOS platform in Xcode if it is missing. The companion is a separate app, not embedded in the Mac app.

### Signing and your own app identity

Shared source ZIPs remove the development team ID. Select your own team after extraction. If using a new bundle identifier for an independent fork, update the Mac app and extension identifiers, Keychain access groups, entitlements, and the Mac bundle identifier lookup in `Apps/macOS/ShortcutAutomation.swift` consistently. Search for `de.presentink` before renaming.

**Copy the entire correctly signed `PresentInk.app` bundle** when installing into Applications. An unsigned/ad-hoc executable without the required entitlements cannot access the shared Shortcuts Keychain group and may report **−34018**. Do not remove signing or Keychain protections to work around this.

A development build is not a notarized public release. Distribution signing, notarization, and App Store submission are separate steps.

## Build from Terminal

Run these commands from the directory containing `PresentInk.xcodeproj`:

```sh
./Tools/build.sh mac
./Tools/build.sh ipad
./Tools/build.sh simulator
```

Optional overrides:

```sh
DEVELOPMENT_TEAM=YOUR_TEAM_ID ./Tools/build.sh mac
CONFIGURATION=Release ./Tools/build.sh mac
```

Configure automatic signing in Xcode first if provisioning profiles are missing. The simulator build disables signing; the Mac and physical-device builds do not. The script builds only: it does not install, launch, or replace running apps.

| Build | Debug product |
| --- | --- |
| Mac | `build/mac/Build/Products/Debug/PresentInk.app` |
| iPad | `build/ipad/Build/Products/Debug-iphoneos/PresentInk Companion.app` |
| Simulator | `build/simulator/Build/Products/Debug-iphonesimulator/PresentInk Companion.app` |

## Connect an iPad

1. Connect Mac and iPad to the same local network.
2. Start the companion host from the Mac's connection menu/window.
3. Open the companion app and select **Connect to Mac**. Allow local-network access when requested.
4. Enter the Mac's 32-character pairing key once and select the discovered Mac. Successful pairing is stored in the devices' Keychains.
5. Draw with Pencil. Mac mouse drawing can stay disabled while the iPad provides input.
6. Request the Mac screen preview on the iPad and approve it on the Mac. macOS screen-recording authorization is required for preview images; it is separate from pairing.

A newly entered key overrides a saved key after a pairing reset. Discovery uses Bonjour; the connection uses authenticated TLS-PSK. Guest Wi-Fi or client isolation may prevent connectivity. There is no manual IP, QR pairing, or Internet relay.

**Sidecar and the companion are alternatives.** To use the companion, run it as a normal iPad app rather than showing the Sidecar display surface.

## Essential controls

| Shortcut | Action |
| --- | --- |
| **Control–Option–A** | Toggle Mac drawing / presentation control |
| **Control–Option–W** | Show or minimize the Mac drawer, including reopening a fully hidden drawer |
| **Control–Option–Escape** | Emergency release of input and hide annotations |
| **P / H / L / A / R / O / E / T** | Pen / highlighter / line / arrow / rectangle / ellipse / eraser / text |
| **V / Escape** | Leave drawing mode |
| **Shift while dragging** | Constrain a shape |

Single-letter tool keys require drawing focus. Otherwise the presentation app receives the keys. The drawer's eye button toggles annotation visibility; its X button fully hides the Mac drawer. The iPad's Mac Drawer switch can show it again.

## AppleScript and Shortcuts

Search for **PresentInk** in Apple Shortcuts. The Mac app must already be running; native actions do not launch it implicitly. Output variables expose individual status, display, and settings properties without manual JSON parsing.

In Script Editor, open the dictionary for the installed app and choose **PresentInk Suite → application**. `set` and `get` are AppleScript language commands, not separate entries in the app dictionary.

```applescript
tell application "PresentInk"
    set current tool to "pen"
    set ink color to "red"
    set stroke width to 4
    set annotations visible to true
    set drawing enabled to true
    get stroke width
end tell
```

Readable/writable properties: `drawing enabled`, `annotations visible`, `drawer state`, `current tool`, `ink color`, `stroke width`, `display index`, `connection enabled`, and `preview enabled`. `status` and `available displays` are read-only JSON strings. Most explicit command-style operations still return a full JSON status. Separate property assignments are not atomic.

Automation identifiers and wire-format keys remain English and stable across UI languages. German and English value aliases are accepted for tools and colors.

## Privacy and permissions

ScreenCaptureKit captures the selected display for an explicitly enabled preview. Preview images are sent to the paired iPad; the app does not record them to disk. PresentInk overlay/drawer windows are excluded from capture to avoid duplicate annotations; approved help/settings windows can be included. Pairing and the local Shortcuts bridge use separate Keychain entries. No cloud account or analytics service is required.

Screen-recording, local-network, and AppleScript Automation permissions are controlled by the operating system. The app cannot bypass these prompts. Screen preview stops when the session is suspended; reconnect behavior and exact OS prompting can vary.

## Languages

The same app supports **German and US English**. The UI follows the operating system's per-app language preference; choose English in the Xcode scheme's **Run → Options → App Language** to test it. Restart after changing language, after finishing/capturing annotations. No separate US bundle identifier or pairing is needed.

AppKit labels, SwiftUI views, shared drawing/error messages, permission descriptions, App Intents labels, and the offline help have translations. System error messages use the OS language. Saved profile names and user text are preserved, including existing German preset profile names. AppleScript identifiers and protocol values are not translated.

Edit the German/English `.strings` resources in `Packages/PresentInkCore/Sources/PresentInkCore/Resources`. Runtime UI uses `inkLocalized`; App Intents retain literal keys for native localization and metadata extraction. The App Shortcuts phrase catalog is `SharedUI/AppShortcuts.xcstrings`. English help is `Docs/UserGuide.md`. Regenerate both HTML guides with `python3 Tools/render_help.py`.

## Tests and documentation

```sh
swift test --package-path Packages/PresentInkCore
swift test --package-path Packages/PresentInkLink
python3 Tools/render_help.py
```

Rebuild the Mac app after changing generated help. The latest review run passed **38 Core tests and 19 Link tests**. See [build evidence](BUILD-STATUS.md) and [review corrections](Docs/Review-Fixes.md) for the scope and outstanding hardware checks. Older entries in those documents are historical.

- [Documentation index](Docs/README.md)
- [English user guide](Docs/UserGuide.md)
- [Tools guide](Tools/README.md)
- [German user guide](Docs/Anleitung.md)
- [AppleScript and Shortcuts reference, German](Docs/Automation.md)
- [Hardware acceptance checklist](Docs/Acceptance.md)
- [Previous German project overview](Docs/Archive/ProjectOverview.de.md)

## Project structure

```text
Apps/macOS/          Mac overlay, drawer, menus, capture, and automation
Apps/iPadOS/         Pencil companion and connection UI
Apps/Shortcuts/      Embedded AppIntents extension
Packages/PresentInkCore/  Drawing model, geometry, settings, validation
Packages/PresentInkLink/  TLS peers, messages, pairing, preview relay
SharedUI/            Shared annotation renderer
Docs/                User guide and technical documentation
Tools/               Build, help generation, and source archive scripts
```

## Make changes and share source

Change UI code in the appropriate `Apps` folder, shared drawing logic in `PresentInkCore`, and connection behavior in `PresentInkLink`. Protocol changes require coordinated Mac/iPad updates. Keep stable profile names and automation identifiers separate from translated labels. Never edit generated build products.

Create a shareable source archive:

```sh
python3 Tools/archive.py
# or choose a destination outside the project:
python3 Tools/archive.py --output /tmp/PresentInk-source.zip
```

The ZIP is written beside the project by default. It excludes build products, user-specific Xcode data, provisioning profiles, and certificates, and removes the team ID from the archived project without changing your local project. It includes `SharedUI` and checks directly referenced Xcode inputs. Review new source/assets for secrets before sharing; the archive helper is not a complete secret scanner. Test a shared release by extracting its ZIP to a clean directory and building both schemes there.

## License and AI-assisted development

This project is licensed under the **MIT License**; see [LICENSE](LICENSE). You may use, modify, and redistribute the covered material, including commercially, subject to preserving the license and copyright notice.

PresentInk was developed with AI assistance. MIT does not require code to be exclusively human-authored; it grants permissions for rights the contributors hold. It does not establish copyrightability of generated material or grant rights to third-party content. Apple SDKs, trademarks, and external content shown in screenshots remain subject to their respective terms. Contributors should review generated code and preserve any applicable third-party notices.

License references: [MIT at OSI](https://opensource.org/license/mit) and [OpenAI Europe Terms, ownership of content](https://openai.com/policies/eu-terms-of-use/). The application itself contains no OpenAI integration and needs no API key.
