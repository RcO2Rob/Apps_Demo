import SwiftUI
import PhotosUI
import Photos
import Supabase

struct EditProfileView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userStore: UserStore
    @State private var username: String
    @State private var bio: String
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    init(user: User) {
        self.user = user
        _username = State(initialValue: user.username)
        _bio = State(initialValue: user.bio ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Photo")) {
                    HStack {
                        Spacer()
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let profilePicture = user.profilePicture,
                                    let url = URL(string: profilePicture) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    PhotosPicker(selection: $photoPickerItem,
                               matching: .images,
                               photoLibrary: .shared()) {
                        Text("Change Photo")
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Section(header: Text("Username")) {
                    TextField("Username", text: $username)
                }
                
                Section(header: Text("Bio")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        //updateChangesToDatabase()
                    }
                }
            }
            .onChange(of: photoPickerItem) {
                Task {
                    if let data = try? await photoPickerItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        Task {
            do {
                var photoURL = user.profilePicture   // 先用旧值占位

                // ① 如果用户选了新图，就上传
                if let image = selectedImage,
                   let data  = image.jpegData(compressionQuality: 0.2) {

                    // 生成文件名：avatars/<userId>.jpg
                    let filePath = "\(user.id).jpg"

                    // ⚠️ 根据你控制台的 bucket 名修改 "avatars"
                    try await SupabaseManager.shared.client
                          .storage
                          .from("avatars")
                          .upload(
                              path: filePath,
                              file: data,
                              options: FileOptions(
                                  cacheControl: "3600",
                                  contentType: "image/jpg",
                                  upsert: false
                              )
                          )

                    // ② 拿公开 URL（或 getPublicURL / createSignedURL）
                    photoURL = try await SupabaseManager.shared.client
                                  .storage
                                  .from("avatars")
                                  .getPublicURL(path: filePath)
                                  .absoluteString
                }

                // ③ 更新数据库
                let updated = User(id: user.id,
                                   username: username,
                                   profilePicture: photoURL,
                                   bio: bio)

                try await SupabaseManager.shared.saveUerInfo(updated)
                
                await MainActor.run {
                    userStore.updateProfile(updated)   // 刷本地状态
                    dismiss()
                }

            } catch {
                print("❌ 保存头像失败:", error)
            }
        }
    }

    
//    private func saveChanges() {
//        // Here you would typically call a method on a UserStore
//        // to save the updated user information. For now, we just dismiss.
//        
//        // Example of creating an updated user object:
//        let updatedUser = User(
//            id: user.id,
//            username: username,
//            profilePicture: user.profilePicture, // This would need to be updated with the new image URL after uploading
//            bio: bio
//        )
//        print("Saving updated user: \(updatedUser)")
//        userStore.updateProfile(updatedUser)
//        updateChangesToDatabase(updatedUser)
//        updatePostToDatabase(updatedUser.id, updatedUser.username)
//        dismiss()
//    }
    
    private func updateChangesToDatabase(_ updatedUser: User) {
        Task {
            do{
                try await SupabaseManager.shared.saveUerInfo(updatedUser)
            }catch{
                print("error ",error)
            }
        }
    }
    
    private func updatePostToDatabase(_ userId:UUID,_ username: String){
        Task {
            do{
                try await SupabaseManager.shared.updatePost(userId, username)
            }catch{
                print("error ",error)
            }
        }
    }
    
}

#Preview {
    EditProfileView(user: User(
        id: UUID(),
        username: "TestUser",
        profilePicture: nil,
        bio: "Test bio"
    ))
} 
