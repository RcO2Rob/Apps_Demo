import SwiftUI

// MARK: - Main Profile View
struct ProfileView: View {
    let user: User
    @EnvironmentObject private var postStore: PostStore
    @EnvironmentObject private var userStore: UserStore
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var selectedPost: Post?
    @State private var showingDeleteAlert = false
    @State private var postToDelete: Post?
    @State private var selectedTab: ProfileTab = .posts

    enum ProfileTab: CaseIterable {
        case posts, history

        var title: String {
            switch self {
            case .posts: return "Posts"
            case .history: return "History"
            }
        }
    }

    private var isCurrentUser: Bool {
        user.id == userStore.currentUser?.id
    }

    private var userPosts: [Post] {
        let posts = postStore.getUserPosts(for: user.id.uuidString)
        return posts.sorted { post1, post2 in
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
                // Header
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
                    
                    if let profilePicture = user.profilePicture,
                           let url = URL(string: profilePicture) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .foregroundColor(.gray)
                        }

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

                // Tab Selector with underline style
                HStack {
                    ForEach(ProfileTab.allCases, id: \.self) { tab in
                        VStack {
                            Text(tab.title)
                                .fontWeight(selectedTab == tab ? .bold : .regular)
                                .foregroundColor(selectedTab == tab ? .blue : .gray)
                                .onTapGesture {
                                    withAnimation {
                                        selectedTab = tab
                                    }
                                }

                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedTab == tab ? .blue : .clear)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                // Tab Content
                Group {
                    if selectedTab == .posts {
                        VStack(alignment: .leading, spacing: 16) {
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
                    } else {
                        HistoryView()
                            .padding(.horizontal)
                    }
                }
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

// MARK: - History View Placeholder
struct HistoryView: View {
    var body: some View {
        Text("No history view yet")
            .foregroundColor(.gray)
            .padding()
    }
}
