import SwiftUI
import PhotosUI

struct EditPostView: View {
    @EnvironmentObject var postStore: PostStore
    @Environment(\.dismiss) var dismiss
    
    let post: Post
    @State private var mainCaption: String
    @State private var detailedCaption: String
    @State private var subject: String
    @State private var selectedImages: [UIImage] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    
    init(post: Post) {
        self.post = post
        _mainCaption = State(initialValue: post.mainCaption)
        _detailedCaption = State(initialValue: post.detailedCaption ?? "")
        _subject = State(initialValue: post.subject)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PhotosPicker(
                        selection: $photoPickerItems,
                        maxSelectionCount: 6,
                        matching: .images,
                        photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Select up to 6 photos")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .onChange(of: photoPickerItems) { _, newItems in
                        Task {
                            selectedImages = []
                            for item in newItems.prefix(6) {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImages.append(uiImage)
                                }
                            }
                        }
                    }
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    
                    TextField("Main Caption", text: $mainCaption)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextEditor(text: $detailedCaption)
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    TextField("Subject", text: $subject)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Edit Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        // Convert selected images to URLs or keep existing ones
        let imageURLs = selectedImages.isEmpty ? post.photos : selectedImages.map { _ in "photo.on.rectangle" }
        let updatedPost = Post(
            id: post.id,
            userId: post.userId,
            username: post.username,
            photos: imageURLs ?? [],
            mainCaption: mainCaption,
            detailedCaption: detailedCaption,
            subject: subject,
            location: post.location,
            userLocation: post.userLocation,
            createdAt: post.createdAt,
            likes: post.likes,
            comments: post.comments,
            isPrivate: post.isPrivate,
            isPinned: post.isPinned
        )
        postStore.updatePost(updatedPost)
        dismiss()
    }
}

#Preview {
    EditPostView(post: Post(
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
    .environmentObject(PostStore())
} 
