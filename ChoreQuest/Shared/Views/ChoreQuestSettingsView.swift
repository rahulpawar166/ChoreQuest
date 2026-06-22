//
//  ChoreQuestSettingsView.swift
//  ChoreQuest
//

import SwiftUI
import UIKit

struct ChoreQuestSettingsView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var authStore: AuthStore

    let role: AppRole
    let selectedHero: HeroProfile?
    var onViewHistory: (() -> Void)?

    @AppStorage("appAnimationsEnabled") private var animationsEnabled = true
    @AppStorage("appHapticsEnabled") private var hapticsEnabled = true
    @State private var presentedSheet: SettingsSheet?
    @State private var isConfirmingRoleSwitch = false
    @State private var isConfirmingSignOut = false

    var body: some View {
        Form {
            profileHeader

            if role == .parent {
                parentManagementSection
            } else {
                kidProfileSection
            }

            appExperienceSection
            supportSection
            deviceAndAccountSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                ChoreQuestColors.background
                QuestBackground()
            }
            .ignoresSafeArea()
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .family(let familyProfile):
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
                    await authStore.addHeroProfile(name: name, avatar: avatar, imageData: imageData)
                }

            case .hero(let hero):
                HeroProfileEditorView(hero: hero, isSaving: authStore.isLoading) { name, avatar, imageData in
                    await authStore.updateHeroProfile(
                        heroID: hero.id,
                        name: name,
                        avatar: avatar,
                        imageData: imageData
                    )
                }

            case .familyReward(let reward):
                FamilyRewardEditorView(
                    currentReward: reward,
                    isSaving: authStore.isLoading
                ) { title, goalXP in
                    await authStore.updateFamilyReward(title: title, goalXP: goalXP)
                } onDelete: {
                    await authStore.clearFamilyReward()
                }
            }
        }
        .alert("Switch Device Mode?", isPresented: $isConfirmingRoleSwitch) {
            Button("Cancel", role: .cancel) {}
            Button("Switch Mode") {
                Task { await authStore.clearSelectedRole() }
            }
        } message: {
            Text("You will return to the Parent or Kid mode selection screen.")
        }
        .alert("Sign Out?", isPresented: $isConfirmingSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive, action: authStore.signOut)
        } message: {
            Text("This device will need the family account credentials to sign in again.")
        }
    }

    private var profileHeader: some View {
        Section {
            HStack(spacing: 16) {
                profileAvatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(profileName)
                        .font(.custom("Quicksand", size: 22).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(role == .parent ? "Parent mode" : selectedHero?.heroTitle ?? "Kid mode")
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.primary)

                    if let email = authStore.userProfile?.email, !email.isEmpty {
                        Text(email)
                            .font(.custom("Quicksand", size: 12).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if role == .kid, let selectedHero {
            QuestProfileAvatar(
                imageBase64: selectedHero.imageBase64,
                fallbackIconName: selectedHero.avatarIconName,
                fallbackColorHex: selectedHero.avatarColorHex,
                size: 64,
                borderColor: ChoreQuestColors.secondary
            )
        } else {
            QuestProfileAvatar(
                imageBase64: authStore.familyProfile?.parentImageBase64,
                fallbackIconName: "crown.fill",
                fallbackColorHex: 0x630ed4,
                size: 64,
                borderColor: ChoreQuestColors.primaryFixed
            )
        }
    }

    private var parentManagementSection: some View {
        Section("Family Management") {
            if let familyProfile = authStore.familyProfile {
                settingsButton(
                    title: "Family Profile & Kids",
                    subtitle: "Update the family name, crest, parent image, or add a child.",
                    icon: "person.3.fill",
                    color: ChoreQuestColors.primary
                ) {
                    presentedSheet = .family(familyProfile)
                }

                settingsButton(
                    title: familyProfile.familyReward == nil ? "Create Family Reward" : "Family Reward",
                    subtitle: "Set the shared XP goal and team reward.",
                    icon: "party.popper.fill",
                    color: ChoreQuestColors.coral
                ) {
                    presentedSheet = .familyReward(familyProfile.familyReward)
                }

                ForEach(familyProfile.heroes) { hero in
                    settingsButton(
                        title: hero.name,
                        subtitle: "Edit hero profile and avatar.",
                        icon: hero.avatarIconName,
                        color: Color(hex: hero.avatarColorHex)
                    ) {
                        presentedSheet = .hero(hero)
                    }
                }
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var kidProfileSection: some View {
        Section("Hero") {
            if let selectedHero {
                settingsButton(
                    title: "Edit My Profile",
                    subtitle: "Change your name, animal token, or photo.",
                    icon: "person.crop.circle.fill",
                    color: ChoreQuestColors.primary
                ) {
                    presentedSheet = .hero(selectedHero)
                }
            }

            if let onViewHistory {
                settingsButton(
                    title: "Activity History",
                    subtitle: "See submitted quests and reward claims.",
                    icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    color: ChoreQuestColors.sky
                ) {
                    onViewHistory()
                }
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var appExperienceSection: some View {
        Section("App Experience") {
            Toggle(isOn: $animationsEnabled) {
                Label("Playful Animations", systemImage: "sparkles")
            }
            .tint(ChoreQuestColors.primary)

            Toggle(isOn: $hapticsEnabled) {
                Label("Haptic Feedback", systemImage: "hand.tap.fill")
            }
            .tint(ChoreQuestColors.primary)

            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            } label: {
                settingsRow(
                    title: "System Permissions",
                    subtitle: "Manage camera and photo library access.",
                    icon: "gearshape.2.fill",
                    color: ChoreQuestColors.onSurfaceVariant
                )
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var deviceAndAccountSection: some View {
        Section("Account & Device") {
            settingsButton(
                title: "Switch Device Mode",
                subtitle: "Choose whether this device opens in Parent or Kid mode.",
                icon: "arrow.triangle.2.circlepath",
                color: ChoreQuestColors.primary
            ) {
                isConfirmingRoleSwitch = true
            }

            if role == .parent {
                NavigationLink {
                    ParentAccountSettingsView(authStore: authStore)
                } label: {
                    settingsRow(
                        title: "Parent Account",
                        subtitle: "Manage sign-in, account access, and family data.",
                        icon: "person.crop.circle.badge.checkmark",
                        color: ChoreQuestColors.primary
                    )
                }
            } else {
                Button(role: .destructive) {
                    isConfirmingSignOut = true
                } label: {
                    settingsRow(
                        title: "Sign Out",
                        subtitle: "Ask a parent before signing out.",
                        icon: "rectangle.portrait.and.arrow.right",
                        color: ChoreQuestColors.error,
                        titleColor: ChoreQuestColors.error
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink {
                PrivacyAndDataView()
            } label: {
                settingsRow(
                    title: "Privacy & Data",
                    subtitle: "Understand how family and proof data are used.",
                    icon: "hand.raised.fill",
                    color: ChoreQuestColors.tertiary
                )
            }

            NavigationLink {
                AboutChoreQuestView()
            } label: {
                settingsRow(
                    title: "About ChoreQuest",
                    subtitle: "App version and product information.",
                    icon: "info.circle.fill",
                    color: ChoreQuestColors.sky
                )
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var profileName: String {
        if role == .kid {
            return selectedHero?.name ?? "Hero"
        }
        return authStore.familyProfile?.familyName ?? "Family"
    }

    private func settingsButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            settingsRow(title: title, subtitle: subtitle, icon: icon, color: color, showsChevron: true)
        }
        .buttonStyle(.plain)
    }

    private func settingsRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        showsChevron: Bool = false,
        titleColor: Color = ChoreQuestColors.onSurface
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Quicksand", size: 15).weight(.bold))
                    .foregroundStyle(titleColor)

                Text(subtitle)
                    .font(.custom("Quicksand", size: 11).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ChoreQuestColors.outline)
            }
        }
        .contentShape(Rectangle())
    }
}

private enum SettingsSheet: Identifiable {
    case family(FamilyProfile)
    case hero(HeroProfile)
    case familyReward(FamilyGoalReward?)

    var id: String {
        switch self {
        case .family: return "family"
        case .hero(let hero): return "hero-\(hero.id)"
        case .familyReward: return "family-reward"
        }
    }
}

private struct ParentAccountSettingsView: View {
    @ObservedObject var authStore: AuthStore

    @State private var isConfirmingSignOut = false
    @State private var isPresentingDeleteAccount = false

    var body: some View {
        Form {
            Section("Parent Account") {
                LabeledContent("Email") {
                    Text(authStore.userProfile?.email ?? "Not available")
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .multilineTextAlignment(.trailing)
                }

                Button(role: .destructive) {
                    isConfirmingSignOut = true
                } label: {
                    accountRow(
                        title: "Sign Out",
                        subtitle: "Remove the family account from this device.",
                        icon: "rectangle.portrait.and.arrow.right"
                    )
                }
                .buttonStyle(.plain)
            }

            Section {
                Button(role: .destructive) {
                    isPresentingDeleteAccount = true
                } label: {
                    accountRow(
                        title: "Delete Account",
                        subtitle: "Permanently delete the account and all associated family data.",
                        icon: "trash.fill"
                    )
                }
                .buttonStyle(.plain)
            } header: {
                Text("Account Data")
            } footer: {
                Text("Account deletion requires the parent password and an additional confirmation.")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                ChoreQuestColors.background
                QuestBackground()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Parent Account")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isPresentingDeleteAccount) {
            DeleteAccountView(authStore: authStore)
        }
        .alert("Sign Out?", isPresented: $isConfirmingSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive, action: authStore.signOut)
        } message: {
            Text("This device will need the family account credentials to sign in again.")
        }
    }

    private func accountRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(ChoreQuestColors.error)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Quicksand", size: 15).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.error)

                Text(subtitle)
                    .font(.custom("Quicksand", size: 11).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct PrivacyAndDataView: View {
    var body: some View {
        Form {
            Section {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }

                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(ChoreQuestColors.background.ignoresSafeArea())
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct AboutChoreQuestView: View {
    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                appHeader
                missionCard

                VStack(alignment: .leading, spacing: 14) {
                    Text("How the adventure works")
                        .font(.custom("Quicksand", size: 20).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    aboutFeature(
                        title: "Parents create quests",
                        message: "Turn everyday responsibilities into clear, age-friendly missions.",
                        icon: "map.fill",
                        color: ChoreQuestColors.primary
                    )

                    aboutFeature(
                        title: "Kids share progress",
                        message: "Complete quests, submit proof, and choose how much XP to contribute.",
                        icon: "sparkles",
                        color: ChoreQuestColors.sky
                    )

                    aboutFeature(
                        title: "Families celebrate together",
                        message: "Approve wins, claim rewards, and work toward a shared family goal.",
                        icon: "party.popper.fill",
                        color: ChoreQuestColors.coral
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Made for growing teams, helpful habits, and plenty of high-fives.")
                    .font(.custom("Quicksand", size: 14).weight(.semibold))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(versionText)
                    .font(.custom("Quicksand", size: 13).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.outline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ChoreQuestColors.surfaceContainer)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background {
            ZStack {
                ChoreQuestColors.background
                QuestBackground()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }

    private var appHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ChoreQuestColors.secondary.opacity(0.25))
                    .frame(width: 172, height: 172)
                    .blur(radius: 16)

                Image("ChoreQuestLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148, height: 148)
                    .shadow(color: ChoreQuestColors.primary.opacity(0.2), radius: 20, y: 10)
            }

            Text("ChoreQuest")
                .font(.custom("Quicksand", size: 32).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Text("Little tasks. Big adventures.")
                .font(.custom("Quicksand", size: 16).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)
        }
        .frame(maxWidth: .infinity)
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Our mission", systemImage: "heart.fill")
                .font(.custom("Quicksand", size: 17).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)

            Text("ChoreQuest helps families turn everyday responsibilities into positive teamwork. Parents guide the adventure, kids build confidence through progress, and everyone gets a reason to celebrate together.")
                .font(.custom("Quicksand", size: 15).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ChoreQuestColors.primaryFixed.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func aboutFeature(title: String, message: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Quicksand", size: 16).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text(message)
                    .font(.custom("Quicksand", size: 13).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(ChoreQuestColors.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ChoreQuestColors.primaryFixed.opacity(0.7), lineWidth: 1)
        }
    }
}

private struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authStore: AuthStore

    @State private var password = ""
    @State private var confirmationText = ""

    private var canDelete: Bool {
        password.count >= 6 && confirmationText == "DELETE" && !authStore.isLoading
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("This cannot be undone")
                                .font(.custom("Quicksand", size: 17).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.error)

                            Text("Deleting the parent account permanently removes family profiles, quests, rewards, contribution history, submissions, and proof photos.")
                                .font(.custom("Quicksand", size: 13).weight(.medium))
                                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(ChoreQuestColors.error)
                    }
                }

                Section("Verify Parent Account") {
                    SecureField("Account password", text: $password)
                        .textContentType(.password)

                    TextField("Type DELETE to confirm", text: $confirmationText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                if let errorMessage = authStore.errorMessage {
                    Section {
                        ErrorBanner(message: errorMessage)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        deleteAccount()
                    } label: {
                        HStack {
                            Spacer()
                            if authStore.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(authStore.isLoading ? "Deleting Account..." : "Permanently Delete Account")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .disabled(!canDelete)
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.large)
            .interactiveDismissDisabled(authStore.isLoading)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(authStore.isLoading)
                }
            }
        }
    }

    private func deleteAccount() {
        Task {
            let didDelete = await authStore.deleteAccount(password: password)
            if didDelete { dismiss() }
        }
    }
}
