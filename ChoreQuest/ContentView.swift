//
//  ContentView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 29/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingLaunchAnimation = true

    var body: some View {
        ZStack {
            AppRootView()

            if isShowingLaunchAnimation {
                PlayfulLaunchView {
                    isShowingLaunchAnimation = false
                }
                .zIndex(1)
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}
