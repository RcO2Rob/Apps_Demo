import SwiftUI

struct PostDetailView: View {
    let post: Post
    @EnvironmentObject var historyStore: BrowsingHistoryStore
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) var dismiss
    @State private var newComment: String = ""
    @State private var showingCommentAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Cover Image(s) - TabView for multiple photos
                if let photos = post.photos, !photos.isEmpty {
                    TabView {
                        ForEach(photos, id: \.self) { photoURL in
                            if photoURL.hasPrefix("file://") {
                                // Handle local file URLs
                                if let url = URL(string: photoURL),
                                   let imageData = try? Data(contentsOf: url),
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    fallbackImageView
                                }
                            } else if photoURL.hasPrefix("http") {
                                // Handle external URLs
                                if let url = URL(string: photoURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        case .failure(_):
                                            fallbackImageView
                                        case .empty:
                                            ProgressView()
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        @unknown default:
                                            fallbackImageView
                                        }
                                    }
                                } else {
                                    fallbackImageView
                                }
                            } else {
                                fallbackImageView
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 300)
                } else {
                    fallbackImageView
                }
                
                // Content below image
                VStack(alignment: .leading, spacing: 12) {
                    // Main Caption (Title)
                    Text(post.mainCaption)
                        .font(.title)
                        .bold()
                    
                    // User Info and other details
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text(post.username)
                        Spacer()
                        Text(post.createdAt, style: .relative)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    // Detailed Caption
                    Text(post.detailedCaption ?? "")
                        .font(.body)
                    
                    // Location
                    if let location = post.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Comments Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comments")
                            .font(.headline)
                        
                        // Comment Input
                        HStack {
                            TextField("Add a comment...", text: $newComment)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: addComment) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(newComment.isEmpty)
                        }
                        
                        // Comments List
                        ForEach(post.comments) { comment in
                            CommentView(comment: comment)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            historyStore.addToHistory(post)
        }
        .alert("Comment Added", isPresented: $showingCommentAlert) {
            Button("OK", role: .cancel) {}
        }
    }
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        
        let comment = Comment(
            id: UUID(),
            postId: post.id,
            userId: userStore.currentUser?.id ?? UUID(),
            username: userStore.currentUser?.username ?? "Unknown",
            text: newComment,
            createdAt: Date()
        )
        
        postStore.addComment(comment, to: post)
        newComment = ""
        showingCommentAlert = true
    }
    
    private var fallbackImageView: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Image")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.username)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.text)
                .font(.body)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        PostDetailView(post: Post(
            id: UUID(),
            userId: UUID(),
            username: "Sample User",
            photos: [],
            mainCaption: "Sample Post",
            detailedCaption: "Sample description",
            subject: "study",
            location: "London",
            userLocation: nil,
            createdAt: Date(),
            likes: 0,
            comments: []
        ))
            .environmentObject(BrowsingHistoryStore())
            .environmentObject(PostStore())
            .environmentObject(UserStore())
    }
} 
