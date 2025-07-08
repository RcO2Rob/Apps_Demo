import SwiftUI

@main
struct MyApp: App {
    @StateObject private var supabase = SupabaseManager.shared
    @StateObject private var userStore = UserStore()
    @StateObject private var postStore = PostStore()
    @StateObject private var messageStore = MessageStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if supabase.currentUser != nil {
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
