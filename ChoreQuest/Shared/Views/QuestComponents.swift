//
//  QuestComponents.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct QuestTextField: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    var keyboardType: UIKeyboardType
    var contentType: UITextContentType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Quicksand", size: 12).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(ChoreQuestColors.outline)
                    .frame(width: 20)

                TextField(placeholder, text: $text)
                    .font(.custom("Quicksand", size: 16).weight(.medium))
                    .keyboardType(keyboardType)
                    .textContentType(contentType)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(ChoreQuestColors.surfaceContainerLow)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(ChoreQuestColors.outlineVariant, lineWidth: 2))
        }
    }
}

struct QuestSecureField: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    var contentType: UITextContentType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Quicksand", size: 12).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(ChoreQuestColors.outline)
                    .frame(width: 20)

                SecureField(placeholder, text: $text)
                    .font(.custom("Quicksand", size: 16).weight(.medium))
                    .textContentType(contentType)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(ChoreQuestColors.surfaceContainerLow)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(ChoreQuestColors.outlineVariant, lineWidth: 2))
        }
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ChoreQuestColors.error)

            Text(message)
                .font(.custom("Quicksand", size: 14).weight(.semibold))
                .foregroundStyle(ChoreQuestColors.errorText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(ChoreQuestColors.errorContainer)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct QuestPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Quicksand", size: 20).weight(.bold))
            .foregroundStyle(.white)
            .frame(minHeight: 58)
            .padding(.horizontal, 22)
            .background(ChoreQuestColors.primary)
            .clipShape(Capsule())
            .shadow(color: ChoreQuestColors.primaryShadow, radius: 0, y: configuration.isPressed ? 0 : 4)
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
