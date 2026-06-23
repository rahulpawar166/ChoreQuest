//
//  TermsAcceptanceView.swift
//  ChoreQuest
//

import SwiftUI

struct TermsAcceptanceView: View {
    let onAccept: () async -> Bool
    let onSignOut: () -> Void

    @State private var hasConfirmedAgreement = false
    @State private var isAccepting = false

    var body: some View {
        TermsOfServiceView()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                acceptancePanel
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out", action: onSignOut)
                        .font(.custom("Quicksand", size: 14).weight(.bold))
                        .disabled(isAccepting)
                }
            }
            .interactiveDismissDisabled()
    }

    private var acceptancePanel: some View {
        VStack(spacing: 12) {
            Button {
                hasConfirmedAgreement.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: hasConfirmedAgreement ? "checkmark.square.fill" : "square")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            hasConfirmedAgreement
                                ? ChoreQuestColors.primary
                                : ChoreQuestColors.onSurfaceVariant
                        )

                    Text("I am a parent or legal guardian, and I have read and agree to the Terms of Service for my family.")
                        .font(.custom("Quicksand", size: 14).weight(.semibold))
                        .foregroundStyle(ChoreQuestColors.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agree to the Terms of Service")
            .accessibilityValue(hasConfirmedAgreement ? "Selected" : "Not selected")

            HStack(spacing: 12) {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Text("Privacy Policy")
                        .font(.custom("Quicksand", size: 14).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.primary)
                        .frame(minHeight: 52)
                        .padding(.horizontal, 16)
                        .background(ChoreQuestColors.surfaceContainerHigh, in: Capsule())
                }

                Button {
                    acceptTerms()
                } label: {
                    HStack(spacing: 8) {
                        if isAccepting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Accept & Continue")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuestPrimaryButtonStyle())
                .disabled(!hasConfirmedAgreement || isAccepting)
                .opacity(hasConfirmedAgreement && !isAccepting ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(ChoreQuestColors.surfaceContainerLowest)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ChoreQuestColors.outlineVariant)
                .frame(height: 1)
        }
    }

    private func acceptTerms() {
        guard hasConfirmedAgreement, !isAccepting else { return }
        isAccepting = true

        Task {
            let didAccept = await onAccept()
            if !didAccept {
                isAccepting = false
            }
        }
    }
}
