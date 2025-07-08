//import SwiftUI
//import PhotosUI
//import Photos
//
//struct PostCreationView: View {
//    @EnvironmentObject var postStore: PostStore
//    @EnvironmentObject var userStore: UserStore
//    @Environment(\.dismiss) private var dismiss
//    @State private var selectedImages: [UIImage] = []
//    @State private var title: String = ""
//    @State private var content: String = ""
//    @State private var selectedCategory: ActivityCategory = .study
//    @State private var photoPickerItems: [PhotosPickerItem] = []
//    @State private var isLoadingImages = false
//    @State private var showSuccessAlert = false
//    @State private var currentImageIndex = 0
//    @State private var showingPhotoPicker = false
//    @State private var selectedLocation: String?
//    @State private var showingLocationPicker = false
//    @Binding var shouldNavigateToFeed: Bool
//    @Binding var showingCreateOptions: Bool
//    
//    private func saveImageToFileSystem(image: UIImage) -> URL? {
//        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
//        
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileName = "\(UUID().uuidString).jpg"
//        let fileURL = documentsDirectory.appendingPathComponent(fileName)
//        
//        do {
//            try data.write(to: fileURL)
//            return fileURL
//        } catch {
//            print("Error saving image: \(error)")
//            return nil
//        }
//    }
//    
//    private func createPost() {
//        let imageURLs = selectedImages.compactMap { saveImageToFileSystem(image: $0)?.absoluteString }
//        
//        let newPost = Post(
//            id: UUID(),
//            userId: userStore.currentUser?.id ?? UUID(),
//            username: userStore.currentUser?.username ?? "Unknown User",
//            photos: imageURLs,
//            mainCaption: title,
//            detailedCaption: content,
//            subject: selectedCategory.rawValue,
//            location: userStore.currentUser?.bio,
//            userLocation: selectedLocation,
//            createdAt: Date(),
//            likes: 0,
//            comments: [],
//            isPrivate: false,
//            isPinned: false
//        )
//        //show in the App
//        postStore.createPost(newPost)
//        Task {
//            do {
//                try await SupabaseManager.shared.savePost(newPost)
//                dismiss()         // 保存成功后回到上一页
//            } catch {
//                print("保存失败：\(error.localizedDescription)")
//            }
//        }
//        showSuccessAlert = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            shouldNavigateToFeed = true
//            showingCreateOptions = false
//            dismiss()
//        }
//        resetFields()
//    }
//    
//    private func resetFields() {
//        title = ""
//        content = ""
//        selectedImages = []
//        selectedCategory = .study
//        photoPickerItems = []
//        currentImageIndex = 0
//        selectedLocation = nil
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                // Photo Preview Section
//                if !selectedImages.isEmpty {
//                    photoPreviewSection
//                } else {
//                    photoSelectionSection
//                }
//                
//                // Post Details Section
//                postDetailsSection
//            }
//            .navigationTitle("Create Post")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Post") {
//                        createPost()
//                    }
//                    .disabled(title.isEmpty || content.isEmpty || selectedImages.isEmpty)
//                }
//            }
//            .alert("POSTED SUCCESSFULLY!!!", isPresented: $showSuccessAlert) {
//                Button("OK", role: .cancel) { }
//            }
//        }
//    }
//    
//    private var photoSelectionSection: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            
//            Image(systemName: "photo.on.rectangle.angled")
//                .font(.system(size: 80))
//                .foregroundColor(.blue)
//            
//            Text("Select Photos")
//                .font(.title2)
//                .fontWeight(.semibold)
//            
//            Text("Choose 1-6 photos from your gallery")
//                .font(.subheadline)
//                .foregroundColor(.gray)
//                .multilineTextAlignment(.center)
//            
//            PhotosPicker(
//                selection: $photoPickerItems,
//                maxSelectionCount: 6,
//                matching: .images
//            ) {
//                HStack {
//                    Image(systemName: "photo.badge.plus")
//                    Text("Choose Photos")
//                }
//                .font(.headline)
//                .foregroundColor(.white)
//                .padding()
//                .background(Color.blue)
//                .cornerRadius(12)
//            }
//            .onChange(of: photoPickerItems) { _, newItems in
//                loadSelectedImages(newItems)
//            }
//            
//            Spacer()
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color(.systemGray6))
//    }
//    
//    private var photoPreviewSection: some View {
//        VStack(spacing: 0) {
//            // Photo carousel
//            TabView(selection: $currentImageIndex) {
//                ForEach(0..<selectedImages.count, id: \.self) { index in
//                    Image(uiImage: selectedImages[index])
//                        .resizable()
//                        .scaledToFill()
//                        .frame(maxWidth: .infinity, maxHeight: 300)
//                        .clipped()
//                        .tag(index)
//                }
//            }
//            .tabViewStyle(.page(indexDisplayMode: .automatic))
//            .frame(height: 300)
//            
//            // Photo counter and selection button
//            HStack {
//                Text("\(currentImageIndex + 1) of \(selectedImages.count)")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                
//                Spacer()
//                
//                PhotosPicker(
//                    selection: $photoPickerItems,
//                    maxSelectionCount: 6,
//                    matching: .images
//                ) {
//                    HStack {
//                        Image(systemName: "photo.badge.plus")
//                        Text("Change Photos")
//                    }
//                    .font(.caption)
//                    .foregroundColor(.blue)
//                }
//                .onChange(of: photoPickerItems) { _, newItems in
//                    loadSelectedImages(newItems)
//                }
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//            .background(Color(.systemGray6))
//        }
//    }
//    
//    private var postDetailsSection: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                // Caption field
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Caption")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    TextField("Write a caption...", text: $title)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                }
//                
//                // Description field
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Description")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    TextEditor(text: $content)
//                        .frame(minHeight: 120)
//                        .padding(8)
//                        .background(Color(.systemGray6))
//                        .cornerRadius(8)
//                }
//                
//                // Category picker
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Category")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    Picker("Category", selection: $selectedCategory) {
//                        ForEach(ActivityCategory.allCases, id: \.self) { category in
//                            Text(category.rawValue.capitalized).tag(category)
//                        }
//                    }
//                    .pickerStyle(MenuPickerStyle())
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(8)
//                }
//                
//                // Location picker
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Meeting Location")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    Button(action: {
//                        showingLocationPicker = true
//                    }) {
//                        HStack {
//                            Image(systemName: "location.circle.fill")
//                                .foregroundColor(.blue)
//                            
//                            if let location = selectedLocation {
//                                VStack(alignment: .leading, spacing: 2) {
//                                    Text(location)
//                                        .foregroundColor(.primary)
//                                        .font(.subheadline)
//                                }
//                            } else {
//                                Text("Choose a meeting location")
//                                    .foregroundColor(.secondary)
//                                    .font(.subheadline)
//                            }
//                            
//                            Spacer()
//                            
//                            Image(systemName: "chevron.right")
//                                .foregroundColor(.gray)
//                                .font(.caption)
//                        }
//                        .padding()
//                        .background(Color(.systemGray6))
//                        .cornerRadius(8)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//            .padding()
//        }
//        .sheet(isPresented: $showingLocationPicker) {
//            LocationPickerView(selectedLocation: $selectedLocation)
//        }
//    }
//    
//    private func loadSelectedImages(_ items: [PhotosPickerItem]) {
//        isLoadingImages = true
//        Task {
//            var loadedImages: [UIImage] = []
//            for item in items {
//                if let data = try? await item.loadTransferable(type: Data.self),
//                   let uiImage = UIImage(data: data) {
//                    loadedImages.append(uiImage)
//                }
//            }
//            DispatchQueue.main.async {
//                self.selectedImages = loadedImages
//                self.isLoadingImages = false
//                self.currentImageIndex = 0
//            }
//        }
//    }
//    
//
import SwiftUI
import PhotosUI
import Photos
import Supabase

extension UIImage {
  /// 按最大边等比缩放
  func resized(maxPixel: CGFloat = 1600) -> UIImage {
    let maxSide = max(size.width, size.height)
    guard maxSide > maxPixel else { return self }     // 小于阈值就不缩
    let scale = maxPixel / maxSide
    let newSize = CGSize(width: size.width * scale, height: size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in self.draw(in: CGRect(origin: .zero, size: newSize)) }
  }
}

struct PostCreationView: View {
    @EnvironmentObject var postStore: PostStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImages: [UIImage] = []
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: ActivityCategory = .study
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var isLoadingImages = false
    @State private var showSuccessAlert = false
    @State private var currentImageIndex = 0
    @State private var showingLocationPicker = false
    @State private var selectedLocation: String?
    @Binding var shouldNavigateToFeed: Bool
    @Binding var showingCreateOptions: Bool

    // 原存文件方法，已保留备用
    private func saveImageToFileSystem(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.3) else { return nil }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    

    private func createPost() {
        guard let userId = userStore.currentUser?.id else { return }
        isLoadingImages = true

        Task {
            do {
                // 1. 上传图片到 Supabase Storage
                var uploadedURLs: [String] = []
                for image in selectedImages {
                    // 1. 先缩放，再压 jpeg
                    let scaled = image.resized(maxPixel: 720)
                    guard let data = scaled.jpegData(compressionQuality: 0.2) else { continue }
                    print("压缩后:", data.count/1024, "KB")

                    let uuid  = UUID().uuidString
                    let path  = "posts/\(userId)/\(uuid).jpg"

                    do{
                        let result = try await SupabaseManager.shared.client.storage
                            .from("post-images")
                            .upload(
                                path: path,
                                file: data,
                                options: FileOptions(
                                    cacheControl: "3600",
                                    contentType: "image/jpg",
                                    upsert: false
                                )
                            )
                        print("✅ storage returned:", result)
                    }catch{
                        print("error", error)
                    }
                    
                    // 4. 取公开 URL（或私有桶改成签名 URL）
                    let publicURL = try await SupabaseManager.shared.client.storage
                        .from("post-images")
                        .getPublicURL(path: path)
                        .absoluteString
                    print("public URL:",publicURL)
                    uploadedURLs.append(publicURL)
                }
//
                let newPost = Post(
                    id: UUID(),
                    userId: userId,
                    username: userStore.currentUser?.username ?? "Unknown User",
                    photos: uploadedURLs,
                    mainCaption: title,
                    detailedCaption: content,
                    subject: selectedCategory.rawValue,
                    location: userStore.currentUser?.bio,
                    userLocation: selectedLocation,
                    createdAt: Date(),
                    likes: 0,
                    comments: [],
                    isPrivate: false,
                    isPinned: false
                )

                // 3. 本地和后端保存
                postStore.createPost(newPost)
                try await SupabaseManager.shared.savePost(newPost)
                

                // 4. 更新 UI
                await MainActor.run {
                    isLoadingImages = false
                    showSuccessAlert = true
                }

                // 5. 跳转回 Feed
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    shouldNavigateToFeed = true
                    showingCreateOptions = false
                    dismiss()
                }

                resetFields()
            } catch {
                print("上传或保存失败：\(error.localizedDescription)")
                await MainActor.run { isLoadingImages = false }
            }
        }
    }

    private func resetFields() {
        title = ""
        content = ""
        selectedImages = []
        selectedCategory = .study
        photoPickerItems = []
        currentImageIndex = 0
        selectedLocation = nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !selectedImages.isEmpty {
                    photoPreviewSection
                } else {
                    photoSelectionSection
                }
                postDetailsSection
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") { createPost() }
                        .disabled(title.isEmpty || content.isEmpty || selectedImages.isEmpty || isLoadingImages)
                }
            }
            .alert("POSTED SUCCESSFULLY!!!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    private var photoSelectionSection: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            Text("Select Photos").font(.title2).fontWeight(.semibold)
            Text("Choose 1-6 photos from your gallery")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            PhotosPicker(
                selection: $photoPickerItems,
                maxSelectionCount: 6,
                matching: .images
            ) {
                HStack { Image(systemName: "photo.badge.plus"); Text("Choose Photos") }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .onChange(of: photoPickerItems) { _, items in loadSelectedImages(items) }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }

    private var photoPreviewSection: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentImageIndex) {
                ForEach(0..<selectedImages.count, id: \.self) { idx in
                    Image(uiImage: selectedImages[idx])
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .clipped()
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 300)
            HStack {
                Text("\(currentImageIndex + 1) of \(selectedImages.count)")
                    .font(.caption).foregroundColor(.gray)
                Spacer()
                PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 6, matching: .images) {
                    HStack { Image(systemName: "photo.badge.plus"); Text("Change Photos") }
                        .font(.caption).foregroundColor(.blue)
                }
                .onChange(of: photoPickerItems) { _, items in loadSelectedImages(items) }
            }
            .padding(.horizontal).padding(.vertical, 8)
            .background(Color(.systemGray6))
        }
    }

    private var postDetailsSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption").font(.headline).foregroundColor(.primary)
                    TextField("Write a caption...", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description").font(.headline).foregroundColor(.primary)
                    TextEditor(text: $content)
                        .frame(minHeight: 120).padding(8)
                        .background(Color(.systemGray6)).cornerRadius(8)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category").font(.headline).foregroundColor(.primary)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ActivityCategory.allCases, id: \.self) {
                            Text($0.rawValue.capitalized).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()).padding()
                    .background(Color(.systemGray6)).cornerRadius(8)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting Location").font(.headline).foregroundColor(.primary)
                    Button(action: { showingLocationPicker = true }) {
                        HStack {
                            Image(systemName: "location.circle.fill").foregroundColor(.blue)
                            Group {
                                if let loc = selectedLocation {
                                    Text(loc).foregroundColor(.primary).font(.subheadline)
                                } else {
                                    Text("Choose a meeting location")
                                        .foregroundColor(.secondary).font(.subheadline)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
                        }
                        .padding().background(Color(.systemGray6)).cornerRadius(8)
                    }
                    .sheet(isPresented: $showingLocationPicker) {
                        LocationPickerView(selectedLocation: $selectedLocation)
                    }
                }
            }
            .padding()
        }
    }

    private func loadSelectedImages(_ items: [PhotosPickerItem]) {
        isLoadingImages = true
        Task {
            var imgs: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                    imgs.append(ui)
                }
            }
            DispatchQueue.main.async {
                selectedImages = imgs
                isLoadingImages = false
                currentImageIndex = 0
            }
        }
    }
}
