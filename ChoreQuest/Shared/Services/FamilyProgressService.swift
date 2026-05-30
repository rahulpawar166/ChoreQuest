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
