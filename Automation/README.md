# Automation

PresentInk provides **43 AppleScript commands**, **11 application properties**, and **16 native Shortcuts actions** in the current source.

- Dictionary: [`Apps/macOS/PresentInk.sdef`](../Apps/macOS/PresentInk.sdef).
- Command manifest: [`Actions.json`](Actions.json).
- Reference: [`Docs/Automation.md`](../Docs/Automation.md) (German).
- English examples and property overview: [user guide](../Docs/UserGuide.md#applescript).

## AppleScript examples

| Script | Purpose |
|---|---|
| [Praesentationsstift.applescript](Examples/Praesentationsstift.applescript) | Set up a presentation pen |
| [Marker-Profil.applescript](Examples/Marker-Profil.applescript) | Configure a highlighter |
| [Mac-Drawer-vollstaendig-ausblenden.applescript](Examples/Mac-Drawer-vollstaendig-ausblenden.applescript) | Fully hide the Mac drawer |
| [Text-einfuegen.applescript](Examples/Text-einfuegen.applescript) | Insert text |
| [Praesentation-beenden.applescript](Examples/Praesentation-beenden.applescript) | Finish annotation control |

Open these in Script Editor and review the commands before running them. The examples can change drawing settings or visibility. Filenames remain stable; AppleScript terminology is English and accepted tool/color values include English and German aliases.

Native Shortcuts actions require an already-running Mac app and return typed objects. Most explicit AppleScript commands return JSON; property `get` returns the individual value. Multiple `set` assignments are not atomic. Drawing configuration, named profiles, and sharing permissions are separate concerns.
