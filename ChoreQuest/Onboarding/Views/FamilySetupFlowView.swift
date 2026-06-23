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

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            if authStore.userProfile?.hasCompletedAppTour == false {
                ParentAppTourView(
                    dismissWhenFinished: false,
                    onFinish: authStore.completeAppTour
                )
            } else if authStore.userProfile?.hasAcceptedCurrentTerms == false {
                TermsAcceptanceView(
                    onAccept: authStore.acceptTermsOfService,
                    onSignOut: authStore.signOut
                )
            } else {
                setupContent
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.84), value: step)
        .animation(
            .spring(response: 0.42, dampingFraction: 0.86),
            value: authStore.userProfile?.hasCompletedAppTour
        )
        .animation(
            .spring(response: 0.42, dampingFraction: 0.86),
            value: authStore.userProfile?.acceptedTermsVersion
        )
        .questToast(message: $authStore.errorMessage)
    }

    @ViewBuilder
    private var setupContent: some View {
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
}

private enum OnboardingStep {
    case familyIdentity
    case heroSetup
}
