# PresentInk 0.9.2

Version **0.9.2**, build **18**, for Mac, iPad Companion and Shortcuts extension.

- Improve presentation-level ordering for Keynote and add LibreOffice/PowerPoint window detection. Reserve two levels for overlay/drawer above the public display shield, instead of retaining the old third text-panel reservation.
- Detect display-filling presentation surfaces that report an ordinary window layer. Reassert front ordering and use stationary auxiliary windows across fullscreen Spaces.
- Decouple annotation epochs from capture-source epochs. Slide-change clearing no longer discards the iPad background image or brings up its preview invitation.
- Tag frames with the producing capture stream's source identity; reject late frames from a replaced source.
- Continue an already-approved preview after geometry changes on the same display; keep explicit approval for another display.
- Show a small loading indicator while waiting for frames, without prompting to reconnect an active stream.

Update both apps together: **wire protocol 9**. Existing pairing keys remain usable. Annotation visibility, drawer visibility and drawing mode remain independent controls. LibreOffice overlay detection does not add native LibreOffice slide automation; slide commands remain available for Keynote and PowerPoint.

See [validation](../BUILD-STATUS.md) and the [hardware checklist](Acceptance.md). Presentation compatibility must be checked with the actual slideshow/display setup.

## Known unresolved issue

The user retested LibreOffice Impress fullscreen after installing 0.9.2 and reported that it still does not work. The Mac drawer and iPad-origin annotations may not appear. Detection alone has not fixed this; the issue remains an explicit [README TODO](../README.md#known-issues-and-todo). Do not treat this release as verified LibreOffice fullscreen support.
