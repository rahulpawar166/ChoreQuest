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

        isLoading = true
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

        isLoading = false
    }

    func selectRole(_ role: AppRole) async {
        guard let currentUserID else {
            route = .auth
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await sessionService.updateSelectedRole(userID: currentUserID, role: role)
            if let profile = userProfile {
                userProfile = UserProfile(
                    userID: profile.userID,
                    email: profile.email,
                    familyID: profile.familyID,
                    onboardingCompleted: profile.onboardingCompleted,
                    selectedRole: role
                )
            }
            route = route(for: userProfile, familyProfile: familyProfile)
        } catch {
            errorMessage = "We couldn't save this device role right now."
        }

        isLoading = false
    }

    func clearSelectedRole() async {
        guard let currentUserID else {
            route = .auth
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await sessionService.clearSelectedRole(userID: currentUserID)
            if let profile = userProfile {
                userProfile = UserProfile(
                    userID: profile.userID,
                    email: profile.email,
                    familyID: profile.familyID,
                    onboardingCompleted: profile.onboardingCompleted,
                    selectedRole: nil
                )
            }
            route = .roleSelection
        } catch {
            errorMessage = "We couldn't clear the saved device role right now."
        }

        isLoading = false
    }

    private func authenticate(_ action: @escaping () async throws -> Void) async {
        guard FirebaseAppIsConfigured.value else {
            errorMessage = "Firebase is not configured yet. Check GoogleService-Info.plist."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await action()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }

        isLoading = false
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
        isLoading = true
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
                selectedRole: nil
            )
            familyProfile = nil
            route = .onboarding
        }

        isLoading = false
    }

    private func apply(snapshot: SessionSnapshot) {
        isSignedIn = true
        currentUserID = snapshot.userProfile.userID
        userProfile = snapshot.userProfile
        familyProfile = snapshot.familyProfile
        route = route(for: snapshot.userProfile, familyProfile: snapshot.familyProfile)
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
