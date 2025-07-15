import SwiftUI

@main
struct MyApp: App {
    @StateObject private var supabase = SupabaseManager.shared
    @StateObject private var userStore = UserStore()
    @StateObject private var postStore = PostStore()
    @StateObject private var messageStore = MessageStore()
    @State private var showWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if showWelcome {
                    WelcomeView {
                        // 从欢迎页面进入引导页面
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showWelcome = false
                            showOnboarding = true
                        }
                    }
                } else if showOnboarding {
                    OnboardingView {
                        // 完成引导，标记已看过欢迎页面，进入登录流程
                        //UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showOnboarding = false
                        }
                    }
                } else if supabase.currentUser != nil {
                    ContentView()
                        
                } else {
                    LoginView { email, pw in
                        Task { try? await supabase.signIn(email: email, password: pw) }
                    }
                }
            }
            .animation(.default, value: supabase.currentUser != nil)
            .environmentObject(userStore)
            .environmentObject(postStore)
            .environmentObject(messageStore)
            .environmentObject(supabase)
        }
    }
}
