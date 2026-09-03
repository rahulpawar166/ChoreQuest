//
//  CreateQuestView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct CreateQuestView: View {
    let familyProfile: FamilyProfile
    let isSaving: Bool
    let onSave: (CreateQuestInput) async -> Bool

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: QuestCategory = .kitchen
    @State private var title = ""
    @State private var details = ""
    @State private var xpValue = 100.0
    @State private var assignmentChoice: QuestAssignmentChoice = .specificHero
    @State private var selectedHeroID: String?
    @State private var frequency: QuestFrequency = .weekly
    @State private var customDueDate = Date().addingTimeInterval(86_400)

    private var categoryPresets: [QuestPreset] {
        QuestPreset.all.filter { $0.category == selectedCategory }
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && !trimmedDetails.isEmpty && resolvedAssignment != nil
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDetails: String {
        details.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resolvedAssignment: QuestAssignment? {
        switch assignmentChoice {
        case .unassigned:
            return .unassigned
        case .everyone:
            return .everyone
        case .specificHero:
            guard let selectedHeroID, let hero = familyProfile.heroes.first(where: { $0.id == selectedHeroID }) else {
                return nil
            }
            return .hero(hero)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChoreQuestColors.background
                    .ignoresSafeArea()

                QuestBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        categorySection
                        presetSection
                        customQuestSection
                        assignmentSection
                        frequencySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Create a Quest")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ChoreQuestColors.primary)
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .topBarTrailing) {
                    QuestProfileAvatar(
                        imageBase64: familyProfile.parentImageBase64,
                        fallbackIconName: "crown.fill",
                        fallbackColorHex: 0x630ed4,
                        size: 36,
                        borderColor: ChoreQuestColors.primaryFixed
                    )
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: saveQuest) {
                    HStack(spacing: 10) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "rocket")
                            Text("Deploy Quest")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuestPrimaryButtonStyle())
                .disabled(!canSave || isSaving)
                .opacity(canSave && !isSaving ? 1 : 0.55)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            selectedHeroID = selectedHeroID ?? familyProfile.heroes.first?.id
            if familyProfile.heroes.isEmpty {
                assignmentChoice = .unassigned
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Category")
                .font(.custom("Quicksand", size: 22).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QuestCategory.allCases) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            VStack(spacing: 10) {
                                Image(systemName: category.iconName)
                                    .font(.system(size: 24, weight: .bold))
                                Text(category.title)
                                    .font(.custom("Quicksand", size: 13).weight(.bold))
                            }
                            .frame(width: 104, height: 96)
                            .background(selectedCategory == category ? ChoreQuestColors.secondary : ChoreQuestColors.surfaceContainerLowest)
                            .foregroundStyle(selectedCategory == category ? ChoreQuestColors.secondaryText : ChoreQuestColors.onSurfaceVariant)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(selectedCategory.title) Suggestions")
                .font(.custom("Quicksand", size: 22).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            VStack(spacing: 12) {
                ForEach(categoryPresets) { preset in
                    Button(action: {
                        title = preset.title
                        details = preset.details
                        xpValue = Double(preset.xpValue)
                    }) {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(ChoreQuestColors.surfaceContainer)
                                .frame(width: 54, height: 54)
                                .overlay {
                                    Image(systemName: preset.category.iconName)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(ChoreQuestColors.primary)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.title)
                                    .font(.custom("Quicksand", size: 18).weight(.bold))
                                    .foregroundStyle(ChoreQuestColors.onSurface)
                                Text(preset.details)
                                    .font(.custom("Quicksand", size: 14).weight(.medium))
                                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            Text("+\(preset.xpValue)")
                                .font(.custom("Quicksand", size: 12).weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(ChoreQuestColors.secondary)
                                .foregroundStyle(ChoreQuestColors.secondaryText)
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(18)
                    .background(ChoreQuestColors.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(ChoreQuestColors.surfaceContainer.opacity(0.9), lineWidth: 1.5)
                    )
                }
            }
        }
    }

    private var customQuestSection: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Forge a Custom Quest")
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                QuestTextField(
                    title: "QUEST NAME",
                    placeholder: "e.g. Master of the Garden",
                    systemImage: "sparkles",
                    text: $title,
                    keyboardType: .default,
                    contentType: .nickname
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("QUEST DESCRIPTION")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.primary)

                    TextEditor(text: $details)
                        .scrollContentBackground(.hidden)
                        .font(.custom("Quicksand", size: 16).weight(.medium))
                        .frame(minHeight: 110)
                        .padding(14)
                        .background(ChoreQuestColors.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(ChoreQuestColors.outlineVariant, lineWidth: 2)
                        )
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("REWARD VALUE")
                            .font(.custom("Quicksand", size: 12).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        Spacer()
                        Text("\(Int(xpValue)) XP")
                            .font(.custom("Quicksand", size: 16).weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ChoreQuestColors.secondary)
                            .foregroundStyle(ChoreQuestColors.secondaryText)
                            .clipShape(Capsule())
                    }

                    Slider(value: $xpValue, in: 10...500, step: 10)
                        .tint(ChoreQuestColors.primary)
                }
            }
        }
    }

    private var assignmentSection: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Assign To")
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                HStack(spacing: 10) {
                    ForEach(QuestAssignmentChoice.allCases) { choice in
                        Button(action: {
                            assignmentChoice = choice
                        }) {
                            Text(choice.title)
                                .font(.custom("Quicksand", size: 13).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(assignmentChoice == choice ? ChoreQuestColors.primary : ChoreQuestColors.surfaceContainerHigh)
                                .foregroundStyle(assignmentChoice == choice ? .white : ChoreQuestColors.onSurfaceVariant)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if assignmentChoice == .specificHero {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(familyProfile.heroes) { hero in
                                Button(action: {
                                    selectedHeroID = hero.id
                                }) {
                                    VStack(spacing: 10) {
                                        QuestProfileAvatar(
                                            imageBase64: hero.imageBase64,
                                            fallbackIconName: hero.avatarIconName,
                                            fallbackColorHex: hero.avatarColorHex,
                                            size: 72,
                                            borderColor: selectedHeroID == hero.id ? ChoreQuestColors.secondary : ChoreQuestColors.surfaceContainerLowest
                                        )

                                        Text(hero.name)
                                            .font(.custom("Quicksand", size: 13).weight(.bold))
                                            .foregroundStyle(ChoreQuestColors.onSurface)
                                    }
                                    .padding(8)
                                    .background(selectedHeroID == hero.id ? ChoreQuestColors.surfaceContainerLow : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var frequencySection: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quest Frequency")
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                HStack(spacing: 10) {
                    ForEach(QuestFrequency.allCases) { option in
                        Button(action: {
                            frequency = option
                        }) {
                            Text(option.title)
                                .font(.custom("Quicksand", size: 13).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(frequency == option ? ChoreQuestColors.primary : ChoreQuestColors.surfaceContainerHigh)
                                .foregroundStyle(frequency == option ? .white : ChoreQuestColors.onSurfaceVariant)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if frequency == .customDate {
                    DatePicker(
                        "Quest Due Date",
                        selection: $customDueDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(ChoreQuestColors.primary)
                }
            }
        }
    }

    private func saveQuest() {
        guard let assignment = resolvedAssignment else {
            return
        }

        let input = CreateQuestInput(
            familyID: familyProfile.id,
            title: trimmedTitle,
            details: trimmedDetails,
            category: selectedCategory,
            xpValue: Int(xpValue),
            assignment: assignment,
            frequency: frequency,
            customDueDate: frequency == .customDate ? customDueDate : nil
        )

        Task {
            let didSave = await onSave(input)
            if didSave {
                dismiss()
            }
        }
    }
}
