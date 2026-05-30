//
//  KidQuestSubmissionService.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import FirebaseFirestore
import Foundation

final class KidQuestSubmissionService {
    private let db = Firestore.firestore()

    func loadSubmissions(familyID: String, heroID: String) async throws -> [KidQuestSubmission] {
        let snapshot = try await db.collection("families")
            .document(familyID)
            .collection("questSubmissions")
            .getDocumentsAsync()

        return snapshot.documents.compactMap { document in
            submission(from: document, familyID: familyID)
        }
        .filter { $0.heroID == heroID }
        .sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
    }

    func submitProof(_ input: CreateKidQuestSubmissionInput) async throws {
        let reference = db.collection("families")
            .document(input.familyID)
            .collection("questSubmissions")
            .document()

        try await reference.setSubmissionDataAsync([
            "id": reference.documentID,
            "familyID": input.familyID,
            "questID": input.quest.id,
            "questTitle": input.quest.title,
            "questXPValue": input.quest.xpValue,
            "heroID": input.hero.id,
            "heroName": input.hero.name,
            "proofImageBase64": input.proofImageData.base64EncodedString(),
            "status": KidQuestSubmissionStatus.pending.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: false)
    }

    private func submission(from document: QueryDocumentSnapshot, familyID: String) -> KidQuestSubmission? {
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

private extension Query {
    func getDocumentsAsync() async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "KidQuestSubmissionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firestore query snapshot."]))
                }
            }
        }
    }
}

private extension DocumentReference {
    func setSubmissionDataAsync(_ data: [String: Any], merge: Bool) async throws {
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
