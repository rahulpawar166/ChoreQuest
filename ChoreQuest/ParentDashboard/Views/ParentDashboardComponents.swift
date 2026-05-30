//
//  ParentDashboardComponents.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI
import UIKit

struct QuestProfileAvatar: View {
    let imageBase64: String?
    let fallbackIconName: String
    let fallbackColorHex: UInt
    let size: CGFloat
    var borderColor: Color = .white

    var body: some View {
        Group {
            if let uiImage = decodedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                        .fill(Color(hex: fallbackColorHex).opacity(0.18))

                    Image(systemName: fallbackIconName)
                        .font(.system(size: size * 0.38, weight: .bold))
                        .foregroundStyle(Color(hex: fallbackColorHex))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .stroke(borderColor, lineWidth: 2)
        )
    }

    private var decodedImage: UIImage? {
        guard
            let imageBase64,
            let data = Data(base64Encoded: imageBase64),
            let image = UIImage(data: data)
        else {
            return nil
        }

        return image
    }
}

struct ParentSurfaceCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(ChoreQuestColors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(ChoreQuestColors.surfaceContainer.opacity(0.9), lineWidth: 1.5)
            )
            .shadow(color: ChoreQuestColors.primary.opacity(0.08), radius: 18, y: 8)
    }
}

struct ParentSectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Quicksand", size: 22).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.custom("Quicksand", size: 14).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.primary)
            }
        }
    }
}

struct ParentStatCard: View {
    let stat: ParentDashboardStat

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Image(systemName: stat.iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: stat.accentHex))
                        .frame(width: 46, height: 46)
                        .background(Color(hex: stat.accentHex).opacity(0.14))
                        .clipShape(Circle())

                    Spacer()

                    if let badgeText = stat.badgeText {
                        Text(badgeText)
                            .font(.custom("Quicksand", size: 11).weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(stat.accentHex == 0xffc329 ? ChoreQuestColors.secondary : ChoreQuestColors.errorContainer)
                            .foregroundStyle(stat.accentHex == 0xffc329 ? ChoreQuestColors.secondaryText : ChoreQuestColors.errorText)
                            .clipShape(Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.title)
                        .font(.custom("Quicksand", size: 18).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(stat.value)
                        .font(.custom("Quicksand", size: 26).weight(.bold))
                        .foregroundStyle(Color(hex: stat.accentHex))

                    Text(stat.subtitle)
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }
            }
        }
    }
}

struct ParentQuestRow: View {
    let quest: FamilyQuest
    let isAwaitingApproval: Bool

    var body: some View {
        ParentSurfaceCard {
            HStack(alignment: .center, spacing: 16) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 62, height: 62)
                    .overlay {
                        Image(systemName: quest.category.iconName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(iconForeground)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(quest.title)
                            .font(.custom("Quicksand", size: 18).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        if quest.isRecurring {
                            Text("RECURRING")
                                .font(.custom("Quicksand", size: 10).weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ChoreQuestColors.tertiaryFixed)
                                .foregroundStyle(ChoreQuestColors.tertiaryText)
                                .clipShape(Capsule())
                        }
                    }

                    Text(quest.details)
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                    HStack(spacing: 10) {
                        Text(quest.category.title)
                            .font(.custom("Quicksand", size: 12).weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(ChoreQuestColors.surfaceContainerLow)
                            .foregroundStyle(ChoreQuestColors.primary)
                            .clipShape(Capsule())

                        Text(quest.status.title)
                            .font(.custom("Quicksand", size: 12).weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(statusBackground)
                            .foregroundStyle(statusForeground)
                            .clipShape(Capsule())
                    }
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 10) {
                    assignmentView

                    Text("\(quest.xpValue) XP")
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ChoreQuestColors.secondary)
                        .foregroundStyle(ChoreQuestColors.secondaryText)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var iconBackground: Color {
        effectiveStatus == .open ? ChoreQuestColors.surfaceContainer : ChoreQuestColors.primaryFixed
    }

    private var iconForeground: Color {
        effectiveStatus == .open ? ChoreQuestColors.outline : ChoreQuestColors.primary
    }

    private var statusBackground: Color {
        switch effectiveStatus {
        case .assigned:
            return ChoreQuestColors.surfaceContainer
        case .inProgress:
            return ChoreQuestColors.primaryFixed
        case .awaitingProof:
            return ChoreQuestColors.secondary
        case .open:
            return ChoreQuestColors.errorContainer
        }
    }

    private var statusForeground: Color {
        switch effectiveStatus {
        case .assigned:
            return ChoreQuestColors.primary
        case .inProgress:
            return ChoreQuestColors.primary
        case .awaitingProof:
            return ChoreQuestColors.secondaryText
        case .open:
            return ChoreQuestColors.errorText
        }
    }

    private var effectiveStatus: ParentQuestStatus {
        isAwaitingApproval ? .awaitingProof : quest.status
    }

    @ViewBuilder
    private var assignmentView: some View {
        switch quest.assignment {
        case .unassigned:
            Text("Open to claim")
                .font(.custom("Quicksand", size: 13).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)
        case .everyone:
            Label("Everyone", systemImage: "person.3.fill")
                .font(.custom("Quicksand", size: 13).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
        case .hero(let hero):
            HStack(spacing: 8) {
                QuestProfileAvatar(
                    imageBase64: hero.imageBase64,
                    fallbackIconName: hero.avatarIconName,
                    fallbackColorHex: hero.avatarColorHex,
                    size: 30,
                    borderColor: ChoreQuestColors.surfaceContainerLowest
                )

                Text(hero.name)
                    .font(.custom("Quicksand", size: 13).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            }
        }
    }
}

struct ParentApprovalCard: View {
    let approval: ParentApproval
    let isUpdating: Bool
    let onApprove: () async -> Void
    let onReject: () async -> Void

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    HStack(spacing: 12) {
                        QuestProfileAvatar(
                            imageBase64: approval.hero.imageBase64,
                            fallbackIconName: approval.hero.avatarIconName,
                            fallbackColorHex: approval.hero.avatarColorHex,
                            size: 48,
                            borderColor: ChoreQuestColors.primaryFixed
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(approval.hero.name)
                                .font(.custom("Quicksand", size: 18).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurface)

                            Text(approval.heroLevelTitle)
                                .font(.custom("Quicksand", size: 12).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.primary)
                        }
                    }

                    Spacer()

                    Text("+\(approval.xp) XP")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ChoreQuestColors.secondary)
                        .foregroundStyle(ChoreQuestColors.secondaryText)
                        .clipShape(Capsule())
                }

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: approval.accentHex).opacity(0.18),
                                ChoreQuestColors.surfaceContainer
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 170)
                    .overlay(alignment: .topLeading) {
                        proofPreview
                    }

                HStack(spacing: 12) {
                    Button {
                        Task { await onApprove() }
                    } label: {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ParentActionPillStyle(background: ChoreQuestColors.tertiary, foreground: .white))
                    .disabled(isUpdating)

                    Button {
                        Task { await onReject() }
                    } label: {
                        Label("Reject", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ParentOutlinePillStyle())
                    .disabled(isUpdating)
                }
            }
        }
        .opacity(isUpdating ? 0.72 : 1)
    }

    @ViewBuilder
    private var proofPreview: some View {
        if let proofImage = decodedProofImage {
            ZStack(alignment: .topLeading) {
                Image(uiImage: proofImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                proofOverlayContent
            }
        } else {
            proofOverlayContent
        }
    }

    private var proofOverlayContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: approval.iconName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: approval.accentHex))

                Spacer()

                Text(approval.proofLabel)
                    .font(.custom("Quicksand", size: 11).weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.86))
                    .foregroundStyle(ChoreQuestColors.primary)
                    .clipShape(Capsule())
            }

            Spacer()

            Text(approval.choreTitle)
                .font(.custom("Quicksand", size: 20).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
        }
        .padding(18)
    }

    private var decodedProofImage: UIImage? {
        guard
            let data = Data(base64Encoded: approval.proofImageBase64),
            let image = UIImage(data: data)
        else {
            return nil
        }

        return image
    }
}

struct ParentHeroCard: View {
    let hero: ParentHeroSummary
    let onViewHistory: () -> Void

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    HStack(spacing: 14) {
                        QuestProfileAvatar(
                            imageBase64: hero.imageBase64,
                            fallbackIconName: hero.avatarIconName,
                            fallbackColorHex: hero.avatarColorHex,
                            size: 62,
                            borderColor: ChoreQuestColors.primaryFixed
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(hero.name)
                                .font(.custom("Quicksand", size: 20).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurface)

                            Text("LVL \(hero.levelValue)")
                                .font(.custom("Quicksand", size: 11).weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ChoreQuestColors.secondary)
                                .foregroundStyle(ChoreQuestColors.secondaryText)
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    Text(hero.levelTitle)
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(ChoreQuestColors.surfaceContainerLow)
                        .foregroundStyle(Color(hex: hero.avatarColorHex))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                HStack(spacing: 12) {
                    Text("Quest proof and reward claim history for this hero.")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                    Spacer()

                    Button("History", action: onViewHistory)
                        .buttonStyle(ParentActionPillStyle(background: ChoreQuestColors.primary, foreground: .white))
                }
            }
        }
    }
}

struct FamilyRewardCard: View {
    let reward: FamilyReward
    let isDeleting: Bool
    let onDelete: () async -> Void

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    Circle()
                        .fill(ChoreQuestColors.secondary)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: reward.iconName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(ChoreQuestColors.secondaryText)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.title)
                            .font(.custom("Quicksand", size: 18).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text(reward.details)
                            .font(.custom("Quicksand", size: 13).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    }

                    Spacer()

                    Text("\(reward.costXP) XP")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(ChoreQuestColors.secondary)
                        .foregroundStyle(ChoreQuestColors.secondaryText)
                        .clipShape(Capsule())
                }

                Button(role: .destructive) {
                    Task { await onDelete() }
                } label: {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .tint(ChoreQuestColors.errorText)
                        } else {
                            Image(systemName: "trash")
                        }
                        Text(isDeleting ? "Removing..." : "Remove Reward")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ParentOutlinePillStyle())
                .disabled(isDeleting)
            }
        }
        .opacity(isDeleting ? 0.72 : 1)
    }
}

struct RewardClaimCard: View {
    let claim: RewardClaim
    let hero: ParentAssignee?
    let isUpdating: Bool
    let onFulfill: () async -> Void
    let onReject: () async -> Void

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    if let hero {
                        QuestProfileAvatar(
                            imageBase64: hero.imageBase64,
                            fallbackIconName: hero.avatarIconName,
                            fallbackColorHex: hero.avatarColorHex,
                            size: 46,
                            borderColor: ChoreQuestColors.primaryFixed
                        )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(claim.heroName)
                            .font(.custom("Quicksand", size: 18).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)
                        Text("claimed \(claim.rewardTitle)")
                            .font(.custom("Quicksand", size: 13).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    }

                    Spacer()

                    Text("-\(claim.rewardCostXP) XP")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(ChoreQuestColors.errorContainer)
                        .foregroundStyle(ChoreQuestColors.errorText)
                        .clipShape(Capsule())
                }

                HStack(spacing: 12) {
                    Label(claim.rewardTitle, systemImage: claim.rewardIconName)
                        .font(.custom("Quicksand", size: 14).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(ChoreQuestColors.surfaceContainerLow)
                        .clipShape(Capsule())

                    Spacer()

                    Text(claim.status.title)
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.secondaryText)
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await onFulfill() }
                    } label: {
                        Label("Grant", systemImage: "gift.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ParentActionPillStyle(background: ChoreQuestColors.tertiary, foreground: .white))
                    .disabled(isUpdating)

                    Button {
                        Task { await onReject() }
                    } label: {
                        Label("Reject", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ParentOutlinePillStyle())
                    .disabled(isUpdating)
                }
            }
        }
        .opacity(isUpdating ? 0.72 : 1)
    }
}

struct ParentActionPillStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Quicksand", size: 14).weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(background)
            .clipShape(Capsule())
            .shadow(color: background.opacity(0.22), radius: 0, y: configuration.isPressed ? 0 : 4)
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ParentOutlinePillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Quicksand", size: 14).weight(.bold))
            .foregroundStyle(ChoreQuestColors.error)
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(ChoreQuestColors.surfaceContainerLowest)
            .overlay(
                Capsule()
                    .stroke(ChoreQuestColors.error, lineWidth: 2)
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
