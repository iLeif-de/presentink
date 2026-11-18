# PresentInk 0.9.0

Version **0.9.0**, build **16**, for macOS, iPad Companion, and the Mac Shortcuts extension. This is a source/development release under the MIT License. The version unifies the earlier platform-specific development numbers; it does not imply removal of features.

## Included

- Native Mac overlay drawing and an authenticated iPad companion with optional Mac screen preview.
- Pen, highlighter, lines, arrows, rectangles, ellipses, eraser, and direct inline text entry.
- Direct object editing without a selection mode: move from the middle, adjust endpoints, rotate rectangles/ellipses from bounding-box corners, and resize from edge midpoints. Shift or the iPad proportions/grid button constrains edits.
- Pencil and finger input without a mode switch, with Pencil priority and a palm-contact filter.
- Done/Cancel in a dedicated iPad text header, including use with floating keyboards and Pencil Scribble.
- iPad previous/next slide controls using native Keynote/PowerPoint automation.
- Content-sized drawers with directional collapse/reopen chevrons, quick colors/sizes, and Mac tooltips.
- Central Mac drawing settings and profiles shared with iPad; AppleScript and native Shortcuts output properties.
- German and US English interfaces and offline help, with chapter navigation on Mac.
- Reusable About view with Software Direction credit, copyright, website placeholder, GitHub link, and full offline MIT License.

## Final changes for 0.9.0

The drawing canvas uses the ordinary arrow cursor instead of a crosshair. Contextual move/resize cursors remain available over editable objects. The Hausnerd website link has been removed from both About views; the GitHub link remains. Documentation and project metadata use the same version on both platforms.

## Compatibility and building

- macOS 27 / iPadOS 27 or later; tested build environment Xcode 27.2.
- Update both apps together: **wire protocol 7**. Existing pairing keys and drawing preferences remain valid.
- Open `PresentInk.xcodeproj`, choose your own development team and the appropriate scheme/device. The repository contains no developer signing credentials.
- Mac scheme: `PresentInkMac` → My Mac. iPad scheme: `PresentInkCompanion` → the iPad.
- The first slide-navigation request requires macOS Automation permission for Keynote or PowerPoint. Screen preview separately requires the relevant system permissions.

See [building instructions](../README.md), [tools](../Tools/README.md), [English guide](UserGuide.md), and [German guide](Anleitung.md).

## Validation and limits

See [BUILD-STATUS.md](../BUILD-STATUS.md) for the current checks. Automated geometry/protocol tests and successful builds do not replace the manual [hardware acceptance checklist](Acceptance.md).

Annotation sessions are not saved when the app quits. One target display and one companion are supported at a time. No annotation export, cloud relay, recording, or automatic per-slide drawing storage is included. A protected system window, DRM content, or an exclusive presentation mode can restrict display/capture. iPad palm filtering reduces accidental touches but is not perfect. Native slide navigation and first-time permissions should be checked with the intended presentation setup before a talk.
