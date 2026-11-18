import Foundation

/// Shared by the Mac app, Shortcuts extension, and companion. Values, IDs, and wire keys are never translated.
public enum InkLocalization {
    public static func text(_ key: String, language: String? = nil) -> String {
        let preferred = language ?? Bundle.main.preferredLocalizations.first ?? "en"
        let code = preferred.lowercased().hasPrefix("de") ? "de" : "en"
        guard let path = Bundle.module.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
    public static func format(_ key: String, arguments: [String], language: String? = nil) -> String {
        let translated = text(key, language: language)
        let pieces = translated.components(separatedBy: "%@")
        guard pieces.count == arguments.count + 1 else { return translated }
        var result = pieces[0]
        for (index, argument) in arguments.enumerated() { result += argument + pieces[index+1] }
        return result
    }
}
public func inkLocalized(_ key: String, _ arguments: String...) -> String {
    arguments.isEmpty ? InkLocalization.text(key) : InkLocalization.format(key, arguments: arguments)
}
