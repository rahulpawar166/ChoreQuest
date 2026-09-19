//
//  ProfilePINViews.swift
//  ChoreQuest
//

import SwiftUI

struct ProfilePINOnboardingView: View {
    @ObservedObject var authStore: AuthStore
    let onBack: () -> Void
    let onComplete: () -> Void

    @State private var pin = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?

    private var canSave: Bool {
        pin.count == 4 && confirmation.count == 4
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                header
                pinCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(
            ZStack {
                ChoreQuestColors.background
                QuestBackground()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Profile PIN")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 70, weight: .bold))
                .foregroundStyle(ChoreQuestColors.primary)
                .frame(width: 118, height: 118)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: ChoreQuestColors.primary.opacity(0.14), radius: 20, y: 10)

            Text("Protect Parent Mode")
                .font(.custom("Quicksand", size: 32).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Text("If parents and kids share this device, a 4-digit PIN keeps profile switching and parent tools behind a quick check.")
                .font(.custom("Quicksand", size: 17).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .multilineTextAlignment(.center)
    }

    private var pinCard: some View {
        VStack(spacing: 18) {
            OnboardingInfoCard(
                icon: "iphone.gen3",
                iconBackground: ChoreQuestColors.surfaceContainer,
                iconForeground: ChoreQuestColors.primary,
                title: "Optional for separate devices",
                message: "Families using one parent device and one kid device can skip this now and turn it on later in Settings."
            )

            PINTextField(title: "CREATE PIN", pin: $pin)
            PINTextField(title: "CONFIRM PIN", pin: $confirmation)

            if let errorMessage {
                ErrorBanner(message: errorMessage)
            }

            Button {
                savePIN()
            } label: {
                Text("Save PIN & Finish")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(QuestPrimaryButtonStyle())
            .disabled(!canSave || authStore.isLoading)
            .opacity(canSave && !authStore.isLoading ? 1 : 0.55)

            Button {
                onComplete()
            } label: {
                Text("Skip for Now")
                    .font(.custom("Quicksand", size: 17).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .disabled(authStore.isLoading)
        }
        .padding(22)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: ChoreQuestColors.primary.opacity(0.10), radius: 22, y: 10)
    }

    private func savePIN() {
        guard pin == confirmation else {
            errorMessage = "The two PINs do not match yet."
            return
        }

        guard authStore.setProfilePIN(pin) else {
            errorMessage = authStore.errorMessage ?? "We couldn't save this PIN right now."
            return
        }

        onComplete()
    }
}

struct ProfilePINPromptView: View {
    let title: String
    let message: String
    let isVerifying: Bool
    let onCancel: () -> Void
    let onVerify: (String) -> Bool

    @State private var pin = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.primary)
                    .frame(width: 88, height: 88)
                    .background(ChoreQuestColors.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(spacing: 8) {
                    Text(title)
                        .font(.custom("Quicksand", size: 26).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(message)
                        .font(.custom("Quicksand", size: 15).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }

                PINTextField(title: "PROFILE PIN", pin: $pin)

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                Button {
                    verify()
                } label: {
                    HStack(spacing: 10) {
                        if isVerifying {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Unlock")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuestPrimaryButtonStyle())
                .disabled(pin.count != 4 || isVerifying)
                .opacity(pin.count == 4 && !isVerifying ? 1 : 0.55)

                Spacer(minLength: 0)
            }
            .padding(22)
            .background(
                ZStack {
                    ChoreQuestColors.background
                    QuestBackground()
                }
                .ignoresSafeArea()
            )
            .navigationTitle("Unlock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private func verify() {
        guard onVerify(pin) else {
            pin = ""
            errorMessage = "That PIN did not match."
            return
        }
        errorMessage = nil
    }
}

struct ProfilePINSettingsView: View {
    @ObservedObject var authStore: AuthStore

    @Environment(\.dismiss) private var dismiss
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isConfirmingRemoval = false

    private var requiresCurrentPIN: Bool {
        authStore.isProfilePINSet
    }

    private var canSave: Bool {
        (!requiresCurrentPIN || currentPIN.count == 4) &&
        newPIN.count == 4 &&
        confirmation.count == 4
    }

    var body: some View {
        Form {
            Section {
                Text("Use a local 4-digit PIN when this device is shared by parents and kids. It is stored in this device's Keychain and can be skipped on separate devices.")
                    .font(.custom("Quicksand", size: 14).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .listRowBackground(ChoreQuestColors.surfaceContainerLowest)

            Section(authStore.isProfilePINSet ? "Change PIN" : "Create PIN") {
                if requiresCurrentPIN {
                    PINTextField(title: "CURRENT PIN", pin: $currentPIN)
                }

                PINTextField(title: "NEW PIN", pin: $newPIN)
                PINTextField(title: "CONFIRM NEW PIN", pin: $confirmation)

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                if let successMessage {
                    Label(successMessage, systemImage: "checkmark.circle.fill")
                        .font(.custom("Quicksand", size: 14).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.primary)
                }

                Button(authStore.isProfilePINSet ? "Update PIN" : "Save PIN") {
                    savePIN()
                }
                .disabled(!canSave)
            }
            .listRowBackground(ChoreQuestColors.surfaceContainerLowest)

            if authStore.isProfilePINSet {
                Section {
                    Button(role: .destructive) {
                        isConfirmingRemoval = true
                    } label: {
                        Label("Remove Profile PIN", systemImage: "trash.fill")
                    }
                }
                .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                ChoreQuestColors.background
                QuestBackground()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Profile PIN")
        .navigationBarTitleDisplayMode(.large)
        .alert("Remove Profile PIN?", isPresented: $isConfirmingRemoval) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                removePIN()
            }
        } message: {
            Text("Parent mode and profile switching will no longer require this local device PIN.")
        }
    }

    private func savePIN() {
        errorMessage = nil
        successMessage = nil

        if requiresCurrentPIN, !authStore.verifyProfilePIN(currentPIN) {
            errorMessage = "The current PIN did not match."
            return
        }

        guard newPIN == confirmation else {
            errorMessage = "The new PINs do not match yet."
            return
        }

        guard authStore.setProfilePIN(newPIN) else {
            errorMessage = authStore.errorMessage ?? "We couldn't save this PIN right now."
            return
        }

        currentPIN = ""
        newPIN = ""
        confirmation = ""
        successMessage = "Profile PIN saved."
    }

    private func removePIN() {
        guard authStore.removeProfilePIN() else {
            errorMessage = authStore.errorMessage ?? "We couldn't remove this PIN right now."
            return
        }
        dismiss()
    }
}

private struct PINTextField: View {
    let title: String
    @Binding var pin: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Quicksand", size: 12).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)

            SecureField("4 digits", text: $pin)
                .font(.custom("Quicksand", size: 22).weight(.bold))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(ChoreQuestColors.surfaceContainerLow)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ChoreQuestColors.outlineVariant, lineWidth: 2))
                .onChange(of: pin) { _, value in
                    let digits = value.filter(\.isNumber)
                    pin = String(digits.prefix(4))
                }
        }
    }
}
