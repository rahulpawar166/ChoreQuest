//
//  AuthView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var authStore: AuthStore

    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var mascotOffset: CGFloat = -8
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
        case confirmPassword
    }

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), password.count >= 6 else {
            return false
        }

        return mode == .signIn || password == confirmPassword
    }

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    mascotHeader
                    authCard
                    footerToggle
                }
                .padding(.horizontal, 20)
                .padding(.top, 42)
                .padding(.bottom, 28)
            }
        }
        .font(.custom("Quicksand", size: 16))
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                mascotOffset = 8
            }
        }
        .questToast(message: $authStore.errorMessage)
    }

    private var mascotHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ChoreQuestColors.secondary.opacity(0.28))
                    .frame(width: 142, height: 142)
                    .blur(radius: 12)

                Image("appIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 122, height: 122)
                    .background(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(.white)
                            .shadow(color: ChoreQuestColors.primary.opacity(0.16), radius: 22, y: 10)
                    )
                    .offset(y: mascotOffset)
            }

            VStack(spacing: 8) {
                Text(mode.title)
                    .font(.custom("Quicksand", size: 32).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
                    .multilineTextAlignment(.center)

                Text(mode.subtitle)
                    .font(.custom("Quicksand", size: 16).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 12)
            }
        }
    }

    private var authCard: some View {
        VStack(spacing: 22) {
            modePicker

            VStack(spacing: 18) {
                QuestTextField(
                    title: "HERO EMAIL",
                    placeholder: "parent@quest.com",
                    systemImage: "envelope.fill",
                    text: $email,
                    keyboardType: .emailAddress,
                    contentType: .emailAddress
                )
                .focused($focusedField, equals: .email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                QuestSecureField(
                    title: "SECRET KEY",
                    placeholder: "At least 6 characters",
                    systemImage: "lock.fill",
                    text: $password,
                    contentType: mode == .signIn ? .password : .newPassword
                )
                .focused($focusedField, equals: .password)

                if mode == .signUp {
                    QuestSecureField(
                        title: "CONFIRM KEY",
                        placeholder: "Match your secret key",
                        systemImage: "key.fill",
                        text: $confirmPassword,
                        contentType: .newPassword
                    )
                    .focused($focusedField, equals: .confirmPassword)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            Button {
                submit()
            } label: {
                HStack(spacing: 10) {
                    if authStore.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(mode.buttonTitle)
                        Image(systemName: mode == .signIn ? "bolt.fill" : "sparkles")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(QuestPrimaryButtonStyle())
            .disabled(!canSubmit || authStore.isLoading)
            .opacity(canSubmit ? 1 : 0.56)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(color: ChoreQuestColors.primary.opacity(0.10), radius: 30, y: 12)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(ChoreQuestColors.secondary.opacity(0.22))
                .frame(width: 78, height: 78)
                .offset(x: 28, y: -28)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(ChoreQuestColors.surfaceContainerHigh, lineWidth: 2)
        )
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(AuthMode.allCases, id: \.self) { authMode in
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        mode = authMode
                        authStore.errorMessage = nil
                    }
                } label: {
                    Text(authMode.rawValue)
                        .font(.custom("Quicksand", size: 14).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(mode == authMode ? .white : ChoreQuestColors.primary)
                        .background(
                            Capsule()
                                .fill(mode == authMode ? ChoreQuestColors.primary : ChoreQuestColors.surfaceContainerLow)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(ChoreQuestColors.surfaceContainer)
        .clipShape(Capsule())
    }

    private var footerToggle: some View {
        HStack(spacing: 6) {
            Text(mode.footerPrompt)
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    mode = mode == .signIn ? .signUp : .signIn
                    authStore.errorMessage = nil
                    confirmPassword = ""
                }
            } label: {
                Text(mode.footerAction)
                    .fontWeight(.bold)
                    .foregroundStyle(ChoreQuestColors.primary)
            }
        }
        .font(.custom("Quicksand", size: 16).weight(.medium))
        .multilineTextAlignment(.center)
    }

    private func submit() {
        focusedField = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            switch mode {
            case .signIn:
                await authStore.signIn(email: trimmedEmail, password: password)
            case .signUp:
                await authStore.signUp(email: trimmedEmail, password: password)
            }
        }
    }
}
