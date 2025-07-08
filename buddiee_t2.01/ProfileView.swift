import SwiftUI

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let user: User
    let isCurrentUser: Bool
    let onEditProfile: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: user.profilePicture ?? "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
            
            Text(user.username)
                .font(.title)
                .bold()
            
            Text(user.bio ?? "")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isCurrentUser {
                HStack(spacing: 20) {
                    Button(action: onEditProfile) {
                        Label("Edit Profile", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onSettings) {
                        Label("Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Interests View
struct InterestsView: View {
    let interests: [ActivityCategory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interests")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest.rawValue.capitalized)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                }
            }
        }
        .padding()
    }
}

// MARK: - Posts View
struct UserPostsView: View {
    let posts: [Post]
    let isCurrentUser: Bool
    let onEditPost: (Post) -> Void
    let onPinPost: (Post) -> Void
    let onTogglePrivacy: (Post) -> Void
    let onDeletePost: (Post) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isCurrentUser ? "My Posts" : "User's Posts")
                .font(.headline)
            
            ForEach(posts) { post in
                PostCard1(post: post, onAvatarTap: { _ in})
                    .overlay(alignment: .topTrailing) {
                        if isCurrentUser {
                            PostMenuView(
                                post: post,
                                onEdit: { onEditPost(post) },
                                onPin: { onPinPost(post) },
                                onTogglePrivacy: { onTogglePrivacy(post) },
                                onDelete: { onDeletePost(post) }
                            )
                        }
                    }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Post Menu View
struct PostMenuView: View {
    let post: Post
    let onEdit: () -> Void
    let onPin: () -> Void
    let onTogglePrivacy: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Menu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            if post.isPinned {
                Button(action: onPin) {
                    Label("Unpin", systemImage: "pin.slash")
                }
            } else {
                Button(action: onPin) {
                    Label("Pin to Top", systemImage: "pin.fill")
                }
            }
            
            Button(action: onTogglePrivacy) {
                if post.isPrivate {
                    Label("Make Public", systemImage: "eye.fill")
                } else {
                    Label("Make Private", systemImage: "eye.slash.fill")
                }
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(5)
                .background(Color.white.opacity(0.7))
                .clipShape(Circle())
        }
        .offset(x: -10, y: 10)
    }
}

// MARK: - Main Profile View
struct ProfileView: View {
    let user: User
    @EnvironmentObject private var postStore: PostStore
    @EnvironmentObject private var userStore: UserStore
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingEditPost = false
    @State private var selectedPost: Post?
    @State private var showingDeleteAlert = false
    @State private var postToDelete: Post?
    
    private var isCurrentUser: Bool {
        user.id == userStore.currentUser?.id
    }
    
    private var userPosts: [Post] {
        let posts = postStore.getUserPosts(for: user.id.uuidString)
        return posts.sorted { post1, post2 in
            // Sort by pinned status first, then by creation date
            if post1.isPinned && !post2.isPinned {
                return true
            } else if !post1.isPinned && post2.isPinned {
                return false
            } else {
                return post1.createdAt > post2.createdAt
            }
        }
    }
    
    private var pinnedPost: Post? {
        postStore.getPinnedPost(for: user.id.uuidString)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        if isCurrentUser {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Image(systemName: user.profilePicture ?? "person.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text(user.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(user.bio ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    if isCurrentUser {
                        Button(action: { showingEditProfile = true }) {
                            Label("Edit Profile", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Bio Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(user.bio ?? "")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Pinned Post Section (if exists)
                    if let pinned = pinnedPost {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.blue)
                                Text("Pinned Post")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            PostCard2(post: pinned)
                                .overlay(alignment: .topTrailing) {
                                    if isCurrentUser {
                                        PostMenuView(
                                            post: pinned,
                                            onEdit: { selectedPost = pinned },
                                            onPin: { postStore.pinPost(pinned) },
                                            onTogglePrivacy: { postStore.togglePostPrivacy(pinned) },
                                            onDelete: { 
                                                postToDelete = pinned
                                                showingDeleteAlert = true
                                            }
                                        )
                                    }
                                }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                
                // Posts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Posts")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    if userPosts.isEmpty {
                        Text("No posts yet")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(userPosts) { post in
                            PostCard2(post: post)
                                .overlay(alignment: .topTrailing) {
                                    if isCurrentUser {
                                        PostMenuView(
                                            post: post,
                                            onEdit: { selectedPost = post },
                                            onPin: { postStore.pinPost(post) },
                                            onTogglePrivacy: { postStore.togglePostPrivacy(post) },
                                            onDelete: { 
                                                postToDelete = post
                                                showingDeleteAlert = true
                                            }
                                        )
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(user: user)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $selectedPost) { post in
            EditPostView(post: post)
        }
        .alert("Delete Post", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let post = postToDelete {
                    postStore.deletePost(post)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        guard let containerWidth = proposal.width else {
            return (sizes.map { _ in .zero }, .zero)
        }
        
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, currentY + rowHeight)
        }
        
        return (offsets, CGSize(width: containerWidth, height: maxY))
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView(user: User(
                id: UUID(),
                username: "TestUser",
                profilePicture: nil,
                bio: "Test bio"
            ))
                .environmentObject(PostStore())
        }
    }
} 
