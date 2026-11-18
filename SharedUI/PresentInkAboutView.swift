import SwiftUI
import PresentInkCore

/// Only this small adapter knows PresentInk names, localization and links.
struct PresentInkAboutView: View {
    static var configuration: AppAboutConfiguration {
        var about = AppAboutConfiguration(
            appName:"PresentInk",
            tagline:inkLocalized("Zeig, was du meinst."),
            author:"Leif Jensen-Pistorius",
            copyright:"© 2026 Leif Jensen-Pistorius"
        )
        about.role = inkLocalized("Software-Regie")
        about.platforms = "MAC + IPAD"
        about.description = inkLocalized("Von der Idee zur sichtbaren Geste. Mit KI-Unterstützung gestaltet und entwickelt.")
        about.footer = inkLocalized("Mit Neugier gemacht.")
        // Replace nil with the real app URL when the website is ready.
        about.websiteURL = nil
        about.websiteLabel = inkLocalized("App-Webseite")
        about.websitePlaceholder = inkLocalized("App-Webseite folgt")
        about.repositoryURL = URL(string:"https://github.com/iLeif-de/presentink")
        about.repositoryLabel = inkLocalized("Quellcode auf GitHub")
        about.licenseTitle = inkLocalized("Freie Software · MIT-Lizenz")
        about.licenseSummary = inkLocalized("Du darfst PresentInk verwenden, verändern und weitergeben – auch kommerziell. Copyright- und Lizenzhinweis müssen erhalten bleiben. Die Software wird ohne Gewährleistung bereitgestellt.")
        about.licenseDisclosureTitle = inkLocalized("Vollständigen Lizenztext anzeigen")
        about.licenseUnavailableText = inkLocalized("Der Lizenztext konnte nicht geladen werden.")
        about.fallbackIcon = "pencil.and.outline"
        return about
    }
    var body: some View { AppAboutView(configuration:Self.configuration) }
}
