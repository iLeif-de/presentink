# Build- und Testnachweis – Mac 0.10.0 / Companion 0.8.0

Prüfumgebung: Xcode 27.2, macOS 27.2.1, macOS-/iOS-SDK 27.2.

| Prüfung | Ergebnis |
|---|---|
| macOS-App, Debug | Erfolgreich gebaut und lokal signiert |
| iPad-App, generischer iOS-Simulator | Erfolgreich gebaut, ohne Signatur |
| iPad-App, generisches echtes iPad / iphoneos SDK | Erfolgreich gebaut, ohne Signatur |
| PresentInkCore | 7 Tests erfolgreich |
| PresentInkLink | 5 Tests erfolgreich |
| TLS-Verbindungsaufbau | Lokaler authentifizierter Ping/Pong erfolgreich |
| Falscher Sitzungsschlüssel | Verbindung wird im automatisierten Test abgewiesen |
| Mac-Laufzeit | App-Start und Beenden über App-Menü beobachtet |

Die Tests prüfen unter anderem Gerätebesitzer, Epochenwechsel, doppelte/veraltete Kommandos, reversible Dokumentaktionen, bildschirmproportionale Formen und TCP-Nachrichtenfragmentierung.

Nachtrag vom 13. November: Der Landscape-Drawer ist implementiert. Geräte- und Simulator-Build sind erfolgreich, die neue App wurde im iPad-Pro-11-Zoll-Simulator gestartet. Die Simulator-Laufzeit ist inzwischen installiert. Die interaktive Prüfung über Device Hub scheiterte an wiederholten Zeitüberschreitungen der UI-Steuerung; Ein-/Ausklappen und Orientierung sind deshalb noch manuell zu bestätigen.

Bonjour über WLAN, Pencil auf echter Hardware, ScreenCaptureKit-Freigabe, Vollbild-Kompatibilität und Ende-zu-Ende-Latenz bleiben hardwareseitig offen. Der Build meldet eine Deprecation-Warnung für `UIRequiresFullScreen`; eine spätere Migration auf die neuen iPad-Fenster-/Orientierungs-APIs ist nötig.

Für die Installation auf einem echten iPad in Xcode das eigene Entwicklungsteam wählen. Release-Signing, Notarisierung und Store-Freigabe sind nicht Bestandteil dieses Buildnachweises.

## Update: Kopplung und Bildschirmvorschau

- Mac- und iPad-Geräte-Build erfolgreich. Beide Apps anschließend über Xcode aktualisiert und gestartet; iPad-Ziel: iPadProM4.
- PresentInkLink: 14 Tests erfolgreich, inklusive TLS, falschem Schlüssel, Wiederverwendung/Rotation gespeicherter Schlüssel (injizierter Testspeicher), Vergessen eines Macs, initialem Bild für spätere Video-Abonnenten, Cache-Löschung bei Pause und nummerierten Vorschauzuständen.
- Die neue Kopplung im echten Schlüsselbund und die sichtbare Bildschirmübertragung auf das reale iPad sind noch durch die einmalige Erstkopplung und macOS-Freigabe des Nutzers zu bestätigen.

## App-Icons

Mac- und iPad-Geräte-Build mit neuen AppIcon-Asset-Katalogen erfolgreich. Mac-Info.plist enthält CFBundleIconFile/AppIcon und CFBundleIconName/AppIcon; das iPad enthält die primären AppIcon-Einträge. Alle zehn Mac-Größen und die deckende iPad-1024-Vorlage wurden auf korrekte Maße geprüft. Die laufenden Apps wurden für diese reine Icon-Änderung nicht neu gestartet.

## Update: Mac-Drawer, Menüs und Icon-Start

- Mac-Debug-Build mit neuem nicht aktivierendem Drawer, Menü-/Shortcut-Steuerung und expliziter Laufzeit-Icon-Zuweisung erfolgreich.
- Start der neuen App und neue Menüstruktur inklusive Darstellung-/Drawer-Aktionen über UI-Steuerung beobachtet.
- Die vorhandene `/Applications/PresentInk.app` wurde nach Signaturprüfung aktualisiert; die vorherige Version ist unter `work/installed-app-backups/` gesichert. Danach wurde die Programme-Version gestartet.
- Die direkte Dock-/⌘Tab-Ansicht und sämtliche Drawer-Interaktionen konnten über die zeitweise ausfallende UI-Steuerung nicht vollständig visuell abgenommen werden. Signierte App-Ressource, App-Info und Startcode sind geprüft.

## Update: Apple Kurzbefehle und AppleScript

- Mac 0.4.0 (Build 4) erfolgreich gebaut und signiert; unter `/Applications/PresentInk.app` installiert und gestartet. Die vorherige Version wurde gesichert.
- PresentInkCore: 13 Tests ohne Fehler, inklusive Wertvalidierung, Farb-Preset-Roundtrip und eindeutiger AppleEvent-Codes.
- Exportiertes AppleScript-Wörterbuch: 36 Befehle und elf Eigenschaften. Echte AppleScript-Aufrufe prüfen Werkzeug/Farbe/Breite, Zeichenmodus, Drawer und Overlay sowie Status/Displays. Ausgangszustand danach wiederhergestellt.
- Ungültige Breite und Displaynummer liefern Fehler −1700; Vorschau ohne verbundenes iPad liefert −2700. Beenden über den neuen Skriptbefehl erfolgreich.
- Die installierte Version beantwortet `read status` erfolgreich. Alle vier mitgelieferten Beispielskripte wurden kompiliert.
- App-Intents-Metadaten enthalten zehn Aktionen und acht vorkonfigurierte App Shortcuts. Ein persönlicher Ablauf in der Kurzbefehle-App wurde noch nicht angelegt oder ausgeführt.
- Bildschirmaufnahme und Zurücksetzen der Kopplung wurden bei diesen Prüfungen nicht ausgelöst. Die bestehenden Systemfreigaben bleiben erforderlich.

## Update: Hilfe und Vollbild – Mac 0.5.0 (Build 5)

- Finaler Mac-Debug-Build erfolgreich, ohne Compilerwarnungen/-fehler. Signierte Installation unter `/Applications/PresentInk.app`; vorherige Version gesichert.
- Anleitung: 323 Zeilen Markdown, daraus generierte Offline-HTML-Lesefassung. Beide Ressourcen stimmen bytegenau mit dem App-Bundle überein. Generierung reproduzierbar, interne Inhaltslinks geprüft.
- Hilfe-Menü und geöffnetes Anleitungsfenster mit formatiertem Text/Inhaltsverzeichnis über UI-Steuerung sichtbar geprüft.
- Tastenkürzel: modal blockierenden Alert durch eigenes SwiftUI-Fenster mit Gruppen, Grid-Tastenspalte, Scrollbereich und Link zur Anleitung ersetzt. Öffnung über Menü und AppleScript erfolgreich; vollständige visuelle Abnahme des Kürzelfensters war nicht möglich, weil die Fernsteuerung anschließend das transparente Panel auswählte.
- Vollbild: Zeichenfläche zu nicht aktivierendem NSPanel geändert, `canJoinAllApplications` für Overlay und Drawer ergänzt, Overlay unterhalb des Drawers angeordnet. Kein Aktivieren der App oder Zurückaktivieren einer früheren App beim Umschalten; App-Ausblendung wird ohne Aktivierung aufgehoben.
- Safari über UI in macOS-Vollbild gebracht, Zeichnen über AppleScript aktiviert, ein Pointer-Teststrich im Dokument registriert (0 → 1 Strich). Safari anschließend wieder in Fenstermodus/Startseite versetzt. Das allein bestätigt weder alle Präsentations-Apps noch die durchgängige visuelle Komposition; Keynote/PowerPoint, iPad-Zeichnen im Vollbild, globale Kürzel und mehrere Displays bleiben separat zu prüfen.
- Beim Space-Wechsel bzw. Verlust des Zeichenfokus endet lokales Zeichnen ohne Dokumentreset. Vorhandene Core-/Link-Tests in diesem Update nicht erneut ausgeführt, da keine Package-Logik geändert wurde.

## Update: Unsichtbarer Mac-Drawer und Kapitelhilfe – Mac 0.6 / Companion 0.4

- Beide Debug-Targets erfolgreich gebaut und signiert. Mac 0.6.0/6 unter Programme installiert und gestartet; iPad Companion 0.4.0/4 auf dem realen iPadProM4 installiert und gestartet. Mac-Host-Verbindung nach Update wieder gestartet; vorhandene Kopplung nicht zurückgesetzt.
- 13 Core- und 15 Link-Tests erfolgreich (28 gesamt). Neue Prüfungen für `invisible`-Wertvalidierung und Codable-Roundtrip der Drawer-Anforderung/Bestätigung. Bestehender authentifizierter TLS-Loopback weiterhin erfolgreich.
- Echte AppleScript-Aufrufe an die installierte App prüfen `invisible`, `hidden` und `toggle drawer`. Der neue Status `mac_drawer_window_visible` bestätigt: Fenster vollständig weg / Griff sichtbar / nach Toggle wieder sichtbar. Eigenschaft `drawer state` liefert `invisible` zurück.
- Kurzbefehle-Metadaten enthalten die vierte Drawer-Option `invisible`; kein persönlicher Kurzbefehle-Ablauf angelegt/ausgeführt.
- Neue Auge-Taste und Chevron im Mac-Drawer über UI-Steuerung gefunden. Hilfe-Fenster und Kapitelwechsel zu „Drawer und Werkzeuge“ mit dauerhaftem Inhaltsverzeichnis links und ausschließlich ausgewähltem Inhalt rechts sichtbar geprüft.
- Generator geprüft: 16 Kapitel, passende eindeutige Navigationsziele und genau ein initial sichtbarer Abschnitt. Installierte Markdown-/HTML-Ressourcen stimmen mit den Projektdateien überein.
- Link-Protokoll auf 3 erhöht: alter Client/Host wird beim Handshake abgewiesen statt eine unbekannte Nachricht zu interpretieren. Mac und iPad gemeinsam aktualisieren.
- Ein realer iPad-Switch-Roundtrip wurde nicht ausgeführt, da der Client beim abschließenden Status nicht verbunden war. Switch-Synchronisierung nach erneuter Verbindung sowie Sichtbarkeit nach Display-/Space-Wechsel bleiben manuell zu bestätigen.
- Bekannte iPad-Buildwarnung zu `UIRequiresFullScreen` bleibt bestehen; keine neue Funktionswarnung im Mac-Build.

## Update: Zentrale Zeichen-Einstellungen, Profile und Freigabe – Mac 0.7 / Companion 0.5

- Finale Mac- und iPad-Debug-Builds erfolgreich. Mac 0.7.0/7 unter Programme installiert, Companion 0.5.0/5 auf dem realen iPadProM4 installiert und gestartet. Vorherige Mac-Version gesichert; Kopplungsschlüssel unverändert.
- 23 Core- und 16 Link-Tests erfolgreich (39 gesamt). Neue Tests decken Profil-/Konfigurationsvalidierung, Persistenz und beschädigte Daten, pro Werkzeug gültige Breiten, echte Mac-Punktbreiten, Druckgrenzen, alte Strichdaten, eingefrorene Darstellungswerte, Mac-Übernahme der Stilautorität, Freigabe-/Pause-Entscheidung und Einstellungsnachrichten ab.
- Separater CoreGraphics-Pixeltest: zwei überlappende Stiftsegmente mit 40 % Deckkraft ergeben auf Weiß RGB 153/153/153 statt aufaddierter Deckkraft. Transparenzgruppen werden auf die Strichumgebung begrenzt; deckende Striche benötigen keine Zwischengruppe.
- Echte AppleScript-Aufrufe an die installierte App: Profil Dunkle Folien, Marker 20 pt, Deckkraft 45 %, eigene Palette und Werkzeugfolge, Fehler für Breite 200. Persistenz über App-Neustart erfolgreich; Ausgangskonfiguration danach wiederhergestellt. Keine Freigaberechte durch diesen Test geändert.
- Einstellungen-Fenster über Menü geöffnet und Profile, Palette, Werkzeugbreiten, Deckkraft, Druckregler und Werkzeugliste sichtbar geprüft.
- Installierte Metadaten: 15 native Aktionen, 42 AppleScript-Befehle. Neue Aktionen für Profil, Deckkraft, Lesen/Anwenden der Zeichen-Einstellungen und gemerkte Freigabe. Native Kurzbefehle-Abläufe nicht separat ausgeführt.
- Reale Verbindung abschließend bestätigt: `ipad_connected=true`, `drawing_settings_synced=true`. Das iPad bestätigt damit den Mac-Einstellungsstand. Die Vorschau war im abschließenden Status live, gemerktes Vertrauen und Autostart aktiviert. Die laufende Sitzung wurde unverändert belassen.
- Nicht als vollständig abgenommen gelten: alle iPad-Schnelländerungen in Gegenrichtung, Pencil-Druckgefühl/Ende-zu-Ende-Latenz sowie Widerruf des Vertrauens durch einen echten Schlüsselwechsel und erneuter Systemdialog nach Neustart. Keine Kopplung zu Testzwecken zurückgesetzt.
- Protokoll 4 erfordert beide neuen Apps. Alte Stroke-JSONs bleiben lesbar; neue Striche tragen eigene Deckkraft-/Druck-/Breitengrenzen. Zeicheneinstellungen und Profile liegen im Mac-App-Einstellungsspeicher; Freigabevertrauen ist an SHA-256 des bestehenden Kopplungsschlüssels gebunden. Keine Schlüssel im Einstellungs-/Status-JSON.
- Mac-Build ohne Compilerwarnungen; bekannte iPad-Warnung zu `UIRequiresFullScreen` bleibt bestehen. Offline-Hilfe ist im installierten Bundle aktuell.

## Update: Textwerkzeug und selektive Vorschaufenster – Mac 0.8 / Companion 0.6

- Finale Debug-Builds beider Targets erfolgreich. Mac 0.8.0/8 installiert, Companion 0.6.0/6 auf iPadProM4 installiert und gestartet. Bestehende Einstellungen/Profile werden um Text ergänzt; Kopplungsschlüssel bleiben erhalten.
- 28 Core- und 16 Link-Tests erfolgreich (44 gesamt). Neue Texttests: Unicode/Mehrzeiligkeit/Limits, Codable, Layout-/Radierer-Treffer, Randpositionen, Undo/Redo, alte Profilkonfigurationen und zentrale Mac-Stilübernahme.
- Gemeinsamer CoreText-Renderer als generiertes Bild geprüft: zwei Zeilen korrekt und aufrecht, 2787 dunkle Textpixel. Vorhandene Druck-/Deckkraft-Darstellung bleibt erhalten.
- Echte AppleScript-Laufzeitprüfung: `insert text` mit Position, unverändertes aktives Werkzeug, Undo/Redo, Fehler für leeren Text/ungültige Position. Testverlauf danach entfernt; Einstellungen nach Neustart unverändert.
- Neues Textwerkzeug im Mac-Menü gefunden und Texteingabepanel nach Positionsklick sichtbar geöffnet. Vollständige Eingabe über die Fernsteuerung war durch zwischenzeitliche UI-Änderungen nicht zuverlässig reproduzierbar. Textobjekte waren anschließend in der realen iPad-Ansicht sichtbar.
- Reales iPad über Device Hub mit dem bereits gemerkten Mac wieder verbunden, ohne Schlüssel neu einzugeben. Live-Vorschau anschließend sichtbar geprüft: PresentInk-Einstellungsfenster erscheint im iPad-Hintergrundbild, Annotationen/Text werden separat darüber dargestellt. Das Fenster wurde nach Beginn der Vorschau geöffnet.
- Vorschau schließt die eigene App grundsätzlich aus; Ausnahmen sind ausschließlich explizite öffentliche Fenster-IDs (Einstellungen, Anleitung, Tastaturkürzel, zugehörige Kindfenster und Farbwähler bei sichtbaren Einstellungen). Overlay/Drawer/Textpanel/Kopplungsfenster sind keine Ausnahmen. Fensterliste wird während der Übertragung bei Änderungen aktualisiert.
- Installierte Metadaten geprüft: 16 native Aktionen, 43 AppleScript-Befehle, aktualisierte Offline-Hilfe bytegleich zum Projekt. Neue Aktion für Text, Werkzeugauswahl `text`, T/⌥⌘T.
- Protokoll 5 erfordert beide aktualisierten Apps. Noch offen: Text-Eingabe über jede iPad-Tastaturvariante, nachträgliche Textbearbeitung/-verschiebung (noch nicht implementiert) sowie erneute Vollbild-/Multimonitor-Abnahme mit Texteingabepanel. Keine bestehende Zeichnung zu Testzwecken entfernt; laufende Sitzung am Ende unverändert belassen.
- Bekannte iPad-Warnung zu `UIRequiresFullScreen` bleibt bestehen; Mac-Build ohne Compilerfehler/-warnungen.


## Update: Native Kurzbefehle-Ausgabe (0.9 / 0.7)

- Signierter Mac-Build einschließlich separater ExtensionKit-AppIntents-Erweiterung erfolgreich; unter `/Applications/PresentInk.app` installiert. iPad-Geräte-Build erfolgreich; eine Installation dieser neuen iPad-Version auf Hardware wurde in diesem Durchlauf nicht durchgeführt.
- PresentInkCore: 31 Tests erfolgreich. PresentInkLink: 18 Tests erfolgreich, inklusive authentifizierter lokaler RPC-Verbindung und falschem Sitzungsschlüssel.
- In Apple Kurzbefehle eine isolierte Statusaktion erfolgreich ausgeführt. Im Variablenmenü wurden die einzelnen nativen Eigenschaften sichtbar: Zeichenmodus, Annotationen, Werkzeug, numerische Werte und weitere Statusfelder. Keine JSON-Konvertierung notwendig.
- Testkurzbefehl „PresentInk – Ausgabe testen“ angelegt. Der Nutzer bearbeitete ihn während der Prüfung weiter; diese Änderungen wurden nicht überschrieben.
- Der Fall „App beendet“ ist durch die Verfügbarkeitsprüfung automatisiert geprüft. Ein vollständiger UI-Durchlauf dieses Fehlerfalls wurde nicht abgeschlossen. Die Verfügbarkeit wird vor dem Lesen des Verbindungsschlüssels geprüft; kein App-Start wird angefordert.
- Die native Erweiterung steuert eine bereits laufende App ohne Aktivierung über TLS ausschließlich auf 127.0.0.1; neuer Sitzungsschlüssel pro Start in dedizierter gemeinsamer Schlüsselbundgruppe.
- Beide Drawer haben einen direkten Schalter „Annotationen ausblenden/zeigen“. Vollständiges Ausblenden des Mac-Drawers hat ein separates X-Symbol.
- Beim abschließenden Beenden hatte der Nutzer zwischenzeitlich drei Annotationen hinzugefügt. Diese Sitzung wurde geschlossen, bevor der neue Bestand abgesichert wurde. Der Nutzer wurde darüber informiert; das Dokument wird derzeit nicht persistent gespeichert.


## Code-Review-Korrekturen (0.9.1 / 0.7.1)

53 Tests erfolgreich (34 Core, 19 Link). Beide Apps aus entpacktem Share-ZIP gebaut; zusätzlich signierter Mac-Build. Details, Grenzen und Hardware-Abnahme: [Review-Fixes](../Review-Fixes.md). Installierte App wurde nicht ersetzt.


## Keynote-Präsentationsfenster (Mac 0.9.2 / Build 11)

- Signierter Mac-Build erfolgreich. Zeichenfläche, Drawer und Texteingabe werden bei erkannten hochliegenden Keynote-Fenstern über deren tatsächlicher Fensterebene angeordnet. Außerhalb der Präsentation wird die bisherige Ebene wiederhergestellt. Beide bekannten Keynote-Bundle-IDs werden berücksichtigt. Nicht aktivierende Panels bleiben erhalten; Keynotes Einstellungen werden nicht verändert.
- Nach Installation durch den Nutzer bestätigt: iPad-Annotationen sind am Mac sichtbar; nach Aktivierung des Zeichenmodus funktionieren Maus/Trackpad und Werkzeugwahl im Drawer; ⌃⌥A schaltet auch während Keynote zuverlässig um. Diese Bestätigung stammt aus dem Nutzertest, nicht aus einem automatisierten UI-Test.
- Noch separat prüfen: sämtliche Folien-/Moderatordisplay-Kombinationen, V/Esc mit anschließendem Weiterblättern, Texteingabe und Space-Wechsel.


## German / US English and GitHub documentation

- English root README and Tools README added, including Xcode/Terminal builds, signing, pairing, source ZIPs, permissions, limitations, and MIT licensing. German project/tools overviews preserved under Docs.
- Standard MIT LICENSE added and included in source archives. AI assistance and third-party rights are explained in the README; no claim that a license guarantees copyrightability of generated material.
- 471 UI/automation/error translation keys in shared German/English resources, localized permission explanations, native Shortcuts phrase catalog, and English offline guide.
- Signed Mac 0.10.0 (12) and Companion 0.8.0 (9) builds succeeded. All 57 tests passed (38 Core, 19 Link).
- Installed apps remain unchanged. English visual/Siri testing on hardware is outstanding; see Docs/Localization.md.


# Development validation log before the unified 0.9.0 version

The following platform-specific version numbers describe historical development builds. The current release and validation record is in the root BUILD-STATUS.md.

# Build and validation status

Current source: **Mac 0.12.0 (15)** and **iPad Companion 0.10.0 (13)**.

## Latest verified application changes

| Check | Result |
|---|---|
| PresentInkCore | 47 tests passed, including direct object transforms, leases, undo and localization |
| PresentInkLink | 21 tests passed, including transform/slide messages, TLS and snapshot coalescing |
| Current unsigned Mac and iPad builds | Succeeded |
| Installed apps | Signed Mac 0.12.0 (15) and iPad 0.10.0 (13), installed and launched |
| Previous extracted sharing ZIP builds | Succeeded before inline text changes |
| English resource tables and offline guides | Included and checked |
| Keynote user test | iPad annotations visible on Mac; direct drawing, drawer tool selection, and Control–Option–A confirmed |

Current source builds and automated tests are verified; direct object editing, slide automation consent/targeting and simultaneous finger/Pencil input have not yet been verified on physical hardware. Both new apps are installed; initial iPad developer verification was completed by the user.

## Outstanding hardware checks

- Complete US English visual review on Mac and physical iPad, including long dialogs and Siri phrases.
- Additional slide/presenter display combinations, Spaces, inline text editing, keyboard avoidance, and Pencil Scribble.
- Real WLAN interruptions and longer sleep/lock cycles.
- Profiling large drawing documents under eraser/network load.

See [acceptance checks](Docs/Acceptance.md), [localization notes](Docs/Localization.md), and [review fixes](Docs/Review-Fixes.md).

The detailed development log is retained in [BuildHistory.md](Docs/Archive/BuildHistory.md). Its older entries describe earlier versions and may have been superseded.


## Font-size drawer indicators — November 15, 2026

Mac and iPad drawers now show proportionally sized A letters for text presets, with font-size accessibility labels. Both app builds succeeded without signing in temporary build directories; these generated products were removed afterward. Installed apps have not been replaced. The change is not yet visually checked on hardware.


## Shared About view — November 15, 2026

Added a shared Mac/iPad About view with the existing icon, violet/mint styling, dynamic version/build, Software Direction credit, AI assistance notice, website/GitHub links, copyright, and expandable full MIT license. Mac About menu and iPad header info button open it. German and English labels are included. Both unsigned app builds succeeded; bundled LICENSE files match the source. An isolated rendered preview was inspected; hardware interactions and English layout still require manual checks. Installed apps remain unchanged.


## Mac drawer spacing and tooltips — November 15, 2026

The panel now computes its width from visible tool/color/preset controls, reducing empty edges and retaining a two-row fallback. The grip minimizes to a handle; the separate minimize chevron is removed. Compact mode remains available through menu/Shift–Command–D. Native AppKit tooltips complement SwiftUI help and include shortcuts with drawing-mode/app-menu context. Mac build succeeded; an isolated content-width preview was inspected. Tooltip behavior over inactive/full-screen apps remains a hardware check. Installed apps have not been replaced.


## Installed development update — November 15, 2026

Signed Mac 0.10.1 (13) installed in Applications and launched without a reported session error. Companion 0.8.1 (10) installed and launched on the physical iPadProM4 after reconnecting the device. Includes About views, text preset letters, and Mac drawer spacing/tooltips. Team ID was supplied only as a build override; project settings remain empty. Temporary build directories were removed after installation. Changes remain local and have not been pushed.


## Inline text entry — November 15, 2026

Mac 0.11.0 (14) and Companion 0.9.0 (11) replace separate text dialogs with native transparent editors directly on the canvas. Return inserts a line; Command–Return confirms; Escape cancels. iPad includes an input accessory toolbar with Done/Cancel. With Text selected, clicking/tapping an existing label edits it. Text drafts remain local until confirmation. Empty input cancels without deleting an original. Confirmed edits preserve style/identity and are undoable; stale replacements and document limits are checked by the authoritative Mac. Wire protocol 6 requires both new apps; saved pairing keys remain usable. No selection mode or resize handles added. Both builds succeeded; 39 Core and 20 Link tests passed. Guides and source ZIP updated. Device/Keynote/Pencil interaction checks remain outstanding. Installed apps were left running; no push performed.


## Inline text update installed — November 15, 2026

Signed Mac 0.11.0 (14) installed in /Applications and launched; signature verified and runtime status reported no error. Companion 0.9.0 (11) installed and launched on the physical iPadProM4. The Mac session was checked immediately before quitting: zero strokes and no active stroke. Existing pairing data and app preferences were retained. Companion connection remains disabled according to the existing Mac preference. Team ID supplied only as a signing override. Device interaction acceptance tests remain outstanding; no push performed.


## iPad keyboard completion fix — November 15, 2026

Companion 0.9.1 (12): dedicated top editing header with Done/Cancel, independent of floating/docked keyboard accessories. Tool drawer and preview invitation are hidden while editing. Keyboard safe-area changes no longer resize the canvas; a docked keyboard may cover the lower canvas. An outside Pencil tap confirms without opening a new label. Explicit completion accepts pending Scribble/IME composition. Text placement now follows the same Finger Drawing preference as other tools; keyboard and controls remain finger-operable. German/English instructions updated. Signed physical-iPad build and 39 Core tests passed. Floating keyboard, Scribble, IME and keyboard/layout behavior still require user verification on the physical iPad. Mac source behavior and wire protocol 6 unchanged.

Companion 0.9.1 (12) installed and launched on the physical iPadProM4; installed version verified with CoreDevice. Temporary build/test products removed.


## Drawer side spacing — November 15, 2026

Mac horizontal content padding increased from 12 to 18 pt, with matching panel width calculations in expanded, compact and two-row layouts. Annotation visibility moved from the left tool group to the right, before the drawer close button. iPad horizontal padding reduced from 10 to 6 pt; the forced 620/1100 pt wrapper was removed. Its grip is now an overlay so its flexible width cannot expand the drawer beyond its controls. Touch targets and responsive two-row fallback retained. Both unsigned app builds succeeded; the isolated Mac preview was rendered and inspected. iPad visual/device verification remains outstanding. Guides and source ZIP updated. Installed apps unchanged.


## Drawer layout update installed — November 15, 2026

Signed builds from the current GitHub working copy installed on Mac and physical iPadProM4. Mac 0.11.0 (14) and Companion 0.9.1 (12) retain their version numbers for this layout-only update. Both apps were stopped before replacement and have been launched afterward. Mac signature verified; runtime status reports no error. Includes wider Mac side padding, annotation visibility at the right, and content-sized iPad drawer with smaller side padding. Signing team supplied only as a build override. Temporary build directories and the installation backup removed.


## Direct editing, slide controls and drawer refinement — November 16, 2026

Source versions: Mac 0.12.0 (15), Companion 0.10.0 (13), wire protocol 7. Existing pairing keys retained. Shared hit-testing and display-aware geometry implement move, endpoint stretch/rotation, rectangle/ellipse corner rotation and side resize; Shift/iPad constraint preserves existing aspect ratio and snaps rotation/line directions. Text moves with drawing tools and edits with Text. Mac Option bypasses hit-testing for drawing over existing objects. Invisible hit regions and Mac hover cursors avoid persistent selection frames. Tiny pointer movement is ignored. Geometry-only live previews hold the existing owner lease, reject stale originals and style/payload tampering, cancel cleanly and commit as one undo step. Existing z-order is retained. Rotation is optional for backwards decoding and used by the shared renderer and eraser hit-testing. Boundary interpolation avoids snapping back during invalid resize/rotation.

Pencil and finger input always available; Pencil preempts an uncommitted finger gesture. Large contacts and finger contacts during Pencil contact/hover plus a brief cooldown are filtered. One gesture at a time; no perfect palm-rejection guarantee. Slide arrows target the last observed Keynote/PowerPoint app, or the sole running supported app. Native AppleScript commands use narrowly scoped sandbox Apple-event exceptions and Automation permission; no System Events or injected keyboard events. Permissions and slideshow behavior require hardware acceptance. Navigation errors do not cancel drawing state.

Mac side padding 16 pt and equal outer button widths; iPad side padding 8 pt with intrinsic drawer sizing. Horizontal grabber bars replaced by directional collapse/reopen chevrons. Mac and isolated iPad SwiftUI drawer content rendered together and visually inspected (the iPad view uses a lightweight preview model on macOS, not an iPad hardware screenshot).

47 Core + 21 Link tests passed; both unsigned app builds succeeded. Tests cover hit regions, topmost priority, endpoint anchoring, aspect ratio on non-square displays, rotated hit-testing/resizing, bounds, no-op clicks, stale edits, leases, cancellation, payload round trips and undo/redo. Guides and sharing archive updated. Installed applications were not replaced and changes were not pushed.


## Object-editing update installation — November 16, 2026

Signed Mac 0.12.0 (15) installed in /Applications, signature verified, launched and runtime status checked with no reported error. Companion 0.10.0 (13) installed on iPadProM4 and installed version verified. Initially iPadOS denied launch with a generic code-signature/entitlement/developer-trust error. The local signed bundle verifies successfully; the embedded development profile includes this iPad and expires on November 19, 2026 at 23:04 UTC. Developer Mode is enabled and the device is paired over USB. The on-device message required an Internet connection to verify the app. The user completed App Verification in iPad settings and confirmed that the app starts successfully. Signing team remains a command-line override.


Installation completed: Mac 0.12.0 (15) and iPad 0.10.0 (13) installed and started. Mac runtime status reports no error; iPad launch confirmed by the user after re-verification. No app-data deletion, developer-certificate replacement or security bypass was needed. Temporary builds and the previous Mac installation backup removed.
