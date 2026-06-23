//
//  UserProfile.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

struct UserProfile {
    static let currentTermsVersion = "2026-06-22"

    let userID: String
    let email: String
    let familyID: String?
    let onboardingCompleted: Bool
    let hasCompletedAppTour: Bool
    let acceptedTermsVersion: String?
    let selectedRole: AppRole?
    let selectedHeroID: String?

    var hasAcceptedCurrentTerms: Bool {
        acceptedTermsVersion == Self.currentTermsVersion
    }

    init(
        userID: String,
        email: String,
        familyID: String?,
        onboardingCompleted: Bool,
        hasCompletedAppTour: Bool,
        acceptedTermsVersion: String? = nil,
        selectedRole: AppRole?,
        selectedHeroID: String?
    ) {
        self.userID = userID
        self.email = email
        self.familyID = familyID
        self.onboardingCompleted = onboardingCompleted
        self.hasCompletedAppTour = hasCompletedAppTour
        self.acceptedTermsVersion = acceptedTermsVersion
        self.selectedRole = selectedRole
        self.selectedHeroID = selectedHeroID
    }
}
