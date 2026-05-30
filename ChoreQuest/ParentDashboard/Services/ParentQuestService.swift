//
//  ParentQuestService.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import FirebaseFirestore
import Foundation

final class ParentQuestService {
    private let db = Firestore.firestore()

    func loadQuests(familyID: String, heroes: [HeroProfile]) async throws -> [FamilyQuest] {
        let snapshot = try await db.collection("families")
            .document(familyID)
            .collection("quests")
            .order(by: "createdAt", descending: true)
            .getDocumentsAsync()

        return snapshot.documents.compactMap { document in
            quest(from: document, familyID: familyID, heroes: heroes)
        }
    }

    func createQuest(_ input: CreateQuestInput) async throws {
        let reference = db.collection("families")
            .document(input.familyID)
            .collection("quests")
            .document()

        let assignmentData = assignmentDictionary(from: input.assignment)

        try await reference.setQuestDataAsync([
            "id": reference.documentID,
            "familyID": input.familyID,
            "title": input.title,
            "details": input.details,
            "category": input.category.rawValue,
            "xpValue": input.xpValue,
            "assignmentMode": assignmentData.mode,
            "assignedHeroID": assignmentData.heroID as Any,
            "frequency": input.frequency.rawValue,
            "customDueDate": input.customDueDate.map(Timestamp.init(date:)) as Any,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: false)
    }

    func claimQuest(familyID: String, questID: String, heroID: String) async throws {
        try await db.collection("families")
            .document(familyID)
            .collection("quests")
            .document(questID)
            .setQuestDataAsync([
                "assignmentMode": QuestAssignmentChoice.specificHero.rawValue,
                "assignedHeroID": heroID,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    func unassignQuest(familyID: String, questID: String) async throws {
        try await db.collection("families")
            .document(familyID)
            .collection("quests")
            .document(questID)
            .setQuestDataAsync([
                "assignmentMode": QuestAssignmentChoice.unassigned.rawValue,
                "assignedHeroID": NSNull(),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    private func quest(from document: QueryDocumentSnapshot, familyID: String, heroes: [HeroProfile]) -> FamilyQuest? {
        let data = document.data()

        guard
            let title = data["title"] as? String,
            let details = data["details"] as? String,
            let categoryRawValue = data["category"] as? String,
            let category = QuestCategory(rawValue: categoryRawValue),
            let frequencyRawValue = data["frequency"] as? String,
            let frequency = QuestFrequency(rawValue: frequencyRawValue)
        else {
            return nil
        }

        let assignmentMode = data["assignmentMode"] as? String ?? QuestAssignmentChoice.unassigned.rawValue
        let assignedHeroID = data["assignedHeroID"] as? String
        let assignment = assignmentFrom(mode: assignmentMode, heroID: assignedHeroID, heroes: heroes)

        return FamilyQuest(
            id: data["id"] as? String ?? document.documentID,
            familyID: familyID,
            title: title,
            details: details,
            category: category,
            xpValue: data["xpValue"] as? Int ?? 0,
            assignment: assignment,
            frequency: frequency,
            customDueDate: (data["customDueDate"] as? Timestamp)?.dateValue(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
        )
    }

    private func assignmentFrom(mode: String, heroID: String?, heroes: [HeroProfile]) -> QuestAssignment {
        switch QuestAssignmentChoice(rawValue: mode) {
        case .everyone:
            return .everyone
        case .specificHero:
            if let heroID, let hero = heroes.first(where: { $0.id == heroID }) {
                return .hero(hero)
            }
            return .unassigned
        case .unassigned, .none:
            return .unassigned
        }
    }

    private func assignmentDictionary(from assignment: QuestAssignment) -> (mode: String, heroID: String?) {
        switch assignment {
        case .unassigned:
            return (QuestAssignmentChoice.unassigned.rawValue, nil)
        case .everyone:
            return (QuestAssignmentChoice.everyone.rawValue, nil)
        case .hero(let hero):
            return (QuestAssignmentChoice.specificHero.rawValue, hero.id)
        }
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
                    continuation.resume(throwing: NSError(domain: "ParentQuestService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firestore query snapshot."]))
                }
            }
        }
    }
}

private extension DocumentReference {
    func setQuestDataAsync(_ data: [String: Any], merge: Bool) async throws {
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
