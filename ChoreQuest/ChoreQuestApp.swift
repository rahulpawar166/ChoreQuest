//
//  ChoreQuestApp.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 29/05/26.
//

import GoogleSignIn
import SwiftUI

@main
struct ChoreQuestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
