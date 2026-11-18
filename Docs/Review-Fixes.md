# Korrekturen aus dem Code Review

Stand: 14. November 2026 · Mac 0.9.2 (11), Companion 0.7.1 (8)

| Befund | Änderung |
|---|---|
| 1. Share-ZIP unvollständig | `SharedUI` aufgenommen; Archivskript bricht bei fehlenden direkt referenzierten Xcode-Eingabedateien ab. |
| 2. Zeichenverlust bei Displayänderungen | Unverändertes Display lässt Dokument und Vorschau bestehen. Geänderte Geometrie erhält normalisierte Zeichnungen und Undo/Redo; laufender Strich wird beendet, alte Eingaben durch neue Epoche abgewiesen. Automatisches Ersatzdisplay erhält die Zeichnungen. Bewusst bestätigter Zieldisplaywechsel über Menü/Automation setzt weiter zurück. |
| 3. Tastaturfokus | Keine direkten `resignKey`-Aufrufe mehr. AppKit gibt den Fokus beim kurzzeitigen Ausblenden des nicht aktivierenden Panels frei; sichtbare Annotationen werden anschließend ohne Key-Anforderung angezeigt. |
| 4. Halbtote Verbindung | Mac-Watchdog beendet Control-Peers ohne Lebenszeichen nach rund zwölf Sekunden. iPad versucht unerwartete Abbrüche bis zu 30 Sekunden erneut; spätere Bonjour-Wiederentdeckung bleibt erlaubt. Manuelles Trennen/Suspendieren unterbindet Wiederverbindung. |
| 5. Sleep/Sperren | Verbindung wird aus Datenschutzgründen weiterhin gestoppt, ihr vorheriger Einschaltzustand aber gemerkt. Bei Rückkehr zur aktiven Sitzung bzw. Aufwecken eines aktiven Displays startet der zuvor eingeschaltete Server erneut. Ein manuell ausgeschalteter Server wird nicht eingeschaltet. |
| 6. Kopplungsschlüssel | Nichtleere neue Eingabe hat Vorrang vor gespeichertem Schlüssel. Nur erfolgreiche Kopplung speichert den neuen Schlüssel. |
| 7. Vorschau-Pause | Vertrauensentzug und Ablehnen der Freigabe stoppen die Vorschau, setzen aber nicht länger das persistierte Flag einer bewussten Pause. Eine tatsächlich bewusst gesetzte Pause bleibt erhalten. |
| 8. Profil | Unveränderte Auswahl ist ohne Schreib-/Sync-Vorgang. Reiner Werkzeugwechsel behält den Profilnamen; geänderte Stilwerte kennzeichnen die Einstellungen als individuell. Werkzeugauswahl selbst bleibt gespeichert und synchronisiert. |
| 9. Snapshot-Last | Radierer ohne Treffer erzeugt keine Revision und keine Übertragung. Dokumentstände werden am Mac auf maximal etwa zehn Übertragungsanfragen pro Sekunde gebündelt. SecurePeer hält höchstens einen Snapshot im Versand und einen neuesten ausstehenden Stand; Zwischenstände werden vor der JSON-Kodierung ersetzt. Aktive Strichvorschau läuft separat weiter. |
| 10. Vorschau-CPU | Überlastungsprüfung vor Render/JPEG-Kodierung; initiale Bildschirmabfrage wird für den Filter wiederverwendet. |

## Durchgeführte Prüfungen

- PresentInkCore: 34 Tests erfolgreich, darunter drei neue Regressionstests für Displaygeometrie, Undo/Redo und Radieren ohne Treffer.
- PresentInkLink: 19 Tests erfolgreich. Neuer authentifizierter TLS-Test sendet 121 Dokumentstände als Burst: nur erster und letzter Stand werden übertragen; letzter Stand kommt an.
- Mac und iPad erfolgreich aus frisch entpacktem Share-ZIP gebaut, ohne Signierung. Diese Builds sind reine Build-Prüfungen und keine installierbaren/signierten Auslieferungen.
- Zusätzlich signierter Mac-Build mit eingebetteter Kurzbefehle-Erweiterung erfolgreich.
- Laufende installierte App wurde weder beendet noch ersetzt. Es wurden keine Benutzerzeichnungen verändert.

## Noch manuell auf Hardware prüfen

1. In Keynote-Vollbild zeichnen, Zeichenmodus verlassen und ohne Mausklick mit Pfeiltasten weiterblättern; ebenfalls Esc, Bedienmodus, Notfall-Ausblenden und Space-Wechsel prüfen.
2. Mit Annotationen und Undo-Historie einen Beamer anstecken, Bildschirmposition/Auflösung ändern und das gewählte Display entfernen. Zeichnungen bleiben erhalten; neuer Displaymaßstab kann sie proportional umpositionieren. Alte iPad-Eingaben dürfen nicht nachträglich landen.
3. iPad-WLAN unterbrechen und wiederherstellen; anschließend längere Unterbrechung mit Bonjour-Wiederentdeckung. Manuelles Trennen darf nicht automatisch rückgängig gemacht werden.
4. Mac sperren, entsperren und Display schlafen lassen/aufwecken. Keine Übertragung während inaktiver Sitzung; zuvor ausgeschalteter Server bleibt aus.
5. Kopplung am Mac zurücksetzen und am gemerkten iPad-Mac neuen Schlüssel eingeben, ohne „Vergessen“ zu benötigen.
6. Vertrauen deaktivieren und wieder aktivieren, Autostart einschalten; von bewusst gesetzter Vorschau-Pause unterscheiden.
7. Profil anwenden, Werkzeuge wechseln, dann Farbe/Breite ändern; Status und iPad müssen konsistent sein.
8. Große Zeichnung mit vielen Punkten radieren und Main-Thread-Zeit, Speicher und Verbindung beobachten. Der automatisierte Burst-Test misst keine Ende-zu-Ende-Leistung großer Dokumente.

Die Änderungen begrenzen die größten vermeidbaren Lasten; ein Delta-Protokoll ist damit noch nicht implementiert. Persistentes Speichern der Zeichensitzung bleibt eine separate, noch offene Funktion.


## Ergänzung: Keynote

Mac 0.9.2 ordnet die Panels über Keynotes tatsächlicher Präsentations-Fensterebene an. Der Nutzer hat sichtbare iPad-Annotationen, Maus-/Trackpad-Zeichnen, Werkzeugwahl und ⌃⌥A bestätigt. Die übrigen Fokus-/Display-Kombinationen der obigen Abnahme bleiben offen.
