import SwiftUI
import PhotosUI

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
                        } else if let profilePicture = user.profilePicture, let url = URL(string: profilePicture) {
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
                
                Section(header: Text("Basic Information")) {
                    TextField("Username", text: $username)
                }
                
                Section(header: Text("About")) {
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
        // Here you would typically call a method on a UserStore
        // to save the updated user information. For now, we just dismiss.
        
        // Example of creating an updated user object:
        let updatedUser = User(
            id: user.id,
            username: username,
            profilePicture: user.profilePicture, // This would need to be updated with the new image URL after uploading
            bio: bio
        )
        print("Saving updated user: \(updatedUser)")
        userStore.updateProfile(updatedUser)
        updateChangesToDatabase(updatedUser)
        updatePostToDatabase(updatedUser.id, updatedUser.username)
        dismiss()
    }
    
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
