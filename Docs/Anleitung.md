# PresentInk – Bedienungsanleitung

Version: Mac und iPad Companion 0.9.2 · Build 18. Diese Anleitung beschreibt den aktuellen Prototyp für macOS 27 und iPadOS 27. Sie ist vollständig offline unter **Hilfe → PresentInk-Anleitung** verfügbar. Links wählen Sie ein Kapitel aus; rechts wird nur der zugehörige Abschnitt angezeigt. Beide Bereiche sind unabhängig scrollbar. Die Markdown-Quelldatei liegt im Projekt unter `Docs/Anleitung.md` und im Mac-App-Bundle.

## Inhalt

- [Schnellstart am Mac](#schnellstart-am-mac)
- [Zeichnen und Bedienen](#zeichnen-und-bedienen)
- [Drawer und Werkzeuge](#drawer-und-werkzeuge)
- [Objekte direkt bearbeiten](#objekte-direkt-bearbeiten)
- [Text einfügen](#text-einfugen)
- [Annotationen direkt leeren](#annotationen-direkt-leeren)
- [Farben und Strichstärken](#farben-und-strichstarken)
- [Zentrale Einstellungen und Profile](#zentrale-einstellungen-und-profile)
- [Tastaturkürzel](#tastaturkurzel)
- [Vollbild, Spaces und mehrere Displays](#vollbild-spaces-und-mehrere-displays)
- [iPad mit dem Mac verbinden](#ipad-mit-dem-mac-verbinden)
- [Bildschirmvorschau auf dem iPad](#bildschirmvorschau-auf-dem-ipad)
- [Apple Pencil und iPad-Drawer](#apple-pencil-und-ipad-drawer)
- [Folien vom iPad steuern](#folien-vom-ipad-steuern)
- [Sidecar als Alternative](#sidecar-als-alternative)
- [Apple Kurzbefehle und AppleScript](#apple-kurzbefehle-und-applescript)
- [Datenschutz und Berechtigungen](#datenschutz-und-berechtigungen)
- [Probleme lösen](#probleme-losen)
- [Eine Präsentation vorbereiten und beenden](#eine-prasentation-vorbereiten-und-beenden)
- [Aktuelle Grenzen](#aktuelle-grenzen)

## Schnellstart am Mac

1. **PresentInk** aus dem Programme-Ordner starten. Bei mehreren Xcode-Kopien darauf achten, welche Version läuft.
2. Unter **Darstellung → Zieldisplay** den Bildschirm mit der Präsentation auswählen.
3. Die gewünschte Präsentation öffnen, bei Bedarf in den Vollbildmodus wechseln.
4. Mit **⌃⌥A** den Zeichenmodus einschalten. Mit Maus oder gedrücktem Trackpad zeichnen.
5. **P** wählt den Stift, **H** den Marker, **R** das Rechteck, **O** die Ellipse. Einzeltasten gelten nur, solange die Zeichenfläche Tastaturfokus hat.
6. Mit **Escape**, **V** oder erneut **⌃⌥A** zum Bedienen der Präsentation zurückkehren.
7. **⌃⌥W** versteckt den Drawer bis auf seinen Griff. Die Annotationen bleiben sichtbar.

**Notfall:** Mit **⌃⌥Escape** werden Annotationen ausgeblendet und die Mauseingabe freigegeben. Eine laufende iPad-Bildschirmübertragung wird damit nicht beendet. Dafür **Verbindung → Bildschirmvorschau pausieren** oder **iPad-Verbindung stoppen** verwenden.

Die Zeichenebene ist transparent. Im Bedienmodus klicken und scrollen Sie durch sie hindurch in der darunterliegenden App. Ihre Markierungen bleiben über dem Bildschirm sichtbar.

## Zeichnen und Bedienen

### Bedienmodus

PresentInk fängt keine Mausereignisse auf der Zeichenfläche ab. Sie können Folien wechseln, Fenster bedienen und Anwendungen verwenden. Der Drawer bleibt anklickbar. Annotationen vom verbundenen iPad erscheinen auch in diesem Modus auf dem Mac.

### Zeichenmodus

Die Zeichenfläche nimmt Maus-/Trackpad-Eingaben an. Ziehen mit gedrückter Taste erzeugt einen Strich oder eine Form. Die darunterliegende App erhält diese Zeigereingaben nicht. Das Auswählen eines Werkzeugs im Mac-Drawer schaltet den Zeichenmodus ein.

Das Overlay ist ein nicht aktivierendes Panel: Es kann Tastaturfokus zum Zeichnen übernehmen, während die Präsentations-App aktiv bleibt. Dadurch soll ein fremder Vollbild-Space beim Einschalten nicht verlassen werden. Die drei globalen Kürzel funktionieren unabhängig vom aktiven Menü.

Beim Verlust des Zeichenfokus, beim Space-Wechsel oder beim Wechsel des Zieldisplays wird lokales Zeichnen beendet. Beim bloßen Space-Wechsel bleiben Zeichnungen und Vorschau erhalten. Nach dem Wechsel bei Bedarf **⌃⌥A** erneut drücken.

### Sichtbarkeit und Inhalt

**Darstellung → Annotationen ausblenden** versteckt nur die Zeichenebene und beendet das lokale Zeichnen. Beim Wiederanzeigen sind die Striche noch vorhanden. **Alle Annotationen löschen** entfernt dagegen den Inhalt; solange der Dokumentzustand erhalten bleibt, lässt sich das Löschen rückgängig machen.

Annotationen sind an Bildschirmpositionen gebunden. Die PresentInk-Folienpfeile wechseln die Folie und leeren anschließend die Annotationen. Bei einem Wechsel direkt in Keynote/PowerPoint oder mit deren eigenen Tastenkürzeln erkennt PresentInk den Wechsel nicht automatisch; dafür steht die Leeren-Taste in beiden Drawern bereit.

## Drawer und Werkzeuge

Der Mac-Drawer schwebt unten auf dem ausgewählten Display und passt seine Breite an die sichtbaren Werkzeuge und Farben an. Seine seitlichen Innenränder betragen 16 Punkte; die äußeren Buttons sind gleich breit. Auf dem iPad folgt der Drawer seiner tatsächlichen Inhaltsbreite mit 8 Punkten Seitenrand; die Buttons behalten ihre Größe. Tooltips zeigen beim Verweilen mit der Maus Funktion und Tastenkürzel; Menükürzel sind als solche gekennzeichnet. Die vier Zustände sind ausgezogen, kompakt, auf den Griff minimiert und vollständig ausgeblendet. Der Abwärtspfeil oben minimiert den Drawer; der Aufwärtspfeil öffnet ihn wieder. Die frühere waagerechte Griffmarkierung entfällt. Das X-Symbol blendet den Drawer einschließlich Griff vollständig aus. Am Mac steht das Auge-Symbol rechts neben den Größen und vor dem X. Es schaltet auf Mac und iPad **Annotationen ausblenden / Annotationen zeigen**; es verändert den Drawer nicht. Auch **Darstellung → Mac-Drawer vollständig ausblenden** ist verfügbar. **⌃⌥W** öffnet auch einen vollständig ausgeblendeten Drawer wieder; bei sichtbarem Drawer minimiert das Kürzel auf den Griff; **⇧⌘D** wechselt bei sichtbarem Drawer zwischen kompakt und ausgezogen.

Der Schalter **Mac-Drawer** oben in der iPad-App steuert ausschließlich den Mac-Drawer: Aus bedeutet vollständig unsichtbar, Ein öffnet ihn ausgezogen. Er ist nur bei bestehender Verbindung und empfangenem Mac-Status bedienbar. Derselbe Schalter steht im Mehr-Menü des iPad-Drawers. Änderungen am Mac und per Automation werden zum iPad zurückgemeldet. Der iPad-Drawer und die Annotationen bleiben dabei unverändert.

Werkzeuge, Farben und Strichstärken sind direkt erreichbar. Weitere Funktionen liegen in den Menüs **Bearbeiten**, **Werkzeuge**, **Darstellung** und **Verbindung**. Über das PresentInk-Symbol in der Menüleiste erreichen Sie zentrale Funktionen auch aus anderen Apps.

| Werkzeug | Bedienung | Mit Shift beim Ziehen |
|---|---|---|
| Stift | Freihand zeichnen | Keine besondere Formbindung |
| Marker | Transparente Hervorhebung | Keine besondere Formbindung |
| Linie | Vom Startpunkt zum Endpunkt ziehen | Winkel in 45°-Schritten |
| Pfeil | Vom Anfang zur Pfeilspitze ziehen | Winkel in 45°-Schritten |
| Rechteck | Zwischen zwei Ecken aufziehen | Quadrat |
| Ellipse | Begrenzungsrechteck aufziehen | Kreis |
| Radierer | Über vorhandene Striche oder Textobjekte ziehen | Keine besondere Formbindung |
| Text | Position anklicken/antippen, Beschriftung eingeben | Keine Formbindung |

Der Radierer entfernt ganze getroffene Striche oder Formen, keine einzelnen Pixel. Rückgängig/Wiederholen wirkt auf die gemeinsame Zeichenebene. Beim gleichzeitigen Zeichnen vom Mac und iPad werden Eingaben durch die Sitzung koordiniert; während eines aktiven Strichs sind konkurrierende Dokumentänderungen eingeschränkt.

## Objekte direkt bearbeiten

Im Zeichenmodus ein vorhandenes Objekt anfassen und ziehen. Es gibt keinen zusätzlichen Auswahlmodus und keine dauerhaften Auswahlrahmen. Bei überlappenden Objekten wird das oberste verwendet. Der Radierer radiert weiterhin. Das Textwerkzeug öffnet Text zur Eingabe; mit anderen Zeichenwerkzeugen lässt sich eine Beschriftung verschieben.

| Stelle beim Ziehen | Wirkung |
|---|---|
| Mitte einer Linie, eines Pfeils oder Freihandstrichs | Ganzes Objekt verschieben |
| Anfang oder Ende einer Linie/eines Pfeils | Das andere Ende bleibt fest; Länge und Richtung ändern |
| Anfang oder Ende eines Freihandstrichs | Gesamten Strich um das andere Ende drehen und strecken |
| Inneres von Rechteck oder Ellipse | Ganzes Objekt verschieben |
| Ecke des Begrenzungsrechtecks | Um die eigene Mitte drehen |
| Mitte einer Seitenkante | Diese Seite vergrößern/verkleinern; gegenüberliegende Seite bleibt fest |

Die Ecken einer Ellipse liegen an den gedachten Ecken ihres Begrenzungsrechtecks. Trefferzonen sind unsichtbar; am Mac gibt der Mauszeiger einen Hinweis. Kleine Formen behalten einen nutzbaren Bereich zum Verschieben.

**Shift am Mac** bzw. die immer sichtbare **Proportions-/Rastertaste auf dem iPad** erhält beim Verändern einer Kante das vorhandene Seitenverhältnis: Ellipse bleibt im gleichen Verhältnis, Kreis bleibt Kreis; entsprechend Rechteck und Quadrat. Beim Drehen oder Ziehen von Linienenden rastet die Richtung damit in 45-Grad-Schritten ein. Beim Neuzeichnen bindet die Taste Rechteck/Ellipse weiterhin zu Quadrat/Kreis.

Ein Klick ohne Ziehen verändert nichts. Eine abgeschlossene Ziehbewegung entspricht genau einem Rückgängig-Schritt. Änderungen werden live übertragen; unterbrochene Berührungen bzw. **Escape/Bedienen** am Mac verwerfen die laufende Änderung. Stil und Objektidentität bleiben erhalten. Der Mac sperrt gleichzeitige Bearbeitung und weist veraltete Änderungen ab. Bewegungen bleiben innerhalb der Zeichenfläche; unzulässige Größen- oder Drehschritte werden nicht übernommen.

Auf freier Fläche zeichnet das Werkzeug weiter. **Option gedrückt halten** erlaubt am Mac neue Striche über vorhandenen Objekten. Für Text innerhalb einer Form das Textwerkzeug verwenden. Beide Apps gemeinsam aktualisieren (Protokoll 9); Kopplungsschlüssel bleiben erhalten.

## Text einfügen

### Am Mac

1. **Text** im Drawer oder unter **Werkzeuge** wählen. Bei Zeichenfokus **T**, bei aktiver PresentInk-App **⌥⌘T** verwenden.
2. Auf die gewünschte Position im Zieldisplay klicken.
3. Direkt an dieser Stelle schreiben. **Return** erzeugt eine neue Zeile.
4. **⌘Return** drücken oder außerhalb des Textes klicken, um ihn zu übernehmen. **Escape** verwirft die Eingabe.

Die Eingabe bleibt direkt im Overlay über der Präsentation. Während der Texteingabe werden Buchstaben wie P oder T als Text verarbeitet. Mit dem Textwerkzeug einen vorhandenen Text anklicken oder doppelklicken, um ihn erneut zu bearbeiten. Außerhalb der Texteingabe gelten die bisherigen Werkzeugkürzel.

### Auf dem iPad

1. Das Textwerkzeug mit dem **T-Symbol** wählen.
2. Mit Finger oder Pencil auf die gewünschte Stelle der Zeichenfläche tippen. Pencil und Finger können Textpositionen ohne Umschalter setzen.
3. Direkt auf der Zeichenfläche über Bildschirm-/Hardwaretastatur oder die systemeigene Pencil-Handschrifteingabe schreiben. **Return** erzeugt eine neue Zeile; **Fertig** in der festen oberen Leiste oder **⌘Return** übernimmt den Text. Während der Texteingabe ist der Werkzeug-Drawer ausgeblendet. Die Zeichenfläche behält auch bei schwebender Tastatur ihre Größe; eine große Bildschirmtastatur kann den unteren Bereich überdecken. Ein Tippen außerhalb des Textes übernimmt die Eingabe, ohne sofort einen neuen Text zu öffnen. **Abbrechen/Escape** verwirft Änderungen. Mit dem Textwerkzeug vorhandenen Text antippen bzw. doppeltippen, um ihn zu bearbeiten.

Farbe, Schriftgröße und Deckkraft kommen vom Mac. Unter **Einstellungen → Werkzeug-Einstellungen → Text** sind sie änderbar. Die Breitenfelder bedeuten beim Text die Schriftgröße in logischen Mac-Punkten; Vorgabe 28 pt, Bereich 8–96 pt, Schnellgrößen 20/28/40 pt. Schrift ist Helvetica, mit System-Fallback für nicht enthaltene Zeichen. Bestehende Profile werden automatisch um Text ergänzt, ohne eigene Werte zu verlieren.

Text darf bis zu 2000 Zeichen und 20 eingegebene Zeilen umfassen. Automatischer Umbruch erfolgt am rechten Displayrand; sehr langer Text wird an der verfügbaren Displayhöhe abgeschnitten. Eine Platzierung direkt am Rand wird so versetzt, dass mindestens eine kurze Zeile Platz hat. Der gemeinsame Layout-Code sorgt für proportionale Darstellung auf dem iPad.

Beim Textwerkzeug zeigt die Schnellgrößenwahl im Mac- und iPad-Drawer unterschiedlich große **A** statt Strichstärken-Punkten. Die Buchstaben zeigen kleine, mittlere und große Schriftgrößen relativ zueinander; der gewählte Punktwert bleibt maßgeblich.

**Rückgängig/Wiederholen** und **Radierer** funktionieren auch für Textobjekte. Eine bestätigte Textänderung ist ein einzelner rückgängig machbarer Schritt; Position, Farbe und Größe bleiben erhalten. Leer gelassene Eingaben werden verworfen und löschen keinen vorhandenen Text. Mit Zeichenwerkzeugen lässt sich Text verschieben. Schriftfamilienwahl und Formatierung einzelner Wörter sind noch nicht enthalten. Während der Eingabe sieht nur das bearbeitende Gerät den Entwurf; der Text wird bei Bestätigung zum anderen Gerät übertragen. Gleichzeitige Änderungen desselben Texts werden abgewiesen, statt neuere Änderungen zu überschreiben. Für diese Funktion müssen beide Apps aktualisiert sein (Verbindungsprotokoll 9).

Über Automation: `insert text "Hallo" at x 0.1 at y 0.2` (normierte Position 0–1) oder die native Aktion **PresentInk-Text einfügen** mit Positionsangaben in Prozent. Der konfigurierte Textstil wird verwendet, ohne das aktive Werkzeug umzustellen.

## Annotationen direkt leeren

Das **Papierkorb-Symbol** ist auf Mac und iPad direkt im ausgezogenen und kompakten Drawer erreichbar. Ein Klick bzw. Tippen leert die bestätigten Annotationen ohne zusätzlichen Dialog. **Rückgängig** stellt sie wieder her. Während einer laufenden Zeichen-/Objektbewegung oder eines Folienwechsels ist die direkte Taste gesperrt; auf einer leeren Fläche ist sie deaktiviert. Die Einstellungen und der Folieninhalt werden nicht gelöscht.

Die Pfeile im Mac-Drawer verwenden dieselbe Kombination aus Folienwechsel und Leeren wie die iPad-Pfeile. Bei Zeichenfokus am Mac funktionieren auch die physischen Tasten **← / →**, solange kein Texteditor oder Strich aktiv ist. Im Bedienmodus gehen die Tasten unverändert an die Präsentations-App; dann erfolgt kein automatisches Leeren durch PresentInk.

Ein bestätigter Folienwechsel wird im Zeichenprotokoll abgegrenzt, sodass verspätete Eingaben der vorherigen Folie nicht wieder erscheinen. Rückgängig kann die vor dem Wechsel geleerten Annotationen bewusst wiederherstellen; es gibt weiterhin keine automatische Zeichnungsablage pro Folie.

## Farben und Strichstärken

Die vom Mac gespeicherte Palette enthält ein bis acht Farben. Reihenfolge und Farben gelten auf beiden Geräten; **⌘1–8** wählt die entsprechenden Plätze bei aktiver PresentInk-App. Ein Werkzeug merkt sich seine zuletzt gewählte Farbe und Breite separat.

Jedes zeichnende Werkzeug hat einen eigenen Breitenbereich innerhalb von **0,5 bis 100 pt**, eine Standardbreite und drei Schnellstärken. Stift und Formen starten mit 2–12 pt (Standard 4), der Marker mit 4–48 pt (Standard 16). Die Werte sind logische Punkte auf dem Mac-Zieldisplay. Das iPad zeigt die gleiche relative Breite in seiner proportionalen Vorschau. Die bisherigen Bildschirm-proportional gespeicherten Striche werden weiterhin unverändert dargestellt.

Die Marker-Deckkraft startet bei 30 %, andere Werkzeuge bei 100 %. **Deckkraft** bedeutet: 100 % deckend, 30 % gut durchscheinend. Der Wert kann pro Werkzeug auf 5–100 % eingestellt werden. Neue Einstellungen gelten nur für neue Striche. Ein bestehender Strich speichert Farbe, Breite, Deckkraft und Druckparameter unabhängig vom aktuellen Profil.

## Zentrale Einstellungen und Profile

**PresentInk → Einstellungen … (⌘,)** öffnet die zentrale Konfiguration. Das iPad übernimmt beim Verbinden automatisch den gültigen Mac-Zustand. Am iPad gewählte Werkzeuge, Farben und Breiten gehen als Änderungswunsch zum Mac; erst dessen Bestätigung aktualisiert den Zustand. Ohne Verbindung sind Änderungen nur Teil der lokalen Testfläche.

### Einstellungen bearbeiten

1. Am Mac **Einstellungen …** öffnen.
2. Farben bearbeiten, hinzufügen/entfernen und über die Pfeile umordnen (ein bis acht Einträge).
3. Unter **Werkzeug-Einstellungen** das zu bearbeitende Werkzeug wählen. Farbe, Deckkraft, Minimum, Maximum, Standardbreite und drei Schnellstärken festlegen.
4. Minimum und Maximum müssen verschieden sein. Standard und alle Schnellstärken müssen im Bereich liegen. Ungültige Einstellungen werden beim Speichern abgewiesen.
5. Pencil-Druck für den Stift ein-/ausschalten und seine Wirkung einstellen. Die gerenderte Stiftbreite bleibt immer innerhalb des Werkzeugbereichs.
6. Sichtbare Werkzeuge und deren Reihenfolge für beide Drawer einstellen. Mindestens ein Werkzeug bleibt sichtbar. Der Radierer entfernt weiterhin ganze Striche; seine Geometrie ist kein pixelweiser Pinsel.
7. **Sichern & anwenden** drücken. Die Einstellungen werden auf dem Mac dauerhaft gespeichert und an das verbundene iPad übertragen.

Während eines aktiven Strichs werden Einstellungsänderungen zurückgewiesen. Hat das iPad oder eine Automation während der Bearbeitung den Zustand geändert, fordert der Editor vor dem Speichern zum **Neu laden** auf. Dadurch werden Änderungen nicht unbemerkt überschrieben. **Neu laden** verwirft die ungespeicherten Editor-Änderungen.

### Profile

Die Vorlagen **Helle Folien**, **Dunkle Folien** und **Whiteboard** sind enthalten. Ein Profil speichert Zeichenparameter, Palette, Werkzeugreihenfolge und Pencil-Druck. In den Mac-Einstellungen ein Profil auswählen und **Anwenden** drücken. Auf dem iPad sind Profile oben über die Farbpaletten-Schaltfläche und im Mehr-Menü auswählbar.

Mit **Als Profil speichern** wird der aktuelle Editor-Entwurf unter dem eingegebenen Namen gespeichert. Ein gleicher Name ersetzt das vorhandene Profil. Bis zu zwölf Profile und Namen bis 40 Zeichen sind möglich. Schnelle Einzeländerungen werden als **Individuell** angezeigt; die gespeicherte Profilvorlage bleibt erhalten. Profile verändern keine Bildschirmfreigaberechte.

### Gemerkte Bildschirmfreigabe

Die Host-Verbindung muss gestartet sein. Bei der nächsten iPad-Anfrage **Freigeben & merken** wählen. Alternativ im Fenster **Verbindung & Freigabe** bzw. in den Einstellungen **Freigabe für die aktuelle Kopplung merken** einschalten. Künftige ausdrückliche Vorschau-Anfragen dieser Kopplung benötigen dann keine zusätzliche PresentInk-Rückfrage mehr.

**Vorschau nach dem Verbinden automatisch starten** ist eine separate, zunächst ausgeschaltete Option. Ein bewusstes **Vorschau pausieren** bleibt auch über Verbindungsabbrüche und Neustarts wirksam, bis die Vorschau ausdrücklich gestartet oder vom iPad neu angefordert wird. Eine gespeicherte Zustimmung allein startet keine Übertragung beim Verbinden.

Das Vertrauen ist an den Kopplungsschlüssel gebunden. Zurücksetzen/Wechsel des Schlüssels widerruft es. Da derzeit ein gemeinsamer Kopplungsschlüssel verwendet wird, gilt es für die aktuelle Kopplung und nicht für einen separat identifizierten iPad-Besitzer. Der jeweils ausgewählte Bildschirm ist die Vorschauquelle.

**macOS-Systemdialoge bleiben unabhängig davon.** PresentInk merkt seine eigene Zustimmung, erteilt aber keine macOS-Aufnahmeberechtigung und kann erneute Systemnachfragen nicht unterdrücken. Die beiden Freigabeschalter gelten sofort; sie sind unabhängig vom Knopf zum Speichern der Zeichenparameter.

## Tastaturkürzel

Die übersichtliche Referenz öffnen Sie unter **Hilfe → Tastaturkürzel …**. Sie ist ein nicht modales, scrollbares Fenster. Sie können sie offen lassen und schließen, ohne einen Dialog bestätigen zu müssen.

### Global – auch in anderen Apps und im Vollbild

| Aktion | Kürzel |
|---|---|
| Zeichnen / Bedienen | ⌃⌥A |
| Drawer zeigen / verstecken | ⌃⌥W |
| Notfall: Eingabe freigeben und Annotationen ausblenden | ⌃⌥Escape |

Wenn macOS die Registrierung eines globalen Kürzels ablehnt, zeigt PresentInk eine Meldung. Prüfen Sie dann, ob eine andere App dasselbe Kürzel verwendet. Die Menüs und der Drawer bleiben als Alternative erreichbar.

### Bei Tastaturfokus auf der Zeichenfläche

| Aktion | Taste |
|---|---|
| Stift / Marker | P / H |
| Linie / Pfeil | L / A |
| Rechteck / Ellipse / Radierer / Text | R / O / E / T |
| Bedienen | V / Escape |
| Quadrat / Kreis / 45°-Schritte | Shift während des Ziehens |

### Bei aktiver PresentInk-App

| Aktion | Kürzel |
|---|---|
| Werkzeuge Stift / Marker / Linie / Pfeil / Rechteck / Ellipse / Radierer | ⌥⌘P / H / L / A / R / O / E / T |
| Bedienmodus | ⌥⌘V |
| Palettenfarben 1–8 | ⌘1–8 |
| Breiter / schmaler | ⌘+ / ⌘− |
| Rückgängig / Wiederholen | ⌘Z / ⇧⌘Z |
| Alle Annotationen löschen | ⇧⌘⌫ |
| Drawer kompakt / ausgezogen | ⇧⌘D |
| Annotationen zeigen / verstecken | ⇧⌘H |
| Verbindung & Freigabe | ⌘I |
| Einstellungen | ⌘, |
| iPad-Verbindung starten / stoppen | ⇧⌘I |
| Vorschau starten / pausieren | ⇧⌘S |
| Kopplung zurücksetzen, mit Rückfrage | ⌥⌘⌫ |
| Zieldisplay 1–9 | ⌃⌘1–9 |
| Anleitung | ⌘? |
| Tastaturkürzel-Fenster | ⌥⌘? |
| PresentInk ausblenden / beenden | ⌘H / ⌘Q |

**Zeichenlegende:** ⌘ Befehl, ⌥ Option/Alt, ⌃ Control, ⇧ Umschalt, ⌫ Rückschritt. Im nicht aktivierenden Vollbild-Overlay kann weiterhin das Menü der Präsentations-App aktiv sein. Dort globale Kürzel, Einzeltasten bei Zeichenfokus, Drawer oder Automation verwenden; App-Menükürzel nicht blind an die Präsentations-App senden.

## Vollbild, Spaces und mehrere Displays

PresentInk legt seine Zeichenfläche und den Drawer über das ausgewählte Display. Beide dürfen anderen Anwendungen in Vollbild-Spaces und Stage Manager folgen. Die App benötigt dazu keine Bedienungshilfen-Freigabe. Ein Vollbildwechsel startet keine Bildschirmaufnahme.

1. Vor der Präsentation das richtige Zieldisplay auswählen.
2. Die Präsentation in Vollbild bringen und den Übergang abwarten.
3. Den Drawer mit **⌃⌥W** bei Bedarf anzeigen und mit **⌃⌥A** zeichnen.
4. Mit **Escape** zurück zur Präsentation wechseln, bevor Sie deren Tastaturbedienung verwenden.

Wenn Sie ein normales PresentInk-Fenster wie Anleitung oder Verbindung öffnen, wird PresentInk aktiviert. macOS kann dafür den Space wechseln. Das ist vom Zeichnen über dem Vollbild zu unterscheiden. Für ungestörtes Präsentieren diese Fenster vorher schließen und mit globalen Kürzeln/Drawer arbeiten.

Die App annotiert jeweils **ein** Zieldisplay. Die Anordnung der Bildschirme, Retina-Skalierung und negative Displaykoordinaten werden über AppKit berücksichtigt. Ein Space-Wechsel auf demselben Display löscht nichts. Ein Zieldisplaywechsel setzt die Zeichenebene zurück und pausiert die Vorschau; bei bestehenden Strichen fragt die Menüaktion vorher nach. Das An-/Abstecken oder Umkonfigurieren von Displays kann die Sitzung ebenfalls neu konfigurieren. Vorher wichtige Inhalte anderweitig sichern.

**Grenzen:** Geschützte Systemoberflächen, Sperrbildschirm und bestimmte exklusive Präsentations-/Videomodi können Overlays verhindern. DRM-geschützter Inhalt kann in der iPad-Vorschau schwarz bleiben. Diese Anleitung verspricht keine Darstellung über Sicherheitsdialogen oder jedem Drittanbieter-Vollbildmodus.

## iPad mit dem Mac verbinden

Für den Drawer-Schalter müssen Mac 0.8 und Companion 0.6 gemeinsam aktualisiert werden (Verbindungsprotokoll 5). Ältere Gegenstellen werden beim Handshake abgewiesen; der vorhandene Kopplungsschlüssel bleibt erhalten.

Die Companion-App ist eine eigenständige iPad-App. Sie wird über das Xcode-Target **PresentInkCompanion** mit dem eigenen Entwicklungsteam auf dem realen iPad installiert. SDK-Download allein installiert die App noch nicht. Developer Mode muss für eine Entwicklungsinstallation eingeschaltet sein.

1. Mac und iPad in dasselbe lokale Netzwerk bringen. Das iPad zeigt die Companion-App, nicht die Sidecar-Oberfläche.
2. Am Mac **Verbindung → iPad verbinden …** öffnen und die Host-Verbindung starten.
3. Lokales Netzwerk für beide Apps erlauben, wenn das System fragt.
4. Auf dem iPad **Mac verbinden** öffnen. Den gefundenen Mac auswählen und den am Mac angezeigten 32-stelligen Schlüssel einmalig eingeben.
5. Nach erfolgreicher Kopplung schließt sich der Dialog. Die Geräte speichern den Schlüssel im jeweiligen Schlüsselbund.
6. Beim nächsten Öffnen verbindet sich das iPad automatisch mit dem zuletzt gekoppelten sichtbaren Mac, sobald dessen Host läuft.

Der Mac muss nicht im lokalen Zeichenmodus sein: Sie können die Präsentation am Mac bedienen und gleichzeitig mit dem Pencil annotieren. Die Striche erscheinen auf dem ausgewählten Zieldisplay.

**Verbindung stoppen** beendet die Sitzung und Übertragung, behält aber die Kopplung. **Kopplung zurücksetzen** erzeugt einen neuen Schlüssel und widerruft alle bisherigen Kopplungen. Auf dem iPad anschließend den gespeicherten Mac vergessen und neu koppeln. Den Schlüssel wie ein Passwort behandeln und nicht im Publikum zeigen.

## Bildschirmvorschau auf dem iPad

Ohne Vorschau ist das iPad bereits als Zeichentablett verwendbar; die gerasterte Fläche stellt die Mac-Zielgeometrie dar. Für das Bild des Mac-Bildschirms ist eine zusätzliche Freigabe nötig.

1. Geräte verbinden.
2. Auf dem iPad **Mac-Bildschirm anzeigen** wählen und die Anfrage am Mac einmalig mit **Freigeben & merken** bestätigen. Bei gemerktem Vertrauen entfällt die PresentInk-Nachfrage. Alternativ am Mac **Vorschau freigeben** bzw. **Bildschirmvorschau starten** verwenden.
3. Die von macOS verlangte Bildschirmaufnahmefreigabe selbst bestätigen. Unter **Systemeinstellungen → Datenschutz & Sicherheit → Bildschirm- & Systemaudioaufnahme** PresentInk prüfen. Die genaue Bezeichnung hängt von macOS ab.
4. Nach einer Berechtigungsänderung gegebenenfalls die Mac-App neu starten, Verbindung wiederherstellen und Vorschau erneut starten.
5. Zum Beenden **Vorschau pausieren** wählen. Der iPad-Hintergrund wird geleert; die Verbindung und Zeichenfunktion können bestehen bleiben.

Die Statuszeile unterscheidet wartende Freigabe, Start, Live-Vorschau, Pause und Fehler. Ein Start ist asynchron und kann kurz dauern. Eine Warnung markiert ein länger als zwei Sekunden altes Hintergrundbild.

Die aktuelle Vorschau überträgt JPEG-Bilder mit maximal 1280 Pixeln Breite und ungefähr sechs Bildern pro Sekunde über einen separaten verschlüsselten Kanal. Audio wird nicht übertragen. Die Vorschau zeigt jetzt auch **PresentInk-Einstellungen**, **Anleitung** und **Tastaturkürzel**. Ein aus den Einstellungen geöffneter macOS-Farbwähler darf ebenfalls erscheinen. Neu geöffnete Fenster werden innerhalb ungefähr einer Sekunde in die laufende Vorschau aufgenommen, ohne manuell neu freizugeben. Voraussetzung: Das Fenster liegt auf dem ausgewählten Zieldisplay.

**Zeichen-Overlay, Drawer, Texteingabefenster und das Verbindungs-/Kopplungsfenster mit dem Schlüssel bleiben ausgeschlossen.** Sonstige PresentInk-Fenster sind standardmäßig ebenfalls ausgeschlossen. Annotationen werden auf dem iPad separat dargestellt, um Doppelbilder und Rückkopplung zu vermeiden. Die Vorschau zeigt die Einstellungen; bedient werden die Mac-Einstellungen weiterhin am Mac. Für ein Video kann die iPad-Bildschirmaufnahme die sichtbare Vorschau erfassen; PresentInk selbst nimmt weiterhin kein Video auf.

Die angezeigte Netzwerk-Roundtrip-Zeit misst nicht die gesamte Pencil-bis-Mac- oder Bildschirm-bis-iPad-Latenz. Bei schnellen Folienanimationen kann das Hintergrundbild sichtbar nachlaufen. Für zeitkritisches Zeichnen auf den Mac-Bildschirm schauen und im Veranstaltungsnetz vorher testen.

## Apple Pencil und iPad-Drawer

Pencil und Finger sind immer verfügbar, auch zum Bearbeiten von Objekten. Die frühere Fingerzeichnen-Testoption entfällt. Der Pencil hat Vorrang: Ein beginnender Pencil-Strich verwirft eine unbestätigte Fingerbewegung. Während Pencil-Kontakt/Hardware-Hover und kurz danach werden Fingerkontakte auf der Fläche ignoriert; sehr große Kontakte werden als mögliche Handballen-Berührung verworfen. Der Filter verringert versehentliche Eingaben, garantiert jedoch keine perfekte Handballenerkennung. Buttons und Tastatur bleiben mit dem Finger bedienbar. Es wird eine Bewegung gleichzeitig bearbeitet.


Die Companion-App verwendet Querformat in beiden Richtungen. Die Zeichenfläche hält die Proportionen des Mac-Zieldisplays ein; ungenutzte Randbalken nehmen keine Striche an.

- **Oben:** Zielbildschirm, Verbindung und Netzwerk-Roundtrip.
- **Unten:** flacher Drawer mit Werkzeugen, Farben und schnellen Stärken.
- **Pfeile:** oben verkleinert der Abwärtspfeil den Drawer auf die kompakte Zeile; der Aufwärtspfeil zieht ihn wieder aus. Der rechte Abwärtspfeil versteckt die Palette bis auf den kleinen Wiederöffnen-Button.
- **Mehr-Menü:** Rückgängig/Wiederholen, genaue Stärke, Formfixierung, Overlay-Sichtbarkeit und Leeren.
- **Pencil und Finger:** zeichnen und bearbeiten Objekte ohne Umschalter. Der Pencil hat Vorrang; Tastatur und Buttons sind per Finger bedienbar.
- **Testfläche:** funktioniert auch ohne Pencil bzw. im Simulator mit Finger oder Maus. Die Fläche wird nicht an den Mac übertragen.

Pencil-Druck und zusammengefasste Touch-Samples werden verarbeitet. Doppeltippen/Squeeze werden entsprechend den vom System gemeldeten Präferenzen unterstützt, soweit eine passende Funktion existiert. Beim Formenzeichnen die Formfixierung für Quadrat/Kreis bzw. 45°-Winkel einschalten. Eine angeschlossene Tastatur kann dafür auch Shift verwenden.

Ohne Mac erscheint eine gekennzeichnete lokale Testfläche. Deren Zeichnungen werden nicht zum Mac übertragen und nicht dauerhaft gespeichert.

## Sidecar als Alternative

Sidecar und Companion sind zwei verschiedene Betriebswege. Für Sidecar das iPad über die macOS-Anzeigeeinstellungen verbinden und als passenden Bildschirm verwenden. PresentInk annotiert das ausgewählte Mac-/Sidecar-Zieldisplay; Sidecar übernimmt die systemseitige Pencil-Eingabe.

Für die Companion-App Sidecar auf dem iPad verlassen und die normale Companion-App öffnen. Deren eigene Vorschau, Kopplung und Werkzeuge sind nicht Bestandteil von Sidecar. Die Companion-App kann nicht zugleich über der Sidecar-Systemoberfläche bedient werden.

### Keynote im Präsentationsmodus

Ab Mac 0.9.2 werden Zeichenfläche, Drawer und Texteingabe über Keynotes Präsentationsfenstern angezeigt. Die Zeichnungen erscheinen auf dem in PresentInk gewählten Zieldisplay; bei mehreren Bildschirmen das Folien- bzw. Moderatordisplay ausdrücklich auswählen.

- **⌃⌥A** (Control + Option + A) schaltet zwischen Zeichnen und Folienbedienung um.
- **⌃⌥W** zeigt den Mac-Drawer auch dann wieder, wenn er vollständig ausgeblendet wurde. Alternativ am iPad den Schalter **Mac-Drawer** verwenden.
- **P, H, L, A, R, O, E und T** wählen Werkzeuge nur bei aktivem Zeichenmodus und Tastaturfokus auf der Zeichenfläche. Im Bedienmodus erhält Keynote die Tastatur.
- **V / Escape** beendet den Zeichenmodus. Annotationen bleiben sichtbar, bis sie separat ausgeblendet werden.
- Werden iPad-Annotationen am Mac angezeigt, aber die Maus zeichnet nicht: zuerst Zeichenmodus mit **⌃⌥A** einschalten; für die Werkzeugwahl den Drawer mit **⌃⌥W** einblenden.

Am 14. November 2026 im Nutzertest bestätigt: iPad-Annotationen am Mac sichtbar, Zeichnen mit Maus/Trackpad und Werkzeugwahl im Drawer sowie Umschalten mit **⌃⌥A** in Keynote. Weitere Kombinationen von Displays, Space-Wechseln und Texteingabe bleiben separat zu prüfen.

## Folien vom iPad steuern

Oben im iPad-Hauptfenster und rechts im Mac-Drawer stehen **← Vorherige Folie** und **→ Nächste Folie** mit automatischem Leeren. Am iPad sind sie nur bei Verbindung und außerhalb eines laufenden Strichs verfügbar; am Mac benötigen sie keine iPad-Verbindung. Während der Texteingabe wird die Kopfzeile durch die Textbedienung ersetzt.

1. Keynote oder PowerPoint am Mac öffnen und die Präsentation starten.
2. Wenn beide Apps laufen, die gewünschte App am Mac kurz in den Vordergrund bringen; PresentInk merkt sich das Ziel.
3. Am iPad den gewünschten Pfeil betätigen.
4. Die erste macOS-Nachfrage zur Steuerung der jeweiligen App erlauben. Später unter **Datenschutz & Sicherheit → Automation → PresentInk** prüfen.

PresentInk verwendet direkte AppleScript-Befehle mit auf Keynote/PowerPoint begrenzten Sandbox-Ausnahmen. Es simuliert keine allgemeinen Tastendrücke und benötigt hierfür keine Bedienungshilfen-Freigabe. Andere Apps erhalten keine Navigation. In Keynote bedeutet Weiter den nächsten Animationsschritt oder die nächste Folie und Zurück die vorige Folie; PowerPoint verwendet nächste/vorherige Folie im laufenden Bildschirmpräsentationsfenster. Nach erfolgreicher Annahme eines PresentInk-Folienbefehls werden alle Annotationen geleert. Auch ein Keynote-Animationsschritt führt zum Leeren. Bei Fehler oder verweigerter Freigabe bleibt die Zeichnung erhalten.

Bei fehlender Präsentation, uneindeutigem Ziel oder verweigerter Automation zeigt das iPad eine Meldung. Animationen und verschiedene Vollbildmodi müssen auf dem jeweiligen Gerät geprüft werden.

## Apple Kurzbefehle und AppleScript

Die Mac-App bietet 16 native Aktionen in **Apple Kurzbefehle** und ein AppleScript-Wörterbuch mit 43 Befehlen und elf Eigenschaften. Damit steuern Sie Werkzeuge, Farbe, Stärke, Zeichenmodus, Drawer, Sichtbarkeit, Displays, Verbindung und Vorschau sowie Fenster und App-Lebenszyklus. Kurzbefehle erhalten Status- und Display-Objekte mit auswählbaren Eigenschaften; AppleScript erhält weiterhin JSON. Die Schnittstellen erzeugen keine synthetischen Striche.

### Einen Präsentations-Kurzbefehl erstellen

1. PresentInk einmal starten.
2. In Apple Kurzbefehle einen neuen Ablauf anlegen und nach **PresentInk** suchen.
3. **PresentInk-Werkzeug setzen → Stift**, **PresentInk-Farbe setzen → Rot**, **PresentInk-Strichstärke setzen → 4** hinzufügen.
4. **PresentInk-Drawer einstellen → Kompakt** hinzufügen.
5. **PresentInk steuern → Annotationen zeigen** und danach **Zeichnen einschalten** hinzufügen.
6. Den Ablauf nach Wunsch über ein eigenes Kürzel oder die Menüleiste starten.

Werkzeug-, Farb- und Stärkeeinstellungen über Automation aktivieren das Zeichnen nicht automatisch. PresentInk muss bereits laufen. Ist die App beendet, endet die Aktion mit einer verständlichen Fehlermeldung. Eine im Hintergrund laufende App wird ohne Aktivierung gesteuert; ausdrücklich gewählte Fenster-/Anzeigeaktionen können natürlich Fenster öffnen. Zum bewussten Starten vorher die Apple-Aktion **App öffnen → PresentInk** hinzufügen. Bei mehreren laufenden PresentInk-Kopien wird eine eindeutige Fehlermeldung ausgegeben.

In Kurzbefehlen ist die Ausgabe ein typisierter PresentInk-Status. In der nächsten Aktion die Ausgabevariable anklicken und die gewünschte Eigenschaft auswählen, etwa **Zeichenmodus aktiv**, **Annotationen sichtbar**, **Werkzeug** oder **Strichstärke / Schriftgröße**. Die Display-Aktion liefert eine Liste von Display-Objekten mit einzeln auswählbaren Eigenschaften. JSON wird intern verarbeitet; ein Wörterbuch- oder JSON-Konvertierungsschritt entfällt. Bestehende Abläufe mit JSON-Auswertung bitte auf diese Eigenschaften umstellen.

Für vollständiges Ausblenden in Kurzbefehlen **PresentInk-Drawer einstellen → Vollständig ausgeblendet** wählen. **Minimiert (Griff)** lässt dagegen den Griff sichtbar.

### AppleScript verwenden

Im Skripteditor **Ablage → Wörterbuch öffnen … → PresentInk** wählen. Beim ersten Zugriff kann macOS die Erlaubnis für den aufrufenden Prozess verlangen.

```applescript
tell application "PresentInk"
    toggle drawing
end tell
```

Vollständig ausblenden und gezielt wieder öffnen:

```applescript
tell application "PresentInk"
    set drawer state to "invisible"
    -- Einschließlich Griff unsichtbar. Zeichnungen und Eingabe bleiben erhalten.
    -- Zum Wiederöffnen: set drawer state to "expanded"
end tell
```

`hidden` bleibt aus Kompatibilitätsgründen der Zustand mit sichtbarem Griff; `invisible` ist der neue vollständig ausgeblendete Zustand. `drawer_state` und `mac_drawer_visible` im Status zeigen den Mac-Zustand an.

Ein Profil gezielt einstellen:

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

### Alle Eigenschaften für `set` und `get`

`set` und `get` gehören zur AppleScript-Sprache und erscheinen deshalb nicht als eigene PresentInk-Befehle im App-Wörterbuch. Im Skripteditor unter **Ablage → Wörterbuch öffnen → PresentInk → PresentInk Suite → application** stehen die Eigenschaften. Die App-Kopie aus dem Programme-Ordner verwenden; bei mehreren gleichnamigen Kopien kann sonst ein altes Wörterbuch geöffnet werden.

| Eigenschaft | Lesen | Schreiben / Werte |
|---|---|---|
| `status` | Gesamtstatus als JSON-Text | Nur lesbar |
| `available displays` | Displayliste als JSON-Text | Nur lesbar |
| `drawing enabled` | `true` / `false` | Zeichenmodus ein / aus |
| `annotations visible` | `true` / `false` | Annotationen zeigen / ausblenden |
| `drawer state` | Text | `"expanded"`, `"compact"`, `"hidden"` (Griff), `"invisible"` (ganz aus) |
| `current tool` | Werkzeugname | `"pen"`, `"marker"`, `"line"`, `"arrow"`, `"rectangle"`, `"ellipse"`, `"eraser"`, `"text"`; deutsche Aliase ebenfalls möglich |
| `ink color` | Hex-Farbe als Text | Farbname, z. B. `"rot"` / `"red"`, oder `"#FF5533"` |
| `stroke width` | Zahl | Breite innerhalb der am Mac eingestellten Grenzen des gewählten Werkzeugs |
| `display index` | Ganzzahl ab 1 | Zieldisplay; Wechsel bei vorhandenen Annotationen wird ohne ausdrückliche Löschfreigabe abgewiesen |
| `connection enabled` | `true` / `false` | Companion-Host starten / stoppen; bedeutet nicht, dass ein iPad verbunden ist |
| `preview enabled` | `true` / `false` | Bildschirmvorschau starten / stoppen; Start ist asynchron |

Die Eigenschaftsnamen sind englisch und enthalten Leerzeichen. JSON-Feldnamen wie `stroke_width` sind keine AppleScript-Eigenschaften. Beispiel: `get stroke width` liest nur eine Zahl, `get status` dagegen den gesamten JSON-Status. Deckkraft und Profile haben derzeit eigene Befehle, aber keine `set`-/`get`-Eigenschaften. Mehrere `set`-Anweisungen werden einzeln angewendet, nicht als atomarer Satz.

Eine bereits laufende App muss für solche Befehle nicht ausdrücklich mit `activate` aktiviert werden. Das ist im Vollbild hilfreich. Status abfragen:

```applescript
tell application "PresentInk"
    set currentStatus to read status
end tell
```

Wichtige Statusfelder sind `drawing_enabled`, `drawer_state`, `tool`, `color`, `stroke_width`, `ipad_connected` und `preview_state`. Vorschau-Start zunächst mit `starting` ist normal; später `live` oder `failed` prüfen. Ungültige Werte liefern Fehler statt stiller Begrenzung. Ein Displaywechsel mit vorhandenen Strichen benötigt `clearing annotations true`; Kopplung zurücksetzen benötigt `confirmed true`.

Die vollständige zusätzliche Referenz liegt im Projekt unter `Docs/Automation.md`, Beispiele unter `Automation/Examples/`. macOS-Berechtigungen werden durch Automation nicht umgangen.

## Datenschutz und Berechtigungen

- **Lokales Netzwerk:** für Bonjour-Gerätesuche und die direkte Mac-iPad-Verbindung.
- **Bildschirmaufnahme:** nur für die ausdrücklich gestartete iPad-Bildschirmvorschau. Lokales Annotieren braucht sie nicht.
- **AppleScript-Automation:** gegebenenfalls Erlaubnis für den aufrufenden Skripteditor/Kurzbefehl, PresentInk zu steuern.
- **Bedienungshilfen:** für die implementierten Zeichen- und Automationsfunktionen nicht erforderlich.
- **Schlüsselbund:** speichert die Kopplung auf beiden Geräten. Keine erneute Schlüsseleingabe pro normalem Start vorgesehen.

Die Verbindung bleibt im lokalen Netzwerk und verwendet authentifiziertes TLS mit gemeinsamem Kopplungsschlüssel. Es gibt keinen Cloud-Dienst. Bildschirmbilder werden nicht als Aufzeichnung gespeichert. Die aktuelle Zeichenebene wird nicht als dauerhaftes Dokument gespeichert. Automationsstatus enthält weder Kopplungsschlüssel noch Bildschirmbilder.

Die Freigabe-Einstellungen beziehen sich auf die aktuelle Kopplung und werden bei Schlüsselwechsel widerrufen. Das Ausblenden des Drawers, der Annotationen oder der gesamten App ist kein verlässlicher Schalter zum Stoppen einer Freigabe. **Vorschau pausieren**, **Verbindung stoppen** oder die App beenden, wenn keine Bildschirmübertragung mehr gewünscht ist.

## Probleme lösen

**iPad: „App konnte nicht überprüft werden – Internetverbindung notwendig“**

Unter **Einstellungen → Allgemein → VPN und Geräteverwaltung** den Entwicklereintrag öffnen und **App überprüfen** wählen, danach PresentInk erneut öffnen. Safari kann funktionieren, obwohl die Entwicklerprüfung noch aussteht oder ihren Apple-Server nicht erreicht. Wenn die Prüfung weiterhin scheitert, ein anderes Netzwerk, etwa einen Handy-Hotspot, versuchen. Die App nicht vorschnell löschen; eine erneute Prüfung genügte beim Installationstest. Siehe auch [Apples Hinweise zur Entwicklerprüfung](https://help.apple.com/xcode/mac/current/en.lproj/dev96a12fb84.html).


### Ich kann die Präsentation nicht anklicken

Wahrscheinlich ist der Zeichenmodus aktiv. **Escape** bei Zeichenfokus oder global **⌃⌥A** drücken. Im Zweifel **⌃⌥Escape** verwenden. Das iPad kann weiterzeichnen, obwohl am Mac der Bedienmodus aktiv ist.

### Im Vollbild verschwinden Drawer oder Zeichnungen

Die aktuelle Mac-Version 0.8 verwenden und eine noch laufende alte Xcode-/Programme-Kopie beenden. Das richtige Zieldisplay prüfen, den Vollbildübergang abwarten, dann **⌃⌥W** und **⌃⌥A** testen. Nach einem Space-Wechsel wird der Zeichenmodus vorsorglich beendet.

Prüfen, ob die Präsentation einen eigenen zweiten Bildschirm oder einen exklusiven Ausgabemodus verwendet. Zunächst mit einem gewöhnlichen macOS-Vollbildfenster vergleichen. Normale Vollbild-Spaces und exklusive Ausgabemodi sind technisch verschieden. Ein geschützter Inhalt lässt sich nicht durch zusätzliche Berechtigungen erzwingen.

### Der Mac erscheint auf dem iPad nicht

Host-Verbindung am Mac starten. Gleiches Netzwerk, lokale Netzwerkrechte und Firewall prüfen. Gast-WLAN und Client-Isolation können die direkte Verbindung verhindern. Bonjour allein koppelt noch nicht. Manuelle IP-Eingabe oder Verbindung über das Internet sind nicht implementiert.

### Der Schlüssel muss immer wieder eingegeben werden

Nicht bei jedem Start **Kopplung zurücksetzen** wählen. Die bestehende Kopplung verwenden. Nach einem tatsächlichen Schlüsselwechsel den alten Mac-Eintrag auf dem iPad vergessen und einmal neu koppeln. Sicherstellen, dass nicht verschiedene Mac-App-Kopien mit verschiedenen Schlüsselbund-/Signaturkontexten gestartet werden.

### Auf dem iPad fehlen die Mac-Bilder

Eine verbundene Zeichenfläche bedeutet noch keine aktive Bildschirmfreigabe. **Mac-Bildschirm anzeigen** wählen, am Mac freigeben und die Systemberechtigung prüfen. Status und Fehlermeldung am iPad beachten. Nach Änderungen gegebenenfalls Mac-App neu starten und erneut verbinden. Bei schwarzen geschützten Videos mit einem gewöhnlichen Fenster gegenprüfen.

### Die Zeichnung liegt auf dem falschen Bildschirm

**Darstellung → Zieldisplay** kontrollieren. Displaywechsel setzt die Zeichenebene zurück. Bei mehreren Monitoren ist nur einer das aktive Ziel. Die iPad-Fläche folgt dessen Seitenverhältnis.

### Tasten lösen die falsche App-Aktion aus

Nur **⌃⌥A**, **⌃⌥W** und **⌃⌥Escape** sind eingebaute globale Kürzel. P/H/L/A/R/O/E und Escape erfordern Zeichenfokus. Menükürzel erfordern die aktive PresentInk-App. Besonders beim nicht aktivierenden Vollbild-Overlay kann weiterhin die Präsentations-App aktiv sein.

### Nach einem Neustart sind die Zeichnungen weg

Der Prototyp speichert die Zeichenebene nicht dauerhaft. Kopplung und Zeichendokument sind getrennt: eine erhaltene Kopplung bedeutet nicht, dass die letzte Zeichenebene wiederhergestellt wird.

## Eine Präsentation vorbereiten und beenden

### Vor dem Vortrag

1. Richtige Mac-App und gegebenenfalls Companion starten.
2. Zieldisplay und Vollbildmodus testen.
3. Globales Zeichnen/Bedienen sowie Notfall-Ausblenden prüfen.
4. iPad verbinden und Vorschau freigeben, falls benötigt.
5. Werkzeuge, Farben und Breite vorbereiten; Teststriche anschließend löschen.
6. Verbindungsdialog und Hilfe schließen, Drawer bei Bedarf kompakt stellen.
7. Eine normale Foliennavigation und einen Pencil-Strich auf der echten Hardware testen.

### Nach dem Vortrag

1. Zeichenmodus ausschalten.
2. Vorschau pausieren und Verbindung stoppen.
3. Annotationen nach Bedarf löschen oder ausblenden.
4. PresentInk beenden. Die Kopplung bleibt für den nächsten Einsatz erhalten.

## Aktuelle Grenzen

- Ein annotiertes Zieldisplay gleichzeitig; keine automatische Zuordnung von Zeichnungen zu Folien.
- Keine Speicherung, kein PDF-/Bildexport und keine Videoaufnahme der Annotationen.
- Die Vorschau ist ein reduzierter Hintergrundstream, kein verlustfreier 60-Hz-Monitor.
- Kein Internet-Relay, kein QR-Pairing, keine manuelle IP-Eingabe und keine Mehrbenutzer-Präsentationssitzung.
- Geschützte Systemoberflächen, DRM und exklusive Vollbildausgabe können die Darstellung bzw. Aufnahme begrenzen.
- Entwicklungsinstallation und Signierung über Xcode; keine App-Store- oder notarisiert verteilte Release-Version.

Technische Hintergrundreferenz zur Overlay-Zuordnung: [Apple: canJoinAllApplications](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/canjoinallapplications). Die tatsächliche Kompatibilität mit der verwendeten Präsentations-App bitte vor dem Vortrag auf der Zielhardware prüfen.


## Sprache wählen

PresentInk unterstützt Deutsch und US-Englisch mit derselben App. Die Sprache folgt der App-Sprache im Betriebssystem; in Xcode kann unter Scheme → Run → Options → App Language Englisch zum Testen gewählt werden. Danach die App neu starten und vorher wichtige Annotationen sichern. Englische Hilfe wird bei englischer App-Sprache geöffnet. AppleScript-Namen, gespeicherte Profile, Schlüssel und Protokollwerte bleiben unverändert.


## Über PresentInk

Am Mac öffnet **PresentInk → Über PresentInk** das gestaltete Infofenster. Auf dem iPad öffnet das Info-Symbol neben dem App-Namen dieselbe Ansicht. Sie zeigt Version und Build, **Software-Regie: Leif Jensen-Pistorius**, Copyright, einen Hinweis auf KI-Unterstützung sowie den Link zum GitHub-Repository und den nicht anklickbaren Platzhalter **App-Webseite folgt**.

Der vollständige MIT-Lizenztext lässt sich direkt aufklappen und kopieren. Er ist mit beiden Apps ausgeliefert und benötigt keine Internetverbindung. Der GitHub-Link wird nur beim Anklicken geöffnet; die Aboutbox lädt keine Webseite im Hintergrund.


Die Aboutbox lässt sich in anderen Projekten wiederverwenden. Die unabhängige SwiftUI-Komponente liegt in `SharedUI/AppAboutView.swift`; PresentInk-Texte und Links stehen ausschließlich in `SharedUI/PresentInkAboutView.swift`. Eine ausführliche Übernahme-Anleitung mit Beispielen liegt im Quellprojekt unter `Docs/About-Reuse.md`.


## Präsentationsfenster und durchgehende Vorschau (0.9.2)

**Bekannter Fehler / TODO:** LibreOffice-Impress-Vollbild funktioniert laut erneutem Nutzertest mit 0.9.2 weiterhin nicht. Mac-Drawer und iPad-Annotationen können unsichtbar bleiben. Die implementierte Erkennung behebt diesen Fall noch nicht; LibreOffice-Vollbild ist nicht als funktionierend abgenommen.

Die Overlay-Höhe berücksichtigt technisch Keynote, PowerPoint und LibreOffice. Displayfüllende Fenster und hohe Präsentations-Schutzfenster werden erkannt; Overlay und Drawer erhalten zwei getrennte Ebenen darüber, soweit die öffentlichen macOS-Ebenen dies erlauben. Die Fenster bleiben als stationäre Hilfsfenster für fremde Vollbild-Spaces vorgesehen.

Ein Folienwechsel leert die Zeichnung, aber verwirft nicht mehr das Bildschirmbild. Zeichensitzung und Aufnahmequelle haben getrennte Kennungen. Nur ein tatsächlicher Quellen-/Geometriewechsel verwirft den bisherigen Hintergrund. Bei geänderter Geometrie desselben bereits freigegebenen Displays wird eine laufende Aufnahme ohne erneute PresentInk-Freigabe fortgesetzt; ein anderes Display benötigt weiterhin die bewusste Freigabe. Beim Warten auf neue Bilder erscheint nur ein Ladeindikator, kein Verbindungsdialog.

Wenn Zeichnungen oder Drawer fehlen, zuerst das Auge (**Annotationen zeigen**) bzw. den iPad-Schalter **Mac-Drawer** oder **⌃⌥W** prüfen. Beide Sichtbarkeiten sind unabhängig. Für Maus/Trackpad-Zeichnen muss der Zeichenmodus aktiv sein (**⌃⌥A** oder Werkzeug im Drawer wählen). LibreOffice ist für die Overlay-Erkennung berücksichtigt; die Folienautomatisierung bleibt auf Keynote/PowerPoint begrenzt. Ein Hardwaretest der konkreten Präsentationsansicht bleibt erforderlich.
