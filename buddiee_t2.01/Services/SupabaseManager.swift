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
            options: SupabaseClientOptions(
                realtime: .init()
              )
        )
        
        self.currentUser = client.auth.currentUser
        
    // ✅ 监听登录 / 登出等状态变化
        Task {
            for await _ in await client.auth.authStateChanges {
                let user = client.auth.currentUser
                DispatchQueue.main.async {
                    self.currentUser = user
                }
                print("📌 Auth state changed. Current user: \(String(describing: user))")
            }
        }
        
        testRealtimeConnection()
        
    }
    
    func testRealtimeConnection() {
        let channel = client.channel("chat_room")

        let _ = channel.onBroadcast(event: "broadcast") { message in
          print("Cursor position received", message)
        }

        Task {
            await channel.subscribe()
            try await channel.broadcast(event: "broadcast", message:["text": "Hello!"])
        }

//        let testChannel = client.channel("test_debug")
//
//        let _ = testChannel.onPostgresChange(
//            InsertAction.self,
//            schema: "public",
//            table: "messages"
//        ) { payload in
//            print("✅ 收到插入事件！内容：", payload.record)
//        }
//
//        Task {
//            await testChannel.subscribe()
//            print("status:",testChannel.status)
//            print("📡 Realtime 订阅已触发 test_debug")
//        }
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
        
        self.currentUser = client.auth.currentUser
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
    
    
    // 检查用户是否已完善资料
//    func checkUserProfileComplete() async throws -> Bool {
//        guard let userId = currentUser?.id else { return false }
//        
//        do {
//            let user = try await fetchUserProfile(userId)
//            return !user.username.isEmpty
//        } catch {
//            // 如果获取用户资料失败，说明用户还没有完善资料
//            return false
//        }
//    }
    
    // SupabaseManager.swift
    func savePost(_ post: Post) async throws {
        // 这一行如果插入失败，会直接 throw
        try await client
          .from("posts")
          .upsert(post)
          .execute()
      }
    
    func updatePost(_ userId:UUID, _ username: String) async throws {
        try await client
            .from("posts")
            .update(["username": username])
            .eq("userId", value: userId)
            .execute()
    }
    
    // MARK: - 检查会话是否存在，不在就插入一条新纪录
    func ensureConversationExists(_ chatUserId: UUID) async throws {
        let myId = client.auth.currentUser?.id

        guard let currentUserId = myId else {
            print("❌ 当前用户未登录")
            return
        }

        // 查询是否已存在会话
        let response = try await client
            .from("conversation_list")
            .select()
            .eq("current_user", value: currentUserId)
            .eq("chat_user", value: chatUserId)
            .limit(1)
            .execute()

        // 如果已有，直接 return
        let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]]
        if let json = json, !json.isEmpty {
            // ✅ 会话已存在
            return
        }

        // ❌ 不存在，插入新记录
        let insertResponse = try await client
            .from("conversation_list")
            .insert([
                "current_user": currentUserId.uuidString,
                "chat_user": chatUserId.uuidString,
                "created_at": ISO8601DateFormatter().string(from: Date())
            ])
            .execute()

        print("✅ 插入会话记录成功")
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
    
    func fetchMutipleUserProfile(_ userId: [UUID]) async throws -> [User] {
        let response = try await client
            .from("profiles")
            .select()
            .in("id", value: userId)
            .execute()
        
        let mutipleProfile = try JSONDecoder().decode([User].self, from: response.data)
        
        return mutipleProfile
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

    // MARK: - fetch all post
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
    
    // MARK: - send messages
    func sendMessage(_ message: Message) async throws {
        print(message)
        
        do{
            try await client
                .from("messages")
                .insert(message)
                .execute()
        }catch{
            print("发送消息出错：", error)
        }
    }
    
    // MARK: - get messages
    func fetchMessages() async throws -> [Message] {
        guard let myId = client.auth.currentUser?.id else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        let response = try await client
            .from("messages")
            .select()
            .or("sender.eq.\(myId),receiver.eq.\(myId)")
            //.eq("sender", value: myId)
            .order("createdAt", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        decoder.dateDecodingStrategy = .formatted(formatter)
        
        do {
            let messages = try decoder.decode([Message].self, from: response.data)
            return messages
        } catch {
            print("❌ 解码失败，原始 JSON：")
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print(jsonString)
            }
            throw error
        }
    }



}




