import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let sender: UUID
    let receiver: UUID
    let text: String
    let imageURL: String?
    let createdAt: Date
    let isRead: Bool
} 
