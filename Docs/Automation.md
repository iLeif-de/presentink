# PresentInk 0.9 – Apple Kurzbefehle und AppleScript

Die **Mac-App** kann über native Kurzbefehle-Aktionen und über ein eigenes AppleScript-Wörterbuch gesteuert werden. Beide Wege verwenden denselben Controller und denselben Zustand wie Drawer und Menüs. Es ist kein UI-Scripting über „System Events“ und keine Bedienungshilfen-Freigabe nötig.

Die iPad-App bleibt der Pencil-Client; diese Automationsschnittstellen sind Bestandteil der Mac-App. Neue Zeichenobjekte entstehen weiterhin durch Maus/Pencil. Die Schnittstelle steuert die vorhandenen Funktionen, Einstellungen und Ausgabe, erzeugt keine synthetischen Gesten.

## Einrichtung

1. Die aktuelle Mac-Version unter `/Applications/PresentInk.app` einmal starten. Bei mehreren Xcode-/App-Kopien auf die richtige Version achten: **0.9.0, Build 9**.
2. In **Kurzbefehle** einen Kurzbefehl erstellen und in der Aktionssuche nach **PresentInk** suchen. Die App stellt native Aktionen bereit; einige häufige Aktionen werden zusätzlich als App-Kurzbefehle angeboten.
3. Für AppleScript im **Skripteditor → Ablage → Wörterbuch öffnen … → PresentInk** das Wörterbuch ansehen. Alternativ die Dateien unter `Automation/Examples/` öffnen.
4. Beim ersten AppleScript-Zugriff kann macOS die Erlaubnis verlangen, dass der aufrufende Prozess PresentInk steuern darf. Diese Systemfreigabe selbst bestätigen.

Ein eigener Apple-Kurzbefehl kann mit einem Tastaturkürzel oder über die Menüleiste gestartet werden. Bestehende globale PresentInk-Kürzel funktionieren weiterhin unabhängig davon.

## Native Kurzbefehle-Aktionen

| Aktion | Parameter / Ergebnis |
|---|---|
| PresentInk steuern | Auswahl der einzelnen Aktionen: Zeichenmodus, Overlay, Drawer, Undo/Redo, Leeren, Verbindung, Vorschau, Notfall, Fenster, Hilfe und Beenden |
| PresentInk-Werkzeug setzen | Stift, Marker, Linie, Pfeil, Rechteck, Ellipse, Radierer |
| PresentInk-Farbe setzen | Rot, Gelb, Blau, Grün, Weiß, Graphit |
| Eigene PresentInk-Farbe setzen | Hex-Farbe `#RRGGBB` |
| PresentInk-Strichstärke setzen | Zahl innerhalb des am Mac eingestellten Werkzeugbereichs, auch Zwischenwerte |
| PresentInk-Drawer einstellen | Ausgezogen, kompakt, minimiert (Griff), vollständig ausgeblendet |
| PresentInk-Zieldisplay wählen | Displayindex ab 1; explizite Option zum Entfernen bestehender Annotationen |
| PresentInk-Status abfragen | Status-Objekt mit auswählbaren Eigenschaften |
| PresentInk-Displays auflisten | Display-Objekte mit Index, ID, Name, Größe und Auswahl |
| PresentInk-Kopplung zurücksetzen | Explizite Bestätigung zum Widerruf aller bisherigen Schlüssel erforderlich |

In Kurzbefehlen ist die Ausgabe ein typisierter PresentInk-Status. In der nächsten Aktion die Ausgabevariable anklicken und die gewünschte Eigenschaft auswählen, etwa **Zeichenmodus aktiv**, **Annotationen sichtbar**, **Werkzeug** oder **Strichstärke / Schriftgröße**. Die Display-Aktion liefert eine Liste von Display-Objekten mit einzeln auswählbaren Eigenschaften. JSON wird intern verarbeitet; ein Wörterbuch- oder JSON-Konvertierungsschritt entfällt. Bestehende Abläufe mit JSON-Auswertung bitte auf diese Eigenschaften umstellen.

PresentInk muss bereits laufen. Ist die App beendet, endet die Aktion mit einer verständlichen Fehlermeldung. Eine im Hintergrund laufende App wird ohne Aktivierung gesteuert; ausdrücklich gewählte Fenster-/Anzeigeaktionen können natürlich Fenster öffnen. Zum bewussten Starten vorher die Apple-Aktion **App öffnen → PresentInk** hinzufügen. Bei mehreren laufenden PresentInk-Kopien wird eine eindeutige Fehlermeldung ausgegeben.

### Beispiel: Präsentationsstift

Einen Kurzbefehl mit diesen Aktionen zusammenstellen:

1. PresentInk-Werkzeug setzen → Stift.
2. PresentInk-Farbe setzen → Rot.
3. PresentInk-Strichstärke setzen → 4.
4. PresentInk-Drawer einstellen → Kompakt.
5. PresentInk steuern → Annotationen zeigen.
6. PresentInk steuern → Zeichnen einschalten.

Werkzeug/Farbe/Stärke allein aktivieren den Zeichenmodus nicht automatisch. Damit lässt sich ein Profil vorbereiten, bevor die Eingabe übernommen wird.

## AppleScript – erste Beispiele

### Umschalten

```applescript
tell application "PresentInk"
    toggle drawing
end tell
```

### Gezielt konfigurieren statt toggeln

```applescript
tell application "PresentInk"
    set current tool to "pen"
    set ink color to "#F0544F"
    set stroke width to 4
    set drawer state to "compact"
    set annotations visible to true
    set drawing enabled to true
end tell
```

### Drawer und Notfall

```applescript
tell application "PresentInk"
    hide drawer
    -- Der kleine Griff bleibt erreichbar.
    show drawer
    compact drawer
    emergency hide
    -- Zeichnen aus; Mausereignisse frei; Annotationen ausgeblendet.
end tell
```

### Verbindung und Vorschau

```applescript
tell application "PresentInk"
    start connection
    -- Das bekannte iPad kann sich nun verbinden.
    -- Erst nach erfolgreicher Verbindung:
    start preview
    set stateJSON to read status
end tell
```

`start preview` ist asynchron. Der unmittelbare Status kann `starting` sein. Bei Bedarf `status` abfragen, bis `preview_state` `live` oder `failed` ist. Die Bildschirmaufnahmeberechtigung wird nicht umgangen; bei fehlender Erlaubnis die Systemfreigabe bestätigen. Ohne verbundenes iPad liefert `start preview` einen Fehler.

### Displays

```applescript
tell application "PresentInk"
    set displaysJSON to list displays
    select display 1
    -- Wenn tatsächlich vorhandene Striche beim Wechsel entfernt werden sollen:
    -- select display 2 clearing annotations true
end tell
```

Der Index gilt für die aktuelle Displayliste, nicht als dauerhaft gespeicherte Geräte-ID. Ein Displaywechsel pausiert die Vorschau und setzt die Zeichenebene zurück. Das erneute Wählen desselben Displays ist ohne Reset möglich.

### Präsentation beenden

```applescript
tell application "PresentInk"
    stop preview
    stop connection
    set drawing enabled to false
    hide annotations
    hide drawer
end tell
```

`quit` beendet die gesamte App. Das reine Ausblenden von Annotationen oder Drawer stoppt keine Bildschirmübertragung. Dafür ausdrücklich `stop preview`, `stop connection` oder `quit` verwenden.

## Alle AppleScript-Befehle

Alle Befehle geben aktuellen JSON-Status zurück; `list displays` gibt stattdessen die Displayliste zurück. `quit` kündigt das Ende an und beendet die App nach dem Antworten.

| Bereich | Befehle |
|---|---|
| Eingabe | `enable drawing`, `disable drawing`, `toggle drawing` |
| Annotationen | `show annotations`, `hide annotations`, `toggle annotations` |
| Drawer | `show drawer`, `compact drawer`, `hide drawer`, `toggle drawer`, `change drawer "expanded"` |
| Werkzeug | `select tool "pen"` |
| Farbe | `select color "rot"` oder `select color "#12A4EF"` |
| Stärke | `change stroke width 4.5` |
| Bearbeiten | `undo annotation`, `redo annotation`, `clear annotations` |
| Displays | `list displays`, `select display 1`, optional `clearing annotations true` |
| Verbindung | `start connection`, `stop connection`, `toggle connection` |
| Vorschau | `start preview`, `stop preview`, `toggle preview` |
| Notfall | `emergency hide` |
| App / Fenster | `show application`, `hide application`, `show settings`, `quit` |
| Hilfe / System | `show shortcuts`, `show about`, `open display settings`, `open capture settings` |
| Status | `read status` |
| Kopplung | `reset pairing confirmed true` – widerruft alle alten Schlüssel |

Hilfe-/Info-/Systembefehle öffnen Oberflächen; sie sind für interaktive Abläufe gedacht. Das Tastaturkürzel-Fenster wartet auf das Schließen seines Dialogs. Für vollständig unbeaufsichtigte Abläufe diese Befehle weglassen.

### Werte

- Werkzeuge: `pen`, `marker`, `line`, `arrow`, `rectangle`, `ellipse`, `eraser`. Deutsche Namen wie `stift`, `rechteck` und `radierer` werden ebenfalls akzeptiert.
- Farben: `red/rot`, `yellow/gelb`, `blue/blau`, `green/grün`, `white/weiß`, `graphite/graphit/black/schwarz` oder `#RRGGBB`.
- Stärke: endliche Zahl im Bereich 2–12. Ungültige Werte werden abgewiesen und nicht stillschweigend gekürzt.
- Drawer: `expanded`, `compact`, `hidden`; auch `ausgezogen`, `kompakt`, `versteckt`.

## AppleScript-Eigenschaften

Diese elf Eigenschaften stehen im Skripteditor unter **PresentInk Suite → application**. `set` und `get` sind AppleScript-Sprachbefehle und keine separaten Einträge des PresentInk-Wörterbuchs. Die Eigenschaftsnamen enthalten Leerzeichen; JSON-Schlüssel mit Unterstrichen sind keine AppleScript-Eigenschaften.

Diese Eigenschaften können mit `get` gelesen beziehungsweise mit `set … to …` gesetzt werden:

| Eigenschaft | Typ | Zugriff |
|---|---|---|
| `status` | JSON-Text | Lesen |
| `available displays` | JSON-Text | Lesen |
| `drawing enabled` | Boolean | Lesen / Schreiben |
| `annotations visible` | Boolean | Lesen / Schreiben |
| `drawer state` | Text | Lesen / Schreiben |
| `current tool` | Text | Lesen / Schreiben |
| `ink color` | Text; beim Lesen normalisiertes Hex | Lesen / Schreiben |
| `stroke width` | Real | Lesen / Schreiben |
| `display index` | Integer ab 1 | Lesen / Schreiben; bei vorhandenen Strichen ohne Löschfreigabe Fehler |
| `connection enabled` | Boolean | Lesen / Schreiben; Host läuft, nicht zwingend ein iPad verbunden |
| `preview enabled` | Boolean | Lesen / Schreiben; angeforderter Start/Live-Zustand |

## JSON-Status und Fehler

Der Status enthält unter anderem:

```json
{
  "api_version": 1,
  "drawing_enabled": false,
  "annotations_visible": true,
  "drawer_state": "compact",
  "tool": "pen",
  "color": "#FF3847",
  "stroke_width": 4,
  "display_index": 1,
  "connection_enabled": false,
  "ipad_connected": false,
  "preview_enabled": false,
  "preview_state": "paused",
  "stroke_count": 0,
  "can_undo": false,
  "can_redo": false,
  "last_error": null
}
```

Zusätzlich werden Displayname, App-Sichtbarkeit, laufender Strich, Verbindungstext und Vorschau-Details geliefert. Kopplungsschlüssel und Bildschirminhalte sind keine Statusfelder.

| Fehlernummer | Bedeutung |
|---|---|
| `-1700` | Ungültiger Wert, etwa Stärke 42 oder Displayindex 0 |
| `-2700` | Aktion gerade nicht möglich: kein iPad, kein Undo-Schritt oder aktiver Strich |
| `-128` | Eine ausdrücklich erforderliche Bestätigung fehlt |
| `-1712` | App noch nicht bereit; Start abwarten und erneut versuchen |

```applescript
try
    tell application "PresentInk" to change stroke width 42
on error messageText number errorCode
    return {errorCode, messageText}
end try
```

## Prüfstand

Der Mac-Build enthält das Wörterbuch und extrahierte Metadaten für 16 native App-Intents sowie acht vorkonfigurierte App-Kurzbefehle. Echte AppleScript-Laufzeittests prüfen Eigenschaften, Werkzeug/Farbe/Stärke, Drawer/Overlay/Zeichenmodus, Wiederherstellung des Ausgangszustands sowie Fehler bei falschen Werten und fehlendem iPad. Die reinen Validierungs- und Zeichenmodelltests laufen als Swift-Package-Tests.

Eine komplette persönliche Kurzbefehle-Automation wurde nicht in die Bibliothek des Nutzers angelegt; die Aktionen werden von der App bereitgestellt und können dort frei kombiniert werden.

## Apple-Referenzen

- [App Intents – Einstieg](https://developer.apple.com/documentation/appintents/getting-started-with-the-app-intents-framework)
- [App Shortcuts implementieren](https://developer.apple.com/videos/play/wwdc2022/10170/)
- [Cocoa Scripting / NSScriptSuiteRegistry](https://developer.apple.com/documentation/foundation/nsscriptsuiteregistry)
- [NSScriptCommand](https://developer.apple.com/documentation/foundation/nsscriptcommand)

## Vollständig unsichtbarer Mac-Drawer (ab 0.6)

Die Aktion **PresentInk-Drawer einstellen** bietet jetzt **Vollständig ausgeblendet**. Per AppleScript:

```applescript
tell application "PresentInk"
    set drawer state to "invisible"
    -- Wieder öffnen: set drawer state to "expanded"
end tell
```

Alternativ `change drawer "invisible"`. Die Werte `expanded`, `compact` und `hidden` bleiben erhalten; `hidden` bedeutet auf den sichtbaren Griff minimiert. `drawer_state` liefert den zusätzlichen Wert `invisible`. `mac_drawer_visible` ist dann false; `mac_drawer_window_visible` zeigt die tatsächliche AppKit-Fenstersichtbarkeit (nach Verarbeitung der UI-Aktualisierung). ⌃⌥W öffnet den vollständig ausgeblendeten Drawer wieder.

Der Schalter **Mac-Drawer** im verbundenen iPad-Client wird vom Mac-Zustand aktualisiert, auch nach Änderungen über Automation. Ausblenden verändert weder Zeichenmodus noch Annotationen oder Vorschau.

## Zentrale Zeichen-Einstellungen und Freigabe (Mac 0.7 / Companion 0.5)

Alle Änderungen laufen über den Mac, werden validiert, dauerhaft gespeichert und an das verbundene iPad übertragen. Der Status enthält zusätzlich `opacity` (0.05–1), `width_minimum`, `width_maximum`, `active_profile`, `drawing_settings_revision` und `drawing_settings_synced`. Letzteres wird erst true, wenn das iPad den aktuellen Einstellungsstand bestätigt hat.

Neue native Aktionen:

| Aktion | Zweck |
|---|---|
| PresentInk-Profil auswählen | Namen eines gespeicherten Profils anwenden |
| PresentInk-Deckkraft setzen | 5–100 Prozent für das aktive Werkzeug |
| PresentInk-Zeichen-Einstellungen lesen | Einstellungsobjekt mit Palette, Werkzeugstilen, Druckoptionen und Profilinformationen |
| PresentInk-Zeichen-Einstellungen anwenden | Einstellungsobjekt aus der Lesen-Aktion übernehmen; keine Freigaberechte |
| PresentInk-Freigabe merken | PresentInk-Zustimmung der aktuellen Kopplung und separaten Autostart konfigurieren |

```applescript
tell application "PresentInk"
    select profile "Dunkle Folien"
    select tool "marker"
    change stroke width 20
    change ink opacity 0.4
    set configurationJSON to read drawing settings
    show preferences
end tell
```

`change ink opacity` verwendet den Faktor 0.05–1; die native Deckkraft-Aktion verwendet 5–100 Prozent. Breiten sind logische Mac-Punkte und werden gegen die **aktuell eingestellten Werkzeuggrenzen** validiert. Der Marker besitzt einen eigenen Bereich; der alte allgemeine Bereich 2–12 gilt nicht mehr für alle Werkzeuge.

Für vollständige Konfiguration `read drawing settings` lesen, das enthaltene `current`-Objekt bearbeiten und mit `apply drawing settings` als JSON-Text übergeben. Darin stehen `tool`, `palette` (RGB-Objekte mit `r`,`g`,`b` von 0–1, ein bis acht Farben), `visibleTools`, `styles`, `pressureEnabled` und `pressureSensitivity`. Jeder Style enthält `tool`, `color`, `width`, `minimum`, `maximum`, drei `quickWidths` und `opacity`. Alle acht Werkzeuge benötigen einen Style; der Radierer bleibt ein Ganzstrich-Radierer. Sichtbare Werkzeuge müssen eindeutig und mindestens eines sein. Profile ändern keine Freigaberechte.

Während eines aktiven Strichs werden Änderungen abgewiesen. Striche speichern ihre ursprünglichen Darstellungswerte und ändern sich nach einem Profilwechsel nicht. Menü-/Drawer- und Automationsänderungen verwenden denselben persistierten Zustand.

### PresentInk-Zustimmung merken

Die Host-Verbindung muss laufen. Das folgende Beispiel ist eine ausdrückliche Entscheidung, Vorschau-Anfragen der aktuellen Kopplung künftig ohne PresentInk-Dialog zu erlauben; es schaltet keinen automatischen Start ein:

```applescript
tell application "PresentInk"
    start connection
    configure sharing "{\"trusted\":true,\"autoStart\":false}"
end tell
```

`autoStart:true` erfordert zugleich `trusted:true`. Eine bewusste Pause bleibt über Neustarts wirksam, bis ausdrücklich gestartet/angefordert wird. `preview_trusted` und `preview_auto_start` stehen im Status. Kopplungswechsel widerruft das Vertrauen. Die Einstellung gilt für den gemeinsam verwendeten Kopplungsschlüssel; keine getrennte individuelle iPad-Autorisierung. macOS-Bildschirmaufnahmeberechtigung und Systemnachfragen werden dadurch nicht umgangen.

## Text einfügen (Mac 0.8 / Companion 0.6)

```applescript
tell application "PresentInk"
    insert text "Meine Beschriftung" at x 0.1 at y 0.2
end tell
```

Position ist auf das Zieldisplay normalisiert: x/y von 0 bis 1, beide standardmäßig 0.1. Die native Aktion **PresentInk-Text einfügen** verwendet 0–100 Prozent. Textstil (Schriftgröße/Farbe/Deckkraft) kommt aus den Mac-Einstellungen für das Werkzeug `text`. Einfügen stellt das aktive Werkzeug nicht um. Alternativ `select tool "text"` und die bestehende Breiten-/Deckkraft-Aktion für den Textstil verwenden.

Text ist auf 2000 Zeichen/20 eingegebene Zeilen begrenzt und unterstützt Undo/Redo sowie Ganzobjekt-Radieren. `read drawing settings` enthält ab jetzt acht Werkzeugstile; alte vollständige Konfigurationen werden automatisch um Text ergänzt. Während aktiver Striche oder nach einem Displaywechsel kann ein Textauftrag abgewiesen werden.

Der Status `preview_public_windows` zählt die explizit im Vorschaufilter enthaltenen öffentlichen PresentInk-Fenster. Einstellungen/Hilfe/Tastenkürzel sind erlaubt, Overlay/Drawer/Kopplungsfenster und unbekannte Fenster bleiben ausgeschlossen. Neu geöffnete erlaubte Fenster werden automatisch ergänzt.


## Ausführung und Entwicklung ab 0.9

Die native Kurzbefehle-Erweiterung läuft getrennt von der Mac-Oberfläche. Sie prüft, ob genau eine Mac-App läuft, und übergibt Anfragen über eine authentifizierte TLS-Verbindung ausschließlich auf dem lokalen Rechner. Der pro App-Start erneuerte Verbindungsschlüssel liegt in einer gemeinsamen Data-Protection-Schlüsselbundgruppe; er ist vom iPad-Kopplungsschlüssel getrennt. Zum Bauen müssen Mac-App und Erweiterung mit demselben Team und passenden Provisionierungsprofilen signiert sein. Die Erweiterung startet die Mac-App nicht automatisch.

Die Aktion zum Anwenden der Zeichen-Einstellungen erwartet das native Einstellungsobjekt der Lesen-Aktion. JSON bleibt ausschließlich die AppleScript-Schnittstelle. Deckkraft und Druckempfindlichkeit werden in Kurzbefehlen als Prozentwerte ausgegeben.
