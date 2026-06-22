//
//  AuthStore.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Combine
import FirebaseAuth
import FirebaseCore

@MainActor
final class AuthStore: ObservableObject {
    @Published var route: AppRoute = .auth
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published private(set) var loadingMessage: String?
    @Published var errorMessage: String?
    @Published private(set) var currentUserID: String?
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var familyProfile: FamilyProfile?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let sessionService = FirestoreSessionService()

    init() {
        guard FirebaseAppIsConfigured.value else {
            return
        }

        let currentUser = Auth.auth().currentUser
        isSignedIn = currentUser != nil
        currentUserID = currentUser?.uid
        route = currentUser == nil ? .auth : .loading

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                await self?.handleAuthChange(user)
            }
        }
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    func signIn(email: String, password: String) async {
        await authenticate {
            try await Auth.auth().signInAsync(withEmail: email, password: password)
        }
    }

    func signUp(email: String, password: String) async {
        await authenticate {
            try await Auth.auth().createUserAsync(withEmail: email, password: password)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            clearSessionState()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func deleteAccount(password: String) async -> Bool {
        guard
            let user = Auth.auth().currentUser,
            let email = user.email,
            let userID = currentUserID
        else {
            errorMessage = "The signed-in account could not be verified."
            return false
        }

        setLoading(true, message: "Deleting family account...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user.reauthenticateAsync(with: credential)
            try await sessionService.deleteAccountData(
                userID: userID,
                familyID: familyProfile?.id ?? userProfile?.familyID
            )
            try await user.deleteAccountAsync()
            clearSessionState()
            return true
        } catch {
            errorMessage = deletionMessage(for: error)
            return false
        }
    }

    func retrySessionLoad() {
        guard let currentUser = Auth.auth().currentUser else {
            route = .auth
            return
        }

        Task {
            await loadSession(for: currentUser)
        }
    }

    func completeOnboarding(with draft: FamilyProfileDraft) async {
        guard let currentUser = Auth.auth().currentUser else {
            route = .auth
            return
        }

        setLoading(true, message: "Saving your family setup...")
        errorMessage = nil

        do {
            let snapshot = try await sessionService.completeOnboarding(
                userID: currentUser.uid,
                email: currentUser.email,
                draft: draft
            )
            apply(snapshot: snapshot)
        } catch {
            errorMessage = "We couldn't save your family setup right now."
        }

        setLoading(false)
    }

    func selectRole(_ role: AppRole) async {
        guard let currentUserID else {
            route = .auth
            return
        }

        setLoading(true, message: "Switching to \(role == .parent ? "parent" : "kid") mode...")
        errorMessage = nil

        do {
            try await sessionService.updateSelectedRole(userID: currentUserID, role: role)
            if let profile = userProfile {
                userProfile = UserProfile(
                    userID: profile.userID,
                    email: profile.email,
                    familyID: profile.familyID,
                    onboardingCompleted: profile.onboardingCompleted,
                    selectedRole: role,
                    selectedHeroID: profile.selectedHeroID
                )
            }
            route = route(for: userProfile, familyProfile: familyProfile)
        } catch {
            errorMessage = "We couldn't save this device role right now."
        }

        setLoading(false)
    }

    func clearSelectedRole() async {
        guard let currentUserID else {
            route = .auth
            return
        }

        setLoading(true, message: "Switching profiles...")
        errorMessage = nil

        do {
            try await sessionService.clearSelectedRole(userID: currentUserID)
            if let profile = userProfile {
                userProfile = UserProfile(
                    userID: profile.userID,
                    email: profile.email,
                    familyID: profile.familyID,
                    onboardingCompleted: profile.onboardingCompleted,
                    selectedRole: nil,
                    selectedHeroID: nil
                )
            }
            route = .roleSelection
        } catch {
            errorMessage = "We couldn't clear the saved device role right now."
        }

        setLoading(false)
    }

    private func authenticate(_ action: @escaping () async throws -> Void) async {
        guard FirebaseAppIsConfigured.value else {
            errorMessage = "Firebase is not configured yet. Check GoogleService-Info.plist."
            return
        }

        setLoading(true, message: "Signing you in...")
        errorMessage = nil

        do {
            try await action()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }

        setLoading(false)
    }

    private func handleAuthChange(_ user: User?) async {
        guard let user else {
            clearSessionState()
            return
        }

        isSignedIn = true
        currentUserID = user.uid
        await loadSession(for: user)
    }

    private func loadSession(for user: User) async {
        setLoading(true, message: "Loading your kingdom...")
        errorMessage = nil
        route = .loading

        do {
            let snapshot = try await sessionService.loadSession(userID: user.uid, email: user.email)
            apply(snapshot: snapshot)
        } catch {
            errorMessage = nil
            userProfile = UserProfile(
                userID: user.uid,
                email: user.email ?? "",
                familyID: nil,
                onboardingCompleted: false,
                selectedRole: nil,
                selectedHeroID: nil
            )
            familyProfile = nil
            route = .onboarding
        }

        setLoading(false)
    }

    private func apply(snapshot: SessionSnapshot) {
        isSignedIn = true
        currentUserID = snapshot.userProfile.userID
        userProfile = snapshot.userProfile
        familyProfile = snapshot.familyProfile
        route = route(for: snapshot.userProfile, familyProfile: snapshot.familyProfile)
    }

    func selectHero(_ heroID: String) async {
        guard let currentUserID, let profile = userProfile else {
            route = .auth
            return
        }

        setLoading(true, message: "Switching hero profile...")
        errorMessage = nil

        do {
            try await sessionService.updateSelectedHero(userID: currentUserID, heroID: heroID)
            userProfile = UserProfile(
                userID: profile.userID,
                email: profile.email,
                familyID: profile.familyID,
                onboardingCompleted: profile.onboardingCompleted,
                selectedRole: profile.selectedRole,
                selectedHeroID: heroID
            )
        } catch {
            errorMessage = "We couldn't switch the hero profile right now."
        }

        setLoading(false)
    }

    func updateFamilyProfile(
        familyName: String,
        crestName: String,
        parentImageData: Data?
    ) async -> Bool {
        guard let familyID = familyProfile?.id else { return false }

        setLoading(true, message: "Saving family profile...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            familyProfile = try await sessionService.updateFamilyProfile(
                familyID: familyID,
                familyName: familyName,
                crestName: crestName,
                parentImageData: parentImageData
            )
            return true
        } catch {
            errorMessage = "We couldn't save the family profile right now."
            return false
        }
    }

    func updateHeroProfile(
        heroID: String,
        name: String,
        avatar: AvatarOption,
        imageData: Data?
    ) async -> Bool {
        guard let familyID = familyProfile?.id else { return false }

        setLoading(true, message: "Saving hero profile...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            familyProfile = try await sessionService.updateHeroProfile(
                familyID: familyID,
                heroID: heroID,
                name: name,
                avatar: avatar,
                imageData: imageData
            )
            return familyProfile != nil
        } catch {
            errorMessage = "We couldn't save this hero profile right now."
            return false
        }
    }

    func updateFamilyReward(title: String, goalXP: Int) async -> Bool {
        guard let familyID = familyProfile?.id else { return false }

        setLoading(true, message: "Saving family reward...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            familyProfile = try await sessionService.updateFamilyReward(
                familyID: familyID,
                title: title,
                goalXP: goalXP
            )
            return true
        } catch {
            errorMessage = "We couldn't save the family reward right now."
            return false
        }
    }

    func clearFamilyReward() async -> Bool {
        guard let familyID = familyProfile?.id else { return false }

        setLoading(true, message: "Removing family reward...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            familyProfile = try await sessionService.clearFamilyReward(familyID: familyID)
            return true
        } catch {
            errorMessage = "We couldn't remove the family reward right now."
            return false
        }
    }

    func addHeroProfile(
        name: String,
        avatar: AvatarOption,
        imageData: Data?
    ) async -> Bool {
        guard let familyID = familyProfile?.id else { return false }

        setLoading(true, message: "Adding new hero...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            familyProfile = try await sessionService.addHeroProfile(
                familyID: familyID,
                name: name,
                avatar: avatar,
                imageData: imageData
            )
            return familyProfile != nil
        } catch {
            errorMessage = "We couldn't add this hero right now."
            return false
        }
    }

    private func route(for userProfile: UserProfile?, familyProfile: FamilyProfile?) -> AppRoute {
        guard let userProfile else {
            return .auth
        }

        if !userProfile.onboardingCompleted || familyProfile == nil {
            return .onboarding
        }

        switch userProfile.selectedRole {
        case .parent:
            return .parentHome
        case .kid:
            return .kidHome
        case .none:
            return .roleSelection
        }
    }

    private func clearSessionState() {
        isSignedIn = false
        isLoading = false
        loadingMessage = nil
        currentUserID = nil
        userProfile = nil
        familyProfile = nil
        route = .auth
        errorMessage = nil
    }

    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard let authCode = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch authCode {
        case .invalidEmail:
            return "That email does not look right yet."
        case .emailAlreadyInUse:
            return "That email already has a quest account."
        case .weakPassword:
            return "Use at least 6 characters for the secret key."
        case .wrongPassword, .invalidCredential:
            return "The email or secret key is incorrect."
        case .userNotFound:
            return "No quest account was found for that email."
        case .networkError:
            return "The network dropped. Try again in a moment."
        default:
            return error.localizedDescription
        }
    }

    private func deletionMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard let authCode = AuthErrorCode(rawValue: nsError.code) else {
            return "We couldn't delete the account. No further changes were made after the failure."
        }

        switch authCode {
        case .wrongPassword, .invalidCredential:
            return "The password is incorrect. Your account was not deleted."
        case .networkError:
            return "The network dropped while deleting the account. Please try again."
        case .requiresRecentLogin:
            return "Please sign out, sign in again, and retry account deletion."
        default:
            return error.localizedDescription
        }
    }

    private func setLoading(_ loading: Bool, message: String? = nil) {
        isLoading = loading
        loadingMessage = loading ? message : nil
    }
}

private enum FirebaseAppIsConfigured {
    static var value: Bool {
        FirebaseApp.app() != nil
    }
}

private extension Auth {
    func signInAsync(withEmail email: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            signIn(withEmail: email, password: password) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func createUserAsync(withEmail email: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            createUser(withEmail: email, password: password) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

private extension User {
    func reauthenticateAsync(with credential: AuthCredential) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reauthenticate(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func deleteAccountAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
