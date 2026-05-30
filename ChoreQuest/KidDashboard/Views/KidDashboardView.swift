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

    private var familyProfile: FamilyProfile? {
        authStore.familyProfile
    }

    private var snapshot: KidDashboardSnapshot? {
        guard let familyProfile else { return nil }
        return KidDashboardSnapshot.resolve(
            from: familyProfile,
            quests: store.quests,
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
                            topBar(snapshot: snapshot)
                            heroHeader(snapshot: snapshot)
                            assignedQuestsSection(snapshot: snapshot, familyProfile: familyProfile)
                            claimableQuestsSection(snapshot: snapshot, familyProfile: familyProfile)
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
        .task(id: questLoadKey) {
            guard let familyProfile else { return }
            await store.loadQuests(familyID: familyProfile.id, heroes: familyProfile.heroes)
        }
        .questToast(message: Binding(
            get: { store.errorMessage ?? authStore.errorMessage },
            set: { newValue in
                store.errorMessage = newValue
                authStore.errorMessage = newValue
            }
        ))
    }

    private func topBar(snapshot: KidDashboardSnapshot) -> some View {
        HStack(spacing: 14) {
            HStack(spacing: 12) {
                QuestProfileAvatar(
                    imageBase64: snapshot.hero.imageBase64,
                    fallbackIconName: snapshot.hero.avatarIconName,
                    fallbackColorHex: snapshot.hero.avatarColorHex,
                    size: 48,
                    borderColor: ChoreQuestColors.primaryFixed
                )

                Text("Hero's Quest Log")
                    .font(.custom("Quicksand", size: 24).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.primary)
            }

            Spacer()

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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.primary)
                    .frame(width: 40, height: 40)
                    .background(ChoreQuestColors.surfaceContainerLowest.opacity(0.88))
                    .clipShape(Circle())
            }
        }
    }

    private func heroHeader(snapshot: KidDashboardSnapshot) -> some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snapshot.hero.levelTitle)
                            .font(.custom("Quicksand", size: 12).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.primary)

                        Text(snapshot.hero.name)
                            .font(.custom("Quicksand", size: 28).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text("\(snapshot.displayFamilyName)'s hero dashboard")
                            .font(.custom("Quicksand", size: 15).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    }

                    Spacer()

                    VStack(spacing: 10) {
                        statBadge(title: "Assigned", value: "\(snapshot.assignedQuestCount)", tint: ChoreQuestColors.primary)
                        statBadge(title: "Open", value: "\(snapshot.claimableQuestCount)", tint: ChoreQuestColors.secondaryText)
                    }
                }

                Text("Quest progress, proof uploads, and rewards will build on top of these Firestore quests.")
                    .font(.custom("Quicksand", size: 14).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                if snapshot.heroes.count > 1 {
                    heroSwitcher(snapshot: snapshot)
                }
            }
        }
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
            ParentSectionHeader(title: "Active Quests", actionTitle: nil, action: nil)

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
                            isUpdating: store.isUpdatingQuest
                        ) {
                            await store.rejectQuest(quest, familyID: familyProfile.id, heroes: familyProfile.heroes)
                        }
                    }
                }
            }
        }
    }

    private func claimableQuestsSection(snapshot: KidDashboardSnapshot, familyProfile: FamilyProfile) -> some View {
        VStack(spacing: 16) {
            ParentSectionHeader(title: "Claimable Bounties", actionTitle: nil, action: nil)

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

    private var questLoadKey: String {
        let familyID = familyProfile?.id ?? "no-family"
        let heroCount = familyProfile?.heroes.count ?? 0
        return "\(familyID)-\(heroCount)"
    }
}

private struct KidAssignedQuestCard: View {
    let quest: FamilyQuest
    let isUpdating: Bool
    let onReject: () async -> Void

    var body: some View {
        ParentSurfaceCard {
            HStack(alignment: .center, spacing: 16) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ChoreQuestColors.primaryFixed)
                    .frame(width: 62, height: 62)
                    .overlay {
                        Image(systemName: quest.category.iconName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.primary)
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

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 10) {
                    Text("\(quest.xpValue) XP")
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ChoreQuestColors.secondary)
                        .foregroundStyle(ChoreQuestColors.secondaryText)
                        .clipShape(Capsule())

                    if case .hero = quest.assignment {
                        Button("Reject") {
                            Task { await onReject() }
                        }
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.error)
                        .disabled(isUpdating)
                    }
                }
            }
        }
        .opacity(isUpdating ? 0.72 : 1)
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

                Button("Claim Quest") {
                    Task { await onClaim() }
                }
                .buttonStyle(ParentActionPillStyle(background: ChoreQuestColors.primary, foreground: .white))
                .disabled(isUpdating)
            }
        }
        .opacity(isUpdating ? 0.72 : 1)
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
