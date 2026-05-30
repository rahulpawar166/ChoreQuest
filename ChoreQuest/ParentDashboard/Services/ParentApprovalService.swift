//
//  ParentApprovalService.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import FirebaseFirestore
import Foundation

final class ParentApprovalService {
    private let db = Firestore.firestore()

    func startPendingApprovalsListener(
        familyID: String,
        onUpdate: @escaping (Result<[KidQuestSubmission], Error>) -> Void
    ) -> ListenerRegistration {
        db.collection("families")
            .document(familyID)
            .collection("questSubmissions")
            .whereField("status", isEqualTo: KidQuestSubmissionStatus.pending.rawValue)
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

    func updateSubmissionStatus(
        familyID: String,
        submissionID: String,
        status: KidQuestSubmissionStatus,
        parentComment: String? = nil
    ) async throws {
        var payload: [String: Any] = [
            "status": status.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let parentComment, !parentComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["parentComment"] = parentComment
        }

        try await db.collection("families")
            .document(familyID)
            .collection("questSubmissions")
            .document(submissionID)
            .setApprovalDataAsync(payload, merge: true)
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
    func setApprovalDataAsync(_ data: [String: Any], merge: Bool) async throws {
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
