import Foundation
import Combine
import Supabase
// import buddiee_t2_01App // Removed incorrect import
// If Message is in Models, use: import buddiee_t2_01App.Models

class MessageStore: ObservableObject {
    @Published var conversations: [String] = [] // Conversation IDs or user IDs
    @Published var messages: [Message] = []
    @Published var user: [User] = []
    
    var channel: RealtimeChannelV2?
    
    var conversationID : String?// Optional to allow for no conversation selected
    
    let userStore : UserStore
    
    var getMessages : [Message]
    
    init(){
        
        self.userStore = UserStore()
        
        self.getMessages = []
        
        self.user = []
        
        self.messages = []
        
        //fetchMessages()
        
    }
    
    func sendChat(_ user: User){
        self.user.append(user)
    }
    
    func sendMessage(_ message: Message){
        
    }
    
//    func addMessageIfNotExists(_ message: Message) {
//        if !messages.contains(where: { $0.id == message.id }) {
//            messages.append(message)
//        }
//    }
    
    
    func fetchMessages() {
        Task{
            //var allMessages: [Message] = []
            
            let data = try await SupabaseManager.shared.fetchMessages()
            
            
            await MainActor.run {
                //self.messages.append(contentsOf: data)
                self.messages = data
            }
            
            //print(self.messages)
        }
    }
    
    
    func markAsRead(_ message: Message) {}
    
        // MARK: - 订阅某个会话的实时消息
        /// 传入当前打开的会话 id
    func startListening(conversationID: String) async throws {

        try await stopListening()
        let conversationID = conversationID // 直接赋值

        // 通道名字随意，但保持唯一即可
        let name = "test"
        let chan = SupabaseManager.shared.client.channel(name)
        
        // 只监听 messages 表针对该会话行的 Insert
        let _ = chan.onPostgresChange(
            InsertAction.self,
            schema: "public",
            //table: "messages",
            //filter: #"conversation_id=eq."\#(conversationID)""# // 行过滤
        ) {
            insert in
              print("Inserted: \(insert.record)")
        }

        // 真正建立 websocket
        await chan.subscribe()
        print("Subscribed to channel: \(name)")
        self.channel = chan
    }

    /// 退出聊天页时调用
    func stopListening() async throws {
        try await channel?.unsubscribe()
        print("Unsubscribed from channel")
        channel = nil
        conversationID = nil
    }
    
    
}

