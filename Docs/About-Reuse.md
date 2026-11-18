# Aboutbox in anderen Projekten wiederverwenden

Die Aboutbox besteht aus zwei Dateien:

| Datei | Aufgabe |
|---|---|
| `SharedUI/AppAboutView.swift` | Allgemeine SwiftUI-Ansicht einschließlich `AppAboutConfiguration`. Keine Abhängigkeit von PresentInkCore. |
| `SharedUI/PresentInkAboutView.swift` | PresentInk-spezifische Texte, Übersetzungen, GitHub-Link und Webseiten-Platzhalter. |

Für ein anderes Projekt genügt die erste Datei und eine eigene kleine Konfiguration. Die zweite Datei dient als Beispiel und muss nicht mitkopiert werden.

## 1. Datei und Lizenz übernehmen

1. `AppAboutView.swift` in das neue Xcode-Projekt ziehen; bei Bedarf **Copy items if needed** wählen.
2. Bei **Target Membership** die App auswählen. Bei einem gemeinsamen Mac-/iPad-Projekt beide App-Targets aktivieren. Eine Kurzbefehle-Erweiterung benötigt die Ansicht nicht.
3. Die MIT-Lizenzhinweise der kopierten Komponente erhalten. Dazu die ursprüngliche `LICENSE` mitführen, gegebenenfalls als `AboutView-LICENSE` oder Bestandteil der Third-Party-Notices. Die Lizenz der eigenen App wird separat in der Konfiguration festgelegt.
4. Soll der Lizenztext im Aboutfenster aus einer Datei kommen, diese Datei in **Copy Bundle Resources** des jeweiligen App-Targets aufnehmen. Standardname ist `LICENSE` ohne Erweiterung.

Die Komponente verwendet SwiftUI mit plattformspezifischer Icon-Erkennung über AppKit/UIKit. Es werden keine PresentInk-Pakete, keine Netzwerkverbindung und kein API-Key benötigt. Die hier geprüften Targets sind macOS/iPadOS 27; für ältere Mindestversionen die verwendeten SwiftUI-APIs im eigenen Target prüfen.

## 2. Eigene Konfiguration anlegen

Zum Beispiel `MyAppAboutView.swift`:

```swift
import SwiftUI

struct MyAppAboutView: View {
    private var configuration: AppAboutConfiguration {
        var about = AppAboutConfiguration(
            appName: "Meine App",
            tagline: "Ein kurzer Satz über meine App.",
            author: "Dein Name",
            copyright: "© 2026 Dein Name"
        )
        about.role = "Software-Regie"
        about.platforms = "MAC + IPAD" // oder "MAC", "IPAD", ""
        about.description = "Hier steht eine kurze Beschreibung."
        about.footer = "Mit Neugier gemacht."

        // Solange die echte Webseite fehlt, ist nur ein Hinweis sichtbar.
        about.websiteURL = nil
        about.websiteLabel = "App-Webseite"
        about.websitePlaceholder = "App-Webseite folgt"

        // Optional: echte URL des eigenen Repositories eintragen.
        about.repositoryURL = nil
        about.repositoryLabel = "Quellcode auf GitHub"

        about.licenseTitle = "Lizenz"
        about.licenseSummary = "Kurze Beschreibung deiner App-Lizenz."
        about.licenseResourceName = "LICENSE"
        about.licenseDisclosureTitle = "Vollständigen Lizenztext anzeigen"
        about.licenseUnavailableText = "Der Lizenztext konnte nicht geladen werden."

        return about
    }

    var body: some View {
        AppAboutView(configuration: configuration)
    }
}
```

Version und Build werden automatisch aus `CFBundleShortVersionString` und `CFBundleVersion` im App-Bundle gelesen. Den App-Namen, die Tagline und das Copyright bewusst konfigurieren, damit keine PresentInk-Texte übernommen werden.

## 3. Im eigenen UI öffnen

Für eine SwiftUI-Sheet-Darstellung auf Mac oder iPad:

```swift
struct ContentView: View {
    @State private var showAbout = false

    var body: some View {
        Button("Über diese App") { showAbout = true }
            .sheet(isPresented: $showAbout) {
                MyAppAboutView()
                    .frame(minWidth: 320, minHeight: 480)
            }
    }
}
```

Im echten iPad-UI zusätzlich einen Schließen-Button in einer NavigationStack-Toolbar vorsehen, wie in `Apps/iPadOS/CompanionView.swift`. Für ein separates Mac-Fenster kann ein `NSHostingController(rootView: MyAppAboutView())` verwendet werden. Das Fenster bzw. dessen Controller als Property behalten, damit es nach dem Öffnen nicht freigegeben wird. Ein vollständiges Beispiel steht in `Apps/macOS/MacHelp.swift` unter `showAbout()`; dort die konkrete PresentInk-Ansicht durch die eigene ersetzen. Die Einbindung in das Hilfe-/App-Menü erfolgt im jeweiligen Projekt.

## Webseiten-Platzhalter aktivieren oder ersetzen

In PresentInk zentral in `SharedUI/PresentInkAboutView.swift`:

```swift
about.websiteURL = nil
about.websitePlaceholder = inkLocalized("App-Webseite folgt")
```

Das erzeugt einen sichtbaren, nicht anklickbaren Platzhalter. Er öffnet keine Beispiel- oder Hausnerd-Seite. Der GitHub-Link bleibt unabhängig davon aktiv.

Sobald eine echte Webseite feststeht, `websiteURL` auf deren URL setzen. Die URL hat Vorrang vor dem Platzhalter. Für vollständig unsichtbare Webseiten-Bedienung beide Werte auf `nil` setzen. Für GitHub entsprechend `repositoryURL` konfigurieren; `nil` blendet diesen Link aus.

## Gestaltung, Icon und Lizenztext

Alle Werte werden in derselben Konfiguration gesetzt:

```swift
about.accentColor = .indigo
about.waveColor = .mint
about.gradientStart = Color(red: 0.08, green: 0.04, blue: 0.28)
about.gradientEnd = Color(red: 0.15, green: 0.06, blue: 0.44)

// Optional: eigenes Bild aus dem Assetkatalog.
about.icon = Image("AboutIcon")
about.fallbackIcon = "app.dashed"

// Optional: Lizenztext direkt liefern statt aus einer Datei.
about.licenseText = "Hier steht der vollständige Lizenztext deiner App."
```

Ohne eigenes Bild verwendet die Ansicht das laufende Mac-App-Icon bzw. das deklarierte iPad-App-Icon. Ein explizites `Image` ist für Previews oder besondere Icon-Varianten sinnvoll.

`licenseText` hat Vorrang vor der Ressourcendatei. `licenseResourceName` enthält den vollständigen Dateinamen, zum Beispiel `LICENSE` oder `MyLicense.txt`. `bundle` ist standardmäßig `.main`; für Ressourcen eines anderen Bundles lässt es sich ersetzen. Version/Build werden aus demselben Bundle gelesen. Die Lizenz der kopierten About-Komponente muss unabhängig von der App-Lizenz weiterhin mitgeführt werden.

## Übersetzungen und Weiterentwicklung

Die allgemeine Komponente nimmt fertige Strings entgegen und enthält englische Standardlabels. Im eigenen Projekt Texte mit `String(localized: ...)` oder der dort verwendeten Lokalisierung setzen. PresentInk verwendet ausschließlich im eigenen Adapter `inkLocalized(...)`; die allgemeine Datei kennt diese Funktion nicht.

Bei Fehlerkorrekturen genügt es, `AppAboutView.swift` in die anderen Projekte zu übernehmen. Deren Konfigurationsdateien bleiben projektspezifisch. Bei mehreren Apps mit häufiger gemeinsamer Weiterentwicklung kann die Komponente später in ein eigenes Swift-Package wandern; für das einfache Kopieren ist kein Package erforderlich.
