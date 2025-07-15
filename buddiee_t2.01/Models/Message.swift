import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let sender: UUID
    let receiver: UUID
    let conversationId: String
    let text: String
    let imageURL: String?
    let createdAt: Date
    var isRead: Bool
}
