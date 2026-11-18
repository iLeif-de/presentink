# PresentInk – Mac 0.9.2 / iPad Companion 0.7.1

Ein natives Swift-Projekt mit zwei Apps, zwei lokalen Swift Packages und automatisierten Tests.

- **PresentInkMac:** Bildschirm-Overlay, Werkzeuge, globale Shortcuts, Sidecar-Bedienung und Companion-Host.
- **PresentInkCompanion:** native iPad-App mit Pencil-Zeichenfläche, Bildschirmvorschau, Werkzeugleiste und Geräteverbindung.
- **Plattformziele:** macOS 27.0 und iPadOS 27.0; gebaut mit Xcode 27.2.

## Projekt öffnen

`PresentInk.xcodeproj` in Xcode öffnen. Externe Pakete oder Dienste werden nicht benötigt; beide Packages liegen im Projektordner.

### Mac starten

1. Schema **PresentInkMac** wählen, Ziel **My Mac**.
2. **⌘R** drücken. Mac-App und Kurzbefehle-Erweiterung benötigen ein ausgewähltes Entwicklungsteam für die gemeinsame Schlüsselbundgruppe.
3. Unter **Darstellung → Zieldisplay** das Display wählen. Im Drawer ein Zeichenwerkzeug auswählen oder mit **⌃⌥A** zwischen Zeichnen und Bedienen wechseln.

Das Schema **PresentInk** bleibt als Alias für den Mac-Build erhalten.

### Companion auf ein iPad installieren

1. In Xcode Schema **PresentInkCompanion** wählen.
2. Unter **Target → Signing & Capabilities** das eigene Entwicklungsteam einstellen. Falls nötig Bundle-ID anpassen.
3. iPad mit iPadOS 27 anschließen, als Ziel wählen und Developer Mode aktivieren.
4. Mit **⌘R** installieren und starten. Die iPad-App wird als separates Target gebaut; sie wird nicht in die Mac-App eingebettet.

Im Simulator kann die Oberfläche mit „Mit Finger zeichnen“ bedient werden. Ein SDK-Build funktioniert auch ohne installierte Simulator-Laufzeit. Pencil, Bonjour zwischen echten Geräten und Aufnahmefreigaben benötigen Hardwaretests.

## Geräte verbinden

**Companion und Sidecar sind zwei alternative Betriebsarten.** Für die Companion-App muss das iPad eine normale iPad-App anzeigen, nicht die Sidecar-Displayoberfläche.

1. Mac und iPad in dasselbe lokale Netzwerk bringen.
2. Auf dem Mac **Verbindung → iPad verbinden … (⌘I)** öffnen und die Verbindung starten. Alternativ **⇧⌘I** zum Starten/Stoppen verwenden.
3. Auf dem iPad **Mac verbinden** öffnen. Lokales Netzwerk auf beiden Geräten erlauben.
4. Den 32-stelligen Kopplungsschlüssel einmalig vom Mac übertragen und den gefundenen Mac antippen. Nach erfolgreicher Verbindung schließt sich der Dialog automatisch; die Kopplung wird im Schlüsselbund gespeichert.
5. Bereits jetzt ist das iPad als Zeichentablett nutzbar: Striche erscheinen auf dem ausgewählten Mac-Display. Der Mac darf dafür im **Bedienmodus** bleiben; er muss keine Mausereignisse abfangen.
6. Für den Bildschirmhintergrund auf dem iPad **Mac-Bildschirm anzeigen** wählen und die Anfrage am Mac bestätigen. Alternativ am Mac **Vorschau freigeben** wählen. Die vom System verlangte Bildschirmaufnahmefreigabe erteilen und gegebenenfalls erneut starten. Fehler erscheinen jetzt auch auf dem iPad.
7. Mit **Vorschau pausieren** wird die Übertragung beendet und der Hintergrund auf dem iPad geleert. Mit **Verbindung stoppen** endet die Sitzung; die Kopplung bleibt erhalten. **Kopplung zurücksetzen** erzeugt ausdrücklich einen neuen Schlüssel und widerruft alle bisherigen Kopplungen.

Der Schlüssel ist ein zufälliges Kopplungspasswort, kein kurzer PIN. Die Übertragung nutzt authentifiziertes TLS-PSK. Mac und iPad speichern ihn im jeweiligen Schlüsselbund. Der Mac behält ihn über Neustarts hinweg; das iPad verbindet sich beim nächsten Öffnen automatisch mit dem zuletzt gekoppelten sichtbaren Mac, sofern dessen Host-Verbindung läuft. Im iPad-Verbindungsdialog kann ein Mac vergessen werden. Discovery über Bonjour gewährt allein keinen Zugriff.

Wenn kein Mac erscheint: Host-Verbindung am Mac starten, lokale Netzwerkberechtigungen und Firewall kontrollieren. Gast-/Veranstaltungs-WLAN kann Kommunikation zwischen Geräten verhindern. Noch keine manuelle IP-Eingabe, QR-Code-Kopplung oder Internet-Verbindung. Wenn ein Schlüssel bewusst zurückgesetzt wurde: auf dem iPad den gemerkten Mac vergessen und einmalig neu koppeln.

## So ist die iPad-Oberfläche aufgebaut

- **Oben:** ausgewählter Mac-Bildschirm, Verbindungsstatus und gemessene Netzwerk-Roundtrip-Zeit.
- **Mitte:** große, korrekt proportionierte Zeichenfläche. Bei Freigabe liegt die Bildschirmvorschau darunter; sonst eine gerasterte Fläche. Balken außerhalb der Zielgeometrie nehmen keine Striche an.
- **Unten über der Zeichenfläche:** flacher Material-Drawer mit Stift, Marker, Linie, Pfeil, Rechteck, Ellipse, Radierer, der Mac-Farbpalette und drei werkzeugspezifischen Schnellstärken. Bei Formen erscheint die Formfixierung.
- **Drawer-Griff:** Antippen wechselt zwischen ausgezogen und kompakt. Nach unten ziehen oder Chevron antippen versteckt die Palette. Der verbleibende Griff zeigt Werkzeug, Farbe und Stärke; antippen oder hochziehen öffnet sie wieder.
- **Mehr-Menü:** Undo/Redo, genaue Strichstärke (Slider), Formfixierung, Mac-Overlay-Sichtbarkeit und Leeren. Das Verstecken des Drawers verändert die Zeichenfläche nicht.
- **Ausrichtung:** beide Querformatrichtungen. Für die aktuelle Vollbild-Konfiguration ist `UIRequiresFullScreen` gesetzt; Apple markiert diesen Schlüssel als veraltet. Bei schmalen Systemfenstern wird der Drawer zweizeilig, statt Trefferflächen zu verkleinern.
- **Statuszeile:** Vorschauzustand und Warnung, wenn das letzte Hintergrundbild älter als zwei Sekunden ist.
- **Ohne Mac:** ausdrücklich gekennzeichnete lokale Testfläche. Sie wird nicht an einen Mac übertragen und nicht gespeichert.

Pencil zeichnet, Finger bedienen standardmäßig die Oberfläche. Ein Testschalter erlaubt Finger-/Simulatorzeichnen. Pencil-Druck wirkt auf die Stiftbreite; zusammengefasste Touch-Samples werden verarbeitet. Doppeltippen und Squeeze respektieren die vom System gemeldete Werkzeug-/Palettenpräferenz, soweit sie zur App passt. Formen erhalten über die Formfixierung Quadrat-/Kreis- beziehungsweise 45°-Verhalten. Eine angeschlossene Tastatur kann beim Ziehen Shift verwenden.

## Mac-Werkzeuge und Shortcuts

| Funktion | Kürzel |
|---|---|
| Zeichnen / Bedienen | **⌃⌥A**, global |
| Palette verstecken / wiederanzeigen | **⌃⌥W**, global |
| Overlay verstecken und Mauseingabe freigeben | **⌃⌥Escape**, global |
| Bedienmodus | Escape bei App-Fokus |
| Stift / Marker / Pfeil / Radierer | P / H / A / E bei Zeichenfokus |
| Rechteck / Ellipse / Linie | R / O / L bei Zeichenfokus |
| Undo / Redo | ⌘Z / ⇧⌘Z bei App-Fokus |
| Quadrat / Kreis / 45°-Schritte | Shift beim Ziehen |

Das Verstecken der Palette lässt Annotationen sichtbar. Das Verstecken des Overlays beendet **keine** aktive Bildschirmfreigabe; dafür die Vorschau pausieren oder Verbindung beenden.

## Sidecar weiterverwenden

Die Mac-App funktioniert weiterhin eigenständig mit Sidecar. In macOS das Präsentationsdisplay auf das iPad spiegeln, in PresentInk unter Darstellung → Zieldisplay die passende Quelle wählen und im Drawer ein Zeichenwerkzeug auswählen. Für Sidecar ist keine eigene Bildschirmaufnahme nötig. Die Companion-App wird in diesem Modus nicht verwendet. Bei Erweiterung statt Spiegelung muss tatsächlich auf dem gewählten Display gezeichnet werden.

## Projektstruktur

```text
PresentInk.xcodeproj/          Zwei App-Targets, drei geteilte Schemes
Apps/
  macOS/
    PresentInkMacApp.swift    App-Einstieg
    MacAppDelegate.swift      Fenster, Modi und globale Shortcuts
    MacMenus.swift            Menüs, Validierung und Tastaturkürzel
    MacToolDrawer.swift       Nicht aktivierender Mac-Werkzeug-Drawer
    MacCanvasView.swift       Lokale Maus-/Sidecar-Eingabe
    MacSession.swift          Verbindlicher Zustand und Sitzung
    CompanionServer.swift     Bonjour, Pairing, Steuer-/Videokanal
    ScreenPreviewService.swift ScreenCaptureKit und JPEG-Vorschau
    CompanionHostView.swift   SwiftUI-Verbindungs-/Freigabedialog
  iPadOS/
    PresentInkCompanionApp.swift
    CompanionView.swift       SwiftUI-Oberfläche
    CompanionModel.swift      Verbindung, Zeichenbefehle und Spiegelstatus
    ToolDrawerView.swift      Überlagernde, einklappbare Werkzeugpalette
    PencilCanvasView.swift    UIKit-Pencil-Eingabe
SharedUI/
  InkRenderer.swift           Gemeinsamer Core-Graphics-Renderer
Packages/
  PresentInkCore/             Modelle, Dokument, Undo/Redo, Geometrie, Tests
  PresentInkLink/             TLS, Protokoll, TCP-Framing, Tests
Docs/
  Architecture.md            Entscheidungen, Protokoll und Grenzen
  Acceptance.md              Hardware-/Abnahmecheckliste
```

Der gemeinsam genutzte Datenkern verwendet den Swift-6-Sprachmodus und `Sendable`-Modelle. App-/Netzwerkmodule verwenden aktuell Swift-5-Kompatibilitätsmodus mit dem Swift-6-Compiler; ihre Zustandsverarbeitung liegt auf der Main Queue. Die Umstellung dieser UI-/Network-Callbacks auf vollständige Swift-6-Isolation ist ein separater Härtungsschritt.

## Tests und Builds

Im Projektordner:

```sh
swift test --package-path Packages/PresentInkCore
swift test --package-path Packages/PresentInkLink

xcodebuild -project PresentInk.xcodeproj -scheme PresentInkMac \
  -configuration Debug -derivedDataPath build/mac build

xcodebuild -project PresentInk.xcodeproj -scheme PresentInkCompanion \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/ipad CODE_SIGNING_ALLOWED=NO build
```

Die Tests prüfen nicht nur Geometrie, sondern auch Undo/Redo, konkurrierende Eingaben, veraltete Sitzungen, TCP-Teilnachrichten sowie einen echten lokalen TLS-Roundtrip und die Ablehnung eines falschen Schlüssels.

## Umfang dieser Version

Dies ist eine lauffähig baubare Entwicklungsgrundlage mit implementiertem Companion-Datenpfad, keine fertig abgenommene Store-Version.

- Vorschau: höchstens **6 fps, 1280 Pixel breit, JPEG**, auf separatem TLS-Kanal. Kein 60-fps-Video und keine zugesagte Ende-zu-Ende-Latenz. Pencil-Tinte erscheint lokal sofort; die Ausgabe am Mac muss separat gemessen werden.
- Ein Mac-Display und ein iPad pro Sitzung. Striche sind bildschirmgebunden, nicht an Folieninhalte gekoppelt.
- Display-/Geometriewechsel beendet die Vorschau und setzt Zeichenebene sowie Undo zurück. Vorschau anschließend erneut freigeben.
- Nach Verbindungsabbruch den bekannten Mac ohne neue Schlüsseleingabe wählen; beim nächsten Öffnen versucht die App die Wiederverbindung automatisch; keine stille Wiedergabe unbestätigter Striche. Bereits bestätigte Mac-Striche bleiben bestehen.
- Maximal 1.000 Strichobjekte beziehungsweise 100.000 Punkte im Dokument, 8.000 Punkte je Strich. Undo-Verlauf ist begrenzt.
- Noch kein Export, Autosave, QR-Pairing, Druckkorrektur geschätzter Touch-Werte, Hover-/Tilt-Rendering, Vorhersage-Rendering oder H.264-Video.
- Store-Metadaten, Release-Signing/Notarisierung, vollständige Accessibility-Abnahme und Store-Privacy-Angaben sind noch keine fertigen Release-Artefakte.
- Fremde Vollbildfenster und Konferenz-Capture hängen weiterhin von deren Verhalten ab. Ganze Bildschirmfreigabe mit Zuschaueransicht testen.

**Build-/Testnachweis:** [BUILD-STATUS.md](../BUILD-STATUS.md). **Vor einem Präsentationseinsatz:** [Abnahmecheckliste](../Docs/Acceptance.md).

## Update: gemerkte Kopplung und Vorschau

Mac und iPad müssen beide mit dieser Version gestartet werden (Wire-Protokoll 5). Bereits gespeicherte Kopplungsschlüssel bleiben erhalten. Die Bildschirmfreigabe bleibt eine eigene, sichtbare Aktion.

Ein erster Bildschirmframe wird für einen später verbundenen Videokanal zwischengespeichert, damit auch ein statischer Desktop sofort sichtbar werden kann. Bei Pause/Disconnect wird dieser Cache geleert. Nummerierte Vorschauzustände verhindern, dass ältere Meldungen des Steuerkanals eine neuere Live-Vorschau des Videokanals wieder ausblenden.

## App-Icons

Mac und iPad verwenden das gemeinsame PresentInk-Motiv. Die plattformspezifischen Asset-Kataloge sind in beiden Targets eingebunden. Originalvorlagen und Gestaltungsbeschreibung liegen unter `Design/`. Beide Icon-Builds wurden erfolgreich geprüft.

## Mac-Drawer und Menüs

Die große Mac-Palette ist durch einen flachen Drawer am unteren Rand des gewählten Displays ersetzt. Er enthält Bedienmodus (Cursor), Zeichenwerkzeuge, Farben und drei direkte Strichstärken. Ein Werkzeug anzuklicken aktiviert den Zeichenmodus. Der Griff wechselt zwischen voller und kompakter Ansicht; Pfeil nach unten beziehungsweise ⌃⌥W reduziert den Drawer auf einen Griff. Darüber lässt er sich wieder öffnen. Der Drawer liegt über dem Desktop und verändert dessen Geometrie nicht.

Andere Aktionen liegen in den Menüs **Bearbeiten**, **Werkzeuge**, **Darstellung**, **Verbindung** und **Hilfe** sowie im Menüleistensymbol. Im Menü stehen die zugehörigen Kürzel; Häkchen zeigen aktuelle Werkzeuge, Farben, Stärke und Zieldisplay.

| Aktion | Kürzel | Geltungsbereich |
|---|---|---|
| Zeichnen / Bedienen | ⌃⌥A | Global |
| Drawer zeigen / verstecken | ⌃⌥W | Global |
| Notfall: Overlay ausblenden und Eingabe freigeben | ⌃⌥Escape | Global |
| Drawer kompakt / ausziehen | ⇧⌘D | In PresentInk |
| Annotationen zeigen / verstecken | ⇧⌘H | In PresentInk |
| Farbe 1–6 | ⌘1–6 | In PresentInk |
| Stärke erhöhen / verringern | ⌘+ / ⌘− | In PresentInk |
| Alle Annotationen löschen | ⇧⌘⌫ | In PresentInk, reversibel |
| Verbindung & Freigabe | ⌘I oder ⌘, | In PresentInk |
| iPad-Verbindung starten / stoppen | ⇧⌘I | In PresentInk |
| Bildschirmvorschau starten / pausieren | ⇧⌘S | In PresentInk, iPad verbunden |
| Zieldisplay 1–9 | ⌃⌘1–9 | In PresentInk |
| Werkzeuge | ⌥⌘P/H/L/A/R/O/E | In PresentInk |
| Bedienen | ⌥⌘V | In PresentInk |

Die bisherigen Einzeltasten P/H/L/A/R/O/E und V/Escape gelten zusätzlich nur bei Fokus auf der Zeichenfläche. Bei Zieldisplaywechsel mit bestehenden Strichen bestätigt die App das Entfernen der alten Zeichenebene.

## Dock- und App-Wechsel-Icon

Das Icon ist im Bundle als AppIcon.icns und über die App-Info eingetragen. Die App bleibt eine reguläre Mac-Anwendung und lädt beim Start ihr eigenes Icon ausdrücklich in AppKit. Eine bereits laufende alte Version übernimmt einen nachträglichen Ressourcen-Build nicht automatisch. Auf diesem Mac wurden mehrere Kopien gefunden, darunter eine ältere Xcode-Kopie ohne Icon-Ressourcen. Die installierte Version unter `/Applications/PresentInk.app` wurde mit dem neuen Build aktualisiert und gestartet. Die direkte visuelle Dock-Prüfung war über die UI-Steuerung nicht zuverlässig möglich.

## Apple Kurzbefehle und AppleScript

Die Mac-App bietet 16 native Kurzbefehle-Aktionen und ein AppleScript-Wörterbuch mit 43 Befehlen und elf Eigenschaften. Zeichenmodus, Werkzeuge, Farben, Strichstärke, Drawer, Overlay, Displays, Verbindung und Vorschau lassen sich steuern; Status und Fehler werden strukturiert zurückgegeben.

In Kurzbefehle nach **PresentInk** suchen. Die vollständige Anleitung mit Befehlsreferenz steht unter [Automation](../Docs/Automation.md); fertige AppleScript-Beispiele liegen unter [Automation/Examples](../Automation/Examples).

## Anleitung und Vollbild (Mac 0.5)

**Hilfe → PresentInk-Anleitung** öffnet die ausführliche Offline-Anleitung mit Inhaltsverzeichnis. Die Markdown-Quelle steht unter [Docs/Anleitung.md](../Docs/Anleitung.md). Nach Änderungen mit `python3 Tools/render_help.py` die gebündelte HTML-Lesefassung aktualisieren. Beide Dateien werden vom Mac-Target kopiert. **Hilfe → Tastaturkürzel …** öffnet eine gruppierte, scrollbar angelegte Referenz mit eigener Tastenspalte.

Zeichenfläche und Drawer dürfen fremden Vollbild-Spaces und Stage Manager folgen. Die Zeichenfläche ist ein nicht aktivierendes NSPanel; Zeichnen aktiviert die Mac-App nicht mehr und stellt beim Beenden keinen zuvor gespeicherten App-/Space-Fokus wieder her. Bei Space-Wechsel oder Verlust des Zeichenfokus endet lokales Zeichnen, ohne das Dokument zu löschen oder die Vorschau zu stoppen. Die Zeichenfläche liegt knapp unter dem Drawer. Normale Hilfe-/Einstellungsfenster aktivieren weiterhin die App.

## Vollständig unsichtbarer Mac-Drawer und Kapitelhilfe (0.6 / 0.4)

Am Mac blendet das X-Symbol neben dem Chevron den Drawer einschließlich Griff aus. Das Auge schaltet auf beiden Plattformen die Sichtbarkeit der Annotationen. Das Chevron minimiert weiterhin auf den Griff. ⌃⌥W, Dock-Wiederöffnen oder Menü → Drawer zeigen öffnen ihn wieder. Display- und Space-Wechsel dürfen einen vollständig ausgeblendeten Drawer nicht zurückholen. Zeichnen, Annotationen und Vorschau bleiben unverändert.

Auf dem iPad steht oben ein eigener **Mac-Drawer**-Switch zur Verfügung, zusätzlich im Mehr-Menü des Drawers. Aus blendet vollständig aus; Ein öffnet den Mac-Drawer ausgezogen. Der vom Mac bestätigte Zustand wird auch nach Menü-/Automationsänderungen und erneuter Verbindung übertragen. Ohne Verbindung bzw. vor dem ersten Status ist der Switch deaktiviert. Mac und iPad müssen beide aktualisiert werden.

AppleScript: `set drawer state to "invisible"` oder `change drawer "invisible"`. Kurzbefehle: **PresentInk-Drawer einstellen → Vollständig ausgeblendet**. `hidden` bleibt der bisherige Zustand mit Griff.

Die Offline-Hilfe hat links ein dauerhaftes Inhaltsverzeichnis und rechts ausschließlich das ausgewählte Kapitel; beide Bereiche scrollen unabhängig. Die vollständige Markdown-Datei bleibt unter [Docs/Anleitung.md](../Docs/Anleitung.md) verfügbar.

## Zentrale Einstellungen und gemerkte Freigabe (0.7 / 0.5)

**PresentInk → Einstellungen … (⌘,)** bietet eigene Palette (1–8 Farben), werkzeugspezifische Farbe, Deckkraft (5–100 %), Breitenbereich innerhalb 0,5–100 logischer Mac-Punkte, Standard-/drei Schnellstärken, Pencil-Druck und Werkzeugreihenfolge. Der Mac speichert alles und bestätigt iPad-Änderungswünsche. Das iPad bestätigt seinerseits den empfangenen Stand; im Automationsstatus sichtbar als `drawing_settings_synced`. Während eines Strichs werden Einstellungen nicht geändert. Vorhandene Striche behalten ihre eigenen Darstellungswerte, auch nach Profilwechsel.

Profile **Helle Folien**, **Dunkle Folien**, **Whiteboard** sind enthalten. Bis zu zwölf benannte Profile können am Mac gespeichert/ersetzt und am iPad oder über Automation gewählt werden. Die Farbpalette ist gemeinsam; pro Werkzeug werden Farbe und Breite separat gemerkt. Das iPad behält nur lokale Ergonomie wie Drawer-Darstellung und Finger-Testmodus.

Bei einer Vorschau-Anfrage einmal **Freigeben & merken** wählen. Danach fragt PresentInk für die bestehende Kopplung nicht erneut. **Nach dem Verbinden automatisch starten** ist eine zusätzliche, standardmäßig ausgeschaltete Option. Bewusstes Pausieren wird gespeichert. Vertrauen ist an einen Fingerabdruck des aktuellen Kopplungsschlüssels gebunden; beim Schlüsselwechsel/Zurücksetzen wird es widerrufen. macOS-Systemfreigaben bleiben erforderlich.

Mac und iPad gemeinsam aktualisieren (Protokoll 4). Bestehende Kopplungsschlüssel bleiben erhalten. Anleitung und Automationsreferenz enthalten die neuen Optionen und JSON-Beispiele.

## Öffentliche Fenster in der Vorschau und Text (0.8 / 0.6)

Die iPad-Vorschau zeigt jetzt Einstellungen, Anleitung und Tastaturkürzel einschließlich eines aus den Einstellungen geöffneten Farbwählers. Overlay, Drawer, Texteingabepanel und Verbindungs-/Kopplungsfenster bleiben ausgeschlossen. Die App ist standardmäßig ausgeschlossen; nur explizit freigegebene Fenster-IDs bilden Ausnahmen. Die Liste wird während der Übertragung bei geöffneten/geschlossenen Fenstern aktualisiert. Damit können Einstellungen für ein Video am iPad sichtbar werden; Mac-Steuerelemente werden weiterhin am Mac bedient.

**Text** im Drawer oder Menü wählen (T bei Zeichenfokus, ⌥⌘T in der App), Position anklicken, mehrzeiligen Text eingeben und mit **Einfügen/⌘Return** bestätigen. Am iPad funktioniert die Platzierung mit Finger oder Pencil; die Eingabe erfolgt per Tastatur. Schriftgröße/Farbe/Deckkraft kommen vom Mac-Textstil (Vorgabe 28 pt, Bereich 8–96 pt). Alte Profile werden verlustfrei um Text ergänzt.

Textobjekte unterstützen Undo/Redo und Radieren. Grenzen: 2000 Zeichen, 20 eingegebene Zeilen, Umbruch innerhalb des Displays. Noch keine Bearbeitung/Verschiebung bereits platzierter Texte oder Formatierung einzelner Wörter. Native Aktion **PresentInk-Text einfügen** bzw. AppleScript `insert text "Hallo" at x 0.1 at y 0.2`. Beide Apps gemeinsam aktualisieren (Protokoll 5); Kopplungsschlüssel bleiben erhalten.


## Native Kurzbefehle-Ausgaben (Mac 0.9 / Companion 0.7)

Die 16 Aktionen liefern native Status-, Display- und Einstellungsobjekte. In Folgeaktionen die Ausgabevariable anklicken und die gewünschte Eigenschaft wählen; bisherige JSON-Konvertierungsschritte entfallen. Einstellungen können als Objekt von der Lesen- an die Anwenden-Aktion übergeben werden. AppleScript behält seine JSON-Schnittstelle.

Die Mac-App muss laufen; im Hintergrund wird sie ohne Aktivierung gesteuert. Bei beendeter App oder mehreren laufenden Kopien erscheint ein Fehler. Für einen bewussten Start die Standardaktion „App öffnen“ vorschalten. Die separate Kurzbefehle-Erweiterung wird zusammen mit der Mac-App eingebettet und benötigt dieselbe Entwicklungssignatur samt gemeinsamer Schlüsselbundgruppe.

Auf beiden Drawern schaltet das Auge „Annotationen ausblenden/zeigen“. Das X schließt den Mac-Drawer vollständig.


## Selbst bauen und Projektarchiv erstellen

Im Terminal in den Projektordner wechseln (dort liegt `PresentInk.xcodeproj`). Benötigt werden Xcode mit macOS-/iPadOS-27-SDK sowie Python 3 für das Archiv.

```sh
# Mac-App einschließlich Kurzbefehle-Erweiterung bauen
./Tools/build.sh mac
# iPad-App für echte Geräte bauen
./Tools/build.sh ipad
# iPad-App für den Simulator, ohne Signierung
./Tools/build.sh simulator
# Teilbares Quellcode-ZIP erzeugen
python3 Tools/archive.py
```

Für Mac und echtes iPad zuvor das eigene Team in Xcode auswählen. Alternativ `DEVELOPMENT_TEAM=DEINE_TEAM_ID ./Tools/build.sh mac` verwenden. Falls passende Entwicklungsprofile fehlen, die App zunächst einmal in Xcode bauen und dort die automatische Signierung einrichten. Das Skript baut nur; es installiert oder startet keine App. Ergebnisse liegen unter `build/mac`, `build/ipad` bzw. `build/simulator`. Für Installation auf dem iPad in Xcode das Schema **PresentInkCompanion** und das eigene iPad wählen, dann ⌘R drücken.

Das Archiv entsteht neben dem Projektordner als `PresentInk-Mac-iPad-Xcode.zip`. Optional: `python3 Tools/archive.py --output /tmp/PresentInk.zip`. Es enthält ausgewählte Quellcode-, Dokumentations- und Design-Dateien; Builds, persönliche Xcode-Daten, Profile, Zertifikate und Schlüsselbunddateien werden nicht aufgenommen. Die Team-ID wird nur in der archivierten Projektdatei entfernt. Empfänger wählen ihr eigenes Team. Vor dem Teilen neu hinzugefügte Quelltexte weiterhin auf selbst eingetragene Geheimnisse prüfen; das Skript ersetzt keinen vollständigen Geheimnis-Scanner.


## Code-Review-Korrekturen

Archivvollständigkeit, Displayerhalt, Fokus, Wiederverbindung, Einstellungen und Übertragung wurden überarbeitet. Details und gezielte Abnahme: [Review-Fixes](../Docs/Review-Fixes.md).
