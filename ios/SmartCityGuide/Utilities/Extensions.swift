import Foundation

// MARK: - Helper Functions
func formatExperienceTime(_ timeInterval: TimeInterval) -> String {
  let hours = Int(timeInterval / 3600)
  let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
  
  if hours > 0 {
    if minutes > 0 {
      return "\(hours)h \(minutes)min"
    } else {
      return "\(hours)h"
    }
  } else {
    return "\(minutes)min"
  }
}

func getCategoryStats(for route: GeneratedRoute) -> [CategoryStat] {
  // Only count intermediate stops (exclude start and end points)
  let intermediateStops = route.waypoints.dropFirst().dropLast()
  
  let categoryGroups = Dictionary(grouping: intermediateStops) { $0.category }
  
  return categoryGroups.map { (category, waypoints) in
    CategoryStat(category: category, count: waypoints.count)
  }.sorted { $0.count > $1.count } // Sort by count descending
}