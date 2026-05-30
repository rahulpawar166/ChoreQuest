//
//  ParentHomePlaceholderView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct ParentHomePlaceholderView: View {
    @ObservedObject var authStore: AuthStore

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            VStack(spacing: 22) {
                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.primary)
                    .frame(width: 112, height: 112)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: ChoreQuestColors.primary.opacity(0.16), radius: 22, y: 10)

                VStack(spacing: 8) {
                    Text("Kingdom Ready")
                        .font(.custom("Quicksand", size: 28).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(parentMessage)
                        .font(.custom("Quicksand", size: 16).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }

                Button("Sign Out") {
                    authStore.signOut()
                }
                .buttonStyle(QuestPrimaryButtonStyle())
            }
            .padding(24)
        }
    }

    private var parentMessage: String {
        if let familyName = authStore.familyProfile?.familyName, !familyName.isEmpty {
            return "\(familyName) is loaded from Firestore, and this device now reopens directly in parent mode."
        }

        return "Signed-in parents who already finished setup land here instead of repeating onboarding."
    }
}
