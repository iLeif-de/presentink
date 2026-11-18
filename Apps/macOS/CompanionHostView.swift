import PresentInkCore
import SwiftUI

struct CompanionHostView: View {
    @ObservedObject var session: MacSession
    @State private var confirmReset = false
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            Label("PresentInk Companion",systemImage:"ipad.and.iphone").font(.largeTitle.bold())
            Text(inkLocalized("Pencil am iPad. Annotationen auf dem Mac.")).foregroundStyle(.secondary)
            GroupBox {
                VStack(alignment:.leading,spacing:12) {
                    Label(session.serverStatus,systemImage:session.connected ? "checkmark.shield.fill" : "network")
                    if session.connected { Text(session.settingsSynchronized ? inkLocalized("Zeichen-Einstellungen am iPad bestätigt") : inkLocalized("Zeichen-Einstellungen werden synchronisiert …")).font(.caption).foregroundStyle(.secondary) }
                    if session.token.isEmpty {
                        Button(inkLocalized("iPad-Verbindung starten")) { session.startServer() }.buttonStyle(.borderedProminent)
                    } else {
                        Text(inkLocalized("Nur beim ersten Mal: Auf dem iPad diesen Mac auswählen und den Kopplungsschlüssel eingeben. Danach wird die Verbindung im Schlüsselbund gemerkt.")).font(.callout)
                        Text(session.token).font(.system(.body,design:.monospaced)).textSelection(.enabled)
                        HStack {
                            Button(inkLocalized("Schlüssel kopieren")) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(session.token,forType:.string) }
                            Button(inkLocalized("Verbindung stoppen")) { session.stopServer() }
                        }
                        Text(inkLocalized("Der Schlüssel bleibt auch nach einem Neustart gleich. Mit ‚Kopplung zurücksetzen‘ werden bisherige Kopplungen ungültig.")).font(.caption).foregroundStyle(.secondary)
                    }
                }.frame(maxWidth:.infinity,alignment:.leading).padding(8)
            }
            GroupBox(inkLocalized("Bildschirmvorschau auf dem iPad")) {
                VStack(alignment:.leading,spacing:12) {
                    Text(inkLocalized("Quelle: %@", String(describing: (session.snapshot.display.name))))
                    Text(session.previewStatus).foregroundStyle(.secondary)
                    Text(inkLocalized("Die Freigabe überträgt den ausgewählten Bildschirm ohne eigene PresentInk-Fenster. macOS fragt nach Bildschirmaufnahmezugriff. Ohne Freigabe bleibt das iPad als leeres Zeichentablett nutzbar.")).font(.callout)
                    Toggle(inkLocalized("Freigabe für die aktuelle Kopplung merken"), isOn: Binding(get: { session.previewPolicy.trusted }, set: { session.setPreviewTrust($0) })).disabled(session.token.isEmpty)
                    Toggle(inkLocalized("Vorschau nach dem Verbinden automatisch starten"), isOn: Binding(get: { session.previewPolicy.autoStart }, set: { session.setPreviewAutoStart($0) })).disabled(!session.previewPolicy.trusted)
                    Text(inkLocalized("Gemerkt wird die PresentInk-Zustimmung; macOS-Systemfreigaben bleiben erforderlich.")).font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button(session.sharing ? inkLocalized("Vorschau pausieren") : inkLocalized("Vorschau freigeben")) {
                            if session.sharing { session.pausePreview() } else { session.startPreview() }
                        }.buttonStyle(.borderedProminent).disabled(!session.connected)
                        if session.sharing { Label(inkLocalized("Bildschirm wird übertragen"),systemImage:"record.circle").foregroundStyle(.red) }
                    }
                }.frame(maxWidth:.infinity,alignment:.leading).padding(8)
            }
            HStack {
                Button(inkLocalized("Bildschirmaufnahme-Einstellungen öffnen")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") { NSWorkspace.shared.open(url) }
                }
                Spacer()
                Button(inkLocalized("Kopplung zurücksetzen"), role: .destructive) { confirmReset = true }
            }
            if let error = session.error {
                Label(error,systemImage:"exclamationmark.triangle").foregroundStyle(.orange).fixedSize(horizontal:false,vertical:true)
                Button(inkLocalized("Hinweis schließen")) { session.error = nil }
            }
            Text(inkLocalized("macOS 27 · lokales TLS-Pairing · keine Cloud · keine Aufzeichnung")).font(.caption).foregroundStyle(.secondary)
        }.padding(24).frame(width:550)
        .alert(inkLocalized("Mac-Bildschirm auf dem iPad anzeigen?"), isPresented: $session.previewRequested) {
            Button(inkLocalized("Einmal freigeben")) { session.startPreview() }
            Button(inkLocalized("Freigeben & merken")) { session.setPreviewTrust(true); session.startPreview() }
            Button(inkLocalized("Nicht jetzt"), role: .cancel) { session.declinePreview() }
        } message: {
            Text(inkLocalized("Das gekoppelte iPad möchte ‚%@‘ sehen. Die Freigabe kann jederzeit pausiert werden.", String(describing: (session.snapshot.display.name))))
        }
        .confirmationDialog(inkLocalized("Kopplung zurücksetzen?"), isPresented: $confirmReset) {
            Button(inkLocalized("Alle bisherigen Kopplungen widerrufen"), role: .destructive) { session.resetPairing() }
        } message: { Text(inkLocalized("Danach muss der neue Schlüssel einmalig auf dem iPad eingegeben werden.")) }
    }
}
