# Documentation

Start with the root [README](../README.md) for requirements, Xcode setup, signing, and building.

| Document | Purpose |
|---|---|
| [Release notes 0.9.2](ReleaseNotes-0.9.2.md) | Presentation overlay ordering and uninterrupted video preview |
| [Release notes 0.9.1](ReleaseNotes-0.9.1.md) | Slide navigation with clearing and direct drawer controls |
| [Release notes 0.9.0](ReleaseNotes-0.9.0.md) | Version contents, compatibility and limitations |
| [UserGuide.md](UserGuide.md) | Current US English user guide |
| [Anleitung.md](Anleitung.md) | Current German user guide |
| [Automation.md](Automation.md) | AppleScript properties, commands, and native Shortcuts reference (German) |
| [Automation examples](../Automation/Examples/) | Runnable AppleScript examples |
| [Architecture.md](Architecture.md) | Technical architecture |
| [Localization.md](Localization.md) | Translation resources, language selection, and validation limits |
| [Acceptance.md](Acceptance.md) | Hardware/manual acceptance checks |
| [Review-Fixes.md](Review-Fixes.md) | Review findings, fixes, and regression checks |
| [Build status](../BUILD-STATUS.md) | Concise current validation record |
| [Tools guide](../Tools/README.md) | Build, test, help, and archive commands |

## Editing documentation

Edit Markdown sources, then run `python3 Tools/render_help.py` to regenerate the two bundled HTML guides. Rebuild the Mac app to embed help updates. Keep stable automation identifiers and saved profile names separate from translated UI labels.

## Historical material

`Archive/` preserves the original German project/tools descriptions and the chronological build log. These are historical references, not current installation instructions. Use the root README and current guides when building or troubleshooting.
