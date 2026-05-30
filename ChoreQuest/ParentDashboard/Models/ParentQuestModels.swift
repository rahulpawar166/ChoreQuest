//
//  ParentQuestModels.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

struct FamilyQuest: Identifiable, Hashable {
    let id: String
    let familyID: String
    let title: String
    let details: String
    let category: QuestCategory
    let xpValue: Int
    let assignment: QuestAssignment
    let frequency: QuestFrequency
    let customDueDate: Date?
    let createdAt: Date?

    var status: ParentQuestStatus {
        switch assignment {
        case .unassigned:
            return .open
        case .everyone, .hero:
            return .assigned
        }
    }

    var isRecurring: Bool {
        switch frequency {
        case .daily, .weekly, .monthly:
            return true
        case .customDate:
            return false
        }
    }
}

enum QuestCategory: String, CaseIterable, Identifiable, Codable {
    case bedroom
    case kitchen
    case school
    case laundry
    case frontYard
    case backYard
    case basement
    case drawingRoom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bedroom: return "Bedroom"
        case .kitchen: return "Kitchen"
        case .school: return "School"
        case .laundry: return "Laundry"
        case .frontYard: return "Front Yard"
        case .backYard: return "Back Yard"
        case .basement: return "Basement"
        case .drawingRoom: return "Drawing Room"
        }
    }

    var iconName: String {
        switch self {
        case .bedroom: return "bed.double.fill"
        case .kitchen: return "fork.knife"
        case .school: return "backpack.fill"
        case .laundry: return "tshirt.fill"
        case .frontYard: return "leaf.fill"
        case .backYard: return "tree.fill"
        case .basement: return "shippingbox.fill"
        case .drawingRoom: return "sofa.fill"
        }
    }
}

enum QuestFrequency: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekly
    case monthly
    case customDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .customDate: return "Custom"
        }
    }
}

enum QuestAssignment: Hashable {
    case unassigned
    case everyone
    case hero(HeroProfile)
}

enum QuestAssignmentChoice: String, CaseIterable, Identifiable {
    case unassigned
    case everyone
    case specificHero

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unassigned: return "Open Quest"
        case .everyone: return "Everyone"
        case .specificHero: return "One Hero"
        }
    }
}

struct QuestPreset: Identifiable, Hashable {
    let id: String
    let category: QuestCategory
    let title: String
    let details: String
    let xpValue: Int

    static let all: [QuestPreset] = [
        QuestPreset(id: "dish-destroyer", category: .kitchen, title: "Dish Destroyer", details: "Clean and put away the breakfast dishes.", xpValue: 50),
        QuestPreset(id: "table-tamer", category: .kitchen, title: "Table Tamer", details: "Wipe down the table until it sparkles.", xpValue: 30),
        QuestPreset(id: "fridge-fighter", category: .kitchen, title: "Fridge Fighter", details: "Organize the shelves and toss old items.", xpValue: 75),
        QuestPreset(id: "bed-boss", category: .bedroom, title: "Bed Boss", details: "Make the bed and reset the pillows.", xpValue: 35),
        QuestPreset(id: "laundry-launch", category: .laundry, title: "Laundry Launch", details: "Fold and sort the clean laundry basket.", xpValue: 60),
        QuestPreset(id: "backpack-ranger", category: .school, title: "Backpack Ranger", details: "Pack school supplies for tomorrow.", xpValue: 40),
        QuestPreset(id: "porch-patrol", category: .frontYard, title: "Porch Patrol", details: "Sweep the front porch and put shoes away.", xpValue: 55),
        QuestPreset(id: "toy-rescue", category: .drawingRoom, title: "Toy Rescue", details: "Return toys to bins and clear the room.", xpValue: 45)
    ]
}

struct CreateQuestInput {
    let familyID: String
    let title: String
    let details: String
    let category: QuestCategory
    let xpValue: Int
    let assignment: QuestAssignment
    let frequency: QuestFrequency
    let customDueDate: Date?
}
