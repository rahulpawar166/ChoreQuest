//
//  FamilyProgressService.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import FirebaseFirestore
import Foundation

final class FamilyProgressService {
    private let db = Firestore.firestore()

    func contributeXP(
        familyID: String,
        rewardID: String,
        hero: HeroProfile,
        amountXP: Int
    ) async throws {
        guard amountXP > 0 else { return }

        let reference = db.collection("families")
            .document(familyID)
            .collection("familyContributions")
            .document()

        try await reference.setContributionDataAsync([
            "id": reference.documentID,
            "familyID": familyID,
            "rewardID": rewardID,
            "heroID": hero.id,
            "heroName": hero.name,
            "amountXP": amountXP,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func startContributionsListener(
        familyID: String,
        onUpdate: @escaping (Result<[FamilyXPContribution], Error>) -> Void
    ) -> ListenerRegistration {
        db.collection("families")
            .document(familyID)
            .collection("familyContributions")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }

                let contributions = snapshot?.documents.compactMap { document -> FamilyXPContribution? in
                    let data = document.data()
                    guard
                        let rewardID = data["rewardID"] as? String,
                        let heroID = data["heroID"] as? String,
                        let heroName = data["heroName"] as? String,
                        let amountXP = data["amountXP"] as? Int
                    else { return nil }

                    return FamilyXPContribution(
                        id: data["id"] as? String ?? document.documentID,
                        familyID: familyID,
                        rewardID: rewardID,
                        heroID: heroID,
                        heroName: heroName,
                        amountXP: amountXP,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
                    )
                } ?? []

                onUpdate(.success(contributions))
            }
    }

    func startSubmissionsListener(
        familyID: String,
        onUpdate: @escaping (Result<[KidQuestSubmission], Error>) -> Void
    ) -> ListenerRegistration {
        db.collection("families")
            .document(familyID)
            .collection("questSubmissions")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }

                guard let snapshot else {
                    onUpdate(.success([]))
                    return
                }

                let submissions = snapshot.documents.compactMap { document in
                    Self.submission(from: document, familyID: familyID)
                }
                .sorted {
                    ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
                }

                onUpdate(.success(submissions))
            }
    }

    private static func submission(from document: QueryDocumentSnapshot, familyID: String) -> KidQuestSubmission? {
        let data = document.data()

        guard
            let questID = data["questID"] as? String,
            let heroID = data["heroID"] as? String,
            let heroName = data["heroName"] as? String,
            let questTitle = data["questTitle"] as? String,
            let proofImageBase64 = data["proofImageBase64"] as? String,
            let statusRawValue = data["status"] as? String,
            let status = KidQuestSubmissionStatus(rawValue: statusRawValue)
        else {
            return nil
        }

        return KidQuestSubmission(
            id: data["id"] as? String ?? document.documentID,
            familyID: familyID,
            questID: questID,
            heroID: heroID,
            heroName: heroName,
            questTitle: questTitle,
            questXPValue: data["questXPValue"] as? Int,
            proofImageBase64: proofImageBase64,
            status: status,
            parentComment: data["parentComment"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
        )
    }
}

private extension DocumentReference {
    func setContributionDataAsync(_ data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
