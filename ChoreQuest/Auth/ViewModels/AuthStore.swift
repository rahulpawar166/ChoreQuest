//
//  AuthStore.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import Security
import UIKit

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
    private var currentAppleNonce: String?
    private let sessionService = FirestoreSessionService()

    var usesPasswordAuthentication: Bool {
        Auth.auth().currentUser?.providerData.contains { $0.providerID == "password" } == true
    }

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
            let result = try await Auth.auth().createUserAsync(withEmail: email, password: password)
            try await self.initializeNewAccountIfNeeded(result)
        }
    }

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        guard let nonce = randomNonceString() else {
            errorMessage = "Apple Sign In could not start securely. Please try again."
            return
        }

        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func signInWithApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard
                let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentAppleNonce,
                let tokenData = appleCredential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                currentAppleNonce = nil
                errorMessage = "Apple did not return the information needed to sign in. Please try again."
                return
            }

            currentAppleNonce = nil
            let credential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )
            await authenticate(message: "Signing in with Apple...") {
                let result = try await Auth.auth().signInAsync(with: credential)
                try await self.initializeNewAccountIfNeeded(result)
            }

        case .failure(let error):
            currentAppleNonce = nil
            if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
                return
            }
            errorMessage = providerMessage(for: error, provider: "Apple")
        }
    }

    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google Sign In is not configured for this app."
            return
        }
        guard let presentingViewController = Self.presentingViewController() else {
            errorMessage = "Google Sign In could not open. Please try again."
            return
        }

        do {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google did not return the information needed to sign in."
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            await authenticate(message: "Signing in with Google...") {
                let result = try await Auth.auth().signInAsync(with: credential)
                try await self.initializeNewAccountIfNeeded(result)
            }
        } catch {
            if error.localizedDescription.localizedCaseInsensitiveContains("cancel") { return }
            errorMessage = providerMessage(for: error, provider: "Google")
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            clearSessionState()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func deleteAccount(password: String? = nil) async -> Bool {
        guard
            let user = Auth.auth().currentUser,
            let userID = currentUserID
        else {
            errorMessage = "The signed-in account could not be verified."
            return false
        }

        setLoading(true, message: "Deleting family account...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            if usesPasswordAuthentication {
                guard let email = user.email, let password, !password.isEmpty else {
                    errorMessage = "Enter the parent account password to continue."
                    return false
                }
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                try await user.reauthenticateAsync(with: credential)
            } else if let lastSignInDate = user.metadata.lastSignInDate,
                      Date().timeIntervalSince(lastSignInDate) > 240 {
                errorMessage = "For security, sign out and sign back in with Apple or Google before deleting the account."
                return false
            }
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
        guard userProfile?.hasAcceptedCurrentTerms == true else {
            errorMessage = "Please accept the Terms of Service before creating your Squad."
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
            errorMessage = onboardingMessage(for: error)
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
                    hasCompletedAppTour: profile.hasCompletedAppTour,
                    acceptedTermsVersion: profile.acceptedTermsVersion,
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
                    hasCompletedAppTour: profile.hasCompletedAppTour,
                    acceptedTermsVersion: profile.acceptedTermsVersion,
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

    func completeAppTour() async -> Bool {
        guard let currentUserID, let profile = userProfile else { return false }

        setLoading(true, message: "Finishing your tour...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            try await sessionService.updateAppTourCompleted(userID: currentUserID)
            userProfile = UserProfile(
                userID: profile.userID,
                email: profile.email,
                familyID: profile.familyID,
                onboardingCompleted: profile.onboardingCompleted,
                hasCompletedAppTour: true,
                acceptedTermsVersion: profile.acceptedTermsVersion,
                selectedRole: profile.selectedRole,
                selectedHeroID: profile.selectedHeroID
            )
            return true
        } catch {
            errorMessage = "We couldn't save your tour progress. Please try again."
            return false
        }
    }

    func acceptTermsOfService() async -> Bool {
        guard let currentUserID, let profile = userProfile else { return false }

        setLoading(true, message: "Saving your agreement...")
        errorMessage = nil
        defer { setLoading(false) }

        do {
            let version = UserProfile.currentTermsVersion
            try await sessionService.updateTermsAccepted(userID: currentUserID, version: version)
            userProfile = UserProfile(
                userID: profile.userID,
                email: profile.email,
                familyID: profile.familyID,
                onboardingCompleted: profile.onboardingCompleted,
                hasCompletedAppTour: profile.hasCompletedAppTour,
                acceptedTermsVersion: version,
                selectedRole: profile.selectedRole,
                selectedHeroID: profile.selectedHeroID
            )
            return true
        } catch {
            errorMessage = "We couldn't save your Terms acceptance. Please try again."
            return false
        }
    }

    private func authenticate(
        message: String = "Signing you in...",
        _ action: @escaping () async throws -> Void
    ) async {
        guard FirebaseAppIsConfigured.value else {
            errorMessage = "Firebase is not configured yet. Check GoogleService-Info.plist."
            return
        }

        setLoading(true, message: message)
        errorMessage = nil

        do {
            try await action()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }

        setLoading(false)
    }

    private func initializeNewAccountIfNeeded(_ result: AuthDataResult) async throws {
        guard result.additionalUserInfo?.isNewUser == true else { return }

        try await sessionService.initializeNewUser(
            userID: result.user.uid,
            email: result.user.email
        )
        let snapshot = try await sessionService.loadSession(
            userID: result.user.uid,
            email: result.user.email
        )
        apply(snapshot: snapshot)
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
                hasCompletedAppTour: false,
                acceptedTermsVersion: nil,
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
                hasCompletedAppTour: profile.hasCompletedAppTour,
                acceptedTermsVersion: profile.acceptedTermsVersion,
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
        case .accountExistsWithDifferentCredential:
            return "An account already uses this email with another sign-in method. Sign in using that method first."
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

    private func onboardingMessage(for error: Error) -> String {
        let message = error.localizedDescription.lowercased()

        if message.contains("exceeds the maximum allowed size") || message.contains("maximum size") {
            return "Your squad has more photo data than we can safely save. Remove one or more profile photos and try again."
        }

        if message.contains("network") || message.contains("offline") {
            return "The network dropped while saving your squad. Your setup is still here—please try again."
        }

        return "We couldn't save your squad yet. Your setup is still here, so you can try again."
    }

    private func providerMessage(for error: Error, provider: String) -> String {
        let nsError = error as NSError
        if let authCode = AuthErrorCode(rawValue: nsError.code) {
            switch authCode {
            case .accountExistsWithDifferentCredential:
                return "An account already uses this email with another sign-in method. Sign in using that method first."
            case .networkError:
                return "The network dropped during \(provider) Sign In. Please try again."
            case .credentialAlreadyInUse:
                return "This \(provider) account is already connected to another ChoreQuest account."
            default:
                break
            }
        }
        return "We couldn't sign in with \(provider) right now. Please try again."
    }

    private func randomNonceString(length: Int = 32) -> String? {
        guard length > 0 else { return nil }
        var randomBytes = [UInt8](repeating: 0, count: length)
        guard SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes) == errSecSuccess else {
            return nil
        }

        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { characters[Int($0) % characters.count] })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static func presentingViewController() -> UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var viewController = windowScene?.keyWindow?.rootViewController

        while let presented = viewController?.presentedViewController {
            viewController = presented
        }

        if let navigationController = viewController as? UINavigationController {
            return navigationController.visibleViewController ?? navigationController
        }
        if let tabController = viewController as? UITabBarController {
            return tabController.selectedViewController ?? tabController
        }
        return viewController
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
    func signInAsync(with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "AuthStore",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Authentication completed without a result."]
                    ))
                }
            }
        }
    }

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

    func createUserAsync(withEmail email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "AuthStore",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Account creation completed without a result."]
                    ))
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
