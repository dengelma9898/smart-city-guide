# Spec Requirements Document

> Spec: POI Notification System
> Created: 2025-08-24

## Overview

Erweitere das bestehende POI-Notification-System um fehlende Features wie Settings-Integration, Route-Completion-Benachrichtigungen und verbessertes Deep-Linking. Das System soll Nutzer während aktiver Routen über erreichte POIs benachrichtigen und eine nahtlose User Experience bieten.

## User Stories

### Story 1: Settings-basierte Notification-Kontrolle

Als App-Nutzer möchte ich in den Einstellungen kontrollieren können, ob ich POI-Benachrichtigungen erhalte, damit ich die App nach meinen Präferenzen verwenden kann.

Der Nutzer kann in den Profile-Settings eine Option "POI-Benachrichtigungen" aktivieren/deaktivieren. Diese Einstellung wird respektiert, auch wenn der ProximityService bereits läuft. Bei deaktivierter Einstellung werden keine Notifications getriggert, aber das Proximity-Monitoring läuft weiter für andere Features.

### Story 2: Route-Completion-Benachrichtigung mit Erfolgs-Ansicht

Als App-Nutzer möchte ich benachrichtigt werden, wenn ich meine geplante Route vollständig absolviert habe, und dabei eine motivierende Zusammenfassung meiner Tour-Leistung sehen, damit ich ein starkes Erfolgserlebnis bekomme und zur nächsten Tour motiviert werde.

Nach dem Besuch aller POIs einer aktiven Route wird eine spezielle "Route abgeschlossen"-Notification ausgelöst. Beim Antippen öffnet sich eine dedizierte RouteSuccessView, die eine schöne Zusammenfassung zeigt: gelaufene Distanz, Gehzeit, Gesamtzeit, und Anzahl besuchter Spots in einer celebratory Darstellung mit Animationen.

### Story 3: Kontextuelle App-Navigation via Notifications

Als App-Nutzer möchte ich beim Antippen von Benachrichtigungen zum passenden App-Bereich geleitet werden, damit ich sofort den relevanten Kontext bekomme.

POI-Benachrichtigungen öffnen die App auf der Hauptkarte mit hervorgehobener aktiver Route. Route-Completion-Benachrichtigungen öffnen die neue RouteSuccessView mit Tour-Statistiken und motivierenden Elementen. In beiden Fällen werden aktive Sheets automatisch dismissed für klare Navigation.

## Spec Scope

1. **Settings-Integration** - ProfileSettings um POI-Notification-Präferenz erweitern
2. **Proximity-Service-Enhancement** - Settings-Respekt und Route-Completion-Detection einbauen  
3. **Route-Completion-Notification** - Spezielle Benachrichtigung bei vollständiger Route
4. **RouteSuccessView** - Dedizierte Erfolgs-Ansicht mit Tour-Statistiken und Animationen
5. **Enhanced Notification-Handling** - Kontextuelle App-Navigation (Map vs. Success-View)
6. **ProximityService-Settings-Binding** - Reactive Settings-Updates während aktiver Routen

## Out of Scope

- Erweiterte Deep-Linking-Funktionen (spezifische POI-Ansichten)
- Custom Notification-Sounds oder -Designs  
- Push-Notifications (nur Local Notifications)
- Erweiterte Analytics oder Tracking der Notification-Interaktionen
- Geo-Fencing mit Core Location Regions (bleibt bei GPS-basierter Distanz-Messung)

## Expected Deliverable

1. ProfileSettings enthalten eine toggle-bare "POI-Benachrichtigungen aktiviert"-Option die funktional wirksam ist
2. Bei vollständiger Route-Absolvierung erscheint eine "Route abgeschlossen"-Notification
3. POI-Notifications öffnen die App auf der Hauptkarte mit hervorgehobener aktiver Route
4. Route-Completion-Notifications öffnen eine animierte RouteSuccessView mit Tour-Statistiken
5. RouteSuccessView zeigt motivierende Zusammenfassung: Distanz, Gehzeit, Gesamtzeit, besuchte Spots
