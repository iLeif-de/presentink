import PresentInkCore
import AppKit
import SwiftUI
import WebKit

/// Local help only: bundled HTML is generated from the shipped Markdown source.
final class MacHelpController {
    private var aboutWindow: NSWindow?
    func showAbout() {
        if aboutWindow == nil {
            let controller = NSHostingController(rootView: PresentInkAboutView())
            let window = NSWindow(contentViewController: controller)
            window.title = inkLocalized("Über PresentInk")
            window.identifier = NSUserInterfaceItemIdentifier("presentink.about")
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 580, height: 690))
            window.minSize = NSSize(width: 480, height: 520)
            window.isReleasedWhenClosed = false
            window.center(); aboutWindow = window
        }
        NSApp.unhide(nil); aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    private var guideWindow: NSWindow?
    private var shortcutsWindow: NSWindow?

    func showGuide() {
        if guideWindow == nil {
            guard let url = Bundle.main.url(forResource: Bundle.main.preferredLocalizations.first?.hasPrefix("de") == true ? "Anleitung" : "UserGuide", withExtension: "html") else {
                let alert = NSAlert(); alert.messageText = inkLocalized("Die Anleitung fehlt im App-Bundle."); alert.runModal(); return
            }
            let webView = WKWebView()
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1060, height: 760),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.title = inkLocalized("PresentInk · Anleitung")
            window.identifier = NSUserInterfaceItemIdentifier("presentink.guide")
            window.minSize = NSSize(width: 760, height: 420)
            window.contentView = webView
            window.isReleasedWhenClosed = false
            window.setFrameAutosaveName("PresentInkGuide")
            window.center(); guideWindow = window
        }
        NSApp.unhide(nil)
        guideWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showShortcuts() {
        if shortcutsWindow == nil {
            let view = ShortcutReferenceView(showGuide: { [weak self] in self?.showGuide() })
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = inkLocalized("PresentInk · Tastaturkürzel")
            window.identifier = NSUserInterfaceItemIdentifier("presentink.shortcuts")
            window.styleMask = [.titled, .closable, .resizable]
            window.minSize = NSSize(width: 630, height: 450)
            window.setContentSize(NSSize(width: 740, height: 730))
            window.isReleasedWhenClosed = false
            window.center(); shortcutsWindow = window
        }
        NSApp.unhide(nil)
        shortcutsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct ShortcutReferenceView: View {
    let showGuide: () -> Void
    private func section(_ title: String, note: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(note).font(.callout).foregroundStyle(.secondary)
            }
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                ForEach(rows.indices, id: \.self) { index in
                    GridRow {
                        Text(rows[index].0).frame(maxWidth: .infinity, alignment: .leading)
                        Text(rows[index].1)
                            .font(.system(.body, design: .monospaced).weight(.medium))
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                            .fixedSize()
                    }
                }
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "keyboard").font(.system(size: 30)).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(inkLocalized("Schnell zur richtigen Aktion")).font(.title2.bold())
                    Text(inkLocalized("⌘ Befehl · ⌥ Option · ⌃ Control · ⇧ Umschalt")).foregroundStyle(.secondary)
                }
                Spacer()
            }.padding(24)
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    section(inkLocalized("Immer erreichbar"), note: inkLocalized("Diese drei Kürzel gelten auch in anderen Apps und im Vollbild."), rows: [
                        (inkLocalized("Zeichnen / Bedienen"), "⌃⌥A"), (inkLocalized("Drawer zeigen / verstecken"), "⌃⌥W"),
                        (inkLocalized("Notfall: Eingabe frei, Annotationen aus"), "⌃⌥Escape")])
                    section(inkLocalized("Auf der Zeichenfläche"), note: inkLocalized("Einzeltasten gelten, wenn die Zeichenfläche Tastaturfokus hat."), rows: [
                        (inkLocalized("Stift / Marker"), "P / H"), (inkLocalized("Linie / Pfeil"), "L / A"),
                        (inkLocalized("Rechteck / Ellipse / Radierer / Text"), "R / O / E / T"), (inkLocalized("Zurück zum Bedienen"), "V / Escape"),
                        (inkLocalized("Quadrat, Kreis, 45°-Winkel"), inkLocalized("⇧ beim Ziehen"))])
                    section("In PresentInk", note: inkLocalized("Menükürzel gelten in der aktiven App; im nicht aktivierenden Vollbild-Overlay die Einzeltasten bzw. globale Kürzel verwenden."), rows: [
                        (inkLocalized("Werkzeug wählen"), "⌥⌘P/H/L/A/R/O/E/T"), (inkLocalized("Bedienmodus"), "⌥⌘V"),
                        (inkLocalized("Palettenfarben 1–8"), "⌘1–8"),
                        (inkLocalized("Strich breiter / schmaler"), "⌘+ / ⌘−"), (inkLocalized("Rückgängig / Wiederholen"), "⌘Z / ⇧⌘Z"),
                        (inkLocalized("Alle Annotationen löschen"), "⇧⌘⌫"), (inkLocalized("Drawer kompakt / ausziehen"), "⇧⌘D"),
                        (inkLocalized("Annotationen zeigen / verstecken"), "⇧⌘H"), (inkLocalized("Verbindung & Freigabe / Einstellungen"), "⌘I / ⌘,"),
                        (inkLocalized("iPad-Verbindung starten / stoppen"), "⇧⌘I"), (inkLocalized("Vorschau starten / pausieren"), "⇧⌘S"),
                        (inkLocalized("Kopplung zurücksetzen (mit Rückfrage)"), "⌥⌘⌫"), (inkLocalized("Zieldisplay 1–9"), "⌃⌘1–9"),
                        (inkLocalized("Anleitung / Tastaturkürzel"), "⌘? / ⌥⌘?"), (inkLocalized("App ausblenden / beenden"), "⌘H / ⌘Q")])
                }.padding(24)
            }
            Divider()
            HStack {
                Text(inkLocalized("Drawer ausblenden pausiert keine Bildschirmübertragung.")).font(.callout).foregroundStyle(.secondary)
                Spacer()
                Button(inkLocalized("Anleitung öffnen"), action: showGuide)
            }.padding(18)
        }.frame(minWidth: 630, minHeight: 450).background(Color(nsColor: .windowBackgroundColor))
    }
}
