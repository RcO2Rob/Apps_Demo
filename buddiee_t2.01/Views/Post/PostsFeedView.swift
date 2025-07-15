import SwiftUI

struct PostsFeedView: View {
    @EnvironmentObject var postStore: PostStore
    let onAvatarTap: (UUID) -> Void
    
    private var sortedPublicPosts: [Post] {
        let publicPosts = postStore.getPublicPosts()
        return publicPosts.sorted { post1, post2 in
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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(sortedPublicPosts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        PostCard1(post: post, onAvatarTap: {userId in
                            onAvatarTap(userId)  // 👈 继续传给 PostsFeedView 或 ContentView
                        })
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        //.navigationTitle("Buddiee")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    withAnimation {
                        postStore.refreshPosts()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.accentColor)
                        Text("Buddiee")
                            .font(.title2).bold()
                            .foregroundColor(.primary)
                    }
                    
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Refresh Feed")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}

//#Preview {
//    NavigationView {
//        PostsFeedView()
//            .environmentObject(PostStore())
//    }
//}
