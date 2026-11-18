# PresentInk – App-Icons

Gemeinsames Motiv für Mac und iPad: heller Bildschirm, mintgrüne Zeichenspur und korallfarbener Stift auf satiniertem Indigo.

- `PresentInk-Mac-master.png`: Original mit transparenten Außenbereichen.
- `PresentInk-iPad-master.png`: deckende, quadratische Originalvorlage für die Systemmaske.
- `../Apps/macOS/Assets.xcassets/AppIcon.appiconset/`: zehn Mac-Icon-Größen, mit optischem Außenabstand.
- `../Apps/iPadOS/Assets.xcassets/AppIcon.appiconset/`: deckende 1024-Pixel-Vorlage; Xcode erzeugt die Gerätegrößen.

Beide Targets verwenden `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`. Ihre Asset-Kataloge werden als Ressourcen kompiliert. Nach einem neuen Build/Start übernimmt das jeweilige System das neue Icon; ein laufender Prozess kann noch sein bisheriges Icon zeigen.

## Erstellung

Erstellt mit dem integrierten Bildgenerator. Die Originale wurden ins Projekt kopiert. Die Größenkonvertierung und der Mac-Außenabstand erfolgen bei der Asset-Aufbereitung ohne Änderung des Motivs.

### Prompt – Mac-Master

Create a single polished native application icon for PresentInk, a Mac and iPad live presentation annotation tool. Output exactly one icon, square 1024x1024 composition. A beautiful deep midnight indigo rounded-square tile, near edge-to-edge with only a very small clear outside margin, soft satin glass finish and restrained subtle depth. Central symbol: a clean white luminous outline of a widescreen display, inside it a vivid mint/turquoise hand-drawn sweeping annotation stroke, with a short distinctive warm coral pencil leaning diagonally from lower right toward the stroke. Carefully balanced simple bold silhouette that remains legible at 32 pixels. Refined Apple-platform productivity app visual quality, quiet soft lighting, crisp clean edges, limited details, no excessive glow, no photo-real hardware, no text, no letters, no wordmark, no watermark, no mockup scene. Outside the rounded tile is genuinely transparent. The tile itself is completely opaque. Icon artwork only.

### Prompt – iPad-Variante

Prepare this exact PresentInk icon as its iPad app-icon counterpart. Preserve the monitor, mint hand-drawn stroke, coral pencil, geometry, proportions, colors and finish unchanged. Change only the outer tile/background: extend the deep indigo tile all the way to all four square image edges and corners, removing all transparency and the small outside margin. The result must be one completely opaque edge-to-edge square icon image, with NO rounded outside corners baked in, since iPadOS supplies its own icon mask. Do not add any new objects, text, badges or borders. Keep the existing artwork composition exactly centered and unchanged. Output square 1024x1024.
