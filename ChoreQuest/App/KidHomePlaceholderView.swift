//
//  KidHomePlaceholderView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct KidHomePlaceholderView: View {
    @ObservedObject var authStore: AuthStore

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            VStack(spacing: 22) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.secondary)
                    .frame(width: 112, height: 112)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: ChoreQuestColors.secondary.opacity(0.18), radius: 22, y: 10)

                VStack(spacing: 8) {
                    Text("Hero Mode Ready")
                        .font(.custom("Quicksand", size: 28).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text("This device will reopen directly in kid mode until the selected role is changed later in settings.")
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
}
