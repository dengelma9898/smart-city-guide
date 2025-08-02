import SwiftUI

// MARK: - Route Planning View
struct RoutePlanningView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var startingCity = ""
  @State private var numberOfPlaces = 3
  @State private var endpointOption: EndpointOption = .roundtrip
  @State private var customEndpoint = ""
  @State private var routeLength: RouteLength = .medium
  @State private var showingRouteBuilder = false
  
  let onRouteGenerated: (GeneratedRoute) -> Void
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 32) {
          // Header
          VStack(spacing: 12) {
            Text("Route konfigurieren")
              .font(.title2)
              .fontWeight(.semibold)
              .multilineTextAlignment(.center)
            
            Text("Erstellen Sie Ihre perfekte Städtereise mit mehreren Stopps")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .padding(.top, 20)
          
          VStack(spacing: 24) {
            // Starting Point Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Image(systemName: "location.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Startpunkt")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              Text("Wählen Sie die Stadt, in der Ihre Route beginnt")
                .font(.caption)
                .foregroundColor(.secondary)
              
              LocationSearchField(
                placeholder: "z.B. Berlin, München, Hamburg",
                text: $startingCity
              )
            }
            
            // Number of Places Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Image(systemName: "map.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Anzahl Orte")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              Text("Wie viele Zwischenstopps möchten Sie zwischen Start und Ziel?")
                .font(.caption)
                .foregroundColor(.secondary)
              
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
                }
                
                Spacer()
                
                Text("\(numberOfPlaces) Zwischenstopps")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            }
            
            // Route Length Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Image(systemName: "ruler.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Routenlänge")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              Text("Wie lang soll die gesamte Route werden?")
                .font(.caption)
                .foregroundColor(.secondary)
              
              HStack(spacing: 12) {
                ForEach(RouteLength.allCases, id: \.self) { length in
                  Button(action: {
                    routeLength = length
                  }) {
                    VStack(spacing: 6) {
                      Text(length.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                      
                      Text(length.description)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                    }
                    .foregroundColor(routeLength == length ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(routeLength == length ? .blue : Color(.systemGray6))
                    )
                  }
                }
              }
            }
            
            // Endpoint Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Image(systemName: "mappin.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Endpunkt")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              Text("Wo soll Ihre Route enden? (Optional)")
                .font(.caption)
                .foregroundColor(.secondary)
              
              VStack(spacing: 8) {
                ForEach(EndpointOption.allCases, id: \.self) { option in
                  Button(action: {
                    endpointOption = option
                  }) {
                    HStack {
                      Image(systemName: endpointOption == option ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(endpointOption == option ? .blue : .secondary)
                        .font(.system(size: 20))
                      
                      VStack(alignment: .leading, spacing: 2) {
                        Text(option.rawValue)
                          .font(.body)
                          .fontWeight(.medium)
                          .foregroundColor(.primary)
                        
                        Text(option.description)
                          .font(.caption)
                          .foregroundColor(.secondary)
                      }
                      
                      Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                      RoundedRectangle(cornerRadius: 10)
                        .fill(endpointOption == option ? Color(.systemBlue).opacity(0.1) : Color(.systemGray6))
                    )
                  }
                }
                
                if endpointOption == .custom {
                  LocationSearchField(
                    placeholder: "Gewünschter Endpunkt",
                    text: $customEndpoint
                  )
                  .padding(.top, 8)
                }
              }
            }
          }
          .padding(.horizontal, 20)
          
          // Continue Button
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
          .padding(.bottom, 30)
        }
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
    }
    .sheet(isPresented: $showingRouteBuilder) {
      RouteBuilderView(
        startingCity: startingCity,
        numberOfPlaces: numberOfPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeLength: routeLength,
        onRouteGenerated: onRouteGenerated
      )
    }
  }
}