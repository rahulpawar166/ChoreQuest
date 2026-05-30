//
//  HeroSetupView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI
import UIKit

struct HeroSetupView: View {
    let familyName: String
    @Binding var heroes: [HeroProfileDraft]
    let onBack: () -> Void
    let isSaving: Bool
    let onComplete: () -> Void
    let onSignOut: () -> Void

    @State private var selectedAvatar = AvatarOption.all[0]
    @State private var heroName = ""
    @State private var heroImageData: Data?

    private var trimmedHeroName: String {
        heroName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddHero: Bool {
        !trimmedHeroName.isEmpty
    }

    private var canCompleteSetup: Bool {
        canAddHero || !heroes.isEmpty
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                topBar
                header
                content
                teamSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.custom("Quicksand", size: 14).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)
            }

            Spacer()

            Button("Sign Out", action: onSignOut)
                .font(.custom("Quicksand", size: 14).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("Summon a New Hero!")
                .font(.custom("Quicksand", size: 32).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Text("Every great adventure starts with a name and a legendary look.")
                .font(.custom("Quicksand", size: 18).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                .multilineTextAlignment(.center)

            QuestProgressBar(progress: 1)
        }
        .multilineTextAlignment(.center)
    }

    private var content: some View {
        VStack(spacing: 18) {
            avatarSection
            heroDetailsSection
        }
    }

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Choose an Avatar", systemImage: "sparkles")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Spacer()

                Text("\(AvatarOption.all.count) Options")
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ChoreQuestColors.secondary)
                    .foregroundStyle(Color(hex: 0x6f5100))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AvatarOption.all) { avatar in
                    AvatarOptionCard(
                        avatar: avatar,
                        isSelected: selectedAvatar == avatar,
                        action: { selectedAvatar = avatar }
                    )
                }
            }

            QuestImagePickerCard(
                title: "Or add a real hero photo",
                subtitle: "Use the gallery or camera to personalize this hero profile.",
                fallbackSystemImage: "person.crop.circle.fill",
                accentColor: ChoreQuestColors.primary,
                imageData: $heroImageData
            )
        }
        .padding(22)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: ChoreQuestColors.primary.opacity(0.10), radius: 22, y: 10)
    }

    private var heroDetailsSection: some View {
        VStack(spacing: 20) {
            QuestTextField(
                title: "HERO NAME",
                placeholder: "E.g. Captain Clean-Up",
                systemImage: "face.smiling.fill",
                text: $heroName,
                keyboardType: .default,
                contentType: .nickname
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("STARTER REWARD")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                    Spacer()

                    Text("+50 XP")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: 0xffdf9f))
                        .foregroundStyle(Color(hex: 0x261a00))
                        .clipShape(Capsule())
                }

                QuestProgressBar(progress: 0.25)
            }

            Button(action: completeSetup) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Complete Quest & Join Team")
                        Image(systemName: "sparkles")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(QuestPrimaryButtonStyle())
            .disabled(!canCompleteSetup || isSaving)
            .opacity(canCompleteSetup && !isSaving ? 1 : 0.55)

            Button(action: addAnotherHero) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(ChoreQuestColors.primary)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    Text("Add Another Hero")
                        .font(.custom("Quicksand", size: 20).weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .background(.white.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                    .foregroundStyle(ChoreQuestColors.primary)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .disabled(!canAddHero || isSaving)
            .opacity(canAddHero && !isSaving ? 1 : 0.55)
        }
        .padding(22)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: ChoreQuestColors.primary.opacity(0.10), radius: 22, y: 10)
    }

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(displayFamilyName)
                .font(.custom("Quicksand", size: 20).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            if heroes.isEmpty {
                OnboardingInfoCard(
                    icon: "person.crop.circle.badge.plus",
                    iconBackground: ChoreQuestColors.surfaceContainer,
                    iconForeground: ChoreQuestColors.primary,
                    title: "Your hero roster is empty",
                    message: "Create the first kid profile now so chores can be assigned to a real hero."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(heroes) { hero in
                        HeroRosterCard(hero: hero)
                    }
                }
            }
        }
    }

    private var displayFamilyName: String {
        let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "The Brave Team" : "\(trimmed)"
    }

    private func addAnotherHero() {
        appendDraftHeroIfNeeded()
    }

    private func completeSetup() {
        guard canCompleteSetup else { return }
        appendDraftHeroIfNeeded()
        onComplete()
    }

    private func appendDraftHeroIfNeeded() {
        guard canAddHero else { return }

        heroes.append(
            HeroProfileDraft(
                name: trimmedHeroName,
                avatar: selectedAvatar,
                imageData: heroImageData,
                levelTitle: "Level \(heroes.count + 1) Scout"
            )
        )
        heroName = ""
        heroImageData = nil
        selectedAvatar = AvatarOption.all[heroes.count % AvatarOption.all.count]
    }
}

private struct AvatarOptionCard: View {
    let avatar: AvatarOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? ChoreQuestColors.surfaceContainer : ChoreQuestColors.surfaceContainerLow)
                        .frame(height: 88)
                        .overlay {
                            Image(systemName: avatar.iconName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color(hex: avatar.colorHex))
                        }

                    if isSelected {
                        Circle()
                            .fill(ChoreQuestColors.primary)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 6, y: -6)
                    }
                }

                Text(avatar.name)
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
                    .multilineTextAlignment(.center)
            }
            .padding(6)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? ChoreQuestColors.primary : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HeroRosterCard: View {
    let hero: HeroProfileDraft

    var body: some View {
        HStack(spacing: 14) {
            heroPreview

            VStack(alignment: .leading, spacing: 4) {
                Text(hero.name)
                    .font(.custom("Quicksand", size: 18).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text(hero.levelTitle)
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            }

            Spacer()

            Text(hero.avatar.name)
                .font(.custom("Quicksand", size: 12).weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ChoreQuestColors.surfaceContainer)
                .foregroundStyle(ChoreQuestColors.primary)
                .clipShape(Capsule())
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: ChoreQuestColors.primary.opacity(0.06), radius: 16, y: 8)
    }

    @ViewBuilder
    private var heroPreview: some View {
        if let imageData = hero.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(hex: hero.avatar.colorHex).opacity(0.14))
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: hero.avatar.iconName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: hero.avatar.colorHex))
                }
        }
    }
}
