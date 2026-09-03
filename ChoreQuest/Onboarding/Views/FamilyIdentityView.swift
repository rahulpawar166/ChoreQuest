//
//  FamilyIdentityView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct FamilyIdentityView: View {
    @Binding var familyName: String
    @Binding var crestName: String
    @Binding var parentImageData: Data?
    let onContinue: () -> Void
    let isSaving: Bool
    let onSignOut: () -> Void

    private var canContinue: Bool {
        !familyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                progressHeader
                configurationCard
                helperCards
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .navigationTitle("Chore Quest")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Sign Out", action: onSignOut)
                    .font(.custom("Quicksand", size: 14).weight(.bold))
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 14) {
            Image("ChoreQuestLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: ChoreQuestColors.primary.opacity(0.12), radius: 16, y: 8)

            Label("SETUP IN PROGRESS", systemImage: "checkmark.shield.fill")
                .font(.custom("Quicksand", size: 13).weight(.bold))
                .foregroundStyle(Color(hex: 0x261a00))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: 0xffdf9f))
                .clipShape(Capsule())

            Text("Build Your Kingdom")
                .font(.custom("Quicksand", size: 32).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Text("Step 1 of 2: Family Identity")
                .font(.custom("Quicksand", size: 18).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

            QuestProgressBar(progress: 0.5)
        }
        .multilineTextAlignment(.center)
    }

    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 10) {
                Label("What's your Squad Name?", systemImage: "square.and.pencil")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                QuestTextField(
                    title: "SQUAD NAME",
                    placeholder: "e.g., The Smith Squad",
                    systemImage: "person.3.fill",
                    text: $familyName,
                    keyboardType: .default,
                    contentType: .organizationName
                )

                Text("This name will appear on all your quest boards and leaderboards.")
                    .font(.custom("Quicksand", size: 12).weight(.semibold))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Choose the Parent Avatar", systemImage: "person.crop.circle.badge.plus")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                LocalAvatarPickerSection(
                    title: "Choose a Parent Avatar",
                    options: LocalAvatarOption.parents,
                    selectedImageData: $parentImageData
                )

                QuestImagePickerCard(
                    title: "Selected parent avatar",
                    subtitle: "Use the plus button to choose from camera or gallery, or pick a default avatar above.",
                    fallbackSystemImage: "person.crop.circle.fill",
                    accentColor: ChoreQuestColors.primary,
                    imageData: $parentImageData
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Claim your Family Crest", systemImage: "shield.fill")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                HStack(spacing: 18) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(ChoreQuestColors.surfaceContainerHigh)
                        .frame(width: 118, height: 118)
                        .overlay {
                            Image(systemName: crestIconName)
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(crestAccent)
                        }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Design a crest")
                            .font(.custom("Quicksand", size: 16).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text("Make your team recognizable. Every great hero squad needs a sigil.")
                            .font(.custom("Quicksand", size: 15).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                        QuestChipRow(labels: ["+100 XP Bonus", "Profile Badge unlocked"])
                    }
                }
                .padding(18)
                .background(.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                        .foregroundStyle(ChoreQuestColors.outlineVariant)
                )

                CrestPicker(crestName: $crestName)
            }

            VStack(spacing: 14) {
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue Quest")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuestPrimaryButtonStyle())
                .disabled(!canContinue || isSaving)
                .opacity(canContinue && !isSaving ? 1 : 0.55)

                Button("Skip for now (We'll use a random crest)", action: onContinue)
                    .font(.custom("Quicksand", size: 14).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.primary)
            }
        }
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: ChoreQuestColors.primary.opacity(0.10), radius: 28, y: 12)
    }

    private var helperCards: some View {
        VStack(spacing: 14) {
            OnboardingInfoCard(
                icon: "person.3.fill",
                iconBackground: ChoreQuestColors.secondary,
                iconForeground: Color(hex: 0x6f5100),
                title: "Step 2: Add Heroes",
                message: "Next, you'll create profiles for your little adventurers and assign their first tasks."
            )

            OnboardingInfoCard(
                icon: "lock.shield.fill",
                iconBackground: Color(hex: 0x007650),
                iconForeground: Color(hex: 0x76ffc2),
                title: "Family Privacy",
                message: "Your squad is private. Only household members can see your quest board and rewards."
            )
        }
    }

    private var crestIconName: String {
        switch crestName {
        case "Castle Crest":
            return "crown.fill"
        case "Star Banner":
            return "sparkles"
        case "Leaf Shield":
            return "leaf.fill"
        case "Lightning Flag":
            return "bolt.fill"
        default:
            return "shield.fill"
        }
    }

    private var crestAccent: Color {
        switch crestName {
        case "Castle Crest":
            return ChoreQuestColors.primary
        case "Star Banner":
            return Color(hex: 0xec4899)
        case "Leaf Shield":
            return Color(hex: 0x10b981)
        case "Lightning Flag":
            return Color(hex: 0xf59e0b)
        default:
            return ChoreQuestColors.primary
        }
    }
}

struct CrestPicker: View {
    @Binding var crestName: String

    private let options = ["Castle Crest", "Star Banner", "Leaf Shield", "Lightning Flag"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CREST STYLE")
                .font(.custom("Quicksand", size: 12).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        Button(option) {
                            crestName = option
                        }
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(crestName == option ? ChoreQuestColors.primary : ChoreQuestColors.surfaceContainerLow)
                        .foregroundStyle(crestName == option ? Color.white : ChoreQuestColors.primary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
