//
//  RewardService.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import FirebaseFirestore
import Foundation

final class RewardService {
    private let db = Firestore.firestore()

    func loadRewards(familyID: String) async throws -> [FamilyReward] {
        let snapshot = try await db.collection("families")
            .document(familyID)
            .collection("rewards")
            .getDocumentsAsync()

        return snapshot.documents.compactMap { document in
            Self.reward(from: document, familyID: familyID)
        }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func createReward(_ input: CreateRewardInput) async throws {
        let reference = db.collection("families")
            .document(input.familyID)
            .collection("rewards")
            .document()

        try await reference.setDataAsync([
            "id": reference.documentID,
            "familyID": input.familyID,
            "title": input.title,
            "details": input.details,
            "costXP": input.costXP,
            "iconName": input.iconName,
            "category": input.category.rawValue,
            "isActive": true,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: false)
    }

    func deleteReward(familyID: String, rewardID: String) async throws {
        try await db.collection("families")
            .document(familyID)
            .collection("rewards")
            .document(rewardID)
            .deleteAsync()
    }

    func startClaimsListener(
        familyID: String,
        onUpdate: @escaping (Result<[RewardClaim], Error>) -> Void
    ) -> ListenerRegistration {
        db.collection("families")
            .document(familyID)
            .collection("rewardClaims")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }
                guard let snapshot else {
                    onUpdate(.success([]))
                    return
                }
                let claims = snapshot.documents.compactMap { Self.claim(from: $0, familyID: familyID) }
                    .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
                onUpdate(.success(claims))
            }
    }

    func claimReward(familyID: String, reward: FamilyReward, hero: HeroProfile) async throws {
        let reference = db.collection("families")
            .document(familyID)
            .collection("rewardClaims")
            .document()

        try await reference.setDataAsync([
            "id": reference.documentID,
            "familyID": familyID,
            "rewardID": reward.id,
            "rewardTitle": reward.title,
            "rewardIconName": reward.iconName,
            "rewardCostXP": reward.costXP,
            "heroID": hero.id,
            "heroName": hero.name,
            "status": RewardClaimStatus.claimed.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: false)
    }

    func updateClaimStatus(
        familyID: String,
        claimID: String,
        status: RewardClaimStatus,
        parentComment: String? = nil
    ) async throws {
        let trimmedComment = parentComment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        try await db.collection("families")
            .document(familyID)
            .collection("rewardClaims")
            .document(claimID)
            .setDataAsync([
                "status": status.rawValue,
                "parentComment": trimmedComment.isEmpty ? FieldValue.delete() : trimmedComment,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    private static func reward(from document: QueryDocumentSnapshot, familyID: String) -> FamilyReward? {
        let data = document.data()
        guard
            let title = data["title"] as? String,
            let details = data["details"] as? String,
            let costXP = data["costXP"] as? Int,
            let iconName = data["iconName"] as? String,
            let categoryRawValue = data["category"] as? String,
            let category = RewardCategory(rawValue: categoryRawValue)
        else { return nil }

        return FamilyReward(
            id: data["id"] as? String ?? document.documentID,
            familyID: familyID,
            title: title,
            details: details,
            costXP: costXP,
            iconName: iconName,
            category: category,
            isActive: data["isActive"] as? Bool ?? true,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
        )
    }

    private static func claim(from document: QueryDocumentSnapshot, familyID: String) -> RewardClaim? {
        let data = document.data()
        guard
            let rewardID = data["rewardID"] as? String,
            let rewardTitle = data["rewardTitle"] as? String,
            let rewardIconName = data["rewardIconName"] as? String,
            let rewardCostXP = data["rewardCostXP"] as? Int,
            let heroID = data["heroID"] as? String,
            let heroName = data["heroName"] as? String,
            let statusRawValue = data["status"] as? String,
            let status = RewardClaimStatus(rawValue: statusRawValue)
        else { return nil }

        return RewardClaim(
            id: data["id"] as? String ?? document.documentID,
            familyID: familyID,
            rewardID: rewardID,
            rewardTitle: rewardTitle,
            rewardIconName: rewardIconName,
            rewardCostXP: rewardCostXP,
            heroID: heroID,
            heroName: heroName,
            status: status,
            parentComment: data["parentComment"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
        )
    }
}

private extension Query {
    func getDocumentsAsync() async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "RewardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firestore query snapshot."]))
                }
            }
        }
    }
}

private extension DocumentReference {
    func setDataAsync(_ data: [String: Any], merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setData(data, merge: merge) { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }

    func deleteAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }
}
