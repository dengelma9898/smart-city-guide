//
//  RouteEditOriginalSpotCard.swift
//  SmartCityGuide
//
//  Shows current spot information in Route Edit interface
//

import SwiftUI
import CoreLocation

struct RouteEditOriginalSpotCard: View {
    let editableSpot: EditableRouteSpot
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Aktueller Stopp")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(editableSpot.originalWaypoint.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    RouteEditOriginalSpotCard(
        editableSpot: EditableRouteSpot(
            originalWaypoint: RoutePoint(
                name: "Nürnberger Burg",
                coordinate: CLLocationCoordinate2D(latitude: 49.4577, longitude: 11.0751),
                address: "Burg 17, 90403 Nürnberg",
                category: .attraction
            ),
            waypointIndex: 1,
            alternativePOIs: []
        )
    )
    .padding()
}
