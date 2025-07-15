import SwiftUI
import MapKit
import CoreLocation

struct LocationFinderView: View {
    @EnvironmentObject var postStore: PostStore
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var internalSelectedLocation: String?
    @Binding var selectedLocation: String?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedPost: Post?
    @State private var showingPostDetail = false
    @State private var filterRadius: Double = 10.0 // km
    @State private var showingFilters = false
    @State private var isSearching = false // 添加搜索状态
    @State private var searchResults: [Post] = [] // 搜索结果
    
    init(selectedLocation: Binding<String?>? = nil) {
        self._selectedLocation = selectedLocation ?? .constant(nil)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Map Section
                ZStack {
                    Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: filteredPosts) { post in
                        MapAnnotation(coordinate: getCoordinate(for: post)) {
                            Button(action: {
                                selectedPost = post
                                showingPostDetail = true
                            }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                        .background(Circle().fill(.white))
                                        .clipShape(Circle())
                                    
                                    Text(post.username)
                                        .font(.caption2)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { _ in
                                // Map is being dragged
                            }
                    )
                    
                    // Filter Button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showingFilters.toggle() }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
                .frame(height: 400)
                
                // Search and Filter Section
                VStack(spacing: 12) {
                    // Search Bar with loading indicator
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search locations or users...", text: $searchText)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if !searchText.isEmpty {
                            Button(action: { 
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Filter Info
                    if showingFilters {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Filter Radius: \(Int(filterRadius))km")
                                    .font(.subheadline)
                                Spacer()
                                Button("Reset") {
                                    filterRadius = 10.0
                                    region.center = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            Slider(value: $filterRadius, in: 1...50, step: 1)
                                .accentColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                // Posts List
                List {
                    ForEach(filteredPosts) { post in
                        Button(action: {
                            selectedPost = post
                            showingPostDetail = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(post.username)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(post.userLocation ?? post.location ?? "Unknown location")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(post.mainCaption)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(formatDistance(for: post))
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Find Buddies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Center map on user location
                        if let userLocation = locationManager.userLocation {
                            region.center = userLocation
                        }
                    }) {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .sheet(isPresented: $showingPostDetail) {
                if let post = selectedPost {
                    NavigationView {
                        PostDetailView(post: post)
                    }
                }
            }
            .onChange(of: locationManager.currentAddress) { oldValue, newValue in
                selectedLocation = newValue
            }
            .onChange(of: searchText) { oldValue, newValue in
                // 实时搜索（防抖）
                if newValue.isEmpty {
                    searchResults = []
                } else {
                    // 添加简单的防抖延迟
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if searchText == newValue { // 确保用户还在输入同样的文本
                            performSearch()
                        }
                    }
                }
            }
        }
    }
    
    // 实现真正的搜索功能
    private var filteredPosts: [Post] {
        // 获取有位置信息的帖子
        let postsWithLocation = postStore.posts.filter { post in
            if let loc = post.userLocation, !loc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            return false
        }
        
        // 如果有搜索结果，优先显示搜索结果
        let baseResults = searchResults.isEmpty ? postsWithLocation : searchResults
        
        // 如果没有搜索文本，返回所有有位置的帖子
        guard !searchText.isEmpty else {
            return baseResults
        }
        
        // 本地过滤：根据搜索文本过滤帖子
        return baseResults.filter { post in
            let searchLower = searchText.lowercased()
            return post.username.lowercased().contains(searchLower) ||
                   post.mainCaption.lowercased().contains(searchLower) ||
                   (post.location?.lowercased().contains(searchLower) ?? false) ||
                   (post.userLocation?.lowercased().contains(searchLower) ?? false) ||
                   post.subject.lowercased().contains(searchLower) ||
                   (post.detailedCaption?.lowercased().contains(searchLower) ?? false)
        }
    }
    
    // 执行搜索（包括数据库查询）
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // TODO: 实现数据库搜索
        Task {
            do {
                // 这里应该调用 SupabaseManager 的搜索方法
                // let results = try await SupabaseManager.shared.searchPosts(query: searchText)
                
                // 目前使用本地搜索作为占位
                let localResults = postStore.posts.filter { post in
                    let searchLower = searchText.lowercased()
                    return post.username.lowercased().contains(searchLower) ||
                           post.mainCaption.lowercased().contains(searchLower) ||
                           (post.location?.lowercased().contains(searchLower) ?? false) ||
                           (post.userLocation?.lowercased().contains(searchLower) ?? false) ||
                           post.subject.lowercased().contains(searchLower)
                }
                
                await MainActor.run {
                    self.searchResults = localResults
                    self.isSearching = false
                }
                
                print("🔍 Search completed for: '\(searchText)', found \(localResults.count) results")
                
            } catch {
                await MainActor.run {
                    self.isSearching = false
                    self.searchResults = []
                }
                print("❌ Search error: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCoordinate(for post: Post) -> CLLocationCoordinate2D {
        // First check if post has a specific user location
        if let userLocation = post.userLocation {
            return getCoordinateForLocation(userLocation)
        }
        
        // Fall back to general location
        let location = (post.location ?? "").lowercased()
        return getCoordinateForLocation(location)
    }
    
    private func getCoordinateForLocation(_ location: String) -> CLLocationCoordinate2D {
        let locationLower = location.lowercased()
        
        switch locationLower {
        case "london", "central london":
            return CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        case "manchester":
            return CLLocationCoordinate2D(latitude: 53.4808, longitude: -2.2426)
        case "birmingham":
            return CLLocationCoordinate2D(latitude: 52.4862, longitude: -1.8904)
        case "leeds":
            return CLLocationCoordinate2D(latitude: 53.8008, longitude: -1.5491)
        case "glasgow":
            return CLLocationCoordinate2D(latitude: 55.8642, longitude: -4.2518)
        case "ucl", "university college london":
            return CLLocationCoordinate2D(latitude: 51.5246, longitude: -0.1340)
        case "imperial college":
            return CLLocationCoordinate2D(latitude: 51.4988, longitude: -0.1749)
        case "shoreditch":
            return CLLocationCoordinate2D(latitude: 51.5250, longitude: -0.0750)
        case "greenwich":
            return CLLocationCoordinate2D(latitude: 51.4800, longitude: 0.0000)
        case "camden":
            return CLLocationCoordinate2D(latitude: 51.5400, longitude: -0.1430)
        case "british library":
            return CLLocationCoordinate2D(latitude: 51.5295, longitude: -0.1276)
        case "senate house library":
            return CLLocationCoordinate2D(latitude: 51.5220, longitude: -0.1300)
        case "lse library":
            return CLLocationCoordinate2D(latitude: 51.5140, longitude: -0.1160)
        case "kings college london":
            return CLLocationCoordinate2D(latitude: 51.5110, longitude: -0.1160)
        case "soas":
            return CLLocationCoordinate2D(latitude: 51.5220, longitude: -0.1300)
        case "birkbeck":
            return CLLocationCoordinate2D(latitude: 51.5220, longitude: -0.1300)
        case "puregym":
            return CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        case "student center":
            return CLLocationCoordinate2D(latitude: 51.5246, longitude: -0.1340)
        default:
            // Default to London if location is not recognized
            return CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        }
    }
    
    private func formatDistance(for post: Post) -> String {
        guard let userLocation = locationManager.userLocation else {
            return "Unknown distance"
        }
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let postCoordinate = getCoordinate(for: post)
        let distance = userLoc.distance(from: CLLocation(latitude: postCoordinate.latitude, longitude: postCoordinate.longitude))
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

#Preview {
    LocationFinderView(selectedLocation: .constant(nil))
        .environmentObject(PostStore())
}
