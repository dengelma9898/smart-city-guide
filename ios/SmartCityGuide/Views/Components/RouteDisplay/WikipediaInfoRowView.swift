import SwiftUI

/// Wikipedia information display for route waypoints
struct WikipediaInfoRowView: View {
  let waypoint: RoutePoint
  let enrichedPOIs: [String: WikipediaEnrichedPOI]
  let onImageTap: (String, String, String) -> Void
  
  var body: some View {
    // Find corresponding enriched POI
    if let enrichedPOI = findEnrichedPOI(for: waypoint) {
      VStack(alignment: .leading, spacing: 6) {
        
        // Wikipedia article found
        if let wikipediaData = enrichedPOI.wikipediaData {
          
          // Wikipedia badge + quality indicator
          HStack(spacing: 6) {
            HStack(spacing: 4) {
              Image(systemName: "book.fill")
                .font(.system(size: 10))
                .foregroundColor(.blue)
              Text("Wikipedia")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            }
            
            // Quality score
            if enrichedPOI.isHighQuality {
              Image(systemName: "star.fill")
                .font(.system(size: 8))
                .foregroundColor(.yellow)
            }
            
            Spacer()
            
            // Link button
            if let pageURL = enrichedPOI.wikipediaURL,
               let url = URL(string: pageURL) {
              Button(action: {
                UIApplication.shared.open(url)
              }) {
                Image(systemName: "arrow.up.right.square")
                  .font(.system(size: 12))
                  .foregroundColor(.blue)
              }
            }
          }
          
          // Wikipedia description (shortened)
          if let extract = wikipediaData.extract {
            Text(String(extract.prefix(120)) + (extract.count > 120 ? "..." : ""))
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(3)
              .fixedSize(horizontal: false, vertical: true)
          } else if let description = wikipediaData.description {
            Text(description)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(2)
          }
          
          // Wikipedia image (optimized for better visibility)
          if let imageURL = enrichedPOI.wikipediaImageURL,
             let url = URL(string: imageURL) {
            HStack(spacing: 12) {
              AsyncImage(url: url) { imagePhase in
                switch imagePhase {
                case .success(let image):
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 50)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                case .failure(_), .empty:
                  RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 50)
                    .overlay(
                      Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    )
                @unknown default:
                  EmptyView()
                }
              }
              
              VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                  Image(systemName: "camera.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                  Text("Wikipedia Foto")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                }
                
                Text("Tap für Vollbild")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
              
              Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
              onImageTap(
                imageURL,
                enrichedPOI.wikipediaData?.title ?? enrichedPOI.basePOI.name,
                enrichedPOI.wikipediaURL ?? ""
              )
            }
          }
          
        } else {
          // Enrichment still running or failed
          HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 10))
              .foregroundColor(.orange)
            Text("Keine Wikipedia-Info gefunden")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
      .padding(.top, 4)
    }
  }
  
  /// Find enriched POI for a given waypoint
  private func findEnrichedPOI(for waypoint: RoutePoint) -> WikipediaEnrichedPOI? {
    // 1) Primary via unique POI ID
    if let id = waypoint.poiId, let enriched = enrichedPOIs[id] {
      return enriched
    }
    // 2) Fallback (Safety): exact coordinate AND exact same name only
    //    (reduces mix-ups if old routes don't have poiId)
    return enrichedPOIs.values.first { enriched in
      enriched.basePOI.name.caseInsensitiveCompare(waypoint.name) == .orderedSame &&
      abs(enriched.basePOI.coordinate.latitude - waypoint.coordinate.latitude) < 0.0001 &&
      abs(enriched.basePOI.coordinate.longitude - waypoint.coordinate.longitude) < 0.0001
    }
  }
}
