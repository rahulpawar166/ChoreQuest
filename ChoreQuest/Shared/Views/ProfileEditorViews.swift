//
//  ProfileEditorViews.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct FamilyProfileEditorView: View {
    let familyProfile: FamilyProfile
    let isSaving: Bool
    let onSave: (String, String, Data?) async -> Bool
    let onAddHero: (String, AvatarOption, Data?) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var familyName: String
    @State private var crestName: String
    @State private var parentImageData: Data?
    @State private var isPresentingAddHero = false

    init(
        familyProfile: FamilyProfile,
        isSaving: Bool,
        onSave: @escaping (String, String, Data?) async -> Bool,
        onAddHero: @escaping (String, AvatarOption, Data?) async -> Bool
    ) {
        self.familyProfile = familyProfile
        self.isSaving = isSaving
        self.onSave = onSave
        self.onAddHero = onAddHero
        _familyName = State(initialValue: familyProfile.familyName)
        _crestName = State(initialValue: familyProfile.crestName)
        _parentImageData = State(initialValue: Data.decodeBase64(familyProfile.parentImageBase64))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChoreQuestColors.background.ignoresSafeArea()
                QuestBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ParentSurfaceCard {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Family Profile")
                                    .font(.custom("Quicksand", size: 24).weight(.bold))
                                    .foregroundStyle(ChoreQuestColors.onSurface)

                                QuestTextField(
                                    title: "FAMILY NAME",
                                    placeholder: "The Smith Squad",
                                    systemImage: "person.3.fill",
                                    text: $familyName,
                                    keyboardType: .default,
                                    contentType: .organizationName
                                )

                                QuestImagePickerCard(
                                    title: "Parent Avatar",
                                    subtitle: "Update the parent profile image used across the dashboard.",
                                    fallbackSystemImage: "person.crop.circle.fill",
                                    accentColor: ChoreQuestColors.primary,
                                    imageData: $parentImageData
                                )

                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Family Crest", systemImage: "shield.fill")
                                        .font(.custom("Quicksand", size: 18).weight(.bold))
                                        .foregroundStyle(ChoreQuestColors.onSurface)

                                    CrestPicker(crestName: $crestName)
                                }
                            }
                        }

                        ParentSurfaceCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Kids")
                                        .font(.custom("Quicksand", size: 24).weight(.bold))
                                        .foregroundStyle(ChoreQuestColors.onSurface)

                                    Spacer()

                                    Button("Add Kid") {
                                        isPresentingAddHero = true
                                    }
                                    .font(.custom("Quicksand", size: 14).weight(.bold))
                                    .foregroundStyle(ChoreQuestColors.primary)
                                    .disabled(isSaving)
                                }

                                if familyProfile.heroes.isEmpty {
                                    Text("No kids added yet.")
                                        .font(.custom("Quicksand", size: 14).weight(.medium))
                                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(familyProfile.heroes) { hero in
                                            HStack(spacing: 12) {
                                                QuestProfileAvatar(
                                                    imageBase64: hero.imageBase64,
                                                    fallbackIconName: hero.avatarIconName,
                                                    fallbackColorHex: hero.avatarColorHex,
                                                    size: 46,
                                                    borderColor: ChoreQuestColors.primaryFixed
                                                )

                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(hero.name)
                                                        .font(.custom("Quicksand", size: 16).weight(.bold))
                                                        .foregroundStyle(ChoreQuestColors.onSurface)
                                                    Text(hero.levelTitle)
                                                        .font(.custom("Quicksand", size: 12).weight(.medium))
                                                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                                }

                                                Spacer()

                                                Text(hero.avatarName)
                                                    .font(.custom("Quicksand", size: 11).weight(.bold))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(ChoreQuestColors.surfaceContainerLow)
                                                    .foregroundStyle(ChoreQuestColors.primary)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let didSave = await onSave(
                                familyName.trimmingCharacters(in: .whitespacesAndNewlines),
                                crestName,
                                parentImageData
                            )
                            if didSave { dismiss() }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(isSaving ? "Saving..." : "Save")
                        }
                    }
                    .disabled(familyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
        .sheet(isPresented: $isPresentingAddHero) {
            AddHeroProfileView(isSaving: isSaving) { name, avatar, imageData in
                await onAddHero(name, avatar, imageData)
            }
        }
    }
}

struct HeroProfileEditorView: View {
    let hero: HeroProfile
    let isSaving: Bool
    let onSave: (String, AvatarOption, Data?) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var heroName: String
    @State private var selectedAvatar: AvatarOption
    @State private var imageData: Data?

    init(
        hero: HeroProfile,
        isSaving: Bool,
        onSave: @escaping (String, AvatarOption, Data?) async -> Bool
    ) {
        self.hero = hero
        self.isSaving = isSaving
        self.onSave = onSave
        _heroName = State(initialValue: hero.name)
        _selectedAvatar = State(initialValue: AvatarOption.avatar(for: hero.avatarID))
        _imageData = State(initialValue: Data.decodeBase64(hero.imageBase64))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChoreQuestColors.background.ignoresSafeArea()
                QuestBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ParentSurfaceCard {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack(spacing: 14) {
                                    HeroAvatarPreview(imageData: imageData, avatar: selectedAvatar, size: 72)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(hero.levelTitle)
                                            .font(.custom("Quicksand", size: 12).weight(.bold))
                                            .foregroundStyle(ChoreQuestColors.primary)

                                        Text("Hero Profile")
                                            .font(.custom("Quicksand", size: 24).weight(.bold))
                                            .foregroundStyle(ChoreQuestColors.onSurface)
                                    }
                                }

                                QuestTextField(
                                    title: "HERO NAME",
                                    placeholder: "Captain Clean-Up",
                                    systemImage: "face.smiling.fill",
                                    text: $heroName,
                                    keyboardType: .default,
                                    contentType: .nickname
                                )

                                AvatarTokenPickerSection(title: "Animal Token", selectedAvatar: $selectedAvatar)

                                QuestImagePickerCard(
                                    title: "Hero Photo",
                                    subtitle: "You can keep a real profile photo or just use the animal token.",
                                    fallbackSystemImage: "person.crop.circle.fill",
                                    accentColor: ChoreQuestColors.primary,
                                    imageData: $imageData
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Hero")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let didSave = await onSave(
                                heroName.trimmingCharacters(in: .whitespacesAndNewlines),
                                selectedAvatar,
                                imageData
                            )
                            if didSave { dismiss() }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(isSaving ? "Saving..." : "Save")
                        }
                    }
                    .disabled(heroName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }
}

private extension Data {
    static func decodeBase64(_ value: String?) -> Data? {
        guard let value else { return nil }
        return Data(base64Encoded: value)
    }
}

struct FamilyRewardEditorView: View {
    let currentReward: FamilyGoalReward?
    let isSaving: Bool
    let onSave: (String, Int) async -> Bool
    let onDelete: (() async -> Bool)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var goalXP: Double

    init(
        currentReward: FamilyGoalReward?,
        isSaving: Bool,
        onSave: @escaping (String, Int) async -> Bool,
        onDelete: (() async -> Bool)? = nil
    ) {
        self.currentReward = currentReward
        self.isSaving = isSaving
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: currentReward?.title ?? "")
        _goalXP = State(initialValue: Double(currentReward?.goalXP ?? 500))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChoreQuestColors.background.ignoresSafeArea()
                QuestBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ParentSurfaceCard {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Family-Wide Reward")
                                    .font(.custom("Quicksand", size: 24).weight(.bold))
                                    .foregroundStyle(ChoreQuestColors.onSurface)

                                QuestTextField(
                                    title: "REWARD TITLE",
                                    placeholder: "Pizza Night",
                                    systemImage: "party.popper.fill",
                                    text: $title,
                                    keyboardType: .default,
                                    contentType: .nickname
                                )

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TEAM GOAL")
                                        .font(.custom("Quicksand", size: 12).weight(.bold))
                                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                                    HStack {
                                        Slider(value: $goalXP, in: 100...5000, step: 50)
                                            .tint(ChoreQuestColors.primary)

                                        Text("\(Int(goalXP)) XP")
                                            .font(.custom("Quicksand", size: 14).weight(.bold))
                                            .foregroundStyle(ChoreQuestColors.primary)
                                    }
                                }

                                if onDelete != nil, currentReward != nil {
                                    Button(role: .destructive) {
                                        Task {
                                            let didDelete = await onDelete?() ?? false
                                            if didDelete { dismiss() }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            if isSaving {
                                                ProgressView()
                                                    .controlSize(.small)
                                            } else {
                                                Image(systemName: "trash")
                                            }
                                            Text(isSaving ? "Removing..." : "Delete Family Reward")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(ParentOutlinePillStyle())
                                    .disabled(isSaving)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(currentReward == nil ? "Create Family Reward" : "Edit Family Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let didSave = await onSave(
                                title.trimmingCharacters(in: .whitespacesAndNewlines),
                                Int(goalXP)
                            )
                            if didSave { dismiss() }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(isSaving ? "Saving..." : "Save")
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }
}

struct AddHeroProfileView: View {
    let isSaving: Bool
    let onSave: (String, AvatarOption, Data?) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var heroName = ""
    @State private var selectedAvatar = AvatarOption.all[0]
    @State private var imageData: Data?

    var body: some View {
        NavigationStack {
            ZStack {
                ChoreQuestColors.background.ignoresSafeArea()
                QuestBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ParentSurfaceCard {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Add New Kid")
                                    .font(.custom("Quicksand", size: 24).weight(.bold))
                                    .foregroundStyle(ChoreQuestColors.onSurface)

                                QuestTextField(
                                    title: "KID NAME",
                                    placeholder: "Avery",
                                    systemImage: "face.smiling.fill",
                                    text: $heroName,
                                    keyboardType: .default,
                                    contentType: .nickname
                                )

                                AvatarTokenPickerSection(title: "Animal Token", selectedAvatar: $selectedAvatar)

                                QuestImagePickerCard(
                                    title: "Kid Photo",
                                    subtitle: "Optional photo for this hero profile.",
                                    fallbackSystemImage: "person.crop.circle.fill",
                                    accentColor: ChoreQuestColors.primary,
                                    imageData: $imageData
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Kid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let didSave = await onSave(
                                heroName.trimmingCharacters(in: .whitespacesAndNewlines),
                                selectedAvatar,
                                imageData
                            )
                            if didSave { dismiss() }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(isSaving ? "Saving..." : "Save")
                        }
                    }
                    .disabled(heroName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }
}
