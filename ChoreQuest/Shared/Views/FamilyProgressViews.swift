//
//  FamilyProgressViews.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct FamilyRewardProgressCard: View {
    let progress: FamilyRewardProgress?

    var body: some View {
        ParentSurfaceCard {
            if let progress {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 12) {
                        Circle()
                            .fill(ChoreQuestColors.secondary)
                            .frame(width: 52, height: 52)
                            .overlay {
                                Image(systemName: "party.popper.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(ChoreQuestColors.secondaryText)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Family Reward: \(progress.title)")
                                .font(.custom("Quicksand", size: 20).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurface)

                            Text("Team Goal: \(progress.goalXP) XP")
                                .font(.custom("Quicksand", size: 12).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        }

                        Spacer()

                        Text("\(progress.currentXP) / \(progress.goalXP)")
                            .font(.custom("Quicksand", size: 14).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.primary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ChoreQuestColors.surfaceContainer)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [ChoreQuestColors.primary, ChoreQuestColors.primaryContainer],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geometry.size.width * progress.progress, 10))
                        }
                    }
                    .frame(height: 16)

                    Text(progress.remainingXP == 0 ? "Reward unlocked. Time to celebrate." : "Just \(progress.remainingXP) more XP to unlock the reward.")
                        .font(.custom("Quicksand", size: 13).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "party.popper")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(ChoreQuestColors.primary)

                    Text("No family reward set")
                        .font(.custom("Quicksand", size: 20).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text("A parent can create a team reward and goal XP for the whole family.")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct HallOfHeroesSection: View {
    let entries: [FamilyLeaderboardEntry]

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Hall of Heroes")
                    .font(.custom("Quicksand", size: 30).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.primaryContainer)

                Text("Who will be the champion this week?")
                    .font(.custom("Quicksand", size: 14).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            }
            .multilineTextAlignment(.center)

            if entries.isEmpty {
                ParentSurfaceCard {
                    VStack(spacing: 12) {
                        Image(systemName: "leaderboard")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.primary)

                        Text("No approved quests yet")
                            .font(.custom("Quicksand", size: 20).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text("The leaderboard will fill in once heroes start earning approved XP.")
                            .font(.custom("Quicksand", size: 14).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 12)
                }
            } else {
                podium(entries: Array(entries.prefix(3)))

                VStack(spacing: 12) {
                    ForEach(entries) { entry in
                        leaderboardRow(entry: entry)
                    }
                }
            }
        }
    }

    private func podium(entries: [FamilyLeaderboardEntry]) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            if let secondPlace = entries.first(where: { $0.rank == 2 }) {
                podiumSlot(entry: secondPlace, height: 90, borderColor: ChoreQuestColors.outlineVariant, badgeBackground: ChoreQuestColors.outlineVariant, badgeForeground: ChoreQuestColors.onSurface)
            }

            if let firstPlace = entries.first(where: { $0.rank == 1 }) {
                podiumSlot(entry: firstPlace, height: 140, borderColor: ChoreQuestColors.secondary, badgeBackground: ChoreQuestColors.secondary, badgeForeground: ChoreQuestColors.secondaryText)
            }

            if let thirdPlace = entries.first(where: { $0.rank == 3 }) {
                podiumSlot(entry: thirdPlace, height: 70, borderColor: ChoreQuestColors.surfaceContainerHigh, badgeBackground: ChoreQuestColors.surfaceContainerHigh, badgeForeground: ChoreQuestColors.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func podiumSlot(entry: FamilyLeaderboardEntry, height: CGFloat, borderColor: Color, badgeBackground: Color, badgeForeground: Color) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                QuestProfileAvatar(
                    imageBase64: entry.imageBase64,
                    fallbackIconName: entry.avatarIconName,
                    fallbackColorHex: entry.avatarColorHex,
                    size: height > 100 ? 76 : 62,
                    borderColor: borderColor
                )

                Text("\(entry.rank)")
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .foregroundStyle(badgeForeground)
                    .frame(width: 24, height: 24)
                    .background(badgeBackground)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(entry.rank == 1 ? ChoreQuestColors.secondary : ChoreQuestColors.surfaceContainerHigh)
                .frame(width: height > 100 ? 110 : 90, height: height)
                .overlay(alignment: .top) {
                    VStack(spacing: 4) {
                        Text(entry.name)
                            .font(.custom("Quicksand", size: 16).weight(.bold))
                            .foregroundStyle(entry.rank == 1 ? ChoreQuestColors.secondaryText : ChoreQuestColors.onSurface)

                        Text("\(entry.totalXP) XP")
                            .font(.custom("Quicksand", size: 12).weight(.bold))
                            .foregroundStyle(entry.rank == 1 ? ChoreQuestColors.secondaryText : ChoreQuestColors.onSurfaceVariant)
                    }
                    .padding(.top, 12)
                }
        }
    }

    private func leaderboardRow(entry: FamilyLeaderboardEntry) -> some View {
        ParentSurfaceCard {
            HStack(spacing: 14) {
                Text("\(entry.rank)")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(entry.rank == 1 ? ChoreQuestColors.secondaryText : ChoreQuestColors.onSurfaceVariant)
                    .frame(width: 26)

                QuestProfileAvatar(
                    imageBase64: entry.imageBase64,
                    fallbackIconName: entry.avatarIconName,
                    fallbackColorHex: entry.avatarColorHex,
                    size: 48,
                    borderColor: entry.rank == 1 ? ChoreQuestColors.secondary : ChoreQuestColors.primaryFixed
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.custom("Quicksand", size: 18).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text("\(entry.completedQuestCount) Quests Completed")
                        .font(.custom("Quicksand", size: 12).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }

                Spacer()

                Text("+\(entry.totalXP) XP")
                    .font(.custom("Quicksand", size: 13).weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(entry.rank == 1 ? ChoreQuestColors.secondary : ChoreQuestColors.surfaceContainer)
                    .foregroundStyle(entry.rank == 1 ? ChoreQuestColors.secondaryText : ChoreQuestColors.onSurfaceVariant)
                    .clipShape(Capsule())
            }
        }
    }
}
