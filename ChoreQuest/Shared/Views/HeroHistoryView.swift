//
//  HeroHistoryView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI
import UIKit

struct HeroHistoryView: View {
    let snapshot: HeroHistorySnapshot

    @State private var previewImageBase64: String?

    var body: some View {
        ZStack {
            ChoreQuestColors.background.ignoresSafeArea()
            QuestBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    historyHeader
                    currentAssignmentsSection
                    questHistorySection
                    rewardHistorySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("\(snapshot.hero.name) History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(
            isPresented: Binding(
                get: { previewImageBase64 != nil },
                set: { isPresented in
                    if !isPresented { previewImageBase64 = nil }
                }
            )
        ) {
            if let imageBase64 = previewImageBase64 {
                NavigationStack {
                    HistoryImagePreviewView(imageBase64: imageBase64)
                }
            }
        }
    }

    private var historyHeader: some View {
        ParentSurfaceCard {
            HStack(spacing: 14) {
                QuestProfileAvatar(
                    imageBase64: snapshot.hero.imageBase64,
                    fallbackIconName: snapshot.hero.avatarIconName,
                    fallbackColorHex: snapshot.hero.avatarColorHex,
                    size: 68,
                    borderColor: ChoreQuestColors.primaryFixed
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.hero.name)
                        .font(.custom("Quicksand", size: 26).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(snapshot.hero.levelTitle)
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.primary)

                    Text("\(snapshot.displayFamilyName) history log")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }

                Spacer()
            }
        }
    }

    private var currentAssignmentsSection: some View {
        VStack(spacing: 16) {
            ParentSectionHeader(title: "Current Assignments", actionTitle: nil, action: nil)

            if snapshot.currentAssignedQuests.isEmpty {
                HistoryEmptyCard(
                    icon: "checklist",
                    title: "No active assignments",
                    message: "Current quests assigned to this hero will appear here."
                )
            } else {
                VStack(spacing: 14) {
                    ForEach(snapshot.currentAssignedQuests) { quest in
                        ParentSurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(ChoreQuestColors.primaryFixed)
                                        .frame(width: 52, height: 52)
                                        .overlay {
                                            Image(systemName: quest.category.iconName)
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundStyle(ChoreQuestColors.primary)
                                        }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(quest.title)
                                            .font(.custom("Quicksand", size: 18).weight(.bold))
                                            .foregroundStyle(ChoreQuestColors.onSurface)

                                        Text(quest.details)
                                            .font(.custom("Quicksand", size: 13).weight(.medium))
                                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Text("\(quest.xpValue) XP")
                                        .font(.custom("Quicksand", size: 12).weight(.bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(ChoreQuestColors.secondary)
                                        .foregroundStyle(ChoreQuestColors.secondaryText)
                                        .clipShape(Capsule())
                                }

                                HStack(spacing: 10) {
                                    historyPill(title: quest.category.title, background: ChoreQuestColors.surfaceContainerLow, foreground: ChoreQuestColors.primary)
                                    historyPill(title: quest.frequency.title, background: ChoreQuestColors.tertiaryFixed, foreground: ChoreQuestColors.tertiaryText)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var questHistorySection: some View {
        VStack(spacing: 16) {
            ParentSectionHeader(title: "Quest History", actionTitle: nil, action: nil)

            if snapshot.questHistory.isEmpty {
                HistoryEmptyCard(
                    icon: "photo.on.rectangle.angled",
                    title: "No quest history yet",
                    message: "Submitted chore proof will appear here with review timestamps."
                )
            } else {
                VStack(spacing: 14) {
                    ForEach(snapshot.questHistory) { item in
                        ParentSurfaceCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .top, spacing: 12) {
                                    Button {
                                        previewImageBase64 = item.proofImageBase64
                                    } label: {
                                        HistoryProofThumbnail(imageBase64: item.proofImageBase64)
                                    }
                                    .buttonStyle(.plain)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.questTitle)
                                            .font(.custom("Quicksand", size: 18).weight(.bold))
                                            .foregroundStyle(ChoreQuestColors.onSurface)

                                        HStack(spacing: 10) {
                                            historyPill(
                                                title: item.status.title,
                                                background: submissionBackground(for: item.status),
                                                foreground: submissionForeground(for: item.status)
                                            )
                                            historyPill(
                                                title: "+\(item.xpValue) XP",
                                                background: ChoreQuestColors.secondary,
                                                foreground: ChoreQuestColors.secondaryText
                                            )
                                        }
                                    }

                                    Spacer(minLength: 0)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    historyDateRow(title: "Submitted", date: item.submittedAt)
                                    if item.status != .pending {
                                        historyDateRow(title: item.status == .approved ? "Approved" : "Reviewed", date: item.reviewedAt)
                                    }
                                    if let parentComment = item.parentComment, !parentComment.isEmpty {
                                        Text(parentComment)
                                            .font(.custom("Quicksand", size: 13).weight(.medium))
                                            .foregroundStyle(item.status == .rejected ? ChoreQuestColors.errorText : ChoreQuestColors.onSurfaceVariant)
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(item.status == .rejected ? ChoreQuestColors.errorContainer : ChoreQuestColors.surfaceContainerLow)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var rewardHistorySection: some View {
        VStack(spacing: 16) {
            ParentSectionHeader(title: "Reward Claim History", actionTitle: nil, action: nil)

            if snapshot.rewardHistory.isEmpty {
                HistoryEmptyCard(
                    icon: "gift.fill",
                    title: "No reward claims yet",
                    message: "Claimed rewards will appear here with their status history."
                )
            } else {
                VStack(spacing: 14) {
                    ForEach(snapshot.rewardHistory) { item in
                        ParentSurfaceCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(ChoreQuestColors.secondary)
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: item.rewardIconName)
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundStyle(ChoreQuestColors.secondaryText)
                                        }

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.rewardTitle)
                                            .font(.custom("Quicksand", size: 18).weight(.bold))
                                            .foregroundStyle(ChoreQuestColors.onSurface)
                                        historyPill(
                                            title: item.status.title,
                                            background: rewardStatusBackground(for: item.status),
                                            foreground: rewardStatusForeground(for: item.status)
                                        )
                                    }

                                    Spacer()

                                    Text("-\(item.costXP) XP")
                                        .font(.custom("Quicksand", size: 12).weight(.bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(ChoreQuestColors.errorContainer)
                                        .foregroundStyle(ChoreQuestColors.errorText)
                                        .clipShape(Capsule())
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    historyDateRow(title: "Claimed", date: item.claimedAt)
                                    if item.status != .claimed {
                                        historyDateRow(title: item.status == .fulfilled ? "Granted" : "Reviewed", date: item.updatedAt)
                                    }
                                    if let parentComment = item.parentComment, !parentComment.isEmpty {
                                        Text(parentComment)
                                            .font(.custom("Quicksand", size: 13).weight(.medium))
                                            .foregroundStyle(item.status == .rejected ? ChoreQuestColors.errorText : ChoreQuestColors.onSurfaceVariant)
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(item.status == .rejected ? ChoreQuestColors.errorContainer : ChoreQuestColors.surfaceContainerLow)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func historyPill(title: String, background: Color, foreground: Color) -> some View {
        Text(title)
            .font(.custom("Quicksand", size: 12).weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(Capsule())
    }

    private func historyDateRow(title: String, date: Date?) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.custom("Quicksand", size: 12).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            Text(formatted(date))
                .font(.custom("Quicksand", size: 12).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurface)
        }
    }

    private func submissionBackground(for status: KidQuestSubmissionStatus) -> Color {
        switch status {
        case .pending: return ChoreQuestColors.surfaceContainerLow
        case .approved: return ChoreQuestColors.tertiaryFixed
        case .rejected: return ChoreQuestColors.errorContainer
        }
    }

    private func submissionForeground(for status: KidQuestSubmissionStatus) -> Color {
        switch status {
        case .pending: return ChoreQuestColors.primary
        case .approved: return ChoreQuestColors.tertiaryText
        case .rejected: return ChoreQuestColors.errorText
        }
    }

    private func rewardStatusBackground(for status: RewardClaimStatus) -> Color {
        switch status {
        case .claimed: return ChoreQuestColors.surfaceContainerLow
        case .fulfilled: return ChoreQuestColors.tertiaryFixed
        case .rejected: return ChoreQuestColors.errorContainer
        }
    }

    private func rewardStatusForeground(for status: RewardClaimStatus) -> Color {
        switch status {
        case .claimed: return ChoreQuestColors.primary
        case .fulfilled: return ChoreQuestColors.tertiaryText
        case .rejected: return ChoreQuestColors.errorText
        }
    }

    private func formatted(_ date: Date?) -> String {
        guard let date else { return "Not recorded yet" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

private struct HistoryProofThumbnail: View {
    let imageBase64: String

    var body: some View {
        Group {
            if let image = decodedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ChoreQuestColors.surfaceContainer)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.primary)
                    }
            }
        }
        .frame(width: 90, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var decodedImage: UIImage? {
        guard
            let data = Data(base64Encoded: imageBase64),
            let image = UIImage(data: data)
        else {
            return nil
        }

        return image
    }
}

private struct HistoryEmptyCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        ParentSurfaceCard {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.primary)

                Text(title)
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text(message)
                    .font(.custom("Quicksand", size: 15).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }
}

private struct HistoryImagePreviewView: View {
    let imageBase64: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = decodedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else {
                ContentUnavailableView("Image Unavailable", systemImage: "photo", description: Text("The proof image could not be loaded."))
                    .foregroundStyle(.white)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
    }

    private var decodedImage: UIImage? {
        guard
            let data = Data(base64Encoded: imageBase64),
            let image = UIImage(data: data)
        else {
            return nil
        }

        return image
    }
}
