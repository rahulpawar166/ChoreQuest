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

    func initializeNewUser(userID: String, email: String?) async throws {
        let data: [String: Any] = [
            "userID": userID,
            "email": email ?? "",
            "onboardingCompleted": false,
            "hasCompletedAppTour": false,
            "selectedRole": NSNull(),
            "selectedHeroID": NSNull(),
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(userID).setDataAsync(data, merge: true)
    }

    func deleteAccountData(userID: String, familyID: String?) async throws {
        if let familyID {
            let familyReference = db.collection("families").document(familyID)
            let subcollections = [
                "quests",
                "questSubmissions",
                "rewards",
                "rewardClaims",
                "familyContributions",
                "feedback"
            ]

            for subcollection in subcollections {
                try await deleteDocuments(in: familyReference.collection(subcollection))
            }

            try await familyReference.deleteAccountDocumentAsync()
        }

        try await db.collection("users")
            .document(userID)
            .deleteAccountDocumentAsync()
    }

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
        let profilePhotoCount = draft.heroes.compactMap(\.imageData).count + (draft.parentImageData == nil ? 0 : 1)
        let perPhotoBudget = profilePhotoCount == 0
            ? QuestImagePurpose.profile.maximumBytes
            : min(QuestImagePurpose.profile.maximumBytes, 560_000 / profilePhotoCount)
        let optimizedParentImageData = QuestImageProcessor.profileData(
            from: draft.parentImageData,
            maximumBytes: perPhotoBudget
        )

        let heroes = draft.heroes.map { heroProfileFromDraft($0, maximumImageBytes: perPhotoBudget) }
        let familyData: [String: Any] = [
            "id": familyID,
            "ownerUserID": userID,
            "familyName": trimmedFamilyName,
            "crestName": draft.crestName,
            "parentImageBase64": optimizedParentImageData?.base64EncodedString() as Any,
            "heroes": heroes.map(heroDictionary),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let userData: [String: Any] = [
            "userID": userID,
            "email": email ?? "",
            "familyID": familyID,
            "onboardingCompleted": true,
            "hasCompletedAppTour": true,
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
            hasCompletedAppTour: true,
            selectedRole: nil,
            selectedHeroID: nil
        )

        let familyProfile = FamilyProfile(
            id: familyID,
            familyName: trimmedFamilyName,
            crestName: draft.crestName,
            parentImageBase64: optimizedParentImageData?.base64EncodedString(),
            familyReward: nil,
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

    func updateAppTourCompleted(userID: String) async throws {
        let data: [String: Any] = [
            "hasCompletedAppTour": true,
            "appTourCompletedAt": FieldValue.serverTimestamp(),
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

    func updateFamilyProfile(
        familyID: String,
        familyName: String,
        crestName: String,
        parentImageData: Data?
    ) async throws -> FamilyProfile {
        let optimizedImageData = QuestImageProcessor.profileData(from: parentImageData)
        let data: [String: Any] = [
            "familyName": familyName.trimmingCharacters(in: .whitespacesAndNewlines),
            "crestName": crestName,
            "parentImageBase64": optimizedImageData?.base64EncodedString() as Any,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("families").document(familyID).setDataAsync(data, merge: true)
        let snapshot = try await db.collection("families").document(familyID).getDocumentAsync()
        return familyProfileFromSnapshot(snapshot, familyID: familyID) ?? FamilyProfile(
            id: familyID,
            familyName: familyName,
            crestName: crestName,
            parentImageBase64: optimizedImageData?.base64EncodedString(),
            familyReward: nil,
            heroes: []
        )
    }

    func updateHeroProfile(
        familyID: String,
        heroID: String,
        name: String,
        avatar: AvatarOption,
        imageData: Data?
    ) async throws -> FamilyProfile? {
        let reference = db.collection("families").document(familyID)
        let snapshot = try await reference.getDocumentAsync()
        guard var data = snapshot.data() else { return nil }

        let optimizedImageData = QuestImageProcessor.profileData(from: imageData)
        var heroes = data["heroes"] as? [[String: Any]] ?? []
        heroes = heroes.map { hero in
            guard (hero["id"] as? String) == heroID else { return hero }

            var updated = hero
            updated["name"] = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updated["avatarID"] = avatar.id
            updated["avatarName"] = avatar.name
            updated["avatarIconName"] = avatar.iconName
            updated["avatarColorHex"] = Int(avatar.colorHex)
            updated["imageBase64"] = optimizedImageData?.base64EncodedString() as Any
            return updated
        }

        data["heroes"] = heroes
        data["updatedAt"] = FieldValue.serverTimestamp()

        try await reference.setDataAsync(data, merge: true)
        let updatedSnapshot = try await reference.getDocumentAsync()
        return familyProfileFromSnapshot(updatedSnapshot, familyID: familyID)
    }

    func updateFamilyReward(
        familyID: String,
        title: String,
        goalXP: Int
    ) async throws -> FamilyProfile {
        let reference = db.collection("families").document(familyID)
        let existingSnapshot = try await reference.getDocumentAsync()
        let existingReward = existingSnapshot.data()?["familyReward"] as? [String: Any]
        let rewardID = existingReward?["id"] as? String ?? UUID().uuidString
        let data: [String: Any] = [
            "familyReward": [
                "id": rewardID,
                "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
                "goalXP": goalXP
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await reference.setDataAsync(data, merge: true)
        let snapshot = try await reference.getDocumentAsync()
        return familyProfileFromSnapshot(snapshot, familyID: familyID) ?? FamilyProfile(
            id: familyID,
            familyName: "",
            crestName: "Castle Crest",
            parentImageBase64: nil,
            familyReward: FamilyGoalReward(id: rewardID, title: title, goalXP: goalXP),
            heroes: []
        )
    }

    func clearFamilyReward(familyID: String) async throws -> FamilyProfile? {
        let data: [String: Any] = [
            "familyReward": NSNull(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("families").document(familyID).setDataAsync(data, merge: true)
        let snapshot = try await db.collection("families").document(familyID).getDocumentAsync()
        return familyProfileFromSnapshot(snapshot, familyID: familyID)
    }

    func addHeroProfile(
        familyID: String,
        name: String,
        avatar: AvatarOption,
        imageData: Data?
    ) async throws -> FamilyProfile? {
        let reference = db.collection("families").document(familyID)
        let snapshot = try await reference.getDocumentAsync()
        guard var data = snapshot.data() else { return nil }

        var heroes = data["heroes"] as? [[String: Any]] ?? []
        let optimizedImageData = QuestImageProcessor.profileData(from: imageData)
        let newHero = HeroProfile(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarID: avatar.id,
            avatarName: avatar.name,
            avatarIconName: avatar.iconName,
            avatarColorHex: avatar.colorHex,
            imageBase64: optimizedImageData?.base64EncodedString(),
            heroTitle: "Scout"
        )

        heroes.append(heroDictionary(newHero))
        data["heroes"] = heroes
        data["updatedAt"] = FieldValue.serverTimestamp()

        try await reference.setDataAsync(data, merge: true)
        let updatedSnapshot = try await reference.getDocumentAsync()
        return familyProfileFromSnapshot(updatedSnapshot, familyID: familyID)
    }

    private func userProfileFromSnapshot(_ snapshot: DocumentSnapshot, userID: String, email: String?) -> UserProfile {
        let data = snapshot.data() ?? [:]
        let selectedRole = AppRole(rawValue: data["selectedRole"] as? String ?? "")

        return UserProfile(
            userID: userID,
            email: (data["email"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? email ?? "",
            familyID: data["familyID"] as? String,
            onboardingCompleted: data["onboardingCompleted"] as? Bool ?? false,
            hasCompletedAppTour: data["hasCompletedAppTour"] as? Bool ?? true,
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
            familyReward: familyRewardFromDictionary(data["familyReward"] as? [String: Any]),
            heroes: heroes
        )
    }

    private func familyRewardFromDictionary(_ data: [String: Any]?) -> FamilyGoalReward? {
        guard
            let data,
            let title = data["title"] as? String,
            let goalXP = data["goalXP"] as? Int
        else {
            return nil
        }

        return FamilyGoalReward(
            id: data["id"] as? String ?? "legacy-family-reward",
            title: title,
            goalXP: goalXP
        )
    }

    private func heroProfileFromDraft(_ draft: HeroProfileDraft, maximumImageBytes: Int) -> HeroProfile {
        let optimizedImageData = QuestImageProcessor.profileData(
            from: draft.imageData,
            maximumBytes: maximumImageBytes
        )
        return HeroProfile(
            id: draft.id.uuidString,
            name: draft.name,
            avatarID: draft.avatar.id,
            avatarName: draft.avatar.name,
            avatarIconName: draft.avatar.iconName,
            avatarColorHex: draft.avatar.colorHex,
            imageBase64: optimizedImageData?.base64EncodedString(),
            heroTitle: draft.heroTitle
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
            "heroTitle": hero.heroTitle
        ]
    }

    private func heroProfileFromDictionary(_ data: [String: Any]) -> HeroProfile {
        let colorValue = data["avatarColorHex"] as? Int ?? Int(0x630ed4)

        return HeroProfile(
            id: data["id"] as? String ?? UUID().uuidString,
            name: data["name"] as? String ?? "",
            avatarID: data["avatarID"] as? String ?? AvatarOption.all[0].id,
            avatarName: data["avatarName"] as? String ?? AvatarOption.all[0].name,
            avatarIconName: data["avatarIconName"] as? String ?? AvatarOption.all[0].iconName,
            avatarColorHex: UInt(colorValue),
            imageBase64: data["imageBase64"] as? String,
            heroTitle: heroTitle(from: data)
        )
    }

    private func heroTitle(from data: [String: Any]) -> String {
        if let title = data["heroTitle"] as? String, !title.isEmpty {
            return title
        }

        let legacyTitle = data["levelTitle"] as? String ?? "Scout"
        let components = legacyTitle.split(separator: " ")
        if components.count >= 3,
           components[0].localizedCaseInsensitiveCompare("Level") == .orderedSame,
           Int(components[1]) != nil {
            return components.dropFirst(2).joined(separator: " ")
        }

        return legacyTitle
    }

    private func deleteDocuments(in collection: CollectionReference) async throws {
        while true {
            let snapshot = try await collection
                .limit(to: 400)
                .getAccountDeletionDocumentsAsync()
            guard !snapshot.documents.isEmpty else { return }

            let batch = db.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commitAccountDeletionAsync()
        }
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

private extension DocumentReference {
    func deleteAccountDocumentAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

private extension Query {
    func getAccountDeletionDocumentsAsync() async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "FirestoreSessionService",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Missing account deletion query snapshot."]
                    ))
                }
            }
        }
    }
}

private extension WriteBatch {
    func commitAccountDeletionAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            commit { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
