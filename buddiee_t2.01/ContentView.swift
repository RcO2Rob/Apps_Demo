//
//  ContentView.swift
//  buddiee_t2.01
//
//  Created by Helen Fung on 07/06/2025.
import SwiftUI

struct SourceFilterButton: View {
    let source: PostSource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(source.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var userStore: UserStore
    @StateObject var messageStore = MessageStore()
    @StateObject var locationStore = LocationStore()
    @StateObject var historyStore = BrowsingHistoryStore()
    @State private var selectedTab = 0
    @State private var showingCreateOptions = false
    @State private var shouldNavigateToFeed = false
    @State private var navigatedFromAvatarTap = false

    @State private var selectedUserId: UUID? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                PostsFeedView(onAvatarTap: { userId in
                    self.selectedUserId = userId
                    self.navigatedFromAvatarTap = true
                    self.selectedTab = 3 // 👈 Messages tab 的 tag
                })
            }
            .tabItem {
                Image(systemName: "doc.text.fill")
                Text("Posts")
            }
            .tag(0)
            
            // Create Post Button View
            CreatePostButtonView(showingCreateOptions: $showingCreateOptions)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Create")
                }
                .tag(1)
            
            LocationView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Location")
                }
                .tag(2)
            MessagesView(initialUserId: selectedUserId)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Messages")
                }
                .tag(3)
            if let user = userStore.currentUser{
                ProfileView(user: user)
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(4)
                
            } else {
                Text("请先登录")
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(4)
            }
        }
        .environmentObject(postStore)
        .environmentObject(userStore)
        .environmentObject(messageStore)
        .environmentObject(locationStore)
        .environmentObject(historyStore)
        .sheet(isPresented: $showingCreateOptions) {
            CreatePostOptionsView(shouldNavigateToFeed: $shouldNavigateToFeed, showingCreateOptions: $showingCreateOptions)
        }
        .onChange(of: shouldNavigateToFeed) { _, newValue in
            if newValue {
                showingCreateOptions = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                    shouldNavigateToFeed = false
                }
            }
        }
        .onChange(of: selectedTab) {_, newValue in
            if newValue == 3 {
                    // ✅ 如果不是通过点击头像进来的，才清空
                    if !navigatedFromAvatarTap {
                        selectedUserId = nil
                    }
                    // ✅ 无论如何都重置标志
                    navigatedFromAvatarTap = false
                }
        }
    }
}

// Create Post Button View
struct CreatePostButtonView: View {
    @Binding var showingCreateOptions: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: {
                showingCreateOptions = true
            }) {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Create Post")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// Create Post Options Overlay View
struct CreatePostOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPhotoPost = false
    @State private var showingTextPost = false
    @Binding var shouldNavigateToFeed: Bool
    @Binding var showingCreateOptions: Bool
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Photo Post Option (Bigger button)
                Button(action: {
                    showingPhotoPost = true
                }) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            Text("Post with Photos")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("(Recommended)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 40)
                
                // Text Post Option (Smaller button)
                Button(action: {
                    showingTextPost = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        Text("Post with Text")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 25)
                    .background(Color.gray)
                    .cornerRadius(15)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 60)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingPhotoPost) {
            PostCreationView(shouldNavigateToFeed: $shouldNavigateToFeed, showingCreateOptions: $showingCreateOptions)
        }
        .sheet(isPresented: $showingTextPost) {
            TextOnlyPostView(shouldNavigateToFeed: $shouldNavigateToFeed, showingCreateOptions: $showingCreateOptions)
        }
    }
}

// Text Only Post View
struct TextOnlyPostView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: ActivityCategory = .study
    @State private var showSuccessAlert = false
    @Binding var shouldNavigateToFeed: Bool
    @Binding var showingCreateOptions: Bool
    
    private func createTextPost() {
        let newPost = Post(
            id: UUID(),
            userId: userStore.currentUser?.id ?? UUID(),
            username: userStore.currentUser?.username ?? "Unknown User",
            photos: [],
            mainCaption: title,
            detailedCaption: content,
            subject: selectedCategory.rawValue,
            location: userStore.currentUser?.bio,
            userLocation: nil,
            createdAt: Date(),
            likes: 0,
            comments: [],
            isPrivate: false,
            isPinned: false
        )
        postStore.createPost(newPost)
        showSuccessAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            shouldNavigateToFeed = true
            showingCreateOptions = false
            dismiss()
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 150)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ActivityCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Text Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createTextPost()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
            .alert("POSTED SUCCESSFULLY!!!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

// Placeholder views for each tab
struct PostsFeedView_TabPlaceholder: View {
    var body: some View {
        Text("Posts Feed")
    }
}

struct LocationView: View {
    var body: some View {
        Text("Location Map")
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search posts...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Custom button style for hover effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    ContentView()
        .environmentObject(PostStore())
}
