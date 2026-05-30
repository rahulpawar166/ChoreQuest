//
//  AvatarTokenViews.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI
import UIKit

struct AvatarTokenPickerSection: View {
    let title: String
    @Binding var selectedAvatar: AvatarOption

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(title, systemImage: "pawprint.fill")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Spacer()

                Text("\(AvatarOption.all.count) Tokens")
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ChoreQuestColors.secondary)
                    .foregroundStyle(Color(hex: 0x6f5100))
                    .clipShape(Capsule())
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                ForEach(AvatarOption.all) { avatar in
                    AvatarTokenCard(
                        avatar: avatar,
                        isSelected: selectedAvatar == avatar
                    ) {
                        selectedAvatar = avatar
                    }
                }
            }
        }
    }
}

struct AvatarTokenCard: View {
    let avatar: AvatarOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? ChoreQuestColors.surfaceContainer : ChoreQuestColors.surfaceContainerLow)
                    .frame(height: 92)
                    .overlay {
                        Circle()
                            .fill(Color(hex: avatar.colorHex).opacity(0.14))
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: avatar.iconName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Color(hex: avatar.colorHex))
                            }
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Circle()
                                .fill(ChoreQuestColors.primary)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .offset(x: 6, y: -6)
                        }
                    }

                Text(avatar.name)
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .padding(6)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? ChoreQuestColors.primary : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HeroAvatarPreview: View {
    let imageData: Data?
    let avatar: AvatarOption
    let size: CGFloat

    var body: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(hex: avatar.colorHex).opacity(0.14))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: avatar.iconName)
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundStyle(Color(hex: avatar.colorHex))
                }
        }
    }
}
