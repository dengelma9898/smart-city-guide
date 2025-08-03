import SwiftUI
import MapKit

// MARK: - Place Categories
enum PlaceCategory: String, CaseIterable, Codable {
  case attraction = "Sehenswürdigkeit"
  case museum = "Museum"
  case gallery = "Galerie"
  case artwork = "Kunstwerk"
  case viewpoint = "Aussichtspunkt"
  case monument = "Denkmal"
  case memorial = "Gedenkstätte"
  case castle = "Burg/Schloss"
  case ruins = "Ruinen"
  case archaeologicalSite = "Archäologische Stätte"
  case park = "Park"
  case garden = "Garten"
  case artsCenter = "Kulturzentrum"
  case townhall = "Rathaus"
  case placeOfWorship = "Gotteshaus"
  case cathedral = "Kathedrale"
  case chapel = "Kapelle"
  case monastery = "Kloster"
  case shrine = "Schrein"
  case spring = "Quelle"
  case waterfall = "Wasserfall"
  case river = "Fluss"
  case canal = "Kanal"
  case lake = "See"
  case nationalPark = "Nationalpark"
  case landmarkAttraction = "Wahrzeichen"
  
  var icon: String {
    switch self {
    case .attraction: return "star.fill"
    case .museum: return "building.columns.fill"
    case .gallery: return "photo.artframe"
    case .artwork: return "paintpalette.fill"
    case .viewpoint: return "binoculars.fill"
    case .monument: return "building.columns"
    case .memorial: return "flame.fill"
    case .castle: return "crown.fill"
    case .ruins: return "building.fill"
    case .archaeologicalSite: return "fossil.shell.fill"
    case .park: return "tree.fill"
    case .garden: return "leaf.fill"
    case .artsCenter: return "theatermasks.fill"
    case .townhall: return "building.2.fill"
    case .placeOfWorship: return "building"
    case .cathedral: return "building.columns.fill"
    case .chapel: return "building"
    case .monastery: return "building.2"
    case .shrine: return "flame"
    case .spring: return "drop.fill"
    case .waterfall: return "water.waves"
    case .river: return "river"
    case .canal: return "water.waves.slash"
    case .lake: return "lake"
    case .nationalPark: return "mountain.2.fill"
    case .landmarkAttraction: return "location.circle.fill"
    }
  }
  
  var color: Color {
    switch self {
    case .attraction: return .orange
    case .museum: return .purple
    case .gallery: return .pink
    case .artwork: return .red
    case .viewpoint: return .cyan
    case .monument: return .gray
    case .memorial: return .black
    case .castle: return .yellow
    case .ruins: return .brown
    case .archaeologicalSite: return .orange
    case .park: return .green
    case .garden: return .mint
    case .artsCenter: return .indigo
    case .townhall: return .blue
    case .placeOfWorship: return .primary
    case .cathedral: return .purple
    case .chapel: return .secondary
    case .monastery: return .brown
    case .shrine: return .orange
    case .spring: return .cyan
    case .waterfall: return .blue
    case .river: return .blue
    case .canal: return .teal
    case .lake: return .teal
    case .nationalPark: return .green
    case .landmarkAttraction: return .orange
    }
  }
  
  var searchTerms: [String] {
    switch self {
    case .attraction:
      return ["sehenswürdigkeiten", "tourist attractions", "landmarks", "monument", "historic sites"]
    case .museum:
      return ["museen", "galleries", "ausstellungen", "art gallery", "history museum"] 
    case .gallery:
      return ["galerie", "gallery", "kunstgalerie", "art gallery", "exhibition"]
    case .artwork:
      return ["kunstwerk", "artwork", "sculpture", "statue", "art installation"]
    case .viewpoint:
      return ["aussichtspunkt", "viewpoint", "lookout", "scenic view", "observation deck"]
    case .monument:
      return ["denkmal", "monument", "memorial", "statue", "historic monument"]
    case .memorial:
      return ["gedenkstätte", "memorial", "remembrance", "war memorial", "commemoration"]
    case .castle:
      return ["burg", "schloss", "castle", "fortress", "palace"]
    case .ruins:
      return ["ruinen", "ruins", "ancient ruins", "archaeological ruins", "historic ruins"]
    case .archaeologicalSite:
      return ["archäologische stätte", "archaeological site", "ancient site", "historical excavation"]
    case .park:
      return ["parks", "gärten", "grünflächen", "green spaces", "botanical garden"]
    case .garden:
      return ["garten", "garden", "botanical garden", "park", "green space"]
    case .artsCenter:
      return ["kulturzentrum", "arts center", "cultural center", "art center", "community center"]
    case .townhall:
      return ["rathaus", "town hall", "city hall", "municipal building", "civic center"]
    case .placeOfWorship:
      return ["gotteshaus", "place of worship", "church", "religious building", "sanctuary"]
    case .cathedral:
      return ["kathedrale", "cathedral", "dom", "basilica", "church"]
    case .chapel:
      return ["kapelle", "chapel", "small church", "religious chapel"]
    case .monastery:
      return ["kloster", "monastery", "abbey", "convent", "religious community"]
    case .shrine:
      return ["schrein", "shrine", "holy place", "religious shrine", "sacred site"]
    case .spring:
      return ["quelle", "spring", "natural spring", "water source", "mineral spring"]
    case .waterfall:
      return ["wasserfall", "waterfall", "falls", "cascade", "natural waterfall"]
    case .river:
      return ["fluss", "river", "stream", "creek", "waterway"]
    case .canal:
      return ["kanal", "canal", "channel", "waterway", "artificial waterway"]
    case .lake:
      return ["see", "lake", "natural lake", "water body", "reservoir"]
    case .nationalPark:
      return ["nationalpark", "national park", "nature reserve", "wildlife park", "forest park"]
    case .landmarkAttraction:
      return ["wahrzeichen", "landmark", "landmark attraction", "famous landmark", "iconic site"]
    }
  }
  
  static func classify(_ mapItem: MKMapItem) -> PlaceCategory {
    let name = mapItem.name?.lowercased() ?? ""
    let category = mapItem.pointOfInterestCategory
    
    // First check MKPointOfInterestCategory
    if let category = category {
      switch category {
      case .museum:
        return .museum
      case .nationalPark:
        return .nationalPark
      case .park:
        return .park
      default:
        break
      }
    }
    
    // Fallback to name-based classification
    if name.contains("museum") {
      return .museum
    } else if name.contains("galerie") || name.contains("gallery") {
      return .gallery
    } else if name.contains("kunstwerk") || name.contains("artwork") || name.contains("sculpture") {
      return .artwork
    } else if name.contains("aussichtspunkt") || name.contains("viewpoint") || name.contains("lookout") {
      return .viewpoint
    } else if name.contains("denkmal") || name.contains("monument") {
      return .monument
    } else if name.contains("gedenkstätte") || name.contains("memorial") {
      return .memorial
    } else if name.contains("burg") || name.contains("schloss") || name.contains("castle") {
      return .castle
    } else if name.contains("ruinen") || name.contains("ruins") {
      return .ruins
    } else if name.contains("archäologisch") || name.contains("archaeological") {
      return .archaeologicalSite
    } else if name.contains("botanischer garten") || name.contains("botanical garden") {
      return .garden
    } else if name.contains("kulturzentrum") || name.contains("arts center") {
      return .artsCenter
    } else if name.contains("rathaus") || name.contains("town hall") || name.contains("city hall") {
      return .townhall
    } else if name.contains("kirche") || name.contains("church") || name.contains("moschee") || name.contains("synagoge") {
      return .placeOfWorship
    } else if name.contains("kathedrale") || name.contains("cathedral") || name.contains("dom") {
      return .cathedral
    } else if name.contains("kapelle") || name.contains("chapel") {
      return .chapel
    } else if name.contains("kloster") || name.contains("monastery") {
      return .monastery
    } else if name.contains("schrein") || name.contains("shrine") {
      return .shrine
    } else if name.contains("quelle") || name.contains("spring") {
      return .spring
    } else if name.contains("wasserfall") || name.contains("waterfall") {
      return .waterfall
    } else if name.contains("see") || name.contains("lake") {
      return .lake
    } else if name.contains("nationalpark") || name.contains("national park") {
      return .nationalPark
    } else if name.contains("park") || name.contains("garten") {
      return .park
    }
    
    return .attraction // Default fallback
  }
}

struct CategoryDistribution {
  static let target: [PlaceCategory: Double] = [
    .attraction: 0.4,      // 40%
    .museum: 0.3,          // 30%
    .park: 0.2,            // 20%
    .nationalPark: 0.1     // 10%
  ]
}

struct CategoryStat {
  let category: PlaceCategory
  let count: Int
}