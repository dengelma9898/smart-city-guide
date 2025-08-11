import SwiftUI
import MapKit

// MARK: - Location Search Field with Autocomplete
struct LocationSearchField: View {
  let placeholder: String
  @Binding var text: String
  var onLocationSelected: ((CLLocationCoordinate2D, String) -> Void)? = nil // NEW: Callback with coordinates
  @State private var searchResults: [MKMapItem] = []
  @State private var isSearching = false
  @FocusState private var isFocused: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      TextField(placeholder, text: $text)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .focused($isFocused)
        .accessibilityIdentifier("route.city.textfield")
        .onChange(of: text) { newValue in
          if !newValue.isEmpty {
            searchLocations(query: newValue)
          } else {
            searchResults = []
          }
        }
      
      if !searchResults.isEmpty && isFocused {
        VStack(spacing: 0) {
          ForEach(searchResults.prefix(5), id: \.self) { item in
            Button(action: {
              selectLocation(item)
            }) {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text(item.name ?? "Unbekannter Ort")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                  
                  if let address = item.placemark.title {
                    Text(address)
                      .font(.caption)
                      .foregroundColor(.secondary)
                      .lineLimit(1)
                  }
                }
                
                Spacer()
                
                Image(systemName: "location.fill")
                  .font(.system(size: 12))
                  .foregroundColor(.blue)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
            
            if item != searchResults.prefix(5).last {
              Divider()
                .padding(.leading, 12)
            }
          }
        }
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.top, 4)
      }
    }
  }
  
  private func searchLocations(query: String) {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    request.resultTypes = [.address, .pointOfInterest]
    
    let search = MKLocalSearch(request: request)
    search.start { response, error in
      DispatchQueue.main.async {
        if let response = response {
          self.searchResults = response.mapItems
        } else {
          self.searchResults = []
        }
      }
    }
  }
  
  private func selectLocation(_ item: MKMapItem) {
    let formattedAddress = formatFullAddress(item.placemark)
    text = formattedAddress
    searchResults = []
    isFocused = false
    
    // NEW: Call the callback with coordinates and text
    let coordinates = item.placemark.coordinate
    onLocationSelected?(coordinates, formattedAddress)
    
                    // Location selected successfully
  }
  
  private func formatFullAddress(_ placemark: MKPlacemark) -> String {
    var components: [String] = []
    
    // Add street name and number
    if let thoroughfare = placemark.thoroughfare {
      var streetComponent = thoroughfare
      if let subThoroughfare = placemark.subThoroughfare {
        streetComponent = "\(thoroughfare) \(subThoroughfare)"
      }
      components.append(streetComponent)
    }
    
    // Add postal code and city
    var cityComponent: String? = nil
    if let postalCode = placemark.postalCode, let locality = placemark.locality {
      cityComponent = "\(postalCode) \(locality)"
    } else if let locality = placemark.locality {
      cityComponent = locality
    }
    
    if let city = cityComponent {
      components.append(city)
    }
    
    return components.joined(separator: ", ")
  }
}