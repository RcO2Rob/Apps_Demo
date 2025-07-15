import Foundation
import Combine

@MainActor
class PostStore: ObservableObject {
    @Published var posts: [Post] = []
    @Published var userPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isStatusVisible: Bool = false
    @Published var statusMessage: String = ""
    
    
    private let userDefaults = UserDefaults.standard
    private let postsKey = "savedPosts"
    private let currentUser = UserStore().currentUser
    
    init() {
        // Force clear all stored posts and reset to clean sample data
        clearAllPosts()
        createSamplePosts()
    }
    
    private func createSamplePosts() {
        self.posts = [
            Post(id: UUID(), userId: UUID(), username: "Alex", photos: ["https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop"], mainCaption: "Gym buddy, London", detailedCaption: "Looking for a consistent gym partner to go to PureGym with 3-4 times a week. Let's motivate each other!", subject: "Gym", location: "London", userLocation: "PureGym", createdAt: Date().addingTimeInterval(-86400 * 2), likes: 15, comments: [], isPrivate: false, isPinned: false),
            Post(id: UUID(), userId: UUID(), username: "Sarah", photos: ["https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400&h=300&fit=crop"], mainCaption: "UCL Study Group", detailedCaption: "Finals are coming up! Need a few people to review lecture notes and do past papers for ECON001. We can meet at the student center.", subject: "Study", location: "UCL, London", userLocation: "Student Center", createdAt: Date().addingTimeInterval(-86400 * 1), likes: 8, comments: [], isPrivate: false, isPinned: false),
            Post(id: UUID(), userId: UUID(), username: "Mike", photos: ["https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400&h=300&fit=crop"], mainCaption: "Hackathon Teammate Wanted", detailedCaption: "I'm a frontend dev looking for a backend dev and a UI/UX designer for the upcoming HackLondon event. Let's build something amazing!", subject: "Coding", location: "Imperial College", userLocation: "Imperial College", createdAt: Date(), likes: 23, comments: [], isPrivate: false, isPinned: false),
            Post(id: UUID(), userId: UUID(), username: "Emma", photos: ["https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=300&fit=crop"], mainCaption: "Music Jam Session", detailedCaption: "Guitarist and vocalist looking for a drummer and a bassist to jam with. I play mostly indie and rock. Have a small studio space we can use.", subject: "Music", location: "Shoreditch", userLocation: "Shoreditch", createdAt: Date().addingTimeInterval(-86400 * 5), likes: 30, comments: [], isPrivate: false, isPinned: false),
            Post(id: UUID(), userId: UUID(), username: "David", photos: ["https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop"], mainCaption: "Photography walk", detailedCaption: "Amateur photographer looking for someone to explore and take photos with this weekend. Thinking of going to Greenwich Park.", subject: "Photography", location: "Greenwich", userLocation: "Greenwich Park", createdAt: Date().addingTimeInterval(-86400 * 3), likes: 12, comments: [], isPrivate: false, isPinned: false),
            Post(id: UUID(), userId: UUID(), username: "Lisa", photos: ["https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop"], mainCaption: "Vegan recipe exchange", detailedCaption: "Anyone else into vegan cooking? Would love to meet up, share recipes, and maybe cook together. All levels welcome!", subject: "Food", location: "Camden", userLocation: "Camden Market", createdAt: Date().addingTimeInterval(-86400 * 4), likes: 18, comments: [], isPrivate: false, isPinned: false)
        ]
        savePosts()
        print("DEBUG: Sample posts created successfully")
        fetchPublicPostsFromDatabase()
       
        
    }
    
    // MARK: - Storage Functions
    private func savePosts() {
        if let encoded = try? JSONEncoder().encode(posts) {
            userDefaults.set(encoded, forKey: postsKey)
        }
        
    }
    
    private func loadPosts() {
        if let data = userDefaults.data(forKey: postsKey),
           let decoded = try? JSONDecoder().decode([Post].self, from: data) {
            posts = decoded
        }
    }
    
    // MARK: - Post Management Functions
    func fetchPublicPostsFromDatabase() {
        Task{
            do{
                let results = try await SupabaseManager.shared.fetchAllPosts()
                results.forEach(createPost(_:))
                
                print(results)
                print("fetch successfully")
            }catch{
                print("fetchPostsFromDatabase error:", error)
            }
        }
    }
    
    func fetchUserPostsFromDatabase(_ userId : UUID) {
        Task{
            do{
                let results = try await SupabaseManager.shared.fetchUserPosts(userId)
                results.forEach(createPost(_:))
                
                print(results)
                print("fetch successfully")
            }catch{
                print("fetchPostsFromDatabase error:", error)
            }
        }
    }
    
    func createPost(_ post: Post) {
        //print("DEBUG: Creating post: \(post)")
        print("DEBUG: Posts count before: \(posts.count)")
        
        posts.insert(post, at: 0)
       //print("DEBUG: Posts count after: \(posts.count)")
        //print("DEBUG: All posts after creation: \(posts.map { $0.mainCaption })")
        savePosts()
        updateUserPosts()
        // Force UI refresh
        objectWillChange.send()
    }
    
    func likePost(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = Post(
                id: post.id,
                userId: post.userId,
                username: post.username,
                photos: post.photos ?? [],
                mainCaption: post.mainCaption,
                detailedCaption: post.detailedCaption,
                subject: post.subject,
                location: post.location,
                userLocation: post.userLocation,
                createdAt: post.createdAt,
                likes: post.likes + 1,
                comments: post.comments,
                isPrivate: post.isPrivate,
                isPinned: post.isPinned
            )
            savePosts()
        }
    }
    
    func addComment(_ comment: Comment, to post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].comments.append(comment)
            Task{
                try await SupabaseManager.shared.savePost(posts[index])
            }
            savePosts()
        }
    }
    
    func updatePost(_ updatedPost: Post) {
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            posts[index] = updatedPost
            savePosts()
            updateUserPosts()
        }
    }
    
    func deletePost(_ post: Post) {
        posts.removeAll { $0.id == post.id }
        savePosts()
        updateUserPosts()
    }
    
    func pinPost(_ post: Post) {
        // Unpin all other posts by this user first
        for i in 0..<posts.count {
            if posts[i].userId == post.userId {
                posts[i].isPinned = false
            }
        }
        
        // Pin the selected post
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isPinned = true
            savePosts()
            updateUserPosts()
        }
    }
    
    func togglePostPrivacy(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isPrivate.toggle()
            savePosts()
            updateUserPosts()
        }
    }
    
    // MARK: - User Posts Management
    func updateUserPosts() {
        // This will be called when we need to refresh user posts
        // The actual filtering will be done in the views
    }
    
    func getUserPosts(for userId: String) -> [Post] {
        let userPosts = posts.filter { $0.userId.uuidString == userId }
        //print("DEBUG: getUserPosts for \(userId): \(userPosts.map { $0.mainCaption })")
        return userPosts
    }
    
    func getPublicPosts() -> [Post] {
        let publicPosts = posts.filter { !$0.isPrivate }
        //print("DEBUG: getPublicPosts: \(publicPosts.map { $0.mainCaption })")
        return publicPosts
    }
    
    func getPinnedPost(for userId: String) -> Post? {
        return posts.first { $0.userId.uuidString == userId && $0.isPinned }
    }
    
    // MARK: - Refresh Function
    func refreshPosts() {
        loadPosts()
        updateUserPosts()
        objectWillChange.send()
    }
    
    // MARK: - Clear All Posts
    func clearAllPosts() {
        posts = []
        userPosts = []
        userDefaults.removeObject(forKey: postsKey)
        print("DEBUG: All posts cleared")
    }
    
    // MARK: - Manual Reset (for future use)
    func resetToSamplePosts() {
        clearAllPosts()
        createSamplePosts()
        updateUserPosts()
        objectWillChange.send()
        print("DEBUG: Reset to sample posts completed")
    }
} 
