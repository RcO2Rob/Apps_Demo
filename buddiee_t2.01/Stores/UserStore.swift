import Foundation
import Combine
import Supabase
// import buddiee_t2_01App // Removed incorrect import
// If User is in Models, use: import buddiee_t2_01App.Models

class UserStore: ObservableObject {
    @Published var currentUser: User?
    @Published var users: [User] = []
    
    
    private var cancellables = Set<AnyCancellable>()
    
    
    init() {
        // Set up a default current user for testing
//        currentUser = User(
//            id: UUID(),
//            username: "TestUser",
//            profilePicture: nil,
//            bio: "Test bio"
//        )
        SupabaseManager.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { authUser in
                guard let id = authUser?.id else { return }
                Task {
                  do {
                    let profile = try await SupabaseManager.shared.fetchUserProfile(id)
                    DispatchQueue.main.async {
                        self.currentUser = profile
                    }
                  } catch {
                    print("拉取完整 Profile 失败：", error)
                  }
                }
              })
            .map { authUser in authUser.map { self.map(authUser: $0)}}
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
        
        
    }
    
    private func map(authUser: Auth.User) -> User {
        
        let metadata = authUser.userMetadata
        let profilePicture = metadata["profilePicture"] as? String
        let bioText = metadata["bio"] as? String
        
        return User(
                id: authUser.id,
                username: authUser.email ?? "",
                profilePicture: profilePicture,
                bio: bioText
            )
        }
    
    func login(username: String, password: String) {}
    
    func updateProfile(_ user: User) {
        currentUser = user
    }
    
    func fetchUsers() {}
} 
