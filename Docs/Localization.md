# German and US English

Source version: 0.9.2 (18) for Mac, Companion, and Shortcuts extension.

Both apps use the same source and app identity. Select English in the OS per-app language preference, or choose English under Xcode Scheme → Run → Options → App Language. German remains available. Restart after changing languages; finish or capture annotations first because sessions are not persisted.

## Resources

- Runtime strings: `Packages/PresentInkCore/Sources/PresentInkCore/Resources/Localizable.xcstrings`. Open **Localization → Localizable** in Xcode to edit German and English together. The same catalog is processed by PresentInkCore and embedded in each app/extension for native App Intents.
- Permission descriptions: `SharedUI/InfoPlist.xcstrings`, a shared German/English String Catalog included in the Mac app, iPad app, and Shortcuts extension. Open it under **Shared UI** in Xcode to edit translations in the catalog editor. Xcode compiles it into each bundle’s `de.lproj/InfoPlist.strings` and `en.lproj/InfoPlist.strings`. These app metadata strings are intentionally outside the Swift package’s runtime resources.
- Native App Intents labels use literal localization keys and the app's Localizable table.
- Siri/App Shortcuts phrases: `SharedUI/AppShortcuts.xcstrings`, schema 1.1 with explicit German/English phrase sets. Entries are manually managed because source extraction marked existing provider phrases as stale. When editing phrases, update both the provider literals and the catalog; compare the eight catalog keys with `autoShortcuts[].phraseTemplates` in the extension’s generated `extract.actionsdata`. The compiled AppShortcuts table uses string-set keys (`#!SET#!_…[0]`).
- English guide: `Docs/UserGuide.md` / `UserGuide.html`.
- German guide: `Docs/Anleitung.md` / `Anleitung.html`.

`InkLocalization` loads the selected German or English package resource bundle. `inkLocalized` supports static keys and explicit `%@` placeholders; substituted user values are never translated. App Intents retain literals so Xcode can extract native metadata. Xcode compiles the catalog into localized `Localizable.strings` files in the package resource bundle and app/extension bundles. Keep the source catalog as the single source of truth; do not edit generated `.strings` files. Entries are manually managed, and generated Swift symbols are disabled because runtime lookup uses literal keys and punctuation-only differences can cause symbol collisions.

Do not translate wire keys, command IDs, bundle IDs, Keychain names, filenames, AppleScript terminology, or saved profile identifiers. Built-in profiles created earlier can keep German names in an English UI, just like user-defined profile names. User text is preserved. Status descriptions received over the companion connection use the originating Mac's selected language; system errors use the operating system's language.

Regenerate both offline guides with `python3 Tools/render_help.py`. Add new runtime keys and both translations in the Localizable catalog. Use the installed Xcode 27.2 Swift toolchain for `swift test --package-path Packages/PresentInkCore`; it compiles String Catalog resources directly, so no duplicate legacy files or JSON runtime fallback are needed. Preserve placeholder counts and order. Rebuild both app targets and check the compiled resources, not only source files. The source archive includes strings and string catalogs.

## Validation

- Localizable catalog migration: all 511 German and 511 English values match the previous source files exactly. Both unsigned app builds succeeded, including the Shortcuts extension; all generated app and package localization tables were checked against the catalog. All 57 PresentInkCore tests passed, including runtime bundle lookup and placeholder substitution. Source archive generation passed with the catalog as the only UI translation source.

- InfoPlist catalog migration: unsigned Debug builds succeeded for Mac (including the Shortcuts extension) and iPad. All three permission descriptions were compared against the catalog in both German and English in all three compiled bundles (six generated `InfoPlist.strings` files). Source archive generation also passed. Installed apps were not replaced by this migration.

- 57 PresentInkCore tests passed, including four localization tests (labels, placeholders, unknown values/IDs, and stable bilingual aliases).
- 23 PresentInkLink tests passed including wire protocol 9 object-editing and slide-navigation payloads.
- Earlier development builds were signed, installed and launched on Mac and physical iPad. See BUILD-STATUS.md for checks of the current 0.9.2 source.
- The installed apps have not been replaced. A complete visual review on physical Mac/iPad with English selected, including long strings, native Siri phrases, dialogs, per-app language switching, and full-screen panels, remains to be performed. Build success is not a visual localization acceptance test.

## SDK warning cleanup

With Xcode 27.2, the text editor accessory uses `UIBarButtonItem.Style.prominent`. The deprecated iPad `UIRequiresFullScreen` opt-out is removed; all four interface orientations are declared and landscape is the preferred default. The canvas already fits the Mac display aspect ratio to the available view bounds. Physical-device verification of portrait layout and resized windows remains pending; the drawer is optimized for landscape. See [Apple’s migration guidance](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key).

Percentage range labels use the localized words “Prozent” / “percent”; the live opacity value uses Foundation’s percent FormatStyle instead of appending a hard-coded percent sign. Both app builds and all 57 Core tests passed after these changes. All eight German/English Siri phrase sets were verified in the compiled bundles and against the extension metadata.
