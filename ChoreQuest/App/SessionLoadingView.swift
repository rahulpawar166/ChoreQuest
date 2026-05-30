//
//  SessionLoadingView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct SessionLoadingView: View {
    @ObservedObject var authStore: AuthStore

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            VStack(spacing: 18) {
                ProgressView()
                    .tint(ChoreQuestColors.primary)
                    .scaleEffect(1.4)

                Text("Loading your kingdom...")
                    .font(.custom("Quicksand", size: 22).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
            }
            .padding(24)
        }
    }
}
