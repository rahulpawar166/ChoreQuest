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

    @Environment(\.dismiss) private var dismiss
    @State private var familyName: String
    @State private var crestName: String
    @State private var parentImageData: Data?

    init(
        familyProfile: FamilyProfile,
        isSaving: Bool,
        onSave: @escaping (String, String, Data?) async -> Bool
    ) {
        self.familyProfile = familyProfile
        self.isSaving = isSaving
        self.onSave = onSave
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
