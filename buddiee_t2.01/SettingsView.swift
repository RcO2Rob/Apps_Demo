import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var bio: String = ""
    @State private var isDarkMode = false
    @State private var fontSize: Double = 16
    @State private var isPrivateProfile = false
    @State private var showOnlineStatus = true
    @State private var allowMessages = true
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section("Profile") {
                    HStack {
                        Text("Profile Photo")
                        Spacer()
                        Button(action: { showingImagePicker = true }) {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Privacy Section
                Section("Privacy") {
                    Toggle("Private Profile", isOn: $isPrivateProfile)
                    Toggle("Show Online Status", isOn: $showOnlineStatus)
                    Toggle("Allow Messages from Strangers", isOn: $allowMessages)
                }
                
                // Appearance Section
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(fontSize))")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $fontSize, in: 12...24, step: 1)
                            .accentColor(.blue)
                    }
                }
                
                // Account Section
                Section("Account") {
                    NavigationLink("Change Password") {
                        Text("Password Change View")
                            .navigationTitle("Change Password")
                    }
                    
                    NavigationLink("Notification Settings") {
                        NotificationSettingsView()
                    }
                    
                    NavigationLink("Data & Privacy") {
                        DataPrivacyView()
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink("Help & FAQ") {
                        HelpFAQView()
                    }
                    
                    NavigationLink("Contact Support") {
                        ContactSupportView()
                    }
                    
                    NavigationLink("About") {
                        AboutView()
                    }
                }
                
                Section {
                    Button("Log out"){
                        Task{
                            do{
                                try await SupabaseManager.shared.logOut()
                            }catch{
                                print("error",error)
                            }
                        }
                        
                    }
                }
                // Danger Zone
                Section {
                    Button("Delete Account", role: .destructive) {
                        // Handle account deletion
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
            .onChange(of: selectedImage) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
            .alert("Settings Saved", isPresented: $showingSaveAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your settings have been saved successfully.")
            }
        }
    }
    
    private func loadCurrentSettings() {
        if let currentUser = userStore.currentUser {
            bio = currentUser.bio ?? ""
        }
        // Load other settings from UserDefaults or app state
    }
    
    private func saveSettings() {
        // Update user bio
        if var currentUser = userStore.currentUser {
            currentUser.bio = bio
            userStore.updateProfile(currentUser)
        }
        
        // Save other settings to UserDefaults
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        UserDefaults.standard.set(isPrivateProfile, forKey: "isPrivateProfile")
        UserDefaults.standard.set(showOnlineStatus, forKey: "showOnlineStatus")
        UserDefaults.standard.set(allowMessages, forKey: "allowMessages")
        
        showingSaveAlert = true
    }
}

// MARK: - Supporting Views
struct NotificationSettingsView: View {
    @State private var pushNotifications = true
    @State private var emailNotifications = false
    @State private var messageNotifications = true
    @State private var postNotifications = true
    
    var body: some View {
        Form {
            Section("Push Notifications") {
                Toggle("Enable Push Notifications", isOn: $pushNotifications)
                Toggle("New Messages", isOn: $messageNotifications)
                Toggle("New Posts from Followed Users", isOn: $postNotifications)
            }
            
            Section("Email Notifications") {
                Toggle("Email Notifications", isOn: $emailNotifications)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataPrivacyView: View {
    var body: some View {
        List {
            Section("Data Usage") {
                NavigationLink("Download My Data") {
                    Text("Data Download View")
                }
                
                NavigationLink("Delete My Data") {
                    Text("Data Deletion View")
                }
            }
            
            Section("Privacy Policy") {
                Link("Read Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
            }
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpFAQView: View {
    var body: some View {
        List {
            Section("Frequently Asked Questions") {
                DisclosureGroup("How do I find buddies?") {
                    Text("Use the location finder to discover people near you, or browse posts in the main feed to find people with similar interests.")
                        .padding(.vertical, 8)
                }
                
                DisclosureGroup("How do I create a post?") {
                    Text("Tap the + button in the main feed to create a new post. You can add photos, captions, and location information.")
                        .padding(.vertical, 8)
                }
                
                DisclosureGroup("How do I message someone?") {
                    Text("Tap on a user's profile or find them in the messages section to start a conversation.")
                        .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactSupportView: View {
    @State private var subject = ""
    @State private var message = ""
    
    var body: some View {
        Form {
            Section("Contact Information") {
                TextField("Subject", text: $subject)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            Section {
                Button("Send Message") {
                    // Handle sending support message
                }
                .disabled(subject.isEmpty || message.isEmpty)
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Buddiee")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 2.01")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Connect with people who share your interests and find activity partners in your area.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Section("Legal") {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                Link("Open Source Licenses", destination: URL(string: "https://example.com/licenses")!)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserStore())
} 
