# PresentInk User Guide — 0.9.2

Mac and iPad Companion · US English

## Start with the Mac

Open PresentInk. Choose your target display in **View → Target Display**. Open your slides, browser, or demonstration app as usual. PresentInk draws on a separate transparent layer over that display.

The current prototype does not save drawing sessions when it quits. Capture important work before restarting or replacing the app. Undo history belongs to the running session.

## Drawing and presentation control

- **Control–Option–A:** toggle Mac drawing mode.
- **Control–Option–W:** reopen or minimize the Mac drawer, even when it was fully hidden.
- **Control–Option–Escape:** release input and hide annotations immediately.
- **V / Escape:** leave drawing mode and return input to the presentation.

When drawing is off, mouse clicks and keyboard input go to the underlying app. Your annotations can remain visible. Single-letter tool shortcuts apply only when the drawing canvas has keyboard focus.

## Tools and colors

Use the drawer or press **P** for pen, **H** for highlighter, **L** for line, **A** for arrow, **R** for rectangle, **O** for ellipse, **E** for eraser, or **T** for text.

Hold **Shift** when dragging shapes to constrain proportions or angles. The eraser removes complete strokes or text objects. Undo and redo restore previous drawing states. Choose Text and click/tap the canvas to type directly at that position. With Text selected, click/tap an existing label (or double-click/tap it) to edit it again. Return inserts a newline; Command–Return confirms; Escape cancels. On iPad, Done and Cancel remain available in a dedicated top bar independently of keyboard size; the tool drawer is hidden while editing. Native Pencil Scribble is supported. The canvas remains stable when the keyboard opens; a docked keyboard may cover its lower area. Pencil and fingers can both place or reopen labels without a mode switch. Keyboard and toolbar controls always accept finger input. Clicking outside the editor confirms the text; on iPad, this tap does not open a new label. Tool letters are treated as text while editing. Empty input cancels without deleting an existing label.

Each confirmed edit is one undo step and retains position, size, color, and object identity. Draft text appears only on the editing device; confirmation sends it to the other device. Concurrent stale edits are rejected. Both apps must be updated together (wire protocol 9). Object editing uses invisible hit zones without a selection mode.

The eye button shows or hides annotations. On Mac it sits on the right, after the size presets and before the X. The Mac drawer has more side padding; the iPad drawer uses its content width with smaller side padding and keeps full-size touch targets. On Mac, the small down chevron minimizes the drawer; the up chevron reopens it. The former horizontal grabber bar is removed. Compact mode remains available through the menu or Shift–Command–D when PresentInk is active. The X button fully hides the Mac drawer. These are separate controls; hiding the drawer does not stop iPad input or screen sharing. The Mac drawer sizes itself to its visible controls. Hover tooltips explain controls and shortcuts, including which shortcuts require the active app.

## Connect an iPad

1. Put both devices on the same local network.
2. Open **Connection → Connect iPad** on the Mac and start the connection.
3. Open PresentInk Companion on the iPad, allow local-network access, and select your Mac.
4. Enter the Mac's 32-character pairing key once. Both devices save pairing in Keychain.
5. Draw with Apple Pencil. The Mac can remain in presentation control mode while the iPad supplies strokes.

Bonjour discovery does not authorize a connection. The pairing key authenticates an encrypted TLS connection. Guest Wi-Fi or client isolation may prevent communication. There is no Internet relay, QR pairing, or manual IP entry.

If you reset pairing on the Mac, enter the new key on the iPad; a new entry takes priority over the saved key. Resetting pairing revokes previous keys.

## Mac screen preview

Tap **Show Mac Screen** on the iPad and approve the request on the Mac. macOS requires screen-recording authorization independently of PresentInk's pairing permission. Approve it in **System Settings → Privacy & Security → Screen & System Audio Recording**, then try again if needed.

The iPad displays the selected Mac screen behind the annotations. PresentInk's annotation layer is rendered separately, so it is not duplicated in captured images. The Mac settings, guide, and keyboard-shortcut windows may be included in the preview; the drawer and connection window are excluded.

**Pause Preview** stops image transmission. You can still draw on a blank canvas while connected. Remembering approval can avoid repeated PresentInk dialogs; macOS can still require system authorization. Auto-start is separate from remembered approval. A deliberately paused preview stays paused until explicitly started or requested again.

For the text tool, the Mac and iPad drawers show differently sized **A** letters for quick font-size selection instead of stroke-width dots. Letter sizes indicate the relative preset sizes; the selected point value is the actual font size.

## Settings and profiles

The Mac is the settings master. Open **PresentInk → Settings** to configure the shared palette, tool visibility/order, opacity, default and quick widths, minimum/maximum widths, and Pencil pressure.

Settings affect new strokes; existing annotations retain their appearance. Save profiles for light slides, dark slides, or other uses. Switching tools retains the active profile name. Changing style values makes the configuration custom. Existing user-defined profile names are not translated or renamed.

## Keynote and multiple displays

PresentInk raises its panels above detected Keynote presentation windows. Select the desired slide or presenter display explicitly. iPad annotations, direct Mac drawing, drawer selection, and **Control–Option–A** have been confirmed in a user Keynote test; other display/Space combinations still need individual testing.

If annotations appear but the mouse does not draw, enable drawing with **Control–Option–A**. If you cannot see tools, reopen the drawer with **Control–Option–W** or its iPad switch. In presentation control mode, Keynote receives the keyboard.

Automatic display geometry changes retain completed annotations and undo history, though normalized geometry can appear scaled. A deliberately confirmed target-display switch clears existing annotations and pauses the preview. A change of Space ends local drawing; enable it again when needed.

## AppleScript

In Script Editor, open the installed PresentInk dictionary and choose **PresentInk Suite → application**. The dictionary's property and command names stay English in both UI languages.

```applescript
tell application "PresentInk"
    set current tool to "pen"
    set ink color to "red"
    set stroke width to 4
    set drawer state to "compact"
    set annotations visible to true
    set drawing enabled to true
    get stroke width
end tell
```

`set` and `get` are part of AppleScript itself. These properties are readable and writable:

| Property | Values |
|---|---|
| `drawing enabled` | Boolean |
| `annotations visible` | Boolean |
| `drawer state` | `expanded`, `compact`, `hidden` (handle), `invisible` (fully hidden) |
| `current tool` | `pen`, `marker`, `line`, `arrow`, `rectangle`, `ellipse`, `eraser`, `text` |
| `ink color` | Color name or `#RRGGBB`; reading returns hex |
| `stroke width` | Number within the selected tool's configured limits |
| `display index` | Integer starting at 1; changing display with existing annotations requires explicit clearance |
| `connection enabled` | Host connection enabled; not necessarily an iPad connected |
| `preview enabled` | Preview requested/running; startup is asynchronous |

`status` and `available displays` are read-only JSON strings. Most command-style operations return a full status JSON string. Property reads return the selected value. Separate `set` operations are not atomic. English and German tool/color aliases remain accepted. Profiles and opacity currently use dedicated commands rather than properties.

## Apple Shortcuts

Search for **PresentInk** in Shortcuts. The Mac app must already be running; native actions return a helpful error if it is stopped. Use Apple's **Open App** action explicitly if you want to start it first.

Actions return typed status, display, or settings objects. Click the output variable in a subsequent action and choose the desired property, such as **Drawing Mode Enabled** or **Stroke Width / Font Size**. No JSON conversion is needed. More than one running Mac app copy produces an error rather than controlling an ambiguous target.

## Language and permissions

PresentInk supports German and US English. Use the operating system's per-app language setting or select an application language in the Xcode scheme's Run options. Quit and relaunch after changing the language; finish or capture annotations first. Automation IDs, stored values, wire-format keys, and saved profile names stay stable across languages.

macOS manages screen-recording and AppleScript Automation permissions. Both platforms manage local-network permissions. PresentInk does not bypass operating-system prompts. No cloud account, analytics service, or OpenAI API key is required to run it.

## Troubleshooting

- **No Mac discovered:** start the Mac host; check local-network permission, firewall, and network isolation.
- **Keychain error −34018:** use the complete correctly signed Mac app with its matching Shortcuts extension and shared Keychain entitlements. Copying an unsigned executable is insufficient.
- **No screen images:** request/approve preview, check system capture access, and verify the selected display.
- **No keyboard tool selection:** enable drawing first; letter shortcuts do not apply when another app owns the keyboard.
- **After sleep or locking:** the connection stops while the session is inactive. A previously enabled host restarts after return; check the preview state and reconnect if necessary.
- **“Mismatched platform” in Xcode:** use `PresentInkMac → My Mac` or `PresentInkCompanion → your iPad`.


## About PresentInk

On the Mac, choose **PresentInk → About PresentInk**. On the iPad, tap the info icon beside the app name. The shared About view displays version/build information, **Software Direction: Leif Jensen-Pistorius**, copyright, AI-assisted development credit, a link to the GitHub repository, and a noninteractive **App Website Coming Soon** placeholder.

Expand the license section to read and copy the complete MIT License. The license ships with both apps and is available offline. The GitHub link opens only when selected; the About view does not load a website in the background.


## Direct object editing

With drawing enabled, drag an existing annotation without a selection mode or permanent selection frames. The topmost hit object wins. Eraser still erases and Text still writes/edits text. On empty canvas, the current tool draws. Hold Option on Mac to draw over existing objects.

| Drag location | Behavior |
|---|---|
| Middle of a line, arrow or freehand stroke | Move the object |
| Either endpoint | Keep the other end fixed; change length and direction. Freehand strokes rotate and stretch as a whole |
| Inside a rectangle or ellipse | Move |
| Corner of its bounding rectangle | Rotate around the center |
| Midpoint of an edge | Resize that edge; the opposite edge stays fixed |
| Visible text, using a drawing tool | Move; use Text to edit contents |

Ellipse corner regions lie at the virtual bounding rectangle's corners. Mac hover cursors hint at the operation. Shift on Mac or the always-visible proportions/grid button on iPad preserves the existing aspect ratio during side resizing and snaps rotation/endpoint angles to 45 degrees. New rectangles/ellipses still become squares/circles with the constraint enabled. A click without dragging changes nothing; each completed drag is one undo step. Preview changes are live; interrupted touches or Escape/Operate on Mac cancel the uncommitted movement. Style and object identity remain intact. The Mac enforces edit ownership, geometry-only updates and stale-edit rejection. Invalid moves outside the canvas are not applied. Update both apps together for wire protocol 9; existing pairing keys remain valid.

## Pencil and finger together

Both are always enabled, including text placement and object editing. The former finger-drawing test option is removed. One gesture is edited at a time. Pencil takes priority over an uncommitted finger gesture. Finger contacts are ignored during Pencil contact/hover and briefly afterward; large contacts are filtered as possible palms. This reduces accidental input but cannot guarantee perfect palm rejection. Keyboard and buttons accept fingers normally.

## Navigate slides from iPad

The iPad header and Mac drawer have left/right slide arrows with automatic clearing. The Mac controls work without an iPad; the iPad controls require a connection. controls are disabled during drawing and replaced by text controls while editing a label. Start a Keynote or PowerPoint slideshow on Mac first. If both apps run, briefly bring the intended app to the foreground so PresentInk can identify the target.

The first use requires macOS Automation permission for the target app; review it in System Settings → Privacy & Security → Automation → PresentInk. PresentInk uses native AppleScript commands with sandbox exceptions limited to Keynote and PowerPoint, without general keyboard injection or Accessibility permission. Keynote Next advances a build or slide; Previous goes to the previous slide. PowerPoint uses slideshow next/previous-slide commands. After a PresentInk navigation command succeeds, all annotations are cleared. A Keynote build step also clears them. If navigation or Automation permission fails, the drawings remain. Errors appear on iPad when the target is ambiguous, not presenting, or permission is denied. Full-screen and animation behavior still needs hardware verification.


## iPad app verification after installation

If iPadOS says the app could not be verified and requires an Internet connection, open Settings → General → VPN & Device Management, select the developer entry and choose Verify App. Then reopen PresentInk. Safari access does not necessarily mean developer verification has completed. If verification still fails, try another network such as a phone hotspot before deleting the app. Re-verification resolved this during the installation test. See [Apple's developer-trust guidance](https://help.apple.com/xcode/mac/current/en.lproj/dev96a12fb84.html).


## Reusing the About view

Copy `SharedUI/AppAboutView.swift` into another app target and supply `AppAboutConfiguration` with your app identity, localized strings, colors, optional website/repository URLs, and license. The component has no PresentInkCore dependency. `SharedUI/PresentInkAboutView.swift` is only the PresentInk-specific adapter. The source includes a detailed German guide with examples in `Docs/About-Reuse.md`.


## Clear annotations directly

The trash button is directly available in both expanded and compact drawers on Mac and iPad. One click/tap clears committed annotations without a confirmation dialog; Undo restores them. The direct button is disabled on an empty canvas, during an active stroke/object drag or while changing slides. It does not change your tool settings or presentation content.

With drawing focus on Mac, the physical Left/Right arrow keys also navigate and clear, except while typing or drawing. In Operate mode, keys go to the presentation app normally and do not trigger PresentInk clearing. Slide changes made outside PresentInk are not detected automatically; use the trash button in that case.

Navigation acknowledgements identify the request and the new document state. Old-slide input is rejected using a new epoch, so in-flight commits cannot resurrect the old annotations. Clearing remains undoable; drawings are not stored automatically per slide. Update both apps together for wire protocol 9; existing pairing keys remain valid.


## Presentation visibility and uninterrupted preview (0.9.2)

**Known issue / TODO:** LibreOffice Impress fullscreen still fails in the user’s retest of 0.9.2. The Mac drawer and iPad-origin annotations may remain invisible. The issue is unresolved; LibreOffice fullscreen support is not verified.

Window ordering attempts to recognize Keynote, PowerPoint and LibreOffice, including display-filling surfaces that report an ordinary layer. Separate overlay/drawer levels remain above the public display-shield level where allowed by macOS; stationary auxiliary windows are used across fullscreen Spaces.

Annotation and capture-source epochs are independent. Clearing on slide navigation no longer removes the background image or opens the preview invitation. Only a real source/geometry change invalidates video. An already-approved stream resumes after geometry changes on the same physical display; switching displays still needs explicit sharing approval. While waiting for frames, a small progress indicator replaces the connection invitation.

If annotations or the Mac drawer are missing, check their independent visibility controls first: Eye for annotations, Mac Drawer on iPad or Control–Option–W for the drawer. Enable drawing mode with Control–Option–A or a drawer tool for direct Mac input. LibreOffice is covered by window-ordering detection; native slide automation remains limited to Keynote/PowerPoint. Verify the actual fullscreen setup on hardware.
