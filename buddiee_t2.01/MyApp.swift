//
//  MyApp.swift
//  buddiee_t2.01
//
//  Created by 欧柔成 on 04/07/2025.
//


import SwiftUI

@main
struct MyApp: App {
    @StateObject private var supabase = SupabaseManager.shared
    @StateObject private var userStore = UserStore()
    @StateObject private var postStore = PostStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if supabase.currentUser != nil {
                    ContentView()
                        .environmentObject(postStore)
                        .environmentObject(userStore)
                } else {
                    LoginView { email, pw in
                        Task { try? await supabase.signIn(email: email, password: pw) }
                    }
                }
            }
            .animation(.default, value: supabase.currentUser != nil)
        }
    }
}
