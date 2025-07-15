import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D? // Published for the blue dot
    @Published var currentPlacemark: CLPlacemark? // Published for location name
    @Published var currentAddress: String = "Unknown Location"
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        // Reverse geocode immediately for initial user location
        reverseGeocode(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied or restricted.")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Geocoding
    func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                print("Error reverse geocoding: \(error?.localizedDescription ?? "Unknown error")")
                self.currentPlacemark = nil
                self.currentAddress = "Unknown Location"
                return
            }
            self.currentPlacemark = placemark
            self.currentAddress = self.formatAddress(placemark: placemark)
        }
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        reverseGeocode(location: location)
    }
    
    private func formatAddress(placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        if let name = placemark.name, name != placemark.locality && name != placemark.thoroughfare { addressComponents.append(name) }
        if let thoroughfare = placemark.thoroughfare { addressComponents.append(thoroughfare) }
        if let locality = placemark.locality { addressComponents.append(locality) }
        if let administrativeArea = placemark.administrativeArea { addressComponents.append(administrativeArea) }
        if let country = placemark.country { addressComponents.append(country) }
        
        return addressComponents.joined(separator: ", ")
    }
} 