//
//  FeedbackService.swift
//  ChoreQuest
//

import FirebaseFirestore
import Foundation

struct FeedbackSubmission {
    let role: AppRole
    let userID: String
    let familyID: String
    let familyName: String
    let heroID: String?
    let heroName: String?
    let category: FeedbackCategory
    let message: String
}

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case idea = "Idea"
    case issue = "Something Isn't Working"
    case experience = "App Experience"
    case praise = "Something I Love"
    case other = "Other"

    var id: String { rawValue }
}

final class FeedbackService {
    private let db = Firestore.firestore()

    func submit(_ submission: FeedbackSubmission) async throws {
        let reference = db.collection("families")
            .document(submission.familyID)
            .collection("feedback")
            .document()

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"

        try await reference.setFeedbackDataAsync([
            "id": reference.documentID,
            "authorRole": submission.role.rawValue,
            "authorRoleLabel": submission.role == .parent ? "Parent" : "Kid",
            "userID": submission.userID,
            "familyID": submission.familyID,
            "familyName": submission.familyName,
            "heroID": submission.heroID.map { $0 as Any } ?? NSNull(),
            "heroName": submission.heroName.map { $0 as Any } ?? NSNull(),
            "category": submission.category.rawValue,
            "message": submission.message,
            "appVersion": version,
            "appBuild": build,
            "platform": "iOS",
            "status": "new",
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
}

private extension DocumentReference {
    func setFeedbackDataAsync(_ data: [String: Any]) async throws {
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
