//
//  RewardModels.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

struct FamilyReward: Identifiable, Hashable {
    let id: String
    let familyID: String
    let title: String
    let details: String
    let costXP: Int
    let iconName: String
    let category: RewardCategory
    let isActive: Bool
    let createdAt: Date?
}

enum RewardCategory: String, CaseIterable, Identifiable {
    case time
    case treat
    case choice
    case privilege
    case outing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .time: return "Screen Time"
        case .treat: return "Treat"
        case .choice: return "Choice"
        case .privilege: return "Privilege"
        case .outing: return "Outing"
        }
    }
}

struct RewardSuggestion: Identifiable, Hashable {
    let id: String
    let title: String
    let details: String
    let costXP: Int
    let iconName: String
    let category: RewardCategory

    static let all: [RewardSuggestion] = [
        RewardSuggestion(id: "screen-10", title: "10 More Minutes", details: "Extra screen time for today.", costXP: 15, iconName: "ipad.and.iphone", category: .time),
        RewardSuggestion(id: "dessert-pick", title: "Pick Dessert", details: "Choose tonight's dessert.", costXP: 25, iconName: "cupcake", category: .treat),
        RewardSuggestion(id: "movie-pick", title: "Movie Night Pick", details: "Choose the family movie.", costXP: 40, iconName: "popcorn.fill", category: .choice),
        RewardSuggestion(id: "late-bedtime", title: "15 Min Later Bedtime", details: "Stay up 15 minutes later this weekend.", costXP: 50, iconName: "moon.stars.fill", category: .privilege),
        RewardSuggestion(id: "park-pick", title: "Park Trip Pick", details: "Choose the next weekend park.", costXP: 60, iconName: "figure.play", category: .outing),
        RewardSuggestion(id: "small-pass", title: "Small Chore Pass", details: "Skip one small chore.", costXP: 75, iconName: "ticket.fill", category: .privilege),
        RewardSuggestion(id: "book-toy", title: "New Book or Small Toy", details: "Pick a small reward item.", costXP: 100, iconName: "gift.fill", category: .treat)
    ]
}

struct CreateRewardInput {
    let familyID: String
    let title: String
    let details: String
    let costXP: Int
    let iconName: String
    let category: RewardCategory
}

struct RewardClaim: Identifiable, Hashable {
    let id: String
    let familyID: String
    let rewardID: String
    let rewardTitle: String
    let rewardIconName: String
    let rewardCostXP: Int
    let heroID: String
    let heroName: String
    let status: RewardClaimStatus
    let createdAt: Date?
    let updatedAt: Date?
}

enum RewardClaimStatus: String {
    case claimed
    case fulfilled
    case rejected

    var title: String {
        switch self {
        case .claimed: return "Pending"
        case .fulfilled: return "Granted"
        case .rejected: return "Rejected"
        }
    }
}
