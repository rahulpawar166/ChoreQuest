//
//  RoleSelectionView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct RoleSelectionView: View {
    @ObservedObject var authStore: AuthStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                mascotHeader
                roleCards
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 36)
        }
        .background(
            ZStack {
                ChoreQuestColors.background
                QuestBackground()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Chore Quest")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Sign Out") {
                    authStore.signOut()
                }
                .font(.custom("Quicksand", size: 14).weight(.bold))
            }
        }
        .questToast(message: $authStore.errorMessage)
    }

    private var mascotHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ChoreQuestColors.primaryContainer.opacity(0.16))
                    .frame(width: 172, height: 172)

                Image(systemName: "teddybear.fill")
                    .font(.system(size: 74))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ChoreQuestColors.primary, ChoreQuestColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Chore Quest")
                .font(.custom("Quicksand", size: 34).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)

            Text("Choose Your Path!")
                .font(.custom("Quicksand", size: 22).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Text("Pick how this device should enter the family account.")
                .font(.custom("Quicksand", size: 16).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
    }

    private var roleCards: some View {
        VStack(spacing: 16) {
            RoleCard(
                title: "I'm a Parent",
                message: "Set quests, manage rewards, and track your heroes' progress.",
                icon: "person.2.badge.gearshape.fill",
                accent: ChoreQuestColors.primary,
                background: .white,
                action: { selectRole(.parent) }
            )

            RoleCard(
                title: "I'm a Hero",
                message: "Complete chores to earn XP and unlock awesome loot.",
                icon: "sparkles",
                accent: Color(hex: 0x6f5100),
                background: Color(hex: 0xffdf9f),
                badge: "+50 XP BONUS",
                action: { selectRole(.kid) }
            )
        }
        .allowsHitTesting(!authStore.isLoading)
        .opacity(authStore.isLoading ? 0.7 : 1)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            if authStore.isLoading {
                ProgressView()
                    .tint(ChoreQuestColors.primary)
            }
        }
    }

    private func selectRole(_ role: AppRole) {
        Task {
            await authStore.selectRole(role)
        }
    }
}

private struct RoleCard: View {
    let title: String
    let message: String
    let icon: String
    let accent: Color
    let background: Color
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(accent)
                    }

                Text(title)
                    .font(.custom("Quicksand", size: 24).weight(.bold))
                    .foregroundStyle(accent)

                Text(message)
                    .font(.custom("Quicksand", size: 16).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(title == "I'm a Parent" ? "Master Account" : "Adventurer Access")
                        .font(.custom("Quicksand", size: 14).weight(.bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(accent)

                if let badge {
                    Text(badge)
                        .font(.custom("Quicksand", size: 11).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accent.opacity(0.12))
                        .foregroundStyle(accent)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(background)
                    .shadow(color: accent.opacity(0.14), radius: 22, y: 10)
            }
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
