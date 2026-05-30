//
//  KidQuestSubmissionModels.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

struct KidQuestSubmission: Identifiable, Hashable {
    let id: String
    let familyID: String
    let questID: String
    let heroID: String
    let heroName: String
    let questTitle: String
    let questXPValue: Int?
    let proofImageBase64: String
    let status: KidQuestSubmissionStatus
    let parentComment: String?
    let createdAt: Date?
    let updatedAt: Date?
}

enum KidQuestSubmissionStatus: String {
    case pending
    case approved
    case rejected

    var title: String {
        switch self {
        case .pending:
            return "Awaiting Approval"
        case .approved:
            return "Approved"
        case .rejected:
            return "Try Again"
        }
    }
}

struct CreateKidQuestSubmissionInput {
    let familyID: String
    let quest: FamilyQuest
    let hero: HeroProfile
    let proofImageData: Data
}
