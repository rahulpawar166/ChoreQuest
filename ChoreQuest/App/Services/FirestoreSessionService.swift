//
//  FirestoreSessionService.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import FirebaseFirestore
import Foundation

struct SessionSnapshot {
    let userProfile: UserProfile
    let familyProfile: FamilyProfile?
}

final class FirestoreSessionService {
    private let db = Firestore.firestore()

    func loadSession(userID: String, email: String?) async throws -> SessionSnapshot {
        let userReference = db.collection("users").document(userID)
        let userSnapshot = try await userReference.getDocumentAsync()
        let userProfile = userProfileFromSnapshot(userSnapshot, userID: userID, email: email)

        guard userProfile.onboardingCompleted, let familyID = userProfile.familyID else {
            return SessionSnapshot(userProfile: userProfile, familyProfile: nil)
        }

        let familySnapshot = try await db.collection("families").document(familyID).getDocumentAsync()
        let familyProfile = familyProfileFromSnapshot(familySnapshot, familyID: familyID)

        return SessionSnapshot(userProfile: userProfile, familyProfile: familyProfile)
    }

    func completeOnboarding(userID: String, email: String?, draft: FamilyProfileDraft) async throws -> SessionSnapshot {
        let trimmedFamilyName = draft.familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let familyID = userID

        let heroes = draft.heroes.map(heroProfileFromDraft)
        let familyData: [String: Any] = [
            "id": familyID,
            "ownerUserID": userID,
            "familyName": trimmedFamilyName,
            "crestName": draft.crestName,
            "parentImageBase64": draft.parentImageData?.base64EncodedString() as Any,
            "heroes": heroes.map(heroDictionary),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let userData: [String: Any] = [
            "userID": userID,
            "email": email ?? "",
            "familyID": familyID,
            "onboardingCompleted": true,
            "selectedRole": NSNull(),
            "selectedHeroID": NSNull(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("families").document(familyID).setDataAsync(familyData, merge: true)
        try await db.collection("users").document(userID).setDataAsync(userData, merge: true)

        let userProfile = UserProfile(
            userID: userID,
            email: email ?? "",
            familyID: familyID,
            onboardingCompleted: true,
            selectedRole: nil,
            selectedHeroID: nil
        )

        let familyProfile = FamilyProfile(
            id: familyID,
            familyName: trimmedFamilyName,
            crestName: draft.crestName,
            parentImageBase64: draft.parentImageData?.base64EncodedString(),
            heroes: heroes
        )

        return SessionSnapshot(userProfile: userProfile, familyProfile: familyProfile)
    }

    func updateSelectedRole(userID: String, role: AppRole) async throws {
        let data: [String: Any] = [
            "selectedRole": role.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(userID).setDataAsync(data, merge: true)
    }

    func updateSelectedHero(userID: String, heroID: String) async throws {
        let data: [String: Any] = [
            "selectedHeroID": heroID,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(userID).setDataAsync(data, merge: true)
    }

    func clearSelectedRole(userID: String) async throws {
        let data: [String: Any] = [
            "selectedRole": NSNull(),
            "selectedHeroID": NSNull(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(userID).setDataAsync(data, merge: true)
    }

    private func userProfileFromSnapshot(_ snapshot: DocumentSnapshot, userID: String, email: String?) -> UserProfile {
        let data = snapshot.data() ?? [:]
        let selectedRole = AppRole(rawValue: data["selectedRole"] as? String ?? "")

        return UserProfile(
            userID: userID,
            email: (data["email"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? email ?? "",
            familyID: data["familyID"] as? String,
            onboardingCompleted: data["onboardingCompleted"] as? Bool ?? false,
            selectedRole: selectedRole,
            selectedHeroID: data["selectedHeroID"] as? String
        )
    }

    private func familyProfileFromSnapshot(_ snapshot: DocumentSnapshot, familyID: String) -> FamilyProfile? {
        guard let data = snapshot.data() else {
            return nil
        }

        let heroes = (data["heroes"] as? [[String: Any]] ?? []).map(heroProfileFromDictionary)

        return FamilyProfile(
            id: familyID,
            familyName: data["familyName"] as? String ?? "",
            crestName: data["crestName"] as? String ?? "Castle Crest",
            parentImageBase64: data["parentImageBase64"] as? String,
            heroes: heroes
        )
    }

    private func heroProfileFromDraft(_ draft: HeroProfileDraft) -> HeroProfile {
        HeroProfile(
            id: draft.id.uuidString,
            name: draft.name,
            avatarID: draft.avatar.id,
            avatarName: draft.avatar.name,
            avatarIconName: draft.avatar.iconName,
            avatarColorHex: draft.avatar.colorHex,
            imageBase64: draft.imageData?.base64EncodedString(),
            levelTitle: draft.levelTitle
        )
    }

    private func heroDictionary(_ hero: HeroProfile) -> [String: Any] {
        [
            "id": hero.id,
            "name": hero.name,
            "avatarID": hero.avatarID,
            "avatarName": hero.avatarName,
            "avatarIconName": hero.avatarIconName,
            "avatarColorHex": Int(hero.avatarColorHex),
            "imageBase64": hero.imageBase64 as Any,
            "levelTitle": hero.levelTitle
        ]
    }

    private func heroProfileFromDictionary(_ data: [String: Any]) -> HeroProfile {
        let colorValue = data["avatarColorHex"] as? Int ?? Int(0x630ed4)

        return HeroProfile(
            id: data["id"] as? String ?? UUID().uuidString,
            name: data["name"] as? String ?? "",
            avatarID: data["avatarID"] as? String ?? "default",
            avatarName: data["avatarName"] as? String ?? "Default",
            avatarIconName: data["avatarIconName"] as? String ?? "star.fill",
            avatarColorHex: UInt(colorValue),
            imageBase64: data["imageBase64"] as? String,
            levelTitle: data["levelTitle"] as? String ?? "Level 1 Scout"
        )
    }
}

private extension DocumentReference {
    func getDocumentAsync() async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "FirestoreSessionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firestore document snapshot."]))
                }
            }
        }
    }

    func setDataAsync(_ data: [String: Any], merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setData(data, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
