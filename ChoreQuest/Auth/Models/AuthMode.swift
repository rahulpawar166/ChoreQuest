//
//  AuthMode.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

enum AuthMode: String, CaseIterable {
    case signIn = "Sign In"
    case signUp = "Sign Up"

    var title: String {
        switch self {
        case .signIn:
            return "Welcome Back, Hero!"
        case .signUp:
            return "Join the Quest!"
        }
    }

    var subtitle: String {
        switch self {
        case .signIn:
            return "Your next quest is waiting. Log in to claim XP and rewards."
        case .signUp:
            return "Create a parent account to start building your family kingdom."
        }
    }

    var buttonTitle: String {
        switch self {
        case .signIn:
            return "Enter Kingdom"
        case .signUp:
            return "Create Account"
        }
    }

    var footerPrompt: String {
        switch self {
        case .signIn:
            return "New to the quest?"
        case .signUp:
            return "Already have a quest account?"
        }
    }

    var footerAction: String {
        switch self {
        case .signIn:
            return "Join the Guild"
        case .signUp:
            return "Return to Base"
        }
    }
}
