# PresentInk selbst bauen, anpassen und teilen

Alle folgenden Terminal-Befehle werden im **Projektordner PresentInk** ausgeführt. Dort liegen `PresentInk.xcodeproj`, `Apps`, `Packages` und `Tools`. Wenn du gerade im Ordner `Tools` bist, zunächst `cd ..` ausführen.

## 1. Vorbereitung

- Xcode mit macOS-27- und iPadOS-27-SDK installieren. Die passende Plattform bei Bedarf in Xcode nachladen.
- `PresentInk.xcodeproj` öffnen.
- Für Mac-App und echtes iPad in „Signing & Capabilities“ dein Entwicklungsteam auswählen. Die Mac-App und ihre Kurzbefehle-Erweiterung müssen mit demselben Team signiert werden. Die automatische Signierung verwenden.
- Bei einem geteilten ZIP ist die Team-ID absichtlich leer. Der Empfänger trägt sein eigenes Team ein.
- Python 3 wird für Hilfe und ZIP-Erstellung benötigt.

## 2. In Xcode bauen und starten

| Was möchtest du starten? | Schema links oben | Zielgerät rechts daneben |
|---|---|---|
| Mac-App | `PresentInkMac` | My Mac / Mein Mac |
| iPad-App auf deinem Gerät | `PresentInkCompanion` | Dein angeschlossenes iPad |
| iPad-App im Simulator | `PresentInkCompanion` | Ein installierter iPad-Simulator |

Dann **⌘R** drücken. Für ein echtes iPad muss das Gerät für Entwicklung eingerichtet sein; die notwendigen Hinweise zeigt Xcode an.

**„Mismatched platform“:** Zuerst das Schema links neben dem Gerätenamen ändern. `PresentInkMac` baut `PresentInk.app` für macOS und kann nicht auf einem iPad gestartet werden. Dafür `PresentInkCompanion` wählen. Die unterstützten Plattformen der Mac-App deshalb nicht ändern.

## 3. Mit dem Build-Skript bauen

```sh
./Tools/build.sh mac
./Tools/build.sh ipad
./Tools/build.sh simulator
```

Ohne Argument baut das Skript die Mac-App. Es baut nur; es installiert, startet oder ersetzt keine laufende App.

| Modus | Ergebnisordner |
|---|---|
| `mac` | `build/mac/Build/Products/Debug/PresentInk.app` |
| `ipad` | `build/ipad/Build/Products/Debug-iphoneos/PresentInk Companion.app` |
| `simulator` | `build/simulator/Build/Products/Debug-iphonesimulator/PresentInk Companion.app` |

Optional Team und Build-Konfiguration vorgeben:

```sh
DEVELOPMENT_TEAM=DEINE_TEAM_ID ./Tools/build.sh mac
CONFIGURATION=Release ./Tools/build.sh mac
```

Bei Release steht im Ergebnisordner entsprechend `Release` statt `Debug`. Ein Release-Build ist noch keine notarisiert verteilbare App und kein App-Store-Upload. Das ZIP-Skript weiter unten erstellt ein Quellcode-Archiv, kein ausführbares Installationspaket und kein Xcode-`.xcarchive`.

Falls Signierungsprofile fehlen, zuerst in Xcode das Team und die automatische Signierung einrichten und dort bauen. Für den Simulator deaktiviert das Skript die Signierung automatisch. Für die gemeinsame Schlüsselbundgruppe der Mac-App und Kurzbefehle-Erweiterung sind passende Signaturen erforderlich.

## 4. Welche Dateien bearbeite ich für eigene Anpassungen?

Dateipfade beziehen sich auf den Projektordner. Swift-Dateien am besten in Xcode bearbeiten.

| Anpassung | Einstieg |
|---|---|
| Mac-Drawer, Schaltflächen, Anordnung | `Apps/macOS/MacToolDrawer.swift` |
| Mac-Menüs und Tastaturkürzel | `Apps/macOS/MacMenus.swift`; globale Kürzel außerdem in `MacAppDelegate.swift` prüfen |
| Mac-Einstellungsfenster | `Apps/macOS/MacDrawingSettingsView.swift` |
| Mac-Zeichenfläche und Eingabe | `Apps/macOS/MacCanvasView.swift` |
| Text-Eingabefenster am Mac | `Apps/macOS/MacTextEntry.swift` |
| Zentraler Mac-Zustand und Steuerung | `Apps/macOS/MacSession.swift` |
| iPad-Drawer und Werkzeuge | `Apps/iPadOS/ToolDrawerView.swift` |
| iPad-Hauptansicht und Verbindungseinrichtung | `Apps/iPadOS/CompanionView.swift`, `CompanionModel.swift` |
| Pencil-/Touch-Verarbeitung | `Apps/iPadOS/PencilCanvasView.swift` |
| Werkzeugmodell, Farben, Breiten und Standardwerte | `Packages/PresentInkCore/Sources/PresentInkCore/InkModel.swift`, `DrawingSettings.swift` |
| Geometrie und Zeichenobjekte, Undo/Redo | `InkGeometry.swift`, `InkDocument.swift` im selben Core-Ordner |
| Textlayout | `InkTextLayout.swift` im Core-Ordner |
| Bildschirmvorschau vom Mac | `Apps/macOS/ScreenPreviewService.swift` |
| Verbindung und Nachrichten | `Apps/macOS/CompanionServer.swift`, `Apps/iPadOS/CompanionModel.swift`, `Packages/PresentInkLink/Sources/PresentInkLink/WireMessage.swift` |
| Native Kurzbefehle und deren Ausgabefelder | `Apps/macOS/PresentInkIntents.swift`, `ShortcutEntities.swift`; Ausführung in `ShortcutAutomation.swift` und `MacAutomation.swift` |
| AppleScript-Befehle | `Apps/macOS/PresentInk.sdef`, `AppleScriptSupport.swift`, `MacAutomation.swift` |
| App-Icons | `Apps/macOS/Assets.xcassets/AppIcon.appiconset` und `Apps/iPadOS/Assets.xcassets/AppIcon.appiconset` |
| Anleitung in der App | `Docs/Anleitung.md`, danach Hilfe neu erzeugen, siehe unten |

Für eine reine Änderung am Drawer brauchst du normalerweise nur die entsprechende Ansichtsdatei. Bei einem neuen Werkzeug müssen zusätzlich gemeinsames Modell, Darstellung, Eingaben, Einstellungen und gegebenenfalls Automation sowie beide Plattformen angepasst werden.

**Farben, Deckkraft und Breiten für deinen Alltag:** Zunächst die Einstellungen in der Mac-App verwenden. Diese Werte werden gespeichert und ans iPad übertragen. Änderungen an Standardwerten im Code überschreiben bereits gespeicherte Einstellungen nicht automatisch.

### Projektstruktur und eigene App-Identität

- Bestehende Swift-Datei ändern: speichern und neu bauen.
- Neue Datei hinzufügen: in Xcode dem richtigen Target zuordnen. Gemeinsam genutzte Paketdateien unter `Packages` ablegen.
- Build-Ergebnisse in `build` oder Xcodes DerivedData nicht bearbeiten; sie werden beim nächsten Build neu erzeugt.
- Die Projektdatei `PresentInk.xcodeproj/project.pbxproj` bevorzugt durch Xcode ändern lassen.
- Für Änderungen am bestehenden PresentInk Team-ID und Bundle-IDs beibehalten, damit gespeicherte Daten und Kopplungen weiter zugeordnet werden können.
- Für eine unabhängige eigene App Team, Bundle-IDs und Namen in Xcode anpassen. Dabei auch Kurzbefehle-Erweiterung, Schlüsselbundgruppen, Entitlements und die Suche nach der Mac-Bundle-ID in `ShortcutAutomation.swift` konsistent ändern. Eine Suche nach `de.presentink` hilft, die Verweise zu finden. Eine neue App-Identität kann neue Systemfreigaben und eine neue Kopplung erfordern.
- Bei Änderungen am Nachrichtenformat die Protokollversion und die Kompatibilitätsprüfung beachten; anschließend Mac und iPad gemeinsam aktualisieren.

## 5. Nach einer Anpassung prüfen

1. Vor Änderungen einen Git-Commit oder eine Sicherung anlegen.
2. Die betroffene App bauen und die geänderte Funktion ausprobieren.
3. Bei gemeinsamem Code oder Verbindungsthemen beide Apps bauen und zusammen prüfen.
4. Bei Änderungen am Zeichenmodell, an Validierung oder Verbindung die Pakettests ausführen:

```sh
swift test --package-path Packages/PresentInkCore
swift test --package-path Packages/PresentInkLink
```

5. Bei Änderungen an der Anleitung das HTML neu erzeugen und anschließend die Mac-App neu bauen:

```sh
python3 Tools/render_help.py
```

6. Funktionsänderungen in `README.md` und `Docs/Anleitung.md` beschreiben. Neue Prüfungen gegebenenfalls in `Docs/Acceptance.md` ergänzen. In `BUILD-STATUS.md` nur tatsächlich durchgeführte Prüfungen dokumentieren.
7. Für eine neue veröffentlichte Version die Versions-/Buildnummern der betroffenen Targets in Xcode und gegebenenfalls den zugehörigen Info.plist-Dateien konsistent aktualisieren. Mac-App und eingebettete Kurzbefehle-Erweiterung gemeinsam versionieren.
8. Vor dem Ersetzen oder Beenden einer laufenden App vorhandene Annotationen sichern bzw. bewusst abschließen: Die aktuelle Zeichenfläche wird beim Beenden nicht dauerhaft gespeichert.

## 6. Teilbares Projektarchiv erstellen

```sh
python3 Tools/archive.py
```

Das Ergebnis liegt **neben** dem Projektordner: `PresentInk-Mac-iPad-Xcode.zip`. Ein bestehendes ZIP an diesem Ziel wird ersetzt. Alternativer Speicherort:

```sh
python3 Tools/archive.py --output /tmp/PresentInk-meine-Version.zip
```

Das Skript nimmt ausgewählte Quellcode-, Dokumentations- und Design-Dateien auf. Build-Ergebnisse, persönliche Xcode-Daten, Profile, Zertifikate und Schlüsselbunddateien werden nicht aufgenommen. Die Team-ID wird nur in der archivierten Projektdatei entfernt; dein lokales Projekt bleibt unverändert.

**Vor dem Teilen:** Neu hinzugefügte Dateien auf persönliche Inhalte, Passwörter und fest eingetragene Schlüssel prüfen. Das Skript ist kein vollständiger Geheimnis-Scanner. Bei neuen Quellcodeordnern oder Dateitypen die Listen `roots` und `allowed` in `Tools/archive.py` ergänzen; keine Build- oder Schlüsseldateien freigeben.

## Skripte im Überblick

| Datei | Zweck |
|---|---|
| `build.sh` | Mac, echtes iPad oder Simulator bauen |
| `archive.py` | Teilbares Quellcode-ZIP ohne Team-ID erstellen |
| `render_help.py` | Offline-HTML aus `Docs/Anleitung.md` erzeugen |
