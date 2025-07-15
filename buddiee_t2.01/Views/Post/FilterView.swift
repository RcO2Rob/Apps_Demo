import SwiftUI

struct FilterView: View {
    @Binding var selectedFilter: PostFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Filter Posts")
                    .font(.title)
                    .padding()
                
                VStack(spacing: 16) {
                    ForEach(PostFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            HStack {
                                Text(filter.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 