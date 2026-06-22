//
//  KidDashboardView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct KidDashboardView: View {
    @ObservedObject var authStore: AuthStore
    @StateObject private var store = KidDashboardStore()
    @State private var submissionQuest: FamilyQuest?
    @State private var isPresentingHistory = false
    @State private var selectedHeroForEditing: HeroProfile?
    @State private var isHeroFloating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var familyProfile: FamilyProfile? {
        authStore.familyProfile
    }

    private var snapshot: KidDashboardSnapshot? {
        guard let familyProfile else { return nil }
        return KidDashboardSnapshot.resolve(
            from: familyProfile,
            quests: store.quests,
            submissions: store.submissions,
            rewards: store.rewards,
            claims: store.rewardClaims,
            selectedHeroID: authStore.userProfile?.selectedHeroID
        )
    }

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            if let familyProfile {
                if let snapshot {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 22) {
                            heroHeader(snapshot: snapshot)
                            assignedQuestsSection(snapshot: snapshot, familyProfile: familyProfile)
                            claimableQuestsSection(snapshot: snapshot, familyProfile: familyProfile)
                            rewardsSection(snapshot: snapshot)
                            availableRewardsSection(snapshot: snapshot, familyProfile: familyProfile)
                            leaderboardSection(snapshot: snapshot)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 40)
                    }
                } else {
                    KidDashboardLinkRequiredView(authStore: authStore)
                }
            } else {
                KidDashboardLinkRequiredView(authStore: authStore)
            }
        }
        .navigationTitle("Hero's Quest Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let snapshot {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        selectedHeroForEditing = snapshot.hero
                    } label: {
                        QuestProfileAvatar(
                            imageBase64: snapshot.hero.imageBase64,
                            fallbackIconName: snapshot.hero.avatarIconName,
                            fallbackColorHex: snapshot.hero.avatarColorHex,
                            size: 34,
                            borderColor: ChoreQuestColors.primaryFixed
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if snapshot != nil {
                    Button {
                        isPresentingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                }

                Menu {
                    Button("Switch Device Role", systemImage: "arrow.triangle.2.circlepath") {
                        Task {
                            await authStore.clearSelectedRole()
                        }
                    }

                    Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
                        authStore.signOut()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isHeroFloating = true
            }
        }
        .task(id: questLoadKey) {
            guard let familyProfile, let heroID = snapshot?.hero.id else { return }
            await store.loadDashboard(familyID: familyProfile.id, heroID: heroID, heroes: familyProfile.heroes)
        }
        .questToast(message: Binding(
            get: { store.errorMessage ?? authStore.errorMessage },
            set: { newValue in
                store.errorMessage = newValue
                authStore.errorMessage = newValue
            }
        ))
        .sheet(item: $submissionQuest) { quest in
            if let familyProfile, let snapshot {
                NavigationStack {
                    KidQuestSubmissionView(
                        quest: quest,
                        hero: snapshot.hero,
                        familyName: snapshot.displayFamilyName,
                        isSubmitting: store.isSubmittingProof
                    ) { imageData in
                        await store.submitProof(
                            for: quest,
                            hero: snapshot.hero,
                            proofImageData: imageData,
                            familyID: familyProfile.id,
                            heroes: familyProfile.heroes
                        )
                    }
                }
            }
        }
        .sheet(
            isPresented: $isPresentingHistory,
            onDismiss: { isPresentingHistory = false }
        ) {
            if let familyProfile, let snapshot {
                NavigationStack {
                    if let historySnapshot = HeroHistorySnapshot.resolve(
                        familyProfile: familyProfile,
                        heroID: snapshot.hero.id,
                        quests: store.quests,
                        submissions: store.submissions,
                        claims: store.rewardClaims
                    ) {
                        HeroHistoryView(snapshot: historySnapshot)
                    }
                }
            }
        }
        .sheet(item: $selectedHeroForEditing) { hero in
            HeroProfileEditorView(
                hero: hero,
                isSaving: authStore.isLoading
            ) { name, avatar, imageData in
                await authStore.updateHeroProfile(
                    heroID: hero.id,
                    name: name,
                    avatar: avatar,
                    imageData: imageData
                )
            }
        }
    }

    private func heroHeader(snapshot: KidDashboardSnapshot) -> some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                ChoreQuestColors.heroGradient

                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 150, height: 150)
                    .offset(x: 46, y: -62)

                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.secondary)
                    .padding(20)
                    .rotationEffect(.degrees(isHeroFloating ? 12 : -8))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 16) {
                        Button {
                            selectedHeroForEditing = snapshot.hero
                        } label: {
                            QuestProfileAvatar(
                                imageBase64: snapshot.hero.imageBase64,
                                fallbackIconName: snapshot.hero.avatarIconName,
                                fallbackColorHex: snapshot.hero.avatarColorHex,
                                size: 78,
                                borderColor: ChoreQuestColors.secondary
                            )
                            .background(.white, in: RoundedRectangle(cornerRadius: 27, style: .continuous))
                            .shadow(color: .black.opacity(0.16), radius: 0, y: 5)
                            .offset(y: isHeroFloating ? -4 : 3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens hero profile editor")

                        VStack(alignment: .leading, spacing: 5) {
                            Text("READY FOR ADVENTURE?")
                                .font(.custom("Quicksand", size: 11).weight(.heavy))
                                .foregroundStyle(ChoreQuestColors.secondary)
                                .tracking(0.8)

                            Text("Hi, \(snapshot.hero.name)! 👋")
                                .font(.custom("Quicksand", size: 28).weight(.bold))
                                .foregroundStyle(.white)

                            Text(snapshot.hero.levelTitle)
                                .font(.custom("Quicksand", size: 13).weight(.bold))
                                .foregroundStyle(.white.opacity(0.86))
                        }
                    }

                    HStack(spacing: 10) {
                        heroStat(icon: "bolt.fill", value: "\(snapshot.heroXP)", label: "XP", color: ChoreQuestColors.secondary)
                        heroStat(icon: "checkmark.seal.fill", value: "\(snapshot.heroApprovedQuestCount)", label: "DONE", color: ChoreQuestColors.tertiaryFixed)
                        heroStat(icon: "map.fill", value: "\(snapshot.assignedQuestCount)", label: "QUESTS", color: ChoreQuestColors.skyContainer)
                    }
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(.white.opacity(0.26), lineWidth: 2)
            }
            .shadow(color: ChoreQuestColors.primary.opacity(0.28), radius: 0, y: 7)
            .shadow(color: ChoreQuestColors.primary.opacity(0.18), radius: 22, y: 12)

            if snapshot.heroes.count > 1 {
                heroSwitcher(snapshot: snapshot)
            }
        }
    }

    private func heroStat(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(value)
                .font(.custom("Quicksand", size: 16).weight(.bold))
                .foregroundStyle(.white)

            Text(label)
                .font(.custom("Quicksand", size: 9).weight(.heavy))
                .foregroundStyle(.white.opacity(0.74))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.14))
        .clipShape(Capsule())
    }

    private func heroSwitcher(snapshot: KidDashboardSnapshot) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(snapshot.heroes) { hero in
                    Button(action: {
                        Task {
                            await authStore.selectHero(hero.id)
                        }
                    }) {
                        HStack(spacing: 10) {
                            QuestProfileAvatar(
                                imageBase64: hero.imageBase64,
                                fallbackIconName: hero.avatarIconName,
                                fallbackColorHex: hero.avatarColorHex,
                                size: 42,
                                borderColor: snapshot.hero.id == hero.id ? ChoreQuestColors.secondary : ChoreQuestColors.surfaceContainerLowest
                            )

                            Text(hero.name)
                                .font(.custom("Quicksand", size: 13).weight(.bold))
                                .foregroundStyle(snapshot.hero.id == hero.id ? ChoreQuestColors.primary : ChoreQuestColors.onSurfaceVariant)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(snapshot.hero.id == hero.id ? ChoreQuestColors.surfaceContainerLow : ChoreQuestColors.surfaceContainerLowest)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(authStore.isLoading)
                }
            }
        }
    }

    private func assignedQuestsSection(snapshot: KidDashboardSnapshot, familyProfile: FamilyProfile) -> some View {
        VStack(spacing: 16) {
            KidSectionHeader(title: "Your Adventures", subtitle: "Pick a quest and earn XP!", icon: "map.fill", color: ChoreQuestColors.primary)

            if snapshot.assignedQuests.isEmpty {
                KidDashboardEmptyCard(
                    icon: "sparkles",
                    title: "No active quests yet",
                    message: "When a parent assigns quests to this hero, they will appear here."
                )
            } else {
                VStack(spacing: 14) {
                    ForEach(snapshot.assignedQuests) { quest in
                        KidAssignedQuestCard(
                            quest: quest,
                            submission: snapshot.latestSubmissionByQuestID[quest.id],
                            isUpdating: store.isUpdatingQuest,
                            onSubmitProof: {
                                submissionQuest = quest
                            }
                        ) {
                            await store.rejectQuest(quest, heroID: snapshot.hero.id, familyID: familyProfile.id, heroes: familyProfile.heroes)
                        }
                    }
                }
            }
        }
    }

    private func claimableQuestsSection(snapshot: KidDashboardSnapshot, familyProfile: FamilyProfile) -> some View {
        VStack(spacing: 16) {
            KidSectionHeader(title: "Bonus Quests", subtitle: "Grab one before another hero does!", icon: "flag.checkered", color: ChoreQuestColors.coral)

            if snapshot.claimableQuests.isEmpty {
                KidDashboardEmptyCard(
                    icon: "flag.checkered.2.crossed",
                    title: "No open quests right now",
                    message: "Parents can leave quests open so any hero can claim them."
                )
            } else {
                VStack(spacing: 14) {
                    ForEach(snapshot.claimableQuests) { quest in
                        KidClaimableQuestCard(
                            quest: quest,
                            isUpdating: store.isUpdatingQuest
                        ) {
                            await store.claimQuest(quest, hero: snapshot.hero, familyID: familyProfile.id, heroes: familyProfile.heroes)
                        }
                    }
                }
            }
        }
    }

    private func rewardsSection(snapshot: KidDashboardSnapshot) -> some View {
        VStack(spacing: 16) {
            KidSectionHeader(title: "Power-Up Progress", subtitle: "Every quest makes you stronger", icon: "bolt.fill", color: ChoreQuestColors.secondaryText)

            FamilyRewardProgressCard(progress: snapshot.familyProgress.rewardProgress)

            ParentSurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        heroRewardBadge(title: "Total XP", value: "\(snapshot.heroXP)", tint: ChoreQuestColors.secondaryText, background: ChoreQuestColors.secondary)
                        heroRewardBadge(title: "Approved", value: "\(snapshot.heroApprovedQuestCount)", tint: ChoreQuestColors.tertiaryText, background: ChoreQuestColors.tertiaryFixed)
                    }

                    Text("Track your earned XP and how many quests a parent has approved.")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }
            }
        }
    }

    private func availableRewardsSection(snapshot: KidDashboardSnapshot, familyProfile: FamilyProfile) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Reward Shop")
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text("\(snapshot.rewards.count)")
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ChoreQuestColors.surfaceContainerLow)
                    .foregroundStyle(ChoreQuestColors.primary)
                    .clipShape(Capsule())

                Spacer()
            }

            if snapshot.rewards.isEmpty {
                KidDashboardEmptyCard(
                    icon: "gift.fill",
                    title: "No shop rewards yet",
                    message: "Ask a parent to add rewards that heroes can claim with XP."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(snapshot.rewards) { reward in
                            KidRewardCard(
                                reward: reward,
                                availableXP: snapshot.heroXP,
                                latestClaim: snapshot.rewardClaims.first(where: { $0.rewardID == reward.id }),
                                isClaiming: store.isClaimingReward
                            ) {
                                await store.claimReward(
                                    reward,
                                    hero: snapshot.hero,
                                    availableXP: snapshot.heroXP,
                                    familyID: familyProfile.id
                                )
                            }
                            .frame(width: 312)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func leaderboardSection(snapshot: KidDashboardSnapshot) -> some View {
        HallOfHeroesSection(entries: snapshot.familyProgress.leaderboard)
    }

    private func statBadge(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.custom("Quicksand", size: 10).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            Text(value)
                .font(.custom("Quicksand", size: 20).weight(.bold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ChoreQuestColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func heroRewardBadge(title: String, value: String, tint: Color, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom("Quicksand", size: 12).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

            Text(value)
                .font(.custom("Quicksand", size: 24).weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(background.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var questLoadKey: String {
        let familyID = familyProfile?.id ?? "no-family"
        let selectedHeroID = authStore.userProfile?.selectedHeroID ?? "no-hero"
        return "\(familyID)-\(selectedHeroID)"
    }
}

private struct KidRewardCard: View {
    let reward: FamilyReward
    let availableXP: Int
    let latestClaim: RewardClaim?
    let isClaiming: Bool
    let onClaim: () async -> Bool
    @State private var isShowingClaimConfirmation = false

    private var canClaim: Bool {
        guard availableXP >= reward.costXP else { return false }

        switch latestClaim?.status {
        case .none, .rejected:
            return true
        case .claimed, .fulfilled:
            return false
        }
    }

    private var buttonTitle: String {
        switch latestClaim?.status {
        case .none:
            return "Claim Reward"
        case .claimed:
            return "Claim Submitted"
        case .fulfilled:
            return "Claim Approved"
        case .rejected:
            return "Claim Again"
        }
    }

    private var buttonStyleConfiguration: (background: Color, foreground: Color) {
        switch latestClaim?.status {
        case .fulfilled:
            return (ChoreQuestColors.tertiary, .white)
        case .claimed:
            return (ChoreQuestColors.surfaceContainerHigh, ChoreQuestColors.onSurfaceVariant)
        default:
            return (ChoreQuestColors.primary, .white)
        }
    }

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Circle()
                        .fill(ChoreQuestColors.secondary)
                        .frame(width: 54, height: 54)
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

                if let latestClaim {
                    Text(statusMessage(for: latestClaim))
                        .font(.custom("Quicksand", size: 12).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                } else {
                    Text(canClaim ? "Ready to claim." : "Earn \(max(reward.costXP - availableXP, 0)) more XP to unlock.")
                        .font(.custom("Quicksand", size: 12).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }

                Button {
                    isShowingClaimConfirmation = true
                } label: {
                    Label(buttonTitle, systemImage: latestClaim?.status == .fulfilled ? "checkmark.seal.fill" : "gift.fill")
                }
                .buttonStyle(
                    ParentActionPillStyle(
                        background: buttonStyleConfiguration.background,
                        foreground: buttonStyleConfiguration.foreground
                    )
                )
                .disabled(!canClaim || isClaiming || latestClaim?.status == .fulfilled)
                .opacity((canClaim || latestClaim?.status == .fulfilled) ? 1 : 0.6)
            }
        }
        .alert("Claim Reward?", isPresented: $isShowingClaimConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Claim") {
                Task { _ = await onClaim() }
            }
        } message: {
            Text("This will reserve \(reward.costXP) XP for \(reward.title).")
        }
    }

    private func statusMessage(for claim: RewardClaim) -> String {
        switch claim.status {
        case .claimed: return "Claim sent to parent. XP is reserved."
        case .fulfilled: return "Reward granted by parent."
        case .rejected:
            if let parentComment = claim.parentComment, !parentComment.isEmpty {
                return "Claim rejected: \(parentComment)"
            }
            return "Claim was rejected."
        }
    }
}

private struct KidAssignedQuestCard: View {
    let quest: FamilyQuest
    let submission: KidQuestSubmission?
    let isUpdating: Bool
    let onSubmitProof: () -> Void
    let onReject: () async -> Void

    private var isDailyQuestLockedForToday: Bool {
        guard
            quest.frequency == .daily,
            let submission,
            submission.status == .approved,
            let approvalDate = submission.updatedAt ?? submission.createdAt
        else {
            return false
        }

        return Calendar.current.isDateInToday(approvalDate)
    }

    private var canSubmitProof: Bool {
        !isUpdating && !isDailyQuestLockedForToday
    }

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(categoryColors.background)
                        .frame(width: 62, height: 62)
                        .overlay {
                            Image(systemName: quest.category.iconName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(categoryColors.foreground)
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(quest.title)
                            .font(.custom("Quicksand", size: 18).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

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

                            Text(quest.frequency.title)
                                .font(.custom("Quicksand", size: 12).weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ChoreQuestColors.tertiaryFixed)
                                .foregroundStyle(ChoreQuestColors.tertiaryText)
                                .clipShape(Capsule())
                        }
                    }
                }

                HStack {
                    Text("\(quest.xpValue) XP")
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ChoreQuestColors.secondary)
                        .foregroundStyle(ChoreQuestColors.secondaryText)
                        .clipShape(Capsule())

                    Spacer()

                    if let submission {
                        Text(submission.status.title)
                            .font(.custom("Quicksand", size: 12).weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(submissionBadgeBackground(for: submission.status))
                            .foregroundStyle(submissionBadgeForeground(for: submission.status))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        onSubmitProof()
                    } label: {
                        Label(submitButtonTitle, systemImage: isDailyQuestLockedForToday ? "checkmark.seal.fill" : "camera.fill")
                    }
                    .buttonStyle(ParentActionPillStyle(background: ChoreQuestColors.primary, foreground: .white))
                    .disabled(!canSubmitProof)

                    if case .hero = quest.assignment {
                        Button("Reject") {
                            Task { await onReject() }
                        }
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.error)
                        .disabled(isUpdating)
                    }
                }

                if let submission {
                    Text(submissionStatusMessage(submission))
                        .font(.custom("Quicksand", size: 12).weight(.medium))
                        .foregroundStyle(submission.status == .rejected ? ChoreQuestColors.errorText : ChoreQuestColors.onSurfaceVariant)
                }

                if isDailyQuestLockedForToday {
                    Label("Daily quest already approved for today", systemImage: "checkmark.seal.fill")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.tertiaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(ChoreQuestColors.tertiaryFixed)
                        .clipShape(Capsule())
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard canSubmitProof else { return }
            onSubmitProof()
        }
        .opacity(isUpdating ? 0.72 : 1)
    }

    private func submissionBadgeBackground(for status: KidQuestSubmissionStatus) -> Color {
        switch status {
        case .pending:
            return ChoreQuestColors.surfaceContainerLow
        case .approved:
            return ChoreQuestColors.tertiaryFixed
        case .rejected:
            return ChoreQuestColors.errorContainer
        }
    }

    private func submissionBadgeForeground(for status: KidQuestSubmissionStatus) -> Color {
        switch status {
        case .pending:
            return ChoreQuestColors.primary
        case .approved:
            return ChoreQuestColors.tertiaryText
        case .rejected:
            return ChoreQuestColors.errorText
        }
    }

    private func submissionStatusMessage(_ submission: KidQuestSubmission) -> String {
        switch submission.status {
        case .pending:
            return "Your proof is waiting for parent approval."
        case .approved:
            if isDailyQuestLockedForToday {
                return "Approved for today. Come back tomorrow to complete this daily quest again."
            }
            return "Approved. The reward has been added to your total."
        case .rejected:
            if let parentComment = submission.parentComment, !parentComment.isEmpty {
                return "Redo required: \(parentComment)"
            }
            return "This proof was rejected. Update the chore and send a new photo."
        }
    }

    private var submitButtonTitle: String {
        if isDailyQuestLockedForToday {
            return "Done for Today"
        }

        return submission == nil ? "Send Proof" : "Update Proof"
    }

    private var categoryColors: (background: Color, foreground: Color) {
        switch quest.category {
        case .bedroom, .drawingRoom:
            return (ChoreQuestColors.primaryFixed, ChoreQuestColors.primary)
        case .kitchen, .laundry:
            return (ChoreQuestColors.coralContainer, ChoreQuestColors.coral)
        case .school, .basement:
            return (ChoreQuestColors.skyContainer, Color(hex: 0x087a9f))
        case .frontYard, .backYard:
            return (ChoreQuestColors.tertiaryFixed, ChoreQuestColors.tertiary)
        }
    }
}

private struct KidClaimableQuestCard: View {
    let quest: FamilyQuest
    let isUpdating: Bool
    let onClaim: () async -> Void

    var body: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(ChoreQuestColors.surfaceContainer)
                        .frame(width: 54, height: 54)
                        .overlay {
                            Image(systemName: quest.category.iconName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(ChoreQuestColors.secondaryText)
                        }

                    Spacer()

                    Text("\(quest.xpValue) XP")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ChoreQuestColors.secondary)
                        .foregroundStyle(ChoreQuestColors.secondaryText)
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(quest.title)
                        .font(.custom("Quicksand", size: 18).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(quest.details)
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }

                Button {
                    Task { await onClaim() }
                } label: {
                    Label("Start Adventure", systemImage: "flag.fill")
                }
                .buttonStyle(ParentActionPillStyle(background: ChoreQuestColors.primary, foreground: .white))
                .disabled(isUpdating)
            }
        }
        .opacity(isUpdating ? 0.72 : 1)
    }
}

private struct KidSectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .rotationEffect(.degrees(-4))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text(subtitle)
                    .font(.custom("Quicksand", size: 12).weight(.semibold))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            }

            Spacer()
        }
    }
}

private struct KidDashboardEmptyCard: View {
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

private struct KidDashboardLinkRequiredView: View {
    @ObservedObject var authStore: AuthStore

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 58, weight: .bold))
                .foregroundStyle(ChoreQuestColors.primary)

            Text("No hero profile is available yet.")
                .font(.custom("Quicksand", size: 24).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)
                .multilineTextAlignment(.center)

            Text("Add at least one hero in the family setup flow, then kid mode can open the quest dashboard.")
                .font(.custom("Quicksand", size: 16).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                .multilineTextAlignment(.center)

            Button("Switch Device Role") {
                Task {
                    await authStore.clearSelectedRole()
                }
            }
            .buttonStyle(QuestPrimaryButtonStyle())
        }
        .padding(24)
    }
}
