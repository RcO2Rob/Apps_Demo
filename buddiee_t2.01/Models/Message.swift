import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let text: String
    let imageURL: String?
    let createdAt: Date
    let isRead: Bool
} 
