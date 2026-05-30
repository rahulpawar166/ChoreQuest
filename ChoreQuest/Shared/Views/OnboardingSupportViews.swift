//
//  OnboardingSupportViews.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct QuestProgressBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ChoreQuestColors.surfaceContainer)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [ChoreQuestColors.primary, ChoreQuestColors.primaryContainer],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(progress, 1)) * proxy.size.width)
            }
        }
        .frame(height: 16)
    }
}

struct OnboardingInfoCard: View {
    let icon: String
    let iconBackground: Color
    let iconForeground: Color
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(iconBackground)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(iconForeground)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("Quicksand", size: 18).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text(message)
                    .font(.custom("Quicksand", size: 15).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
            }

            Spacer()
        }
        .padding(18)
        .background(ChoreQuestColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct QuestChipRow: View {
    let labels: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.custom("Quicksand", size: 11).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(chipBackground(for: label))
                        .foregroundStyle(chipForeground(for: label))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func chipBackground(for label: String) -> Color {
        label.contains("XP") ? Color(hex: 0x4edea3) : Color(hex: 0xeaddff)
    }

    private func chipForeground(for label: String) -> Color {
        label.contains("XP") ? Color(hex: 0x005236) : Color(hex: 0x25005a)
    }
}
