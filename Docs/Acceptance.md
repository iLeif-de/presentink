# Hardware-Abnahme – Mac + iPad

Diese Liste ist noch nicht als bestanden markiert. Automatisierte Tests und Builds stehen im Buildnachweis.

## Mac / Sidecar

- [ ] Programme-Version zeigt das Icon im Dock und in ⌘Tab nach vollständigem Neustart.
- [ ] Drawer: Werkzeug anklicken aktiviert Zeichnen; Cursor aktiviert Bedienen.
- [ ] Drawer-Griff kompakt/ausgezogen, Chevron/⌃⌥W versteckt und Griff öffnet wieder.
- [ ] Farben ⌘1–6 und Breite ⌘+/⌘− entsprechen den Menü-Häkchen.
- [ ] Bearbeiten-/Darstellung-/Verbindung-Menüs und ihre Tastaturkürzel prüfen; nicht verfügbare Aktionen sind deaktiviert.
- [ ] Drawer folgt dem gewählten Display; Wechsel mit vorhandenen Strichen fragt nach Bestätigung.

- [ ] Mac-Overlay ohne Capture-/Netzwerkfreigabe bedienen.
- [ ] Alle Werkzeuge, Undo/Redo und rückgängig machbares Leeren testen.
- [ ] Mit Shift Quadrat/Kreis und 45°-Linien in allen vier Richtungen erzeugen; Shift während des Ziehens wechseln.
- [ ] ⌃⌥A, ⌃⌥W und ⌃⌥Escape aus fremder App testen; Notfallaktion auch während eines iPad-Strichs prüfen.
- [ ] Fremde Fenster im Bedienmodus anklicken/ziehen/scrollen.
- [ ] Sidecar-Spiegelung mit Pencil prüfen; keine Companion-App parallel verwenden.
- [ ] Keynote-/Browser-Vollbild, Spaces und Stage Manager einzeln prüfen.

## Companion

- [ ] Querformat links/rechts: Drawer bleibt flach und vollständig erreichbar.
- [ ] Drawer am Griff kompakt schalten, nach unten verstecken und am verbleibenden Griff wieder öffnen.
- [ ] Werkzeug-, Farb- und Stärkenwechsel direkt antippen; genaue Stärke und Undo/Redo über das Mehr-Menü prüfen.
- [ ] Beim Ein-/Ausklappen bleiben Hintergrund, Striche und normalisierte Eingabekoordinaten unverändert.
- [ ] Squeeze-Palettenaktion mit dem neuen Drawer prüfen.

- [ ] Auf beiden Geräten lokales Netzwerk erlauben; Mac erscheint in der Suche.
- [ ] Richtiger Schlüssel verbindet, falscher Schlüssel gibt keine Verbindung frei.
- [ ] Ein zweites iPad kann eine aktive Sitzung nicht übernehmen.
- [ ] Ohne Capture-Freigabe auf gerasterter Fläche zeichnen: Striche erscheinen auf dem Mac, dortige Maus bleibt bedienbar.
- [ ] Eckpunkte und Kreise bei unterschiedlichen Display-/iPad-Seitenverhältnissen prüfen; Letterboxing nimmt keine Striche an.
- [ ] Pencil zeichnet, Handfläche/Finger erzeugen ohne Testschalter keine Striche.
- [ ] Doppeltippen/Squeeze mit verschiedenen Pencil-Systempräferenzen prüfen.
- [ ] Bildschirmvorschau ausdrücklich starten, OS-Freigabe prüfen; keine Doppelstriche und keine PresentInk-Palette im Hintergrundvideo.
- [ ] Vorschau pausieren: Hintergrund auf dem iPad leer, Tinte bleibt, keine neuen Bildschirmbilder.
- [ ] Beide Apps neu starten: gleicher Mac-Schlüssel, gespeicherte iPad-Kopplung und Wiederverbindung ohne erneutes Eintippen.
- [ ] „Vergessen“ auf dem iPad und „Kopplung zurücksetzen“ auf dem Mac testen; alte Schlüssel werden danach abgewiesen.
- [ ] „Mac-Bildschirm anzeigen“ fordert die Freigabe am Mac an; verweigerte OS-Aufnahmefreigabe liefert eine verständliche Meldung auf dem iPad.
- [ ] Unveränderten Desktop vor Freigabe stehen lassen: auch ein später Videokanal erhält das erste Bild.
- [ ] WLAN trennen während eines Strichs: keine spätere Wiedergabe; nach manuellem Reconnect bestätigten Mac-Zustand übernehmen.
- [ ] App in Hintergrund bringen: Verbindung endet; Vordergrund erfordert neues Verbinden.
- [ ] Display abziehen/rotieren/auflösen: alte Punkte verworfen, neue Geometrie korrekt, Vorschau muss erneut freigegeben werden.
- [ ] Mac sperren/aufwecken: kein fortgesetzter Hintergrundstream.
- [ ] Bei 1.000 Strichen und 100.000 Punkten Größenlimit verständlich behandeln; keine festhängende aktive Eingabe.

## Publikum und Leistung

- [ ] Physisches Beamerbild und echte Konferenz-Zuschaueransicht prüfen; Fensterfreigabe und Displayfreigabe unterscheiden.
- [ ] Pencil-bis-Mac und Hintergrundalter separat messen. Netzwerk-RTT ist kein Ersatz dafür.
- [ ] Schwaches WLAN und 1 % Paketverlust testen: Zeichenkanal bleibt bedienbar, alte Videobilder stauen sich nicht beliebig.
- [ ] 60 Minuten Betrieb, Speicherentwicklung und Akkuverbrauch dokumentieren.

## Automation auf dem Mac

- [ ] PresentInk-Aktionen in Apple Kurzbefehle finden und einen Ablauf aus Werkzeug, Farbe, Breite und Zeichenmodus ausführen.
- [ ] Zeichenmodus und Drawer über AppleScript umschalten; Statusabfrage liefert den aktuellen Zustand.
- [ ] Menü, Drawer und Automation zeigen dieselben Einstellungen.
- [ ] Ungültige Werte werden mit verständlichem Fehler abgewiesen.
- [ ] Displaywechsel mit vorhandenen Strichen verlangt ausdrücklich das Löschen.
- [ ] Zurücksetzen der Kopplung verlangt ausdrücklich `confirmed true`.
- [ ] Vorschau respektiert Verbindung und macOS-Aufnahmefreigabe; Startzustand wird asynchron gemeldet.

## Hilfe und Vollbild

- [ ] Anleitung unter Hilfe öffnen, Inhaltslinks und lange Tabellen prüfen; ohne Netzwerk nutzbar.
- [ ] Tastaturkürzel-Referenz öffnen, scrollen, verkleinern und erneut öffnen; Gruppen und Tastenspalte bleiben lesbar.
- [ ] Über einem fremden Vollbild-Space den Zeichenmodus mit globalem Kürzel einschalten; Präsentation bleibt sichtbar.
- [ ] Mit Mac/Trackpad und iPad zeichnen, Drawer bedienen und Escape/Notfall-Ausblenden prüfen.
- [ ] Space wechseln: Zeichnen endet, vorhandene Striche und Vorschau bleiben erhalten.
- [ ] Mehrere Displays, Keynote/PowerPoint und Stage Manager auf Zielhardware prüfen.

## Vollständig ausgeblendeter Mac-Drawer und Kapitelhilfe

- [ ] X blendet auch den Griff aus; der obere Abwärtspfeil minimiert auf den Griff. Das Auge schaltet ausschließlich Annotationen.
- [ ] ⌃⌥W und explizites Wiederöffnen holen den unsichtbaren Drawer zurück.
- [ ] Unsichtbarer Drawer bleibt bei Space-/Displaywechsel unsichtbar.
- [ ] iPad-Switch oben und im Mehr-Menü blendet den Mac-Drawer aus/ein; Mac-Menü und Automation aktualisieren den Switch zurück.
- [ ] Switch ist ohne Verbindung/vor erstem Mac-Status deaktiviert; bei Wiederverbindung stimmt der Anfangszustand.
- [ ] AppleScript `invisible` und native Kurzbefehle-Option entfernen den Griff; `hidden` bleibt kompatibel.
- [ ] Hilfe: Linksauswahl wechselt rechts das Kapitel, beide Bereiche scrollen unabhängig, Navigation per Tastatur nutzbar.

## Zentrale Einstellungen und gemerkte Freigabe

- [ ] Je Werkzeug Farbe, Deckkraft, Breitenbereich, Standard- und Schnellstärken einstellen und nach Neustart prüfen.
- [ ] Palette hinzufügen/löschen/umordnen, Werkzeugreihenfolge ändern; beide Drawer und Mac-Menü folgen.
- [ ] Mac-Änderung am realen iPad übernehmen; iPad-Schnellauswahl am Mac bestätigen; `drawing_settings_synced` wird true.
- [ ] Profil am Mac speichern/ersetzen und am iPad auswählen; bestehende Striche bleiben unverändert.
- [ ] Pencil-Druck deaktivieren/variieren; Breite bleibt in den Grenzen.
- [ ] Aktiver Strich blockiert Parameteränderungen; veralteter Editor-Entwurf überschreibt keine zwischenzeitliche Änderung.
- [ ] Freigeben & merken vermeidet weitere PresentInk-Nachfrage, ohne macOS-Zustimmung zu umgehen.
- [ ] Autostart separat einschalten; bewusste Pause bleibt nach Wiederverbinden/App-Neustart wirksam.
- [ ] Vertrauen widerrufen/Schlüssel wechseln stoppt bzw. verhindert die automatische Freigabe.

## Text und öffentliche Vorschaufenster

- [ ] Einstellungen und Hilfe im laufenden iPad-Bild sehen, auch wenn sie nach Vorschau-Start geöffnet werden.
- [ ] Overlay/Drawer/Inline-Texteingabe/Kopplungsfenster bleiben aus dem Hintergrundbild ausgeschlossen; kein Schlüssel sichtbar.
- [ ] Aus den Einstellungen geöffneten Farbwähler sehen und schließen, ohne die Vorschau neu zu starten.
- [ ] Am Mac T wählen, Position anklicken, mehrzeilig schreiben und einfügen; Escape bricht ab, ⌘Return fügt ein.
- [ ] Am iPad Text mit Finger/Pencil platzieren und über Bildschirm-/Hardwaretastatur eingeben.
- [ ] Textfarbe, Schriftgröße und Deckkraft am Mac einstellen; beide Ausgaben stimmen überein.
- [ ] Radierer, Undo/Redo und Profilwechsel mit Textobjekten prüfen.
- [ ] Alte benannte Profile behalten eigene Farben und Parameter; Text ist nach Migration zusätzlich verfügbar.


## Kurzbefehle und Annotationen (0.9.0)

- Status liefert auswählbare boolesche, numerische und benannte Eigenschaften; keine manuelle JSON-Konvertierung.
- Displayliste und Einstellungen liefern native Objekte.
- Beendete Mac-App: Aktion meldet Fehler und startet sie nicht.
- Hintergrund-App: Status und Zeichensteuerung aktivieren kein Fenster.
- Mehrere laufende Kopien: eindeutiger Fehler.
- Auf beiden Drawern schaltet das Auge Annotationen aus/ an. Das X blendet nur den Mac-Drawer vollständig aus.


## Regressionen aus Code Review

Hardware-Prüfschritte stehen in [Review-Fixes](Review-Fixes.md), insbesondere Keynote-Fokus, Bildschirmwechsel mit Undo-Historie, WLAN-Unterbrechung und Sperren/Aufwecken.


### Keynote-Nutzertest vom 14.11.2026

Bestätigt mit Mac 0.9.2: iPad-Annotationen am Mac sichtbar; Maus/Trackpad und Werkzeugwahl nach Aktivierung funktionieren; ⌃⌥A schaltet in Keynote um. Nicht als vollständige Abnahme aller Monitor-/Space-/Texteingabe-Kombinationen werten.


## Abnahme 0.9.0: direkte Bearbeitung und iPad-Bedienung

Diese Prüfpunkte sind eine manuelle Checkliste, keine Behauptung einer vollständigen Abnahme.

- [ ] Standardpfeil beim Zeichnen, Löschen, Textplatzieren und an Linienenden; kein Fadenkreuz.
- [ ] Mac-/iPad-Aboutbox zeigt 0.9.0, Build 16, GitHub-Link und MIT-Lizenz; kein Hausnerd-Link.
- [ ] Mitte ziehen verschiebt Striche/Pfeile; Enden ziehen ändert Richtung/Länge mit festem Gegenende.
- [ ] Rechteck/Ellipse innen verschieben, an Begrenzungsecken drehen, an Seitenmitten skalieren.
- [ ] Shift bzw. iPad-Proportionsschalter erhält das vorhandene Seitenverhältnis; gedrehte Formen und Randbegrenzung prüfen.
- [ ] Ein Klick ohne Bewegung erzeugt keinen Undo-Schritt; eine Ziehbewegung erzeugt genau einen.
- [ ] Bearbeitung auf beiden Geräten sichtbar, ohne Doppelobjekt; Abbruch und Verbindungsverlust stellen das Original wieder her.
- [ ] Inline-Text mit großer, schwebender und Hardware-Tastatur sowie Scribble beenden/abbrechen; obere Buttons bleiben erreichbar.
- [ ] Finger und Pencil ohne Umschalter; Pencil-Vorrang, Handballenfilter und schnelle Eingabewechsel prüfen.
- [ ] Folienpfeile in Keynote/PowerPoint einschließlich erster Automation-Freigabe, verweigerter Freigabe und zwei gleichzeitig laufender Apps testen.
- [ ] Deutsch/US-Englisch, kompakter/ausgezogener Drawer und große Schriftgrößen auf physischer Hardware prüfen.


## Abnahme 0.9.1: Folienwechsel und Leeren

- [ ] Direkte Papierkorb-Taste in ausgezogenem und kompaktem Drawer auf beiden Geräten testen; kein Dialog, Undo stellt die Zeichnung wieder her.
- [ ] Mac-Drawer-Pfeile ohne verbundenes iPad und iPad-Pfeile mit Verbindung testen.
- [ ] Erfolgreicher Keynote-/PowerPoint-Befehl leert beide Ansichten; Keynote-Animationsschritt ebenfalls prüfen.
- [ ] Verweigerte Automation, geschlossene Präsentation, zu schnelle Wiederholung und Zeitüberschreitung erhalten die Zeichnung.
- [ ] Physische Mac-Pfeiltasten bei Zeichenfokus leeren nach Navigation; Texteditor und aktive Striche bleiben geschützt.
- [ ] Externe Foliennavigation wird nicht erkannt: Papierkorb verwenden.
- [ ] Verzögerte alte Preview-/Commit-Pakete erscheinen nach dem Wechsel nicht erneut; eine neue Zeichnung auf der neuen Folie funktioniert.
- [ ] Source-/Displaywechsel während einer Automation-Nachfrage verändert keine Annotationen der neuen Quelle.


## Regressionen 0.9.2

- [ ] Keynote-Vollbild: Overlay und Drawer über der Präsentation, Maus/Trackpad und ⌃⌥A bedienbar; iPad-Striche auf dem gewählten Mac-Display sichtbar.
- [ ] LibreOffice-Impress-Vollbild: Drawer und iPad-Annotationen sichtbar; Ein-/Ausblenden bleibt getrennt steuerbar.
- [ ] PowerPoint/Keynote über PresentInk-Pfeile wechseln: Zeichnung geleert, Hintergrund bleibt ohne Vorschau-/Verbindungs-Popup sichtbar.
- [ ] Statische Folie unmittelbar nach Wechsel und langsames WLAN: kein dauerhaft verschwundenes Bild, keine falsche Neu-Freigabe.
- [ ] Geometriewechsel auf demselben bereits freigegebenen Display setzt Capture fort; tatsächlicher Displaywechsel verwirft alte Bilder und startet keine unfreigegebene Quelle.
- [ ] Zeichnung ausgeblendet / Drawer vollständig versteckt / Bedienmodus gezielt unterscheiden; keine unbeabsichtigte Sichtbarkeitsänderung durch Präsentationserkennung.
