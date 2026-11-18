import PresentInkCore
import Foundation
import Security

public protocol PairingSecretStorage {
    func read(account: String) throws -> Data?
    func write(_ data: Data, account: String) throws
    func remove(account: String) throws
}

public struct KeychainPairingStorage: PairingSecretStorage {
    private let service = "de.presentink.pairing.v1"
    public init() {}
    private func query(_ account: String) -> [String: Any] {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                  kSecAttrService as String: service, kSecAttrAccount as String: account]
        return query
    }
    public func read(account: String) throws -> Data? {
        var query = query(account); query[kSecReturnData as String] = true; query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw PairingStorageError(status: status) }
        return data
    }
    public func write(_ data: Data, account: String) throws {
        let query = query(account)
        var attributes: [String: Any] = [kSecValueData as String: data]
        #if !os(macOS)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        #endif
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw PairingStorageError(status: status) }
    }
    public func remove(account: String) throws {
        let status = SecItemDelete(query(account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw PairingStorageError(status: status) }
    }
}
public struct PairingStorageError: LocalizedError {
    let status: OSStatus
    public var errorDescription: String? { inkLocalized("Kopplung konnte nicht im Schlüsselbund gespeichert/gelesen werden (%@).", String(describing: (status))) }
}
public struct TrustedMac: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let key: String
}

/// Keys are saved only after successful authenticated pairing. No secrets in UserDefaults or Bonjour.
public final class PairingRepository {
    private let storage: any PairingSecretStorage
    public init(storage: any PairingSecretStorage = KeychainPairingStorage()) { self.storage = storage }
    public func hostKey() throws -> String {
        if let data = try storage.read(account: "host-key"), let key = String(data: data, encoding: .utf8) {
            guard PairingKey.isValid(key) else { throw LinkError.invalidToken }
            return key
        }
        let key = PairingKey.generate(); try storage.write(Data(key.utf8), account: "host-key"); return key
    }
    @discardableResult public func rotateHostKey() throws -> String {
        let key = PairingKey.generate(); try storage.write(Data(key.utf8), account: "host-key"); return key
    }
    public func trustedMacs() throws -> [TrustedMac] {
        guard let data = try storage.read(account: "trusted-macs") else { return [] }
        return try JSONDecoder().decode([TrustedMac].self, from: data)
    }
    public func remember(id: String, name: String, key: String) throws {
        let key = PairingKey.normalized(key); guard PairingKey.isValid(key) else { throw LinkError.invalidToken }
        var hosts = try trustedMacs(); hosts.removeAll { $0.id == id }
        hosts.insert(TrustedMac(id: id, name: name, key: key), at: 0)
        try storage.write(JSONEncoder().encode(Array(hosts.prefix(10))), account: "trusted-macs")
    }
    public func forget(id: String) throws {
        let hosts = try trustedMacs().filter { $0.id != id }
        try storage.write(JSONEncoder().encode(hosts), account: "trusted-macs")
    }
}
