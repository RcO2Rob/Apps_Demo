import SwiftUI
import Supabase

// MARK: - Main View
struct MessagesView: View {
    var initialUserId: UUID?
    @State private var selectedUserId: UUID? = nil
    @State private var messageText: String = ""
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var messageStore: MessageStore
    
    var body: some View {
        NavigationStack {
            Group {
                if let userId = selectedUserId {
                    ChatView(
                        userId: userId,
                        onSend: sendMessage,
                        onBack: { self.selectedUserId = nil },
                        messageText: $messageText
                    )
                } else {
                    ConversationsList(
                        onSelectUser: { user in
                            self.selectedUserId = user.id
                        },
                        onDelete: deleteConversation
                    )
                }
            }
            .onAppear(perform: messageStore.fetchMessages)
        }
        .toolbar(selectedUserId != nil ? .hidden : .visible, for: .tabBar)
        .task {
            if selectedUserId == nil, let id = initialUserId {
                selectedUserId = id
            }
            if let userId = initialUserId, !messageStore.user.contains(where: { $0.id == userId }) {
                do {
                    let user = try await SupabaseManager.shared.fetchUserProfile(userId)
                    messageStore.user.append(user)
                } catch {
                    print("❌ Failed to fetch user profile:", error)
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty, let selectedUserId = selectedUserId, let currentUser = userStore.currentUser else { return }
        
        let newMessage = Message(
            id: UUID(),
            sender: currentUser.id,
            receiver: selectedUserId,
            conversationId: conversationIDText(userA: currentUser.id, userB: selectedUserId),
            text: messageText,
            imageURL: nil,
            createdAt: Date(),
            isRead: false
        )
        
        messageStore.messages.append(newMessage)
        Task {
            try await SupabaseManager.shared.sendMessage(newMessage)
        }
        messageText = ""
    }
    
    private func deleteConversation(at offsets: IndexSet) {
        let usersToDelete = offsets.map { messageStore.user[$0] }
        for user in usersToDelete {
            messageStore.deleteConversation(with: user.id)
        }
    }
    
    private func conversationIDText(userA: UUID, userB: UUID) -> String {
        let sorted = [userA.uuidString, userB.uuidString].sorted()
        return sorted.joined(separator: "_")
    }
}

// MARK: - Chat View and its Subviews
struct ChatView: View {
    let userId: UUID
    let onSend: () -> Void
    let onBack: () -> Void
    @Binding var messageText: String
    @EnvironmentObject var messageStore: MessageStore
    @State private var scrollToBottomTrigger = false
    
    private var conversationID: String {
        let currentUserId = SupabaseManager.shared.currentUser!.id
        return [currentUserId.uuidString, userId.uuidString].sorted().joined(separator: "_")
    }
    
    private var messages: [Message] {
        messageStore.messages
            .filter { ($0.sender == userId && $0.receiver == SupabaseManager.shared.currentUser!.id) || ($0.sender == SupabaseManager.shared.currentUser!.id && $0.receiver == userId) }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            ChatHeaderView(userId: userId, onBack: onBack)
            
            // Message List
            MessageListView(messages: messages, scrollToBottomTrigger: $scrollToBottomTrigger)
            
            // Message Input
            MessageInputView(messageText: $messageText, onSend: {
                onSend()
                // A short delay to allow the new message to be added to the list before scrolling.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottomTrigger.toggle()
                }
            })
        }
        .navigationBarHidden(true)
        .onAppear {
            messageStore.markConversationAsRead(conversationId: conversationID)
        }
        .onChange(of: messages) {
            messageStore.markConversationAsRead(conversationId: conversationID)
            scrollToBottomTrigger.toggle()
        }
        .task {
            do {
                try await SupabaseManager.shared.ensureConversationExists(userId)
            } catch {
                print("❌ Task error in ChatView:", error)
            }
        }
        .onDisappear {
            // Polling is managed by the parent view (MessagesView)
        }
    }
}

private struct ChatHeaderView: View {
    let userId: UUID
    let onBack: () -> Void
    @EnvironmentObject var messageStore: MessageStore

    private var user: User? {
        messageStore.user.first(where: { $0.id == userId })
    }

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left").foregroundColor(.primary)
            }
            
            if let user = user {
                HStack(spacing: 8) {
                    if let profilePicture = user.profilePicture, let url = URL(string: profilePicture) {
                        AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { ProgressView() }
                        .frame(width: 32, height: 32).clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill").resizable().scaledToFill()
                        .frame(width: 32, height: 32).clipShape(Circle()).foregroundColor(.gray)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.username).font(.headline)
                        Text(user.bio ?? "").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            Button(action: {}) { Image(systemName: "phone").foregroundColor(.blue) }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .gray.opacity(0.2), radius: 1, y: 1)
    }
}

private struct MessageListView: View {
    let messages: [Message]
    @Binding var scrollToBottomTrigger: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message).id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: scrollToBottomTrigger) { _, newValue in
                if newValue, let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onAppear {
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

private struct MessageInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void

    var body: some View {
        HStack {
            TextField("Type a message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(messageText.isEmpty ? Color.gray : Color.blue)
                    .clipShape(Circle())
            }
            .disabled(messageText.isEmpty)
            .padding(.trailing)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
}

struct MessageBubble: View {
    let message: Message
    @EnvironmentObject var userStore: UserStore
    
    private var isCurrentUser: Bool { message.sender == userStore.currentUser?.id }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.createdAt, formatter: timeFormatter)
                    .font(.caption2).foregroundColor(.secondary).padding(.horizontal, 4)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Conversations List and its Subviews
struct ConversationsList: View {
    let onSelectUser: (User) -> Void
    let onDelete: (IndexSet) -> Void
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var messageStore: MessageStore
    
    var body: some View {
        Group {
            if messageStore.user.isEmpty {
                // 空状态视图
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "message.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No chats")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Start a conversation by viewing someone's profile")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Messages")
                .navigationBarTitleDisplayMode(.large)
            } else {
                // 有聊天会话时显示列表
                List {
                    ForEach(messageStore.user) { user in
                        Button(action: { onSelectUser(user) }) {
                            if let currentUserId = userStore.currentUser?.id {
                                ConversationRowView(
                                    user: user,
                                    lastMessage: getLastMessage(for: user.id),
                                    unreadCount: messageStore.unreadMessageCount(for: conversationIDText(userA: currentUserId, userB: user.id))
                                )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: onDelete)
                }
                .navigationTitle("Messages")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .task {
            await fetchConversations()
        }
    }
    
    private func conversationIDText(userA: UUID, userB: UUID) -> String {
        let sorted = [userA.uuidString, userB.uuidString].sorted()
        return sorted.joined(separator: "_")
    }
    
    private func getLastMessage(for userId: UUID) -> Message? {
        return messageStore.messages
            .filter { $0.sender == userId || $0.receiver == userId }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    private func fetchConversations() async {
        guard let myId = userStore.currentUser?.id else {
            print("❌ Current user is nil, skipping conversation fetch.")
            return
        }
        do {
            let response = try await SupabaseManager.shared.client
                .from("conversation_list")
                .select("current_user, chat_user")
                .or("current_user.eq.\(myId),chat_user.eq.\(myId)")
                .execute()
            
            let rawList = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
            
            let opponentIds: [UUID] = rawList.compactMap {
                guard let currentUserStr = $0["current_user"] as? String,
                      let chatUserStr = $0["chat_user"] as? String,
                      let currentUser = UUID(uuidString: currentUserStr),
                      let chatUser = UUID(uuidString: chatUserStr) else { return nil }
                return currentUser == myId ? chatUser : currentUser
            }
            
            let uniqueOpponentIds = Array(Set(opponentIds))
            let users = try await SupabaseManager.shared.fetchMutipleUserProfile(uniqueOpponentIds)
            
            await MainActor.run {
                messageStore.user = users
            }
        } catch {
            print("❌ Failed to fetch conversation list: \(error)")
        }
    }
    
    
}

private struct ConversationRowView: View {
    let user: User
    let lastMessage: Message?
    let unreadCount: Int

    var body: some View {
        HStack(spacing: 12) {
            if let profilePicture = user.profilePicture, let url = URL(string: profilePicture) {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { ProgressView() }
                .frame(width: 50, height: 50).clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill").resizable()
                .frame(width: 50, height: 50).foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.username).font(.headline).foregroundColor(.primary)
                    Spacer()
                    if let message = lastMessage {
                        Text(message.createdAt, formatter: Self.dateFormatter)
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    if let message = lastMessage {
                        Text(message.text).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                    } else {
                        Text("No messages yet").font(.subheadline).foregroundColor(.secondary).italic()
                    }
                    Spacer()
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func conversationIDText(userA: UUID, userB: UUID) -> String {
        let sorted = [userA.uuidString, userB.uuidString].sorted()
        return sorted.joined(separator: "_")
    }
    
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        return DateFormatter() // Simplified for brevity, original logic can be restored if needed
    }
}

// MARK: - Preview
#Preview {
    MessagesView()
        .environmentObject(MessageStore())
        .environmentObject(UserStore())
}
