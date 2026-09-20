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
        .background {
            ZStack {
                ChoreQuestColors.background
                QuestBackground()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Parent Gate")
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
            Image("ChoreQuestLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: ChoreQuestColors.primary.opacity(0.12), radius: 16, y: 8)

            Label("OPTIONAL QUEST STEP", systemImage: "lock.shield.fill")
                .font(.custom("Quicksand", size: 13).weight(.bold))
                .foregroundStyle(Color(hex: 0x261a00))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: 0xffdf9f))
                .clipShape(Capsule())

            Text("Set a Parent Gate")
                .font(.custom("Quicksand", size: 32).weight(.bold))
                .foregroundStyle(ChoreQuestColors.onSurface)

            Text("Add a 4-digit code if your heroes will use this same device.")
                .font(.custom("Quicksand", size: 17).weight(.medium))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                .multilineTextAlignment(.center)

            QuestProgressBar(progress: 1)
        }
        .multilineTextAlignment(.center)
    }

    private var pinCard: some View {
        VStack(spacing: 18) {
            OnboardingInfoCard(
                icon: "person.2.badge.gearshape.fill",
                iconBackground: ChoreQuestColors.surfaceContainer,
                iconForeground: ChoreQuestColors.primary,
                title: "Shared device helper",
                message: "When this is on, parent tools ask for the code before opening."
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
                Text("Skip - we use separate devices")
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
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
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
    var actionTitle = "Open Parent Gate"
    var forgotTitle = "Forgot Parent Gate PIN?"
    var forgotMessage = "Ask a parent to sign back in. After sign-in, they can choose a new Parent Gate PIN for this device."
    var forgotActionTitle = "Sign Out"
    var forgotActionRole: ButtonRole? = .destructive
    var showsForgotPIN = false
    let onCancel: () -> Void
    var onForgotPIN: (() -> Void)?
    let onVerify: (String) -> Bool

    @State private var pin = ""
    @State private var errorMessage: String?
    @State private var isPresentingForgotPIN = false

    var body: some View {
        NavigationStack {
            ZStack {
                ChoreQuestColors.background
                    .ignoresSafeArea()

                QuestBackground()

                VStack(spacing: 22) {
                    Spacer(minLength: 18)

                    VStack(spacing: 20) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.primary)
                            .frame(width: 88, height: 88)
                            .background(ChoreQuestColors.primaryFixed.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        VStack(spacing: 8) {
                            Text(title)
                                .font(.custom("Quicksand", size: 28).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurface)

                            Text(message)
                                .font(.custom("Quicksand", size: 15).weight(.medium))
                                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }

                        PINTextField(title: "ENTER PIN", pin: $pin)

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
                                Text(actionTitle)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(QuestPrimaryButtonStyle())
                        .disabled(pin.count != 4 || isVerifying)
                        .opacity(pin.count == 4 && !isVerifying ? 1 : 0.55)

                        if showsForgotPIN || onForgotPIN != nil {
                            Button {
                                isPresentingForgotPIN = true
                            } label: {
                                Text("Forgot PIN?")
                                    .font(.custom("Quicksand", size: 15).weight(.bold))
                                    .foregroundStyle(ChoreQuestColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(22)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: ChoreQuestColors.primary.opacity(0.10), radius: 24, y: 12)

                    Spacer(minLength: 18)
                }
                .padding(20)
            }
            .navigationTitle("Unlock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .alert(forgotTitle, isPresented: $isPresentingForgotPIN) {
                Button("Cancel", role: .cancel) {}
                if let onForgotPIN {
                    Button(forgotActionTitle, role: forgotActionRole) {
                        onForgotPIN()
                    }
                } else {
                    Button("OK") {}
                }
            } message: {
                Text(forgotMessage)
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
            statusSection

            if authStore.isProfilePINSet {
                changePINSection
                recoverySection
                removeSection
            } else {
                setPINSection
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
        .navigationTitle("Parent Gate")
        .navigationBarTitleDisplayMode(.large)
        .alert("Turn Off Parent Gate?", isPresented: $isConfirmingRemoval) {
            Button("Cancel", role: .cancel) {}
            Button("Turn Off", role: .destructive) {
                removePIN()
            }
        } message: {
            Text("Parent tools and profile switching will open without a PIN on this device.")
        }
    }

    private var statusSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(authStore.isProfilePINSet ? "Parent Gate is set" : "Parent Gate is off")
                        .font(.custom("Quicksand", size: 16).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(authStore.isProfilePINSet ? "Parent tools and profile switching ask for a code on this device." : "Set a 4-digit code when parents and kids share this device.")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: authStore.isProfilePINSet ? "lock.shield.fill" : "lock.open.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.primary)
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var setPINSection: some View {
        Section("Set Parent Gate") {
            PINTextField(title: "CREATE PIN", pin: $newPIN)
            PINTextField(title: "CONFIRM PIN", pin: $confirmation)
            validationMessages

            Button("Set Parent Gate") {
                savePIN()
            }
            .disabled(!canSave)
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var changePINSection: some View {
        Section("Change PIN") {
            PINTextField(title: "CURRENT PIN", pin: $currentPIN)
            PINTextField(title: "NEW PIN", pin: $newPIN)
            PINTextField(title: "CONFIRM NEW PIN", pin: $confirmation)
            validationMessages

            Button("Change PIN") {
                savePIN()
            }
            .disabled(!canSave)
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var recoverySection: some View {
        Section {
            Label {
                Text("If the PIN is forgotten, sign out. A parent can sign back in and set a new Parent Gate PIN.")
                    .font(.custom("Quicksand", size: 14).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(ChoreQuestColors.primary)
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var removeSection: some View {
        Section {
            Button(role: .destructive) {
                isConfirmingRemoval = true
            } label: {
                Label("Turn Off Parent Gate", systemImage: "trash.fill")
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    @ViewBuilder
    private var validationMessages: some View {
        if let errorMessage {
            ErrorBanner(message: errorMessage)
        }

        if let successMessage {
            Label(successMessage, systemImage: "checkmark.circle.fill")
                .font(.custom("Quicksand", size: 14).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)
        }
    }

    private func savePIN() {
        errorMessage = nil
        successMessage = nil
        let isCreatingPIN = !authStore.isProfilePINSet

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
        successMessage = "Parent Gate saved."

        if isCreatingPIN {
            dismiss()
        }
    }

    private func removePIN() {
        guard authStore.removeProfilePIN() else {
            errorMessage = authStore.errorMessage ?? "We couldn't turn off Parent Gate right now."
            return
        }
        dismiss()
    }
}

struct HeroPINListView: View {
    @ObservedObject var authStore: AuthStore

    var body: some View {
        Form {
            Section {
                Label {
                    Text("Hero PINs are optional. Use them when multiple kids share this device. A parent can reset any Hero PIN here.")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "person.2.badge.key.fill")
                        .foregroundStyle(ChoreQuestColors.primary)
                }
            }
            .listRowBackground(ChoreQuestColors.surfaceContainerLowest)

            Section("Heroes") {
                ForEach(authStore.familyProfile?.heroes ?? []) { hero in
                    NavigationLink {
                        HeroPINSettingsView(
                            authStore: authStore,
                            hero: hero,
                            mode: .parentReset
                        )
                    } label: {
                        HStack(spacing: 13) {
                            QuestProfileAvatar(
                                imageBase64: hero.imageBase64,
                                fallbackIconName: hero.avatarIconName,
                                fallbackColorHex: hero.avatarColorHex,
                                size: 42,
                                borderColor: authStore.isHeroPINSet(heroID: hero.id) ? ChoreQuestColors.secondary : ChoreQuestColors.surfaceContainerHigh
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(hero.name)
                                    .font(.custom("Quicksand", size: 15).weight(.bold))
                                    .foregroundStyle(ChoreQuestColors.onSurface)

                                Text(authStore.isHeroPINSet(heroID: hero.id) ? "Hero PIN is set. Parent can change or reset it." : "Hero PIN is off.")
                                    .font(.custom("Quicksand", size: 11).weight(.medium))
                                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
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
        .navigationTitle("Hero PINs")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct HeroPINSettingsView: View {
    enum Mode {
        case parentReset
        case heroSelfManage
    }

    @ObservedObject var authStore: AuthStore
    let hero: HeroProfile
    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isConfirmingRemoval = false

    private var isPINSet: Bool {
        authStore.isHeroPINSet(heroID: hero.id)
    }

    private var requiresCurrentPIN: Bool {
        mode == .heroSelfManage && isPINSet
    }

    private var canSave: Bool {
        (!requiresCurrentPIN || currentPIN.count == 4) &&
        newPIN.count == 4 &&
        confirmation.count == 4
    }

    var body: some View {
        Form {
            statusSection

            if isPINSet {
                changePINSection
                recoverySection
                removeSection
            } else {
                setPINSection
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
        .navigationTitle("Hero PIN")
        .navigationBarTitleDisplayMode(.large)
        .alert("Turn Off Hero PIN?", isPresented: $isConfirmingRemoval) {
            Button("Cancel", role: .cancel) {}
            Button("Turn Off", role: .destructive) {
                removePIN()
            }
        } message: {
            Text("\(hero.name)'s quest board will open without a PIN on this device.")
        }
    }

    private var statusSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isPINSet ? "\(hero.name)'s Hero PIN is set" : "\(hero.name)'s Hero PIN is off")
                        .font(.custom("Quicksand", size: 16).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text(isPINSet ? setStatusMessage : offStatusMessage)
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: isPINSet ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ChoreQuestColors.primary)
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var setPINSection: some View {
        Section {
            PINTextField(title: "CREATE PIN", pin: $newPIN)
            PINTextField(title: "CONFIRM PIN", pin: $confirmation)
            validationMessages

            Button("Set Hero PIN") {
                savePIN()
            }
            .disabled(!canSave)
        } header: {
            Text("Set Hero PIN")
        } footer: {
            Text("This PIN opens \(hero.name)'s quest board on this device.")
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var changePINSection: some View {
        Section {
            if requiresCurrentPIN {
                PINTextField(title: "CURRENT PIN", pin: $currentPIN)
            }

            PINTextField(title: "NEW PIN", pin: $newPIN)
            PINTextField(title: "CONFIRM NEW PIN", pin: $confirmation)
            validationMessages

            Button(mode == .parentReset ? "Set New PIN" : "Change PIN") {
                savePIN()
            }
            .disabled(!canSave)
        } header: {
            Text(mode == .parentReset ? "Reset Hero PIN" : "Change Hero PIN")
        } footer: {
            Text(mode == .parentReset ? "Use this if \(hero.name) forgets their PIN. The old PIN is not needed in Parent mode." : "If this PIN is forgotten, ask a parent to reset it from Parent mode.")
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var recoverySection: some View {
        Section {
            Label {
                Text(mode == .parentReset ? "Forgotten PIN? Set a new one above, or turn it off below." : "Forgotten PIN? Ask a parent to open Parent mode and reset it from Hero PINs.")
                    .font(.custom("Quicksand", size: 14).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(ChoreQuestColors.primary)
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    private var removeSection: some View {
        Section {
            Button(role: .destructive) {
                isConfirmingRemoval = true
            } label: {
                Label("Turn Off Hero PIN", systemImage: "trash.fill")
            }
        }
        .listRowBackground(ChoreQuestColors.surfaceContainerLowest)
    }

    @ViewBuilder
    private var validationMessages: some View {
        if let errorMessage {
            ErrorBanner(message: errorMessage)
        }

        if let successMessage {
            Label(successMessage, systemImage: "checkmark.circle.fill")
                .font(.custom("Quicksand", size: 14).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)
        }
    }

    private var setStatusMessage: String {
        switch mode {
        case .parentReset:
            return "This hero profile asks for a PIN before opening. You can change it here if it is forgotten."
        case .heroSelfManage:
            return "Your quest board asks for this PIN before opening. If you forget it, ask a parent to reset it."
        }
    }

    private var offStatusMessage: String {
        switch mode {
        case .parentReset:
            return "Set a 4-digit PIN when this hero shares the device with other family members."
        case .heroSelfManage:
            return "Set a 4-digit PIN if you share this device with another hero."
        }
    }

    private func savePIN() {
        errorMessage = nil
        successMessage = nil
        let isCreatingPIN = !isPINSet

        if requiresCurrentPIN, !authStore.verifyHeroPIN(currentPIN, heroID: hero.id) {
            errorMessage = "The current PIN did not match."
            return
        }

        guard newPIN == confirmation else {
            errorMessage = "The new PINs do not match yet."
            return
        }

        guard authStore.setHeroPIN(newPIN, heroID: hero.id) else {
            errorMessage = authStore.errorMessage ?? "We couldn't save this Hero PIN right now."
            return
        }

        currentPIN = ""
        newPIN = ""
        confirmation = ""
        successMessage = "\(hero.name)'s Hero PIN saved."

        if isCreatingPIN {
            dismiss()
        }
    }

    private func removePIN() {
        guard authStore.removeHeroPIN(heroID: hero.id) else {
            errorMessage = authStore.errorMessage ?? "We couldn't turn off this Hero PIN right now."
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
