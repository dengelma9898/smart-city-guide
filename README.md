# Smart City Guide 🏙️

Eine iOS SwiftUI-App für intelligente Multi-Stop-Walking-Routen in Städten mit TSP-Optimierung.

## 🚀 Features

- **Intelligente Routenplanung**: TSP-optimierte Walking-Routen zwischen Sehenswürdigkeiten
- **Geoapify API Integration**: POI-Discovery mit Kategorie-basierter Auswahl  
- **MapKit Integration**: Präzise Walking-Directions mit 0.2s Rate Limiting
- **Friendly German UI**: "Los, planen wir!" - Conversational User Experience
- **Caching & Performance**: POI-Caching für optimale Performance
- **Manuelles Hinzufügen von POIs**: Über die `+`-Schaltfläche in der Detailansicht per Swipe (nehmen/überspringen)
- **Einzelne POIs löschen**: Swipe-Action „Löschen“ in der Routenliste; beim letzten Zwischenstopp zurück zur Planung
- **Vollständige Reoptimierung**: CTA „Jetzt optimieren“ ordnet neue Stopps intelligent an (Start/Ziel fix)

## ⚙️ Systemanforderungen

- iOS 17.5 oder neuer
- Xcode 15.0 oder neuer