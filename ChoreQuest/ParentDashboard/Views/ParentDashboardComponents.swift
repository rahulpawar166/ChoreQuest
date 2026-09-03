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
            .shadow(color: ChoreQuestColors.primary.opacity(0.11), radius: 0, y: 5)
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ParentSurfaceCard {
            HStack(alignment: .top, spacing: 16) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 62, height: 62)
                    .overlay {
                        Image(systemName: quest.category.iconName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(iconForeground)
                    }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(quest.title)
                            .font(.custom("Quicksand", size: 18).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)

                        Spacer(minLength: 0)

                        if quest.isRecurring {
                            recurringPill
                        }
                    }

                    Text(quest.details)
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .bottom, spacing: 12) {
                        HStack(spacing: 10) {
                            categoryPill
                            statusPill
                        }

                        Spacer(minLength: 12)

                        VStack(alignment: .trailing, spacing: 10) {
                            assignmentView
                            xpPill
                        }
                    }
                }
            }
        }
        }
        .buttonStyle(.plain)
    }

    private var recurringPill: some View {
        Text("RECURRING")
            .font(.custom("Quicksand", size: 10).weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ChoreQuestColors.tertiaryFixed)
            .foregroundStyle(ChoreQuestColors.tertiaryText)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
    }

    private var categoryPill: some View {
        Text(quest.category.title)
            .font(.custom("Quicksand", size: 12).weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ChoreQuestColors.surfaceContainerLow)
            .foregroundStyle(ChoreQuestColors.primary)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
    }

    private var statusPill: some View {
        Text(effectiveStatus.title)
            .font(.custom("Quicksand", size: 12).weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusBackground)
            .foregroundStyle(statusForeground)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
    }

    private var xpPill: some View {
        Text("\(quest.xpValue) XP")
            .font(.custom("Quicksand", size: 13).weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ChoreQuestColors.secondary)
            .foregroundStyle(ChoreQuestColors.secondaryText)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
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
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        case .everyone:
            Label("Everyone", systemImage: "person.3.fill")
                .font(.custom("Quicksand", size: 13).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
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
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}

struct ParentApprovalCard: View {
    let approval: ParentApproval
    let isUpdating: Bool
    let onApprove: () async -> Void
    let onReject: () -> Void
    @State private var isShowingProofPreview = false

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
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(approval.heroTitle)
                                .font(.custom("Quicksand", size: 12).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.primary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
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
                        .fixedSize(horizontal: true, vertical: false)
                }

                proofPanel

                reviewHeader
                approvalActionButtons
            }
        }
        .opacity(isUpdating ? 0.72 : 1)
        .fullScreenCover(isPresented: $isShowingProofPreview) {
            if let proofImage = decodedProofImage {
                ProofImagePreviewView(
                    image: proofImage,
                    title: approval.choreTitle
                )
            }
        }
    }

    private var proofPanel: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
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
            .frame(height: 180)
            .overlay {
                proofPreview
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .onTapGesture {
                if decodedProofImage != nil {
                    isShowingProofPreview = true
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(ChoreQuestColors.primaryFixed.opacity(0.7), lineWidth: 1)
            }
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
                    .fixedSize(horizontal: true, vertical: false)
            }

            Spacer()

            Text(approval.choreTitle)
                .font(.custom("Quicksand", size: 20).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
    }

    private var reviewHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ChoreQuestColors.tertiary)

            Text("Review proof")
                .font(.custom("Quicksand", size: 13).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Spacer()

            Text("Tap image to zoom")
                .font(.custom("Quicksand", size: 11).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ChoreQuestColors.surfaceContainerLow)
                .clipShape(Capsule())
        }
    }

    private var approvalActionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                approveButton
                rejectButton
            }

            VStack(spacing: 12) {
                approveButton
                rejectButton
            }
        }
    }

    private var approveButton: some View {
        Button {
            Task { await onApprove() }
        } label: {
            Label("Approve", systemImage: "checkmark.circle.fill")
                .font(.custom("Quicksand", size: 13).weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(ChoreQuestColors.tertiary)
        .disabled(isUpdating)
    }

    private var rejectButton: some View {
        Button {
            onReject()
        } label: {
            Label("Reject", systemImage: "xmark.circle")
                .font(.custom("Quicksand", size: 13).weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(ChoreQuestColors.error)
        .disabled(isUpdating)
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

private struct ProofImagePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let title: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ZoomableImageView(image: image)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Quicksand", size: 14).weight(.bold))
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let point = recognizer.location(in: imageView)
                let zoomScale = min(scrollView.maximumZoomScale, 2.5)
                let width = scrollView.bounds.width / zoomScale
                let height = scrollView.bounds.height / zoomScale
                let rect = CGRect(
                    x: point.x - width / 2,
                    y: point.y - height / 2,
                    width: width,
                    height: height
                )
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}

struct ParentHeroCard: View {
    let hero: ParentHeroSummary
    let onEditProfile: () -> Void
    let onViewHistory: () -> Void

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Button(action: onEditProfile) {
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

                                Text(hero.heroTitle)
                                    .font(.custom("Quicksand", size: 11).weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(ChoreQuestColors.secondary)
                                    .foregroundStyle(ChoreQuestColors.secondaryText)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                }

                HStack(spacing: 12) {
                    Text("Tap the avatar to edit this hero's profile.")
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
    let onReject: () -> Void

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
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
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("claimed \(claim.rewardTitle)")
                            .font(.custom("Quicksand", size: 13).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Text("-\(claim.rewardCostXP) XP")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(ChoreQuestColors.errorContainer)
                        .foregroundStyle(ChoreQuestColors.errorText)
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: false)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        rewardTitlePill
                        Spacer()
                        statusLabel
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        rewardTitlePill
                        statusLabel
                    }
                }

                rewardActionButtons
            }
        }
        .opacity(isUpdating ? 0.72 : 1)
    }

    private var rewardTitlePill: some View {
        Label(claim.rewardTitle, systemImage: claim.rewardIconName)
            .font(.custom("Quicksand", size: 14).weight(.bold))
            .foregroundStyle(ChoreQuestColors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ChoreQuestColors.surfaceContainerLow)
            .clipShape(Capsule())
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var statusLabel: some View {
        Text(claim.status.title)
            .font(.custom("Quicksand", size: 12).weight(.bold))
            .foregroundStyle(ChoreQuestColors.secondaryText)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var rewardActionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                grantButton
                rejectButton
            }

            VStack(spacing: 12) {
                grantButton
                rejectButton
            }
        }
    }

    private var grantButton: some View {
        Button {
            Task { await onFulfill() }
        } label: {
            Label("Grant", systemImage: "gift.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ParentActionPillStyle(background: ChoreQuestColors.tertiary, foreground: .white))
        .disabled(isUpdating)
    }

    private var rejectButton: some View {
        Button {
            onReject()
        } label: {
            Label("Reject", systemImage: "xmark.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ParentOutlinePillStyle())
        .disabled(isUpdating)
    }
}

struct ParentRejectionCommentView: View {
    let title: String
    let subtitle: String
    let isSaving: Bool
    let onSubmit: (String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ChoreQuestColors.background.ignoresSafeArea()
                QuestBackground()

                VStack(spacing: 20) {
                    ParentSurfaceCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(title)
                                .font(.custom("Quicksand", size: 24).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurface)

                            Text(subtitle)
                                .font(.custom("Quicksand", size: 14).weight(.medium))
                                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("COMMENT")
                                    .font(.custom("Quicksand", size: 12).weight(.bold))
                                    .foregroundStyle(ChoreQuestColors.primary)

                                ZStack(alignment: .topLeading) {
                                    if comment.isEmpty {
                                        Text("Tell them what needs to change.")
                                            .font(.custom("Quicksand", size: 16).weight(.medium))
                                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant.opacity(0.6))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 18)
                                    }

                                    TextEditor(text: $comment)
                                        .scrollContentBackground(.hidden)
                                        .padding(12)
                                        .frame(minHeight: 140)
                                        .foregroundStyle(ChoreQuestColors.onSurface)
                                }
                                .background(ChoreQuestColors.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(ChoreQuestColors.outlineVariant, lineWidth: 2)
                                )
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .navigationTitle("Reject with Comment")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await onSubmit(comment)
                            dismiss()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Reject")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
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
            .background {
                Capsule()
                    .fill(background)
                    .shadow(color: background.opacity(0.22), radius: 0, y: configuration.isPressed ? 0 : 4)
            }
            .contentShape(Capsule())
            .offset(y: configuration.isPressed ? 3 : 0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
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
