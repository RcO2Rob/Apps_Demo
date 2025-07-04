import Foundation

private let yyyyMMddFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.timeZone = TimeZone(secondsFromGMT: 0)
    return fmt
}()

public struct Post: Identifiable, Codable {
    public let id: UUID
    public let userId: UUID
    public let username: String // Add username for display
    public let photos: [String]? // URLs or local paths
    public let mainCaption: String
    public let detailedCaption: String?
    public let subject: String
    public let location: String?
    public let userLocation: String? // Specific meeting location
    public let createdAt: Date
    public var likes: Int
    public var comments: [Comment]
    public var isPrivate: Bool // Add privacy setting
    public var isPinned: Bool // Add pinned status
    
    
    enum CodingKeys: String, CodingKey {
            case id, userId, username, photos,
                 mainCaption, detailedCaption,
                 subject, location, userLocation,
                 createdAt, likes, comments,
                 isPrivate, isPinned
        }
    
    public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
        
            id               = try c.decode(UUID.self,    forKey: .id)
            userId           = try c.decode(UUID.self,    forKey: .userId)
            username         = try c.decode(String.self,  forKey: .username)
            //photos           = try c.decodeIfPresent([String].self, forKey: .photos)
            if let arr = try? c.decodeIfPresent([String].self, forKey: .photos) {
                        photos = arr
                    } else if let single = try? c.decodeIfPresent(String.self, forKey: .photos) {
                        // 如果后端给了单个 URL 字符串，把它包成长度为 1 的数组
                        photos = [single]
                    } else {
                        // null 或者根本没字段时，都设成 nil (或 [])
                        photos = nil
                    }
            mainCaption      = try c.decode(String.self,  forKey: .mainCaption)
            detailedCaption  = try c.decodeIfPresent(String.self, forKey: .detailedCaption)
            subject          = try c.decode(String.self,  forKey: .subject)
            location         = try c.decodeIfPresent(String.self, forKey: .location)
            userLocation     = try c.decodeIfPresent(String.self, forKey: .userLocation)

            // 自定义解析 “yyyy-MM-dd” 格式
            let dateString = try c.decode(String.self, forKey: .createdAt)
            guard let dt = yyyyMMddFormatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .createdAt, in: c,
                    debugDescription: "日期必须是 yyyy-MM-dd 格式"
                )
            }
            createdAt = dt

            likes      = try c.decodeIfPresent(Int.self, forKey: .likes)     ?? 0
            comments   = try c.decodeIfPresent([Comment].self, forKey: .comments) ?? []
            isPrivate  = try c.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
            isPinned   = try c.decodeIfPresent(Bool.self, forKey: .isPinned)  ?? false
        }
    
    public init(id: UUID = UUID(), userId: UUID = UUID(), username: String, photos: [String], mainCaption: String, detailedCaption: String?, subject: String, location: String?, userLocation: String?, createdAt: Date = Date(), likes: Int = 0, comments: [Comment] = [], isPrivate: Bool = false, isPinned: Bool = false) {
        self.id = id
        self.userId = userId
        self.username = username
        self.photos = photos
        self.mainCaption = mainCaption
        self.detailedCaption = detailedCaption
        self.subject = subject
        self.location = location
        self.userLocation = userLocation
        self.createdAt = createdAt
        self.likes = likes
        self.comments = comments
        self.isPrivate = isPrivate
        self.isPinned = isPinned
    }
} 
