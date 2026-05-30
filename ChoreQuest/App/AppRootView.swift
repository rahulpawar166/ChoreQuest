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
                NavigationStack {
                    FamilySetupFlowView(authStore: authStore)
                }
            case .roleSelection:
                NavigationStack {
                    RoleSelectionView(authStore: authStore)
                }
            case .parentHome:
                NavigationStack {
                    ParentDashboardView(authStore: authStore)
                }
            case .kidHome:
                NavigationStack {
                    KidDashboardView(authStore: authStore)
                }
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: authStore.route)
        .overlay {
            if authStore.isLoading, authStore.route != .loading {
                BlockingLoadingOverlay(message: authStore.loadingMessage ?? "Working...")
                    .transition(.opacity)
            }
        }
    }
}
