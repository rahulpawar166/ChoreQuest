//
//  CreateRewardView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct CreateRewardView: View {
    let familyID: String
    let isSaving: Bool
    let onSave: (CreateRewardInput) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSuggestion: RewardSuggestion?
    @State private var title = ""
    @State private var details = ""
    @State private var costXP = 25.0
    @State private var iconName = "gift.fill"
    @State private var category: RewardCategory = .treat

    var body: some View {
        NavigationStack {
            ZStack {
                ChoreQuestColors.background.ignoresSafeArea()
                QuestBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        suggestionSection
                        rewardForm
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Create Reward")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var suggestionSection: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Suggested Rewards")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(RewardSuggestion.all) { suggestion in
                            Button {
                                applySuggestion(suggestion)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(suggestion.title, systemImage: suggestion.iconName)
                                        .font(.custom("Quicksand", size: 14).weight(.bold))
                                    Text("\(suggestion.costXP) XP")
                                        .font(.custom("Quicksand", size: 12).weight(.bold))
                                }
                                .foregroundStyle(selectedSuggestion?.id == suggestion.id ? .white : ChoreQuestColors.primary)
                                .padding(14)
                                .background(selectedSuggestion?.id == suggestion.id ? ChoreQuestColors.primary : ChoreQuestColors.surfaceContainerLow)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var rewardForm: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                QuestTextField(title: "REWARD TITLE", placeholder: "Movie Night Pick", systemImage: "gift.fill", text: $title, keyboardType: .default, contentType: .nickname)
                QuestTextField(title: "DETAILS", placeholder: "Choose the family movie", systemImage: "sparkles", text: $details, keyboardType: .default, contentType: .nickname)

                VStack(alignment: .leading, spacing: 8) {
                    Text("COST")
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    HStack {
                        Slider(value: $costXP, in: 10...200, step: 5)
                            .tint(ChoreQuestColors.primary)
                        Text("\(Int(costXP)) XP")
                            .font(.custom("Quicksand", size: 14).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.primary)
                    }
                }

                Button {
                    Task {
                        let didSave = await onSave(
                            CreateRewardInput(
                                familyID: familyID,
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                                costXP: Int(costXP),
                                iconName: iconName,
                                category: category
                            )
                        )
                        if didSave { dismiss() }
                    }
                } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text("Save Reward")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuestPrimaryButtonStyle())
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
    }

    private func applySuggestion(_ suggestion: RewardSuggestion) {
        selectedSuggestion = suggestion
        title = suggestion.title
        details = suggestion.details
        costXP = Double(suggestion.costXP)
        iconName = suggestion.iconName
        category = suggestion.category
    }
}
