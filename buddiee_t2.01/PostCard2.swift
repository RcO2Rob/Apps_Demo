//
//  PostCard1.swift
//  buddiee_t2.01
//
//  Created by Helen Fung on 07/06/2025.
import SwiftUI

struct PostCard2: View {
    let post: Post
    @EnvironmentObject private var postStore: PostStore
    @State private var showingDetail = false
    @State private var showingComments = false
    
    @State private var selectedUserId: UUID? = nil
    @State private var showMessagesView = false
    //let onAvatarTap: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover Image
            if let photos = post.photos,let firstImage = photos.first {
                if firstImage.hasPrefix("file://") {
                    // Handle local file URLs
                    if let url = URL(string: firstImage),
                       let imageData = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    } else {
                        fallbackImageView
                    }
                } else if firstImage.hasPrefix("http") {
                    // Handle external URLs
                    if let imageUrl = URL(string: firstImage) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                            case .failure(_):
                                fallbackImageView
                            case .empty:
                                ProgressView()
                                    .frame(height: 250)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
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
            } else {
                fallbackImageView
            }
            
            
            // Content below image
            VStack(alignment: .leading, spacing: 12) {
                // MARK: - Header: User Info
                HStack {
                    Button(action: {
                    }){
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(post.username)
                                .font(.headline)
                            
                            // Privacy indicator
                            if post.isPrivate {
                                Image(systemName: "eye.slash.fill")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            
                            // Pinned indicator
                            if post.isPinned {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        
                        Text(post.location ?? "Unknown location")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    // Post age
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Main Caption (Title)
                Text(post.mainCaption)
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Detailed Caption (Description)
                Text(post.detailedCaption ?? "")
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                // Location
                if let location = post.location {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Meeting Location
                if let userLocation = post.userLocation {
                    Label("Meet at: \(userLocation)", systemImage: "location.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                // Interaction buttons
                HStack(spacing: 20) {
                    Button(action: {
                        postStore.likePost(post)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                            Text("\(post.likes)")
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        showingComments = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .foregroundColor(.blue)
                            Text("\(post.comments.count)")
                                .font(.caption)
                        }
                    }
                    
                    Spacer()
                }
                .foregroundColor(.primary)

            }.padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                PostDetailView(post: post)
            }
        }
        .sheet(isPresented: $showingComments) {
            NavigationView {
                CommentsView(post: post)
            }
        }
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
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Preview
struct PostCard2_Previews: PreviewProvider {
    static var previews: some View {
        PostCard2(post: Post(
            id: UUID(),
            userId: UUID(),
            username: "Sample User",
            photos: ["https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=2787&auto=format&fit=crop"],
            mainCaption: "Sample Post",
            detailedCaption: "This is a sample description that shows how the text will look. It can be a bit long but it will be truncated.",
            subject: "study",
            location: "London",
            userLocation: nil,
            createdAt: Date(),
            likes: 10,
            comments: []
        ))
        .environmentObject(PostStore())
        .padding()
    }
}
