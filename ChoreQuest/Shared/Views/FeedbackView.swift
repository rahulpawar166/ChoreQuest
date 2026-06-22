//
//  FeedbackView.swift
//  ChoreQuest
//

import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    let role: AppRole
    let selectedHero: HeroProfile?
    let userProfile: UserProfile?
    let familyProfile: FamilyProfile?

    @State private var category: FeedbackCategory = .idea
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var isShowingSuccess = false

    private let feedbackService = FeedbackService()

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        trimmedMessage.count >= 10 && trimmedMessage.count <= 1_000 && !isSubmitting
    }

    var body: some View {
        Form {
            standpointSection
            feedbackSection

            if let errorMessage {
                Section {
                    ErrorBanner(message: errorMessage)
                }
            }

            Section {
                Button(action: submit) {
                    HStack(spacing: 10) {
                        Spacer()

                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }

                        Text(isSubmitting ? "Sending..." : "Send Feedback")
                            .font(.custom("Quicksand", size: 16).weight(.bold))

                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 5)
                }
                .listRowBackground(canSubmit ? ChoreQuestColors.primary : ChoreQuestColors.outlineVariant)
                .disabled(!canSubmit)
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
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.large)
        .interactiveDismissDisabled(isSubmitting)
        .alert("Feedback Sent!", isPresented: $isShowingSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text(role == .parent ? "Thanks for sharing a parent's perspective." : "Thanks for helping make ChoreQuest more fun!")
        }
    }

    private var standpointSection: some View {
        Section("Sending As") {
            HStack(spacing: 14) {
                Image(systemName: role == .parent ? "crown.fill" : selectedHero?.avatarIconName ?? "figure.child")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(role == .parent ? ChoreQuestColors.primary : ChoreQuestColors.sky)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(role == .parent ? "Parent Feedback" : "Kid Feedback")
                        .font(.custom("Quicksand", size: 16).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(role == .parent ? "Saved with the Parent standpoint." : "Saved with \(selectedHero?.name ?? "this hero")'s Kid standpoint.")
                        .font(.custom("Quicksand", size: 12).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var feedbackSection: some View {
        Section {
            Picker("Feedback Type", selection: $category) {
                ForEach(FeedbackCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }

            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text(role == .parent ? "What could help your family use ChoreQuest better?" : "What do you like, or what would make quests more fun?")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.outline)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 9)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $message)
                    .font(.custom("Quicksand", size: 15).weight(.medium))
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
            }

            HStack {
                Text("At least 10 characters")
                Spacer()
                Text("\(trimmedMessage.count)/1000")
            }
            .font(.custom("Quicksand", size: 11).weight(.semibold))
            .foregroundStyle(trimmedMessage.count > 1_000 ? ChoreQuestColors.error : ChoreQuestColors.outline)
        } header: {
            Text("Your Feedback")
        } footer: {
            Text("Avoid including passwords, addresses, school details, or other private information.")
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private func submit() {
        guard canSubmit else { return }
        guard let userProfile, let familyID = userProfile.familyID, let familyProfile else {
            errorMessage = "Your family account could not be identified. Please try again after signing in."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let submission = FeedbackSubmission(
            role: role,
            userID: userProfile.userID,
            familyID: familyID,
            familyName: familyProfile.familyName,
            heroID: role == .kid ? selectedHero?.id : nil,
            heroName: role == .kid ? selectedHero?.name : nil,
            category: category,
            message: trimmedMessage
        )

        Task {
            do {
                try await feedbackService.submit(submission)
                isSubmitting = false
                isShowingSuccess = true
            } catch {
                isSubmitting = false
                errorMessage = "We couldn't send your feedback right now. Please try again."
            }
        }
    }
}
