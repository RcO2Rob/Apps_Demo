import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject private var supabase: SupabaseManager
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    @State private var showContentView: Bool = false
    
    var onSetupComplete: (() -> Void)?
    
    @State private var username = ""
    @State private var bio = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("个人头像")) {
                HStack {
                    Spacer()
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
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
                    Text("选择头像")
                        .frame(maxWidth: .infinity)
                }
            }
            
            Section(header: Text("基本信息")) {
                TextField("用户名", text: $username)
                    .textContentType(.username)
            }
            
            Section(header: Text("个人简介")) {
                TextEditor(text: $bio)
                    .frame(minHeight: 100)
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("完善个人资料")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    saveProfile()
                    print(supabase.currentUser?.id)
                }
                .disabled(isLoading || username.isEmpty)
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
    
    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 创建用户资料
                guard let uid = supabase.client.auth.currentSession?.user.id else { return }

                let newUser = User(
                    id: uid,
                    username: username,
                    profilePicture: nil, // 暂时设为nil，后续可以添加图片上传功能
                    bio: bio.isEmpty ? nil : bio,
                )
                
                // 保存到数据库
                try await SupabaseManager.shared.saveUerInfo(newUser)
                
                
                // 更新本地用户存储
                userStore.updateProfile(newUser)
                
                // 完成设置，关闭页面
                await MainActor.run {
                    onSetupComplete?()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(SupabaseManager.shared)
        .environmentObject(UserStore())
        
}
