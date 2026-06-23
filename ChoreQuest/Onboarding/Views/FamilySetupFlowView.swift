//
//  FamilySetupFlowView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct FamilySetupFlowView: View {
    @ObservedObject var authStore: AuthStore

    @State private var draft = FamilyProfileDraft()
    @State private var step: OnboardingStep = .familyIdentity
    @State private var isPresentingAppTour = false

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            switch step {
            case .familyIdentity:
                FamilyIdentityView(
                    familyName: $draft.familyName,
                    crestName: $draft.crestName,
                    parentImageData: $draft.parentImageData,
                    onContinue: { step = .heroSetup },
                    isSaving: authStore.isLoading,
                    onSignOut: authStore.signOut
                )
            case .heroSetup:
                HeroSetupView(
                    familyName: draft.familyName,
                    heroes: $draft.heroes,
                    onBack: { step = .familyIdentity },
                    isSaving: authStore.isLoading,
                    onComplete: {
                        Task {
                            await authStore.completeOnboarding(with: draft)
                        }
                    },
                    onSignOut: authStore.signOut
                )
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.84), value: step)
        .questToast(message: $authStore.errorMessage)
        .fullScreenCover(isPresented: $isPresentingAppTour) {
            ParentAppTourView(onFinish: authStore.completeAppTour)
        }
        .onAppear {
            presentAppTourIfNeeded()
        }
        .onChange(of: authStore.userProfile?.hasCompletedAppTour) { _, _ in
            presentAppTourIfNeeded()
        }
    }

    private func presentAppTourIfNeeded() {
        guard authStore.userProfile?.hasCompletedAppTour == false else { return }
        isPresentingAppTour = true
    }
}

private enum OnboardingStep {
    case familyIdentity
    case heroSetup
}
