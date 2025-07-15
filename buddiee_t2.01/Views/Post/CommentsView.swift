import SwiftUI

struct CommentsView: View {
    @EnvironmentObject var store: PostStore
    @EnvironmentObject var userStore: UserStore
    let post: Post
    @State private var newComment: String = ""
    @State private var showingCommentAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Comments header
            Text("Comments")
                .font(.headline)
                .padding(.horizontal)
            
            // Comment input
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: addComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
            }
            
            // Comments list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(post.comments) { comment in
                        CommentRowView(comment: comment)
                    }
                }
                .padding(.horizontal)
            }
        }
        .alert("Comment Added", isPresented: $showingCommentAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func addComment() {
        guard !newComment.isEmpty, let currentUser = userStore.currentUser else { return }
        let comment = Comment(
            id: UUID(),
            postId: post.id,
            userId: currentUser.id,
            username: currentUser.username,
            text: newComment,
            createdAt: Date()
        )
        store.addComment(comment, to: post)
        newComment = ""
        showingCommentAlert = true
    }
}

struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(comment.text)
                .font(.body)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CommentsView(post: Post(
        id: UUID(),
        userId: UUID(),
        username: "Sample User",
        photos: ["sample_image_url"],
        mainCaption: "Sample Post",
        detailedCaption: "Sample description",
        subject: "study",
        location: "London",
        userLocation: nil,
        createdAt: Date(),
        likes: 0,
        comments: [],
        isPrivate: false,
        isPinned: false
    ))
    .environmentObject(PostStore())
    .environmentObject(UserStore())
} 
