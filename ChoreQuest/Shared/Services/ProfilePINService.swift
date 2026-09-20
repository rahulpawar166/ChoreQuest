//
//  ProfilePINService.swift
//  ChoreQuest
//

import CryptoKit
import Foundation
import Security

enum ProfilePINError: LocalizedError {
    case invalidPIN
    case keychainUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidPIN:
            return "Use a 4-digit PIN."
        case .keychainUnavailable:
            return "We couldn't save this PIN right now."
        }
    }
}

final class ProfilePINService {
    private let service = "com.rahulpawar166.ChoreQuest.profilePIN"

    func hasPIN(for userID: String) -> Bool {
        hasPIN(for: userID, scope: .parentGate)
    }

    func hasHeroPIN(for userID: String, heroID: String) -> Bool {
        hasPIN(for: userID, scope: .hero(heroID))
    }

    private func hasPIN(for userID: String, scope: ProfilePINScope) -> Bool {
        var query = baseQuery(userID: userID, scope: scope)
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    func setPIN(_ pin: String, for userID: String) throws {
        try setPIN(pin, for: userID, scope: .parentGate)
    }

    func setHeroPIN(_ pin: String, for userID: String, heroID: String) throws {
        try setPIN(pin, for: userID, scope: .hero(heroID))
    }

    private func setPIN(_ pin: String, for userID: String, scope: ProfilePINScope) throws {
        guard Self.isValid(pin) else {
            throw ProfilePINError.invalidPIN
        }

        let salt = try randomBytes(count: 16)
        let record = ProfilePINRecord(
            version: 1,
            saltBase64: salt.base64EncodedString(),
            hashBase64: Self.hash(pin: pin, salt: salt).base64EncodedString()
        )
        let data = try JSONEncoder().encode(record)

        var query = baseQuery(userID: userID, scope: scope)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw ProfilePINError.keychainUnavailable
        }

        query.merge(attributes) { _, new in new }
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw ProfilePINError.keychainUnavailable
        }
    }

    func verify(_ pin: String, for userID: String) -> Bool {
        verify(pin, for: userID, scope: .parentGate)
    }

    func verifyHeroPIN(_ pin: String, for userID: String, heroID: String) -> Bool {
        verify(pin, for: userID, scope: .hero(heroID))
    }

    private func verify(_ pin: String, for userID: String, scope: ProfilePINScope) -> Bool {
        guard
            Self.isValid(pin),
            let record = try? loadRecord(for: userID, scope: scope),
            let salt = Data(base64Encoded: record.saltBase64)
        else {
            return false
        }

        let candidate = Self.hash(pin: pin, salt: salt).base64EncodedString()
        return candidate == record.hashBase64
    }

    func removePIN(for userID: String) throws {
        try removePIN(for: userID, scope: .parentGate)
    }

    func removeHeroPIN(for userID: String, heroID: String) throws {
        try removePIN(for: userID, scope: .hero(heroID))
    }

    private func removePIN(for userID: String, scope: ProfilePINScope) throws {
        let status = SecItemDelete(baseQuery(userID: userID, scope: scope) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ProfilePINError.keychainUnavailable
        }
    }

    private func loadRecord(for userID: String, scope: ProfilePINScope) throws -> ProfilePINRecord? {
        var query = baseQuery(userID: userID, scope: scope)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw ProfilePINError.keychainUnavailable
        }

        return try JSONDecoder().decode(ProfilePINRecord.self, from: data)
    }

    private func baseQuery(userID: String, scope: ProfilePINScope) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: scope.accountName(userID: userID)
        ]
    }

    private func randomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw ProfilePINError.keychainUnavailable
        }
        return Data(bytes)
    }

    private static func isValid(_ pin: String) -> Bool {
        pin.count == 4 && pin.allSatisfy(\.isNumber)
    }

    private static func hash(pin: String, salt: Data) -> Data {
        var data = Data()
        data.append(salt)
        data.append(Data(pin.utf8))
        return Data(SHA256.hash(data: data))
    }
}

private enum ProfilePINScope {
    case parentGate
    case hero(String)

    func accountName(userID: String) -> String {
        switch self {
        case .parentGate:
            return "profile-pin.\(userID)"
        case .hero(let heroID):
            return "profile-pin.\(userID).hero.\(heroID)"
        }
    }
}

private struct ProfilePINRecord: Codable {
    let version: Int
    let saltBase64: String
    let hashBase64: String
}
