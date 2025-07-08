import Foundation
import Combine
// import buddiee_t2_01App // Removed incorrect import
// If Message is in Models, use: import buddiee_t2_01App.Models

class MessageStore: ObservableObject {
    @Published var conversations: [String] = [] // Conversation IDs or user IDs
    @Published var messages: [Message] = []
    @Published var user: [User] = []
    
    let userStore : UserStore
    
    var getMessages : [Message]
    
    init(){
        
        self.userStore = UserStore()
        
        self.getMessages = []
        
        self.user = [
            User(id: UUID(uuidString: "7f0498d7-9d2f-47b4-9073-a8da1074070a")!, username: "Alex Johnson", profilePicture: nil, bio: "Gym enthusiast looking for workout buddies"),
            User(id: UUID(), username: "Sarah Chen", profilePicture: nil, bio: "UCL student studying Computer Science"),
            User(id: UUID(), username: "Mike Rodriguez", profilePicture: nil, bio: "Frontend developer, hackathon lover"),
            User(id: UUID(), username: "Emma Wilson", profilePicture: nil, bio: "Guitarist and vocalist, indie music fan"),
            User(id: UUID(), username: "David Thompson", profilePicture: nil, bio: "Amateur photographer, nature lover"),
            User(id: UUID(), username: "Lisa Park", profilePicture: nil, bio: "Vegan chef, recipe collector")
        ]
        
        self.messages = [
            Message(id: UUID(), sender: UUID(uuidString: "aab3ae8e-076c-462c-9e86-f7cfbaedc3a1")!, receiver: UUID(uuidString: "7f0498d7-9d2f-47b4-9073-a8da1074070a")!, text: "Hey! I saw your gym post. Are you still looking for a workout partner?", imageURL: nil, createdAt: Date().addingTimeInterval(-3600), isRead: true),
        Message(id: UUID(), sender: UUID(uuidString: "aab3ae8e-076c-462c-9e86-f7cfbaedc3a1")!, receiver: UUID(uuidString: "7f0498d7-9d2f-47b4-9073-a8da1074070a")!, text: "Yes! I'm still looking. What's your schedule like?", imageURL: nil, createdAt: Date().addingTimeInterval(-3500), isRead: true),
        Message(id: UUID(), sender: UUID(uuidString: "aab3ae8e-076c-462c-9e86-f7cfbaedc3a1")!, receiver: UUID(uuidString: "7f0498d7-9d2f-47b4-9073-a8da1074070a")!, text: "I usually go in the mornings around 7 AM. Does that work for you?", imageURL: nil, createdAt: Date().addingTimeInterval(-3400), isRead: true),
        Message(id: UUID(), sender: UUID(uuidString: "aab3ae8e-076c-462c-9e86-f7cfbaedc3a1")!, receiver: UUID(uuidString: "7f0498d7-9d2f-47b4-9073-a8da1074070a")!, text: "Perfect! Let's meet tomorrow at PureGym?", imageURL: nil, createdAt: Date().addingTimeInterval(-3300), isRead: false)
        ]
        
        //fetchMessages()
        
    }
    
    func sendChat(_ user: User){
        self.user.append(user)
    }
    
    func sendMessage(_ message: Message){
        
    }
    
    
    func fetchMessages() {
        Task{
            //var allMessages: [Message] = []
            
            let data = try await SupabaseManager.shared.fetchMessages()
            
            
            await MainActor.run {
                self.messages.append(contentsOf: data)
            }
            
            print(self.messages)
        }
    }
    
    
    func markAsRead(_ message: Message) {}
    
    
    
}

//import Foundation
//import Supabase
//import Realtime // 如果你单独引了子包
//
//@MainActor
//final class MessageStore: ObservableObject {
//
//    // MARK: - 公共可观测状态
//    @Published private(set) var messages: [Message] = []
//
//    // MARK: - 私有属性
//    private let supabase = SupabaseManager.shared.supabase
//    private var channel: RealtimeChannelV2?
//    private var conversationID: String?
//    private let selectedUserId: UUID? = nil
//
//    // MARK: - 订阅某个会话的实时消息
//    /// 传入当前打开的会话 id
//    func startListening(conversationID: String) async throws {
//        // 若已在监听其他会话，先取消
//        try await stopListening()
//        
//        let currentUser = SupabaseManager.shared.currentUser!.id
//        self.conversationID = conversationIDText(userA: currentUser, userB: selectedUserId ?? UUID())
//
//        // 通道名字随意，但保持唯一即可
//        let name = "conversation_\(conversationID)"
//        let chan = supabase.channel(name)
//
//        // 只监听 messages 表针对该会话行的 Insert
//        // 最新 API：onPostgresChange<InsertAction>
//        let _ = chan.onPostgresChange(
//            InsertAction.self,
//            schema: "public",
//            table: "messages",
//            filter: "conversation_id=eq.\(conversationID)"  // 行过滤
//        ) { [weak self] insert in
//            guard let data = try? JSONSerialization.data(withJSONObject: insert.record),
//                  let msg  = try? JSONDecoder().decode(Message.self, from: data)
//            else { return }
//            
//            Task { @MainActor in
//                    self?.messages.append(msg)
//                }
//        }
//
//        // 真正建立 websocket
//        await chan.subscribe()
//        self.channel = chan
//    }
//
//    /// 退出聊天页时调用
//    func stopListening() async throws {
//        try await channel?.unsubscribe()
//        channel = nil
//        conversationID = nil
//    }
//
//    // MARK: - 发送消息
//    func send(text: String, to receiver: UUID) async throws {
//        guard let current = SupabaseManager.shared.currentUser else { return }
//        let new = Message(
//            id: UUID(),
//            conversation_id: conversationID ?? "",
//            senderId: current.id,
//            receiverId: receiver,
//            text: text,
//            imageURL: nil,
//            createdAt: Date(),
//            isRead: false
//        )
//        // 插入后，Realtime 触发器会把同一条消息通过 websocket 推给订阅方
//        try await supabase
//            .from("messages")
//            .insert(new)
//            .execute()
//    }
//
//    // MARK: - 首次加载历史记录
//    func loadHistory(conversationID: String) async throws {
//        // conversation_id 如果是 UUID 类型，传 uuidString；如果列本身就是 uuid 也可以直接传 UUID
//        let result: [Message] = try await supabase
//            .from("messages")
//            .select()                                     // 全列
//            .eq("conversation_id", value: conversationID)
//            .order("created_at", ascending: true)
//            .execute()                                   // ① 触发网络请求
//            .value                                       // ② 自动按 [Message].self 解码
//        self.messages = result
//    }
//    
//    // MARK: - 转换id
//    func conversationIDText(userA: UUID, userB: UUID) -> String {
//        // 保证顺序固定（较小的排前面）
//        let pair = userA.uuidString < userB.uuidString
//            ? userA.uuidString + userB.uuidString
//            : userB.uuidString + userA.uuidString
//        return pair           // 返回 String，直接塞进 conversation_id 列
//    }
//
//}



