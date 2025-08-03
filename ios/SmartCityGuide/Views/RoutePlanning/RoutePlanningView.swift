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
                
                Text("Wo startest du?")
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
                .accessibilityLabel("Startort Info")
                .accessibilityHint("Mehr Infos zum Startort")
              }
              
              LocationSearchField(
                placeholder: "Berlin, München, Hamburg... worauf hast du Lust?",
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
                
                Text("Wie viele Stopps?")
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
                .accessibilityLabel("Stopp-Anzahl Info")
                .accessibilityHint("Mehr Infos zu den Stopps")
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
                  .accessibilityLabel("\(number) Stopps")
                  .accessibilityAddTraits(numberOfPlaces == number ? .isSelected : [])
                }
                
                Spacer()
              }
              .accessibilityElement(children: .contain)
              .accessibilityLabel("Stopp-Anzahl wählen")
            }
            
            // Route Length Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "ruler.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Wie weit gehst du?")
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
                .accessibilityLabel("Distanz Info")
                .accessibilityHint("Mehr Infos zur Distanz")
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
                  .accessibilityLabel("\(length.rawValue) Tour")
                  .accessibilityAddTraits(routeLength == length ? .isSelected : [])
                }
              }
              .accessibilityElement(children: .contain)
              .accessibilityLabel("Distanz wählen")
            }
            
            // Endpoint Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "mappin.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Wo willst du hin?")
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
                .accessibilityLabel("Ziel Info")
                .accessibilityHint("Mehr Infos zum Ziel")
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
                  .accessibilityLabel("\(option.rawValue) Ziel")
                  .accessibilityAddTraits(endpointOption == option ? .isSelected : [])
                }
              }
              .accessibilityElement(children: .contain)
              .accessibilityLabel("Ziel wählen")
              
              if endpointOption == .custom {
                LocationSearchField(
                  placeholder: "Wo soll's enden?",
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
            Text("Los geht's!")
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
        .accessibilityLabel("Los geht's!")
        .accessibilityHint("Startet deine Abenteuer-Tour!")
      }
      .navigationTitle("Lass uns loslegen!")
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
      .alert("Startort Info", isPresented: $showingStartPointInfo) {
        Button("Alles klar!") { }
      } message: {
        Text("Sag mir einfach, wo wir starten sollen! Ich finde dann automatisch coole Orte in der Nähe.")
      }
      .alert("Stopp-Anzahl Info", isPresented: $showingPlacesInfo) {
        Button("Verstanden!") { }
      } message: {
        Text("Wie viele Stopps sollen wir einbauen? Mehr Stopps = mehr zu entdecken, aber auch längere Tour!")
      }
      .alert("Distanz Info", isPresented: $showingLengthInfo) {
        Button("Passt!") { }
      } message: {
        Text("Kurz (≤5km): Gemütlich durch die City\nMittel (≤15km): Richtig was sehen\nLang (≤50km): Abenteuer-Modus an!")
      }
      .alert("Ziel Info", isPresented: $showingEndpointInfo) {
        Button("Macht Sinn!") { }
      } message: {
        Text("Wo soll's am Ende hingehen?\n• Rundreise: Zurück zum Start\n• Stopp: Einfach am letzten Ort bleiben\n• Custom: Du bestimmst das Ziel!")
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