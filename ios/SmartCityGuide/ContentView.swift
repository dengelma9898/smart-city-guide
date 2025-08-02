import SwiftUI
import MapKit

struct ContentView: View {
  @State private var cameraPosition = MapCameraPosition.region(
    MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), // Berlin default
      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
  )
  @State private var showingProfile = false
  @State private var showingRoutePlanning = false
  @State private var activeRoute: GeneratedRoute?
  
  var body: some View {
    ZStack {
      // Fullscreen Map
      Map(position: $cameraPosition) {
        // Display route if active
        if let route = activeRoute {
          // Route polylines
          ForEach(Array(route.routes.enumerated()), id: \.offset) { index, mkRoute in
            MapPolyline(mkRoute)
              .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
          }
          
          // Waypoint markers
          ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
            Marker(
              waypoint.name,
              coordinate: waypoint.coordinate
            )
            .tint(index == 0 ? .green : (index == route.waypoints.count - 1 ? .red : waypoint.category.color))
          }
        }
      }
      .mapControls {
        MapCompass()
        MapScaleView()
      }
      .mapStyle(.standard)
      .ignoresSafeArea()
      
      // Overlay following iOS design patterns
      VStack {
        // Top overlay - Profile button (top-left like Apple Maps)
        HStack {
          // Profile Button
          Button(action: {
            showingProfile = true
          }) {
            Image(systemName: "person.circle.fill")
              .font(.system(size: 20))
              .foregroundColor(.blue)
              .frame(width: 40, height: 40)
              .background(
                Circle()
                  .fill(.regularMaterial)
                  .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
              )
          }
          
          Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        
        Spacer()
        
        // Bottom overlay - Different based on route state
        if let route = activeRoute {
          // Route is active - Show route controls
          VStack(spacing: 16) {
            // Route info card
            HStack(spacing: 12) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Aktive Route")
                  .font(.caption)
                  .foregroundColor(.secondary)
                
                Text("\(Int(route.totalDistance / 1000)) km • \(formatExperienceTime(route.totalExperienceTime))")
                  .font(.subheadline)
                  .fontWeight(.medium)
              }
              
              Spacer()
              
              Text("\(route.numberOfStops) Stopps")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            // Route action buttons
            HStack(spacing: 12) {
              // Stop Route Button
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  activeRoute = nil
                }
              }) {
                HStack(spacing: 6) {
                  Image(systemName: "stop.fill")
                    .font(.system(size: 16, weight: .medium))
                  Text("Route stoppen")
                    .font(.body)
                    .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(.red)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
              }
              
              // Modify Route Button
              Button(action: {
                showingRoutePlanning = true
              }) {
                HStack(spacing: 6) {
                  Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                  Text("Ändern")
                    .font(.body)
                    .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
              }
            }
          }
          .padding(.bottom, 50)
          
        } else {
          // No active route - Show plan route button
          VStack(spacing: 16) {
            // Plan Route Button - Main interaction
            Button(action: {
              showingRoutePlanning = true
            }) {
              HStack(spacing: 8) {
                Image(systemName: "location.north.line.fill")
                  .font(.system(size: 18, weight: .medium))
                Text("Route planen")
                  .font(.headline)
                  .fontWeight(.medium)
              }
              .foregroundColor(.white)
              .padding(.horizontal, 32)
              .padding(.vertical, 16)
              .background(
                RoundedRectangle(cornerRadius: 28)
                  .fill(.blue)
                  .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
              )
            }
          }
          .padding(.bottom, 50)
        }
      }
    }
    .sheet(isPresented: $showingProfile) {
      ProfileView()
    }
    .sheet(isPresented: $showingRoutePlanning) {
      RoutePlanningView(onRouteGenerated: { route in
        activeRoute = route
        showingRoutePlanning = false // Dismiss the route planning sheet
        // Adjust camera to show entire route
        if let firstWaypoint = route.waypoints.first,
           let lastWaypoint = route.waypoints.last {
          let coordinates = route.waypoints.map { $0.coordinate }
          let minLat = coordinates.map { $0.latitude }.min() ?? firstWaypoint.coordinate.latitude
          let maxLat = coordinates.map { $0.latitude }.max() ?? firstWaypoint.coordinate.latitude
          let minLon = coordinates.map { $0.longitude }.min() ?? firstWaypoint.coordinate.longitude
          let maxLon = coordinates.map { $0.longitude }.max() ?? firstWaypoint.coordinate.longitude
          
          let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
          )
          
          let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
          )
          
          withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = MapCameraPosition.region(
              MKCoordinateRegion(center: center, span: span)
            )
          }
        }
      })
    }
  }
}

#Preview {
  ContentView()
}