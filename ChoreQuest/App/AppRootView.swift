//
//  AppRootView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct AppRootView: View {
    @StateObject private var authStore = AuthStore()

    var body: some View {
        Group {
            switch authStore.route {
            case .auth:
                AuthView(authStore: authStore)
            case .loading:
                SessionLoadingView(authStore: authStore)
            case .onboarding:
                FamilySetupFlowView(authStore: authStore)
            case .roleSelection:
                RoleSelectionView(authStore: authStore)
            case .parentHome:
                ParentHomePlaceholderView(authStore: authStore)
            case .kidHome:
                KidHomePlaceholderView(authStore: authStore)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: authStore.route)
    }
}
