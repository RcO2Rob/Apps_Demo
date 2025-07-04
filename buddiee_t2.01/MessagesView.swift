import SwiftUI

struct MessagesView: View {
    @State private var selectedUserId: UUID? = nil
    @State private var messageText: String = ""
    @State private var messages: [Message] = sampleMessages
    @EnvironmentObject var userStore: UserStore
    
    var body: some View {
        NavigationView {
            Group {
                if let selectedUserId = selectedUserId {
                    ChatView(
                        userId: selectedUserId,
                        messages: messages.filter { $0.senderId == selectedUserId || $0.receiverId == selectedUserId },
                        messageText: $messageText,
                        onSend: sendMessage,
                        onBack: { self.selectedUserId = nil }
                    )
                } else {
                    ConversationsList(
                        conversations: sampleUsers,
                        messages: messages,
                        onSelectUser: { user in
                            self.selectedUserId = user.id
                        }
                    )
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty, let selectedUserId = selectedUserId else { return }
        
        let newMessage = Message(
            id: UUID(),
            senderId: UUID(), // Replace with actual current user ID
            receiverId: selectedUserId,
            text: messageText,
            imageURL: nil,
            createdAt: Date(),
            isRead: false
        )
        
        messages.append(newMessage)
        messageText = ""
    }
}

struct ChatView: View {
    let userId: UUID
    let messages: [Message]
    @Binding var messageText: String
    let onSend: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            // Chat Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                if let user = sampleUsers.first(where: { $0.id == userId }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username)
                                .font(.headline)
                            Text(user.bio ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "phone")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: .gray.opacity(0.2), radius: 1, y: 1)
            
            // Messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages.sorted(by: { $0.createdAt < $1.createdAt })) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Message Input
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
}

struct MessageBubble: View {
    let message: Message
    @EnvironmentObject var userStore: UserStore
    
    var body: some View {
        HStack {
            if message.senderId == userStore.currentUser?.id {
                Spacer()
            }
            
            VStack(alignment: message.senderId == userStore.currentUser?.id ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.senderId == userStore.currentUser?.id ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.senderId == userStore.currentUser?.id ? .white : .primary)
                    .cornerRadius(18)
                
                Text(formatTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if message.senderId != userStore.currentUser?.id {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ConversationsList: View {
    let conversations: [User]
    let messages: [Message]
    let onSelectUser: (User) -> Void
    
    var body: some View {
        List {
            ForEach(conversations) { user in
                Button(action: { onSelectUser(user) }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(user.username)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if let lastMessage = getLastMessage(for: user.id) {
                                    Text(formatTime(lastMessage.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let lastMessage = getLastMessage(for: user.id) {
                                Text(lastMessage.text)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                Text("No messages yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func getLastMessage(for userId: UUID) -> Message? {
        return messages
            .filter { $0.senderId == userId || $0.receiverId == userId }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// Sample Data
let sampleUsers: [User] = [
    User(id: UUID(), username: "Alex Johnson", profilePicture: nil, bio: "Gym enthusiast looking for workout buddies"),
    User(id: UUID(), username: "Sarah Chen", profilePicture: nil, bio: "UCL student studying Computer Science"),
    User(id: UUID(), username: "Mike Rodriguez", profilePicture: nil, bio: "Frontend developer, hackathon lover"),
    User(id: UUID(), username: "Emma Wilson", profilePicture: nil, bio: "Guitarist and vocalist, indie music fan"),
    User(id: UUID(), username: "David Thompson", profilePicture: nil, bio: "Amateur photographer, nature lover"),
    User(id: UUID(), username: "Lisa Park", profilePicture: nil, bio: "Vegan chef, recipe collector")
]

let sampleMessages: [Message] = [
    // Conversation with Alex
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Hey! I saw your gym post. Are you still looking for a workout partner?", imageURL: nil, createdAt: Date().addingTimeInterval(-3600), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Yes! I'm still looking. What's your schedule like?", imageURL: nil, createdAt: Date().addingTimeInterval(-3500), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "I usually go in the mornings around 7 AM. Does that work for you?", imageURL: nil, createdAt: Date().addingTimeInterval(-3400), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Perfect! Let's meet tomorrow at PureGym?", imageURL: nil, createdAt: Date().addingTimeInterval(-3300), isRead: false),
    
    // Conversation with Sarah
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Hi! I'm also studying for ECON001 finals. Want to form a study group?", imageURL: nil, createdAt: Date().addingTimeInterval(-7200), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "That would be great! When are you free to meet?", imageURL: nil, createdAt: Date().addingTimeInterval(-7100), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "I'm free tomorrow afternoon. Student center at 2 PM?", imageURL: nil, createdAt: Date().addingTimeInterval(-7000), isRead: true),
    
    // Conversation with Mike
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Hey! I'm interested in your hackathon project. What tech stack are you thinking?", imageURL: nil, createdAt: Date().addingTimeInterval(-10800), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "I'm thinking React Native for mobile and Node.js backend. What about you?", imageURL: nil, createdAt: Date().addingTimeInterval(-10700), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Perfect! I'm experienced with both. Let's discuss the project idea?", imageURL: nil, createdAt: Date().addingTimeInterval(-10600), isRead: false),
    
    // Conversation with Emma
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Hi! I play drums and I'm looking for people to jam with. What kind of music do you play?", imageURL: nil, createdAt: Date().addingTimeInterval(-14400), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "I play guitar and sing! Mostly indie and rock. What about you?", imageURL: nil, createdAt: Date().addingTimeInterval(-14300), isRead: true),
    
    // Conversation with David
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Hey! I'm also into photography. Want to go to Greenwich Park this weekend?", imageURL: nil, createdAt: Date().addingTimeInterval(-18000), isRead: true),
    
    // Conversation with Lisa
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Hi! I love vegan cooking too. Want to share some recipes?", imageURL: nil, createdAt: Date().addingTimeInterval(-21600), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Absolutely! Do you have any favorite vegan restaurants in Camden?", imageURL: nil, createdAt: Date().addingTimeInterval(-21500), isRead: true),
    Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Yes! There's this amazing place called 'Green Earth'. We should go together!", imageURL: nil, createdAt: Date().addingTimeInterval(-21400), isRead: false)
]

#Preview {
    MessagesView()
}
