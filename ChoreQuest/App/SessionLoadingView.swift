//
//  SessionLoadingView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct SessionLoadingView: View {
    @ObservedObject var authStore: AuthStore

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            VStack(spacing: 18) {
                ProgressView()
                    .tint(ChoreQuestColors.primary)
                    .scaleEffect(1.4)

                Text(authStore.loadingMessage ?? "Loading your kingdom...")
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
            }
            .padding(24)
        }
    }
}

struct BlockingLoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.16)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .tint(ChoreQuestColors.primary)
                    .scaleEffect(1.25)

                Text(message)
                    .font(.custom("Quicksand", size: 18).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(ChoreQuestColors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(ChoreQuestColors.primaryFixed.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 18, y: 10)
            .padding(.horizontal, 36)
        }
    }
}
