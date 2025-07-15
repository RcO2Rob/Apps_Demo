import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: String?
    @State private var searchText = ""
    @State private var searchResults: [LocationResult] = []
    @State private var isSearching = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a location...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchLocations()
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            searchResults = []
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Map View
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: searchResults) { result in
                    MapAnnotation(coordinate: result.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            Text(result.name)
                                .font(.caption)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.white)
                                .cornerRadius(4)
                        }
                        .onTapGesture {
                            selectedCoordinate = result.coordinate
                            selectedLocation = result.name
                        }
                    }
                }
                .frame(height: 300)
                
                // Search Results
                if isSearching {
                    HStack {
                        ProgressView()
                        Text("Searching...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !searchResults.isEmpty {
                    List(searchResults) { result in
                        Button(action: {
                            selectedLocation = result.name
                            selectedCoordinate = result.coordinate
                            region.center = result.coordinate
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(result.address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let distance = result.distance {
                                    Text("\(String(format: "%.1f", distance))km away")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else if !searchText.isEmpty && !isSearching {
                    VStack {
                        Image(systemName: "location.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No locations found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    VStack {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Search for a location")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Enter a place name, address, or landmark")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedLocation == nil)
                }
            }
        }
    }
    
    private func searchLocations() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults = []
        
        // Create a search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    return
                }
                
                guard let response = response else { return }
                
                searchResults = response.mapItems.map { item in
                    LocationResult(
                        id: UUID(),
                        name: item.name ?? "Unknown Location",
                        address: item.placemark.thoroughfare ?? item.placemark.locality ?? "Unknown Address",
                        coordinate: item.placemark.coordinate,
                        distance: calculateDistance(from: item.placemark.coordinate)
                    )
                }
            }
        }
    }
    
    private func calculateDistance(from coordinate: CLLocationCoordinate2D) -> Double? {
        // For now, we'll use a fixed reference point (London center)
        // In a real app, you'd use the user's current location
        let referenceLocation = CLLocation(latitude: 51.5074, longitude: -0.1278)
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let distance = referenceLocation.distance(from: targetLocation) / 1000 // Convert to km
        return distance
    }
}

struct LocationResult: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distance: Double?
}

#Preview {
    LocationPickerView(selectedLocation: .constant(nil))
} 