import SwiftUI
import MapKit

// MARK: - Route Planning View
struct RoutePlanningView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var settingsManager = ProfileSettingsManager()
  
  @State private var startingCity = ""
  @State private var startingCoordinates: CLLocationCoordinate2D? = nil // NEW: Store coordinates
  @State private var numberOfPlaces = 3
  @State private var endpointOption: EndpointOption = .roundtrip
  @State private var customEndpoint = ""
  @State private var customEndpointCoordinates: CLLocationCoordinate2D? = nil // NEW: Store endpoint coordinates
  @State private var routeLength: RouteLength = .medium
  @State private var showingRouteBuilder = false
  @State private var showingStartPointInfo = false
  @State private var showingPlacesInfo = false
  @State private var showingLengthInfo = false
  @State private var showingEndpointInfo = false
  
  let onRouteGenerated: (GeneratedRoute) -> Void
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
            // Starting Point Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "location.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Startpunkt")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                  showingStartPointInfo = true
                }) {
                  Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Startpunkt Information")
                .accessibilityHint("Zeigt Details zum Startpunkt an")
              }
              
              LocationSearchField(
                placeholder: "z.B. Berlin, München, Hamburg",
                text: $startingCity,
                onLocationSelected: { coordinates, address in
                  startingCoordinates = coordinates
                  print("RoutePlanningView: Starting location coordinates saved: \(coordinates)")
                }
              )
              
              // City extraction hint
              if !startingCity.isEmpty {
                CityInputHintView(inputText: startingCity)
              }
            }
            
            // Number of Places Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "map.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Anzahl Orte")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                  showingPlacesInfo = true
                }) {
                  Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Anzahl Orte Information")
                .accessibilityHint("Zeigt Details zur Anzahl der Zwischenstopps an")
              }
              
              HStack(spacing: 12) {
                ForEach(2...5, id: \.self) { number in
                  Button(action: {
                    numberOfPlaces = number
                  }) {
                    Text("\(number)")
                      .font(.headline)
                      .fontWeight(.medium)
                      .foregroundColor(numberOfPlaces == number ? .white : .blue)
                      .frame(width: 50, height: 50)
                      .background(
                        Circle()
                          .fill(numberOfPlaces == number ? .blue : Color(.systemGray6))
                      )
                  }
                  .accessibilityLabel("\(number) Zwischenstopps")
                  .accessibilityAddTraits(numberOfPlaces == number ? .isSelected : [])
                }
                
                Spacer()
              }
              .accessibilityElement(children: .contain)
              .accessibilityLabel("Anzahl Zwischenstopps Auswahl")
            }
            
            // Route Length Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "ruler.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Routenlänge")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                  showingLengthInfo = true
                }) {
                  Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Routenlänge Information")
                .accessibilityHint("Zeigt Details zu den Routenlängen-Optionen an")
              }
              
              HStack(spacing: 12) {
                ForEach(RouteLength.allCases, id: \.self) { length in
                  Button(action: {
                    routeLength = length
                  }) {
                    Text(length.rawValue)
                      .font(.body)
                      .fontWeight(.medium)
                      .foregroundColor(routeLength == length ? .white : .blue)
                      .padding(.horizontal, 16)
                      .padding(.vertical, 12)
                      .frame(maxWidth: .infinity)
                      .background(
                        RoundedRectangle(cornerRadius: 12)
                          .fill(routeLength == length ? .blue : Color(.systemGray6))
                      )
                  }
                  .accessibilityLabel("\(length.rawValue) Route")
                  .accessibilityAddTraits(routeLength == length ? .isSelected : [])
                }
              }
              .accessibilityElement(children: .contain)
              .accessibilityLabel("Routenlänge Auswahl")
            }
            
            // Endpoint Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "mappin.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Endpunkt")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                  showingEndpointInfo = true
                }) {
                  Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Endpunkt Information")
                .accessibilityHint("Zeigt Details zu den Endpunkt-Optionen an")
              }
              
              HStack(spacing: 8) {
                ForEach(EndpointOption.allCases, id: \.self) { option in
                  Button(action: {
                    endpointOption = option
                  }) {
                    Text(option.rawValue)
                      .font(.body)
                      .fontWeight(.medium)
                      .foregroundColor(endpointOption == option ? .white : .blue)
                      .padding(.horizontal, 16)
                      .padding(.vertical, 12)
                      .frame(maxWidth: .infinity)
                      .background(
                        RoundedRectangle(cornerRadius: 10)
                          .fill(endpointOption == option ? .blue : Color(.systemGray6))
                      )
                  }
                  .accessibilityLabel("\(option.rawValue) Endpunkt")
                  .accessibilityAddTraits(endpointOption == option ? .isSelected : [])
                }
              }
              .accessibilityElement(children: .contain)
              .accessibilityLabel("Endpunkt Auswahl")
              
              if endpointOption == .custom {
                LocationSearchField(
                  placeholder: "Custom Endpunkt",
                  text: $customEndpoint
                )
                .padding(.top, 8)
                
                // City extraction hint for custom endpoint
                if !customEndpoint.isEmpty {
                  CityInputHintView(inputText: customEndpoint)
                    .padding(.top, 4)
                }
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 20)
        }
        }
        
        // Bottom Button with Safe Area Support
        Button(action: {
          showingRouteBuilder = true
        }) {
          HStack(spacing: 8) {
            Text("Route erstellen")
              .font(.headline)
              .fontWeight(.medium)
            
            Image(systemName: "arrow.right")
              .font(.system(size: 16, weight: .medium))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(startingCity.isEmpty ? .gray : .blue)
          )
        }
        .disabled(startingCity.isEmpty)
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(.regularMaterial.opacity(0.8))
        .accessibilityLabel("Route erstellen")
        .accessibilityHint("Erstellt eine neue Route mit den gewählten Einstellungen")
      }
      .navigationTitle("Route planen")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fertig") {
            dismiss()
          }
        }
      }
      .sheet(isPresented: $showingRouteBuilder) {
        RouteBuilderView(
          startingCity: startingCity,
          startingCoordinates: startingCoordinates, // NEW: Pass coordinates
          numberOfPlaces: numberOfPlaces,
          endpointOption: endpointOption,
          customEndpoint: customEndpoint,
          customEndpointCoordinates: customEndpointCoordinates, // NEW: Pass endpoint coordinates
          routeLength: routeLength,
          onRouteGenerated: onRouteGenerated
        )
      }
      .onAppear {
        loadDefaultSettings()
      }
      .alert("Startpunkt Info", isPresented: $showingStartPointInfo) {
        Button("OK") { }
      } message: {
        Text("Wählen Sie die Stadt, in der Ihre Route beginnt. Das System findet automatisch interessante Orte in der Umgebung.")
      }
      .alert("Anzahl Orte Info", isPresented: $showingPlacesInfo) {
        Button("OK") { }
      } message: {
        Text("Wie viele Zwischenstopps möchten Sie zwischen Start und Ziel? Mehr Orte bedeuten eine längere, abwechslungsreichere Route.")
      }
      .alert("Routenlänge Info", isPresented: $showingLengthInfo) {
        Button("OK") { }
      } message: {
        Text("Kurz (≤5km): Kompakte Stadtbesichtigung\nMittel (≤15km): Ausgedehnte Erkundung\nLang (≤50km): Ganztagesausflug")
      }
      .alert("Endpunkt Info", isPresented: $showingEndpointInfo) {
        Button("OK") { }
      } message: {
        Text("Wählen Sie, wo Ihre Route enden soll:\n• Rundreise: Zurück zum Startpunkt\n• Stopp: Route endet am letzten Stopp\n• Custom: Bestimmen Sie selbst den Endpunkt")
      }
    }
  }
  
  private func loadDefaultSettings() {
    // Load default values from profile settings, but only if not already set
    let defaults = settingsManager.settings.getDefaultsForRoutePlanning()
    
    if numberOfPlaces == 3 { // Only update if still at default value
      numberOfPlaces = defaults.0
    }
    
    if endpointOption == .roundtrip { // Only update if still at default value
      endpointOption = defaults.1
    }
    
    if routeLength == .medium { // Only update if still at default value
      routeLength = defaults.2
    }
    
    if customEndpoint.isEmpty { // Only update if empty
      customEndpoint = defaults.3
    }
  }
}