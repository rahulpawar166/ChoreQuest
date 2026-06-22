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

            VStack(spacing: 22) {
                HeroLoadingAnimation()

                Text(authStore.loadingMessage ?? "Loading your kingdom...")
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text("Your next adventure is almost ready!")
                    .font(.custom("Quicksand", size: 14).weight(.semibold))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
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
                HeroLoadingAnimation(isCompact: true)

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

private struct HeroLoadingAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false
    var isCompact = false

    var body: some View {
        ZStack {
            Circle()
                .fill(ChoreQuestColors.primaryFixed)
                .frame(width: isCompact ? 58 : 92, height: isCompact ? 58 : 92)

            Image(systemName: "shield.fill")
                .font(.system(size: isCompact ? 25 : 40, weight: .bold))
                .foregroundStyle(ChoreQuestColors.primary)
                .scaleEffect(isAnimating && !reduceMotion ? 1.08 : 0.94)
        }
        .frame(width: isCompact ? 86 : 132, height: isCompact ? 86 : 132)
        .overlay {
            Circle()
                .trim(from: 0.08, to: 0.78)
                .stroke(
                    AngularGradient(
                        colors: [ChoreQuestColors.primary, ChoreQuestColors.sky, ChoreQuestColors.secondary, ChoreQuestColors.primary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: isCompact ? 5 : 7, lineCap: .round)
                )
                .rotationEffect(.degrees(isAnimating && !reduceMotion ? 360 : 0))
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}
