import Foundation
import Combine
import Supabase
// import buddiee_t2_01App // Removed incorrect import
// If Message is in Models, use: import buddiee_t2_01App.Models

class MessageStore: ObservableObject {
    @Published var conversations: [String] = [] // Conversation IDs or user IDs
    @Published var messages: [Message] = []
    @Published var user: [User] = []
    
    var hasUnreadMessages: Bool {
        messages.contains { !$0.isRead && $0.receiver == userStore.currentUser?.id }
    }
    
    private var pollingTimer: Timer?
    
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

    func startPolling(every interval: TimeInterval = 2.0) {
        // Invalidate any existing timer to avoid duplicates
        stopPolling()
        // Fetch messages immediately when polling starts
        fetchMessages()
        // Schedule a new timer
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetchMessages()
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    func unreadMessageCount(for conversationId: String) -> Int {
        messages.filter { $0.conversationId == conversationId && !$0.isRead && $0.receiver == userStore.currentUser?.id }.count
    }

    func markConversationAsRead(conversationId: String) {
        let unreadMessages = messages.filter { $0.conversationId == conversationId && !$0.isRead }
        guard !unreadMessages.isEmpty else { return }

        for message in unreadMessages {
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index].isRead = true
            }
        }

        Task {
            do {
                let messageIds = unreadMessages.map { $0.id }
                try await SupabaseManager.shared.markMessagesAsRead(messageIds)
            } catch {
                print("❌ Failed to mark messages as read: \(error)")
            }
        }
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
                //self.messages.append(contentsOf: data)
                self.messages = data
            }
            
            //print(self.messages)
        }
    }
    
    func deleteConversation(with userId: UUID) {
       // Remove the user from the local list
        user.removeAll { $0.id == userId }
       //TODO: Add database deletion logic here
          Task {
               try? await SupabaseManager.shared.deleteConversation(with: userId)
          }
        print("DEBUG: Conversation with user \(userId) deleted locally.")
    }
    
    
}
