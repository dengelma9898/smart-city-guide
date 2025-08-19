import SwiftUI
import MapKit

/// Individual waypoint row in the route list with contact info and Wikipedia integration
struct RouteWaypointRowView: View {
  let route: GeneratedRoute
  let index: Int
  let waypoint: RoutePoint
  let endpointOption: EndpointOption
  let customEndpoint: String
  let enrichedPOIs: [String: WikipediaEnrichedPOI]
  
  let onWikipediaImageTap: (String, String, String) -> Void
  
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(index == 0 ? .green : (index == route.waypoints.count - 1 ? .red : waypoint.category.color))
            .frame(width: 28, height: 28)
          if index == 0 {
            Image(systemName: "figure.walk").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
          } else if index == route.waypoints.count - 1 {
            Image(systemName: "flag.fill").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
          } else {
            Image(systemName: waypoint.category.icon).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
          }
        }
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            let displayName: String = {
              if index == 0 { return "Start" }
              if index == route.waypoints.count - 1 {
                switch endpointOption { case .custom: return customEndpoint.isEmpty ? "Ziel" : customEndpoint; default: return "Ziel" }
              }
              return waypoint.name
            }()
            Text(displayName).font(.body).fontWeight(.medium)
          }
          Text(waypoint.address).font(.caption).foregroundColor(.secondary).lineLimit(2)
          
          // Contact Information
          ContactInfoView(waypoint: waypoint)
          
          // Wikipedia Info (only for intermediate waypoints)
          if index > 0 && index < route.waypoints.count - 1 {
            WikipediaInfoRowView(
              waypoint: waypoint,
              enrichedPOIs: enrichedPOIs,
              onImageTap: onWikipediaImageTap
            )
          }
        }
        Spacer()
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 8)
      .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
  }
}

/// Contact information display for waypoints
struct ContactInfoView: View {
  let waypoint: RoutePoint
  
  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      if let phoneNumber = waypoint.phoneNumber {
        Button(action: { 
          if let u = URL(string: "tel:\(phoneNumber.replacingOccurrences(of: " ", with: ""))") { 
            UIApplication.shared.open(u) 
          } 
        }) {
          HStack(spacing: 4) {
            Image(systemName: "phone.fill").font(.system(size: 10)).foregroundColor(.blue)
            Text(phoneNumber).font(.caption).foregroundColor(.blue)
          }
        }
      }
      if let url = waypoint.url {
        Button(action: { UIApplication.shared.open(url) }) {
          HStack(spacing: 4) {
            Image(systemName: "link").font(.system(size: 10)).foregroundColor(.blue)
            Text(url.host ?? url.absoluteString).font(.caption).foregroundColor(.blue).lineLimit(1)
          }
        }
      }
      if let email = waypoint.emailAddress {
        Button(action: { 
          if let u = URL(string: "mailto:\(email)") { 
            UIApplication.shared.open(u) 
          } 
        }) {
          HStack(spacing: 4) {
            Image(systemName: "envelope.fill").font(.system(size: 10)).foregroundColor(.blue)
            Text(email).font(.caption).foregroundColor(.blue).lineLimit(1)
          }
        }
      }
      if let hours = waypoint.operatingHours, !hours.isEmpty {
        HStack(spacing: 4) {
          Image(systemName: "clock.fill").font(.system(size: 10)).foregroundColor(.orange)
          Text(hours).font(.caption).foregroundColor(.secondary).lineLimit(2)
        }
      }
    }
  }
}

/// Walking segment between waypoints
struct RouteWalkingRowView: View {
  let route: GeneratedRoute
  let index: Int
  
  var body: some View {
    VStack(spacing: 4) {
      Rectangle().fill(Color(.systemGray4)).frame(width: 2, height: 20)
      HStack(spacing: 6) {
        Image(systemName: "figure.walk").font(.system(size: 12)).foregroundColor(.secondary)
        let walkingTime = route.walkingTimes[index]
        let walkingDistance = route.walkingDistances[index]
        Text("\(Int(walkingTime / 60)) min • \(Int(walkingDistance)) m").font(.caption2).foregroundColor(.secondary).fontWeight(.medium)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Capsule().fill(Color(.systemGray5)))
      Rectangle().fill(Color(.systemGray4)).frame(width: 2, height: 20)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 2)
  }
}
