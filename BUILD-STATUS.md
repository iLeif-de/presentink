# PresentInk 0.9.2 — build and validation status

Current source: **0.9.2 (18)** for Mac, iPad Companion, and the Mac Shortcuts extension. Wire protocol: **9**. The former independent development version numbers are unified; existing pairing data remains compatible.

## Automated validation

| Check | Result |
|---|---|
| PresentInkCore | 57 tests passed: geometry, object-editing leases, undo, text, automation and localization |
| PresentInkLink | 23 tests passed: wire messages, TLS, framing and snapshot coalescing |
| Mac build | Succeeded: signed Release configuration; 0.9.2 installed |
| iPad build | Succeeded: signed Release configuration; 0.9.2 installed |
| Source ZIP | Source-only archive includes both apps, offline guides, resources, license and all five automation examples |

The arrow cursor replaces the crosshair. Both About views retain GitHub and show a noninteractive website placeholder; no Hausnerd URL is configured. Project and bundle version/build numbers agree.

## Hardware evidence and installation

Earlier development builds were signed, installed and started on Mac and a physical iPad. The user resolved an iPad online developer-verification prompt and confirmed launch. Previous Keynote testing confirmed visible iPad-to-Mac annotations, direct Mac drawing, drawer tool selection, and Control–Option–A. These observations do not certify every presentation/display/input combination.

The current 0.9.2 apps, including slide-change clearing, direct clear buttons and the reusable About view, are installed and launched on Mac and physical iPad. Signing credentials, device profiles, pairing keys and personal Xcode state are excluded from the repository.

## Known unresolved failure

**LibreOffice Impress fullscreen:** the user retested the installed 0.9.2 build and reported it still does not work. Mac drawer and iPad-to-Mac annotations can remain invisible. This is an open README TODO, not a verified fix. Automated policy tests cover the intended calculation, not WindowServer behavior on this hardware.

## Manual checks still required

- Direct editing across both devices, rotated edge resizing, interruption and concurrent ownership in long sessions.
- Floating/docked/hardware keyboards, Scribble, finger/Pencil transitions and palm filtering.
- Keynote/PowerPoint slide automation with first-time/denied permissions, both apps running, animations and fullscreen displays.
- Complete German/US English visual review, accessibility and keyboard navigation.
- Long-running WLAN/capture tests, physical audience output and end-to-end latency measurements.

Use [Acceptance.md](Docs/Acceptance.md) for the manual checklist, [release notes](Docs/ReleaseNotes-0.9.2.md) for scope and limits, and [historical build records](Docs/Archive/BuildHistory.md) for earlier development evidence. A successful build and automated test run is not a complete hardware acceptance test.


## Reusable About component — November 16, 2026

Extracted standalone `SharedUI/AppAboutView.swift` with an app-owned configuration for identity, localized strings, colors, icon, website/repository links and license. PresentInk's adapter supplies its own labels, GitHub URL and a nil website URL plus localized coming-soon placeholder. The component has no PresentInkCore dependency. Mac and iPad Debug builds succeeded, and the component compiled/rendered independently without either PresentInk package. Placeholder layout visually inspected. Reuse instructions and MIT-licensed copy bundle prepared. This follow-up is installed on Mac and iPad; its source changes remain local and have not been pushed to GitHub.


Latest About follow-up installation: both signed Release builds succeeded. Mac bundle signature verified; the replaced app launched and reported no runtime error. Companion installed and launched on the physical iPad; version 0.9.0 (16) confirmed. Existing app data retained. Team supplied only as a build override. Temporary build directories and previous Mac installation backup removed.


## Slide navigation and direct clearing — November 16, 2026

Source 0.9.1 (17), protocol 8. After accepted PresentInk navigation, the Mac clears annotations with one undo checkpoint and starts a new document epoch. Navigation failure/throttling preserves document state. Mac arrows in the drawer and physical Left/Right during drawing focus use the same path as iPad arrows. Both drawers expose a direct undoable clear button. The iPad blocks new input until a matching request acknowledgement or failure; a timeout releases the control with an error. Late old-epoch input is rejected. The external AppleScript call is performed outside any mutating document access, avoiding reentrancy conflicts during permission dialogs. Changing the canvas during that call preserves the new canvas. External slide changes are not observed automatically.

51 Core and 22 Link tests passed, including success/failure/no-op/busy navigation, undo restoration, visibility preservation, epoch isolation and acknowledgement payloads. Both app builds succeeded. Guides and release notes updated. Both drawer layouts rendered and visually inspected using an isolated preview model; actual presentation transitions, permission dialogs and timing still require device checks. This update is installed on both devices. Source changes have not been pushed.


0.9.1 installation completed: signed Release builds installed and launched on Mac and iPadProM4; version/build 0.9.1 (17) verified. Mac signature verified. Runtime status reports no error, an authenticated iPad connection, synchronized drawing settings and live screen preview. No existing Mac drawing session was running before replacement. Temporary builds and the previous installation backup removed.


## Presentation regression corrections — November 16, 2026

Source 0.9.2 (18), protocol 9. The runtime exposed annotations hidden and drawer fully hidden with two retained drawings; visibility remains independently user-controlled. Keynote shield-level policy reserved an obsolete third window slot and could place the overlay at the shield level. Two slots now permit overlay/drawer above it, and known fullscreen surfaces with ordinary reported layers are recognized. LibreOffice/PowerPoint added to detection; ordering is reasserted at unchanged levels, and windows use stationary auxiliary behavior.

The user confirmed the slide-change popup appears on iPad. New annotation epochs were clearing the video background and invoking the preview invitation. Independent snapshot.sourceEpoch now survives slide clears. Frames carry the originating capture stream's identity and asynchronous decoding checks sourceEpoch; source changes still invalidate old frames. Same-display geometry changes resume an already-approved stream; true display changes do not auto-share another source. Starting/live streams show a small progress indicator when necessary.

57 Core and 23 Link tests passed, including shield-level headroom, known-app detection, offset-display coverage, unchanged capture identity across slide navigation and invalidation on source changes. Both signed Release builds succeeded. Actual Keynote/LibreOffice presentation layering and the popup fix still require device verification after installation. The user authorized discarding the two live annotations. Both apps were replaced and launched; changes remain unpushed.


0.9.2 installation completed: the two annotations were discarded with explicit approval. Signed Mac and iPad apps installed and launched; Mac bundle 0.9.2 (18), iPad version/build verified. BenQ target and existing connection restored. Runtime reports authenticated iPad connection, synchronized settings, live preview and no error. Overlay observed as an onscreen 1600×900 window on BenQ at normal level while no presentation app was running. The drawer was subsequently in the fully-hidden state; this remains a user-controlled preference. Keynote/LibreOffice fullscreen behavior and PowerPoint transition-popup absence still need the user's actual presentation test. Temporary builds and previous installation backup removed.


November 16, 2026 user follow-up: LibreOffice still fails after the 0.9.2 update. README, release notes and both guides now explicitly mark the issue unresolved and retain it as a TODO.
