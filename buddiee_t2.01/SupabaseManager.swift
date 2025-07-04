//
//  SupabaseManager.swift
//  buddiee_t2.01
//
//  Created by 欧柔成 on 02/07/2025.
//


import Supabase
import Foundation

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published private(set) var currentUser: Auth.User?
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://mdhxjzxgdrhrqqdpobia.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kaHhqenhnZHJocnFxZHBvYmlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzNzQ2NjcsImV4cCI6MjA2Njk1MDY2N30.mPYlTt5BLUvi20KVFRhZeco0dflwpAJKsYPNWA8mKm4",
        )
        
        self.currentUser = client.auth.currentUser
    }
    
    func signIn(email: String, password: String) async throws {
        let authResponse = try await client.auth.signIn(
            email: email,
            password: password
            )
        
        //let appUser = map(authResponse.user)
        self.currentUser = authResponse.user
    }
    
    
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(
            email: email,
            password: password,
        )
    }
    
    func logOut() async throws{
        try await client.auth.signOut()
        self.currentUser = nil
    }
    
    func saveUerInfo(_ user: User) async throws {
        let _ = try await client
            .from("profiles")
            .upsert(user)
            .execute()
    }
    
    // SupabaseManager.swift
    func savePost(_ post: Post) async throws {
        // 这一行如果插入失败，会直接 throw
        try await client
          .from("posts")
          .insert(post)
          .execute()
      }
    
    func fetchUserProfile(_ userId: UUID) async throws -> User {
        let response = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
        
        let profile = try JSONDecoder().decode(User.self, from: response.data)
        
        return profile
    }
    
    func fetchUserPosts(_ user: UUID) async throws -> [Post] {
        let response = try await client
            .from("posts")
            .select()
            .eq("id", value: user)
            .execute()
        
        let dateFormatter: DateFormatter = {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.timeZone = TimeZone(secondsFromGMT: 0)
            return fmt
        }()
        
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let posts = try decoder.decode([Post].self, from: response.data)
        
        return posts
    }


    func fetchAllPosts() async throws -> [Post] {
        let response = try await client
            .from("posts")
            .select()
            .execute()
        
        let dateFormatter: DateFormatter = {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.timeZone = TimeZone(secondsFromGMT: 0)
            return fmt
        }()
        
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let posts = try decoder.decode([Post].self, from: response.data)
        
        return posts
    }
}
