# PresentInk 0.9.1

Version **0.9.1**, build **17**, for Mac, iPad Companion and the Mac Shortcuts extension.

- PresentInk slide arrows now clear annotations after the presentation app accepts the command. Failures and rate-limited no-ops leave the drawing unchanged.
- Previous/next arrows are also available in the Mac drawer without requiring a connected iPad. With drawing focus, Mac Left/Right keys perform the same action outside text entry or an active stroke.
- Direct trash buttons in expanded and compact Mac/iPad drawers clear annotations in one step, without a confirmation popup. Undo can restore the cleared drawings.
- Navigation acknowledgement and a new document epoch prevent old-slide input from reappearing after clearing. The iPad waits for the matching response before starting new input.
- The reusable About component and optional website placeholder are included; see [reuse instructions](About-Reuse.md).

Update both apps together: **wire protocol 8**. Existing pairing keys remain valid. Native slide navigation still requires Automation permission for the target presentation app. A Keynote build/animation step also clears annotations. Changes made directly in the presentation app or through its own keyboard controls are not detected automatically; use the direct clear button.

This is not automatic per-slide annotation storage. See [validation status](../BUILD-STATUS.md), [English guide](UserGuide.md), and [German guide](Anleitung.md).
