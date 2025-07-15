import SwiftUI

struct AddPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                    TextField("Location", text: $location)
                }
            }
            .navigationTitle("New Post")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Post") {
                    // TODO: Add post creation logic
                    dismiss()
                }
                .disabled(title.isEmpty || description.isEmpty)
            )
        }
    }
} 