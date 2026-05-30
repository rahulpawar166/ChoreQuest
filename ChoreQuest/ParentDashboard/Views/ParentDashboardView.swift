//
//  ParentDashboardView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct ParentDashboardView: View {
    @ObservedObject var authStore: AuthStore
    @StateObject private var dashboardStore = ParentDashboardStore()

    @State private var selectedTab: ParentDashboardTab = .quests
    @State private var selectedHistorySnapshot: HeroHistorySnapshot?
    @State private var isPresentingFamilyEditor = false
    @State private var isPresentingFamilyRewardEditor = false
    @State private var selectedHeroForEditing: HeroProfile?
    private var snapshot: ParentDashboardSnapshot? {
        authStore.familyProfile.map { familyProfile in
            let familyProgress = FamilyProgressSnapshot.resolve(
                familyProfile: familyProfile,
                submissions: dashboardStore.submissions,
                quests: dashboardStore.quests,
                claims: dashboardStore.rewardClaims
            )

            return ParentDashboardSnapshot(
                familyProfile: familyProfile,
                quests: dashboardStore.quests,
                pendingApprovals: dashboardStore.pendingApprovals,
                pendingRewardClaims: dashboardStore.rewardClaims.filter { $0.status == .claimed },
                availableRewards: dashboardStore.rewards.filter(\.isActive),
                familyProgress: familyProgress
            )
        }
    }

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            if let snapshot {
                TabView(selection: $selectedTab) {
                    dashboardTabContent(snapshot: snapshot, tab: .quests)
                        .tag(ParentDashboardTab.quests)
                        .tabItem {
                            Label("Quests", systemImage: "checklist")
                        }

                    approvalsDashboardTab(snapshot: snapshot)

                    dashboardTabContent(snapshot: snapshot, tab: .heroes)
                        .tag(ParentDashboardTab.heroes)
                        .tabItem {
                            Label("Heroes", systemImage: "person.2")
                        }
                }
                .tint(ChoreQuestColors.primary)
                .safeAreaInset(edge: .bottom) {
                    if selectedTab == .quests {
                        HStack {
                            Spacer()

                            Button(action: {
                                dashboardStore.isPresentingCreateQuest = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, height: 60)
                                    .background(ChoreQuestColors.primary)
                                    .clipShape(Circle())
                                    .shadow(color: ChoreQuestColors.primary.opacity(0.28), radius: 18, y: 10)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 72)
                    }
                }
                .sheet(isPresented: $dashboardStore.isPresentingCreateQuest) {
                    if let familyProfile = authStore.familyProfile {
                        CreateQuestView(
                            familyProfile: familyProfile,
                            isSaving: dashboardStore.isSavingQuest
                        ) { input in
                            await dashboardStore.createQuest(input, heroes: familyProfile.heroes)
                        }
                    }
                }
                .sheet(isPresented: $dashboardStore.isPresentingCreateReward) {
                    if let familyProfile = authStore.familyProfile {
                        CreateRewardView(
                            familyID: familyProfile.id,
                            isSaving: dashboardStore.isSavingReward
                        ) { input in
                            await dashboardStore.createReward(input)
                        }
                    }
                }
            } else {
                ParentDashboardEmptyState(authStore: authStore)
            }
        }
        .navigationTitle("Chore Quest")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let snapshot {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresentingFamilyEditor = true
                    } label: {
                        QuestProfileAvatar(
                            imageBase64: snapshot.parentImageBase64,
                            fallbackIconName: "crown.fill",
                            fallbackColorHex: 0x630ed4,
                            size: 34,
                            borderColor: ChoreQuestColors.primaryFixed
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    selectedTab = .approvals
                }) {
                    Image(systemName: "bell")
                        .overlay(alignment: .topTrailing) {
                            if let snapshot, (snapshot.pendingApprovals.count + snapshot.pendingRewardClaims.count) > 0 {
                                Text("\(min(snapshot.pendingApprovals.count + snapshot.pendingRewardClaims.count, 9))")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .padding(2)
                                    .background(ChoreQuestColors.error)
                                    .clipShape(Capsule())
                                    .offset(x: 8, y: -8)
                            }
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
        .task(id: questLoadKey) {
            guard let familyProfile = authStore.familyProfile else {
                return
            }

            await dashboardStore.loadQuests(familyID: familyProfile.id, heroes: familyProfile.heroes)
        }
        .questToast(message: Binding(
            get: { dashboardStore.errorMessage ?? authStore.errorMessage },
            set: { newValue in
                dashboardStore.errorMessage = newValue
                authStore.errorMessage = newValue
            }
        ))
        .sheet(item: $selectedHistorySnapshot) { snapshot in
            NavigationStack {
                HeroHistoryView(snapshot: snapshot)
            }
        }
        .sheet(isPresented: $isPresentingFamilyEditor) {
            if let familyProfile = authStore.familyProfile {
                FamilyProfileEditorView(
                    familyProfile: familyProfile,
                    isSaving: authStore.isLoading
                ) { familyName, crestName, parentImageData in
                    await authStore.updateFamilyProfile(
                        familyName: familyName,
                        crestName: crestName,
                        parentImageData: parentImageData
                    )
                } onAddHero: { name, avatar, imageData in
                    await authStore.addHeroProfile(
                        name: name,
                        avatar: avatar,
                        imageData: imageData
                    )
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
        .sheet(isPresented: $isPresentingFamilyRewardEditor) {
            FamilyRewardEditorView(
                currentReward: authStore.familyProfile?.familyReward,
                isSaving: authStore.isLoading
            ) { title, goalXP in
                await authStore.updateFamilyReward(title: title, goalXP: goalXP)
            } onDelete: {
                await authStore.clearFamilyReward()
            }
        }
    }

    private func header(snapshot: ParentDashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The Commander's Desk")
                .font(.custom("Quicksand", size: 34).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Text("Reviewing \(snapshot.displayFamilyName)'s progress and keeping every hero on mission.")
                .font(.custom("Quicksand", size: 17).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func dashboardTabContent(snapshot: ParentDashboardSnapshot, tab: ParentDashboardTab) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                header(snapshot: snapshot)

                switch tab {
                case .quests:
                    questsTab(snapshot: snapshot)
                case .approvals:
                    approvalsTab(snapshot: snapshot)
                case .heroes:
                    heroesTab(snapshot: snapshot)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, tab == .quests ? 170 : 120)
        }
    }

    @ViewBuilder
    private func approvalsDashboardTab(snapshot: ParentDashboardSnapshot) -> some View {
        let approvalsCount = snapshot.pendingApprovals.count + snapshot.pendingRewardClaims.count

        if approvalsCount > 0 {
            dashboardTabContent(snapshot: snapshot, tab: .approvals)
                .tag(ParentDashboardTab.approvals)
                .tabItem {
                    Label("Approvals", systemImage: "checkmark.seal")
                }
                .badge(approvalsCount)
        } else {
            dashboardTabContent(snapshot: snapshot, tab: .approvals)
                .tag(ParentDashboardTab.approvals)
                .tabItem {
                    Label("Approvals", systemImage: "checkmark.seal")
                }
        }
    }

    private func questsTab(snapshot: ParentDashboardSnapshot) -> some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(snapshot.statCards) { stat in
                    ParentStatCard(stat: stat)
                }
            }

            HStack(spacing: 16) {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "flag.checkered.2.crossed")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Deploy New Quest")
                        .font(.custom("Quicksand", size: 24).weight(.bold))
                        .foregroundStyle(.white)

                    Text("Assign the next adventure to your squad, or leave it open so a hero can claim it.")
                        .font(.custom("Quicksand", size: 15).weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [ChoreQuestColors.primary, ChoreQuestColors.primaryContainer],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(ChoreQuestColors.primaryContainer.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: ChoreQuestColors.primary.opacity(0.18), radius: 22, y: 10)

            VStack(spacing: 16) {
                ParentSectionHeader(title: "Active Quests", actionTitle: nil, action: nil)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        staticChip(title: dashboardStore.isLoadingQuests ? "Loading Firestore Quests" : "Live Quest Records")
                    }
                    .padding(.vertical, 2)
                }

                if snapshot.activeQuests.isEmpty {
                    ParentSurfaceCard {
                        VStack(spacing: 12) {
                            Image(systemName: "checklist")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(ChoreQuestColors.primary)

                            Text("No quests loaded yet")
                                .font(.custom("Quicksand", size: 22).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurface)

                            Text(dashboardStore.isLoadingQuests ? "Loading quests from Firestore." : "Create the first quest and it will appear here from Firestore.")
                                .font(.custom("Quicksand", size: 15).weight(.medium))
                                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                } else {
                    VStack(spacing: 14) {
                        ForEach(snapshot.activeQuests) { quest in
                            ParentQuestRow(
                                quest: quest,
                                isAwaitingApproval: snapshot.awaitingApprovalQuestIDs.contains(quest.id)
                            )
                        }
                    }
                }
            }
        }
    }

    private func approvalsTab(snapshot: ParentDashboardSnapshot) -> some View {
        VStack(spacing: 16) {
            ParentSectionHeader(title: "Pending Approvals", actionTitle: nil, action: nil)

            if snapshot.pendingApprovals.isEmpty && snapshot.pendingRewardClaims.isEmpty {
                ParentSurfaceCard {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.tertiary)

                        Text("Nothing waiting right now")
                            .font(.custom("Quicksand", size: 22).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text("Completed quests and reward claims will show up here when heroes need your attention.")
                            .font(.custom("Quicksand", size: 15).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            } else {
                VStack(spacing: 16) {
                    ForEach(snapshot.pendingApprovals) { approval in
                        ParentApprovalCard(
                            approval: approval,
                            isUpdating: dashboardStore.isUpdatingApproval,
                            onApprove: {
                                await dashboardStore.approve(approval)
                            },
                            onReject: {
                                await dashboardStore.reject(approval)
                            }
                        )
                    }

                    ForEach(snapshot.pendingRewardClaims) { claim in
                        RewardClaimCard(
                            claim: claim,
                            hero: snapshot.heroes.first(where: { $0.id == claim.heroID }).map {
                                ParentAssignee(
                                    name: $0.name,
                                    imageBase64: $0.imageBase64,
                                    avatarIconName: $0.avatarIconName,
                                    avatarColorHex: $0.avatarColorHex
                                )
                            },
                            isUpdating: dashboardStore.isUpdatingClaim,
                            onFulfill: {
                                await dashboardStore.fulfill(claim)
                            },
                            onReject: {
                                await dashboardStore.reject(claim)
                            }
                        )
                    }
                }
            }
        }
    }

    private func heroesTab(snapshot: ParentDashboardSnapshot) -> some View {
        VStack(spacing: 20) {
            ParentSurfaceCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.secondaryText)
                            .frame(width: 52, height: 52)
                            .background(ChoreQuestColors.secondary)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(snapshot.displayFamilyName)
                                .font(.custom("Quicksand", size: 22).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurface)

                            Text("\(snapshot.heroes.count) hero profiles loaded from Firestore.")
                                .font(.custom("Quicksand", size: 15).weight(.medium))
                                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        }

                        Spacer()

                        Text(snapshot.crestName)
                            .font(.custom("Quicksand", size: 12).weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(ChoreQuestColors.secondary)
                            .foregroundStyle(ChoreQuestColors.secondaryText)
                            .clipShape(Capsule())
                    }

                    Button("Manage Family Squad") {
                        isPresentingFamilyEditor = true
                    }
                        .buttonStyle(ParentActionPillStyle(background: ChoreQuestColors.primary, foreground: .white))
                }
            }

            ParentSectionHeader(title: "Rewards", actionTitle: "Create Reward") {
                dashboardStore.isPresentingCreateReward = true
            }

            if snapshot.availableRewards.isEmpty {
                ParentSurfaceCard {
                    VStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.primary)

                        Text("No rewards yet")
                            .font(.custom("Quicksand", size: 22).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text("Create a reward so heroes can spend their XP.")
                            .font(.custom("Quicksand", size: 15).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            } else {
                VStack(spacing: 14) {
                    ForEach(snapshot.availableRewards) { reward in
                        FamilyRewardCard(
                            reward: reward,
                            isDeleting: dashboardStore.deletingRewardID == reward.id
                        ) {
                            await dashboardStore.deleteReward(reward)
                        }
                    }
                }
            }

            VStack(spacing: 16) {
                ParentSectionHeader(
                    title: "Family-Wide Reward",
                    actionTitle: snapshot.familyProgress.rewardProgress == nil ? "Create Reward" : "Edit Reward"
                ) {
                    isPresentingFamilyRewardEditor = true
                }

                FamilyRewardProgressCard(progress: snapshot.familyProgress.rewardProgress)
            }

            ParentSectionHeader(title: "Your Heroes", actionTitle: nil, action: nil)

            HallOfHeroesSection(entries: snapshot.familyProgress.leaderboard)

            if snapshot.heroes.isEmpty {
                ParentSurfaceCard {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.primary)

                        Text("No hero profiles found")
                            .font(.custom("Quicksand", size: 22).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text("Add kids during onboarding and they will appear here from the saved family document.")
                            .font(.custom("Quicksand", size: 15).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            } else {
                VStack(spacing: 16) {
                    ForEach(snapshot.heroes) { hero in
                        ParentHeroCard(
                            hero: hero,
                            onEditProfile: {
                                selectedHeroForEditing = authStore.familyProfile?.heroes.first(where: { $0.id == hero.id })
                            }
                        ) {
                            guard let familyProfile = authStore.familyProfile else { return }
                            selectedHistorySnapshot = HeroHistorySnapshot.resolve(
                                familyProfile: familyProfile,
                                heroID: hero.id,
                                quests: dashboardStore.quests,
                                submissions: dashboardStore.submissions,
                                claims: dashboardStore.rewardClaims
                            )
                        }
                    }
                }
            }

            ParentSurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Family Stats")
                        .font(.custom("Quicksand", size: 22).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.primary)

                    HStack {
                        familyStatColumn(title: "Heroes", value: "\(snapshot.familyStats.heroCount)", tint: ChoreQuestColors.primary)
                        Divider()
                            .frame(height: 46)
                        familyStatColumn(title: "Crest", value: snapshot.familyStats.crestName, tint: ChoreQuestColors.secondaryText)
                        Divider()
                            .frame(height: 46)
                        familyStatColumn(title: "Family", value: snapshot.familyStats.familyName, tint: ChoreQuestColors.tertiary)
                    }
                }
            }
        }
    }

    private func staticChip(title: String) -> some View {
        Text(title)
            .font(.custom("Quicksand", size: 13).weight(.bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ChoreQuestColors.surfaceContainerHighest)
            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            .clipShape(Capsule())
    }

    private var questLoadKey: String {
        let familyID = authStore.familyProfile?.id ?? "no-family"
        let heroCount = authStore.familyProfile?.heroes.count ?? 0
        return "\(familyID)-\(heroCount)"
    }

    private func familyStatColumn(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.custom("Quicksand", size: 12).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

            Text(value)
                .font(.custom("Quicksand", size: 28).weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ParentDashboardEmptyState: View {
    @ObservedObject var authStore: AuthStore

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 58, weight: .bold))
                .foregroundStyle(ChoreQuestColors.primary)

            Text("Parent dashboard is waiting on family data.")
                .font(.custom("Quicksand", size: 24).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Text("If the Firestore family record is missing, run setup again and this screen will fill in from the saved family profile.")
                .font(.custom("Quicksand", size: 16).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                .multilineTextAlignment(.center)

            Button("Sign Out") {
                authStore.signOut()
            }
            .buttonStyle(QuestPrimaryButtonStyle())
        }
        .padding(24)
    }
}
