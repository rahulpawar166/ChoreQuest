//
//  QuestToastView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct QuestToastView: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ChoreQuestColors.error)
                .padding(.top, 1)

            Text(message)
                .font(.custom("Quicksand", size: 14).weight(.semibold))
                .foregroundStyle(ChoreQuestColors.errorText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.errorText.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.45))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(ChoreQuestColors.errorContainer.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: ChoreQuestColors.error.opacity(0.12), radius: 20, y: 8)
    }
}

private struct QuestToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    QuestToastView(message: message) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            self.message = nil
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: message)
            .task(id: message) {
                guard message != nil else {
                    return
                }

                try? await Task.sleep(nanoseconds: 4_000_000_000)
                guard !Task.isCancelled, self.message != nil else {
                    return
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    self.message = nil
                }
            }
    }
}

extension View {
    func questToast(message: Binding<String?>) -> some View {
        modifier(QuestToastModifier(message: message))
    }
}
