//
//  ParentDashboardModels.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

enum ParentDashboardTab: String, CaseIterable, Identifiable {
    case quests
    case approvals
    case heroes

    var id: String { rawValue }
}

struct ParentDashboardSnapshot {
    let familyName: String
    let crestName: String
    let parentImageBase64: String?
    let statCards: [ParentDashboardStat]
    let activeQuests: [FamilyQuest]
    let pendingApprovals: [ParentApproval]
    let heroes: [ParentHeroSummary]
    let familyStats: ParentFamilyStats

    init(familyProfile: FamilyProfile, quests: [FamilyQuest], pendingApprovals: [ParentApproval] = []) {
        familyName = familyProfile.familyName
        crestName = familyProfile.crestName
        parentImageBase64 = familyProfile.parentImageBase64

        heroes = familyProfile.heroes.enumerated().map { index, hero in
            ParentHeroSummary(
                id: hero.id,
                name: hero.name,
                levelTitle: hero.levelTitle,
                levelValue: ParentDashboardSnapshot.levelValue(from: hero.levelTitle, fallback: index + 1),
                avatarIconName: hero.avatarIconName,
                avatarColorHex: hero.avatarColorHex,
                imageBase64: hero.imageBase64
            )
        }

        activeQuests = quests
        self.pendingApprovals = pendingApprovals

        statCards = [
            ParentDashboardStat(
                title: "Active Quests",
                subtitle: "Live quest records loaded from Firestore.",
                value: "\(quests.count)",
                iconName: "checklist",
                accentHex: 0x630ed4,
                badgeText: nil
            ),
            ParentDashboardStat(
                title: "Heroes Registered",
                subtitle: "Kids added to this family from Firestore.",
                value: "\(heroes.count)",
                iconName: "person.2.fill",
                accentHex: 0xffc329,
                badgeText: nil
            )
        ]

        familyStats = ParentFamilyStats(
            heroCount: heroes.count,
            crestName: crestName,
            familyName: familyName
        )
    }

    var displayFamilyName: String {
        let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Your Family Squad" : trimmed
    }

    private static func levelValue(from title: String, fallback: Int) -> Int {
        let digits = title.compactMap(\.wholeNumberValue)
        guard !digits.isEmpty else {
            return fallback
        }

        return digits.reduce(0) { ($0 * 10) + $1 }
    }
}

struct ParentDashboardStat: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let value: String
    let iconName: String
    let accentHex: UInt
    let badgeText: String?
}

enum ParentQuestStatus {
    case assigned
    case inProgress
    case awaitingProof
    case open

    var title: String {
        switch self {
        case .assigned:
            return "Assigned"
        case .inProgress:
            return "In Progress"
        case .awaitingProof:
            return "Awaiting Review"
        case .open:
            return "Unassigned"
        }
    }
}

struct ParentApproval: Identifiable {
    let id: String
    let hero: ParentAssignee
    let heroLevelTitle: String
    let choreTitle: String
    let proofLabel: String
    let xp: Int
    let iconName: String
    let accentHex: UInt
}

struct ParentAssignee {
    let name: String
    let imageBase64: String?
    let avatarIconName: String
    let avatarColorHex: UInt
}

struct ParentHeroSummary: Identifiable {
    let id: String
    let name: String
    let levelTitle: String
    let levelValue: Int
    let avatarIconName: String
    let avatarColorHex: UInt
    let imageBase64: String?
}

struct ParentFamilyStats {
    let heroCount: Int
    let crestName: String
    let familyName: String
}
