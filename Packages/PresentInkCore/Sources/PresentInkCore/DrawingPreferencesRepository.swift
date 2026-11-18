import Foundation

public final class DrawingPreferencesRepository {
    private let defaults: UserDefaults
    private let key = "drawing-library-v1"
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func load() throws -> DrawingLibrary {
        guard let data = defaults.data(forKey: key) else { return DrawingLibrary() }
        let library = try JSONDecoder().decode(DrawingLibrary.self, from: data)
        guard library.valid else { throw AutomationFailure.invalid(inkLocalized("Gespeicherte Zeichen-Einstellungen sind ungültig.")) }
        return library
    }
    public func save(_ library: DrawingLibrary) throws {
        guard library.valid else { throw AutomationFailure.invalid(inkLocalized("Zeichen-Einstellungen oder Profile ungültig.")) }
        defaults.set(try JSONEncoder().encode(library), forKey: key)
    }
}
