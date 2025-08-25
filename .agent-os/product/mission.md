# Product Mission

## Pitch

Smart City Guide ist eine iOS-App, die Reisenden und Stadtbesuchern hilft, effiziente Multi-Stop-Walking-Routen zu erstellen, ohne Zeit für komplexe Reiseplanung zu verschwenden.

## Users

### Primary Customers

- **Spontane Stadtbesucher**: Menschen, die eine Stadt erkunden möchten, aber keine Zeit oder Lust haben, detaillierte Routen zu planen
- **Effizienz-orientierte Reisende**: Nutzer, die maximale Sehenswürdigkeiten in minimaler Zeit besuchen möchten

### User Personas

**Spontaner Städtetourist** (25-45 Jahre)
- **Role:** Berufstätige Person oder Student auf Städtereise
- **Context:** Hat nur wenige Stunden oder einen Tag Zeit für Stadterkundung
- **Pain Points:** Zeitaufwändige Routenplanung, ineffiziente Routen zwischen Sehenswürdigkeiten, Überforderung durch zu viele Optionen
- **Goals:** Schnell eine optimierte Route erstellen, maximale Anzahl interessanter Orte besuchen, flexibel Änderungen vornehmen können

## The Problem

### Zeitaufwändige Routenplanung

Viele Stadtbesucher verbringen mehr Zeit mit der Planung ihrer Route als mit dem eigentlichen Erkunden. Traditionelle Routen-Apps bieten entweder zu wenige oder zu viele Optionen ohne intelligente Optimierung.

**Our Solution:** TSP-optimierte Routengenerierung mit minimalem Input und maximaler Effizienz.

### Ineffiziente Routen zwischen POIs

Standard-Navigation-Apps optimieren nur Punkt-zu-Punkt-Routen, nicht aber Multi-Stop-Routen zwischen mehreren Sehenswürdigkeiten.

**Our Solution:** Traveling Salesman Problem (TSP) Algorithmus für mathematisch optimierte Walking-Routen.

## Differentiators

### Fokus auf Geschwindigkeit statt Komplexität

Anders als andere Reise-Apps, die mit Features überladen sind, konzentrieren wir uns auf schnelle Routengenerierung ohne übermäßige Filter oder komplizierte Einstellungen. Das Ergebnis ist eine App, die in unter 30 Sekunden eine optimierte Route erstellt - perfekt für spontane Kurztrips und Wochenendreisen.

### Intelligente Post-Generation Anpassung

Im Gegensatz zu starren Routenplanern ermöglichen wir flexible Anpassungen nach der Generierung durch Swipe-Mechanismen und einfache POI-Modifikation. Dies bietet die perfekte Balance zwischen Automatisierung und Kontrolle.

### TSP-Optimierung für Walking Routes

Während andere Apps einfache Punkt-zu-Punkt Navigation bieten, verwenden wir mathematische Optimierung speziell für Fußgänger-Routen zwischen multiplen Zielen.

## Key Features

### Core Features

- **TSP-Optimierte Routengenerierung:** Mathematisch optimierte Walking-Routen zwischen mehreren Sehenswürdigkeiten
- **POI-Discovery mit Kategorisierung:** Automatische Entdeckung relevanter Points of Interest basierend auf Kategorien
- **Schnelle Route-Erstellung:** Route-Generierung in unter 30 Sekunden ohne komplexe Eingaben
- **Geografische Verteilung:** Intelligente 200m Mindestabstand-Algorithmen für optimale POI-Verteilung

### Anpassung und Flexibilität Features

- **Swipe-basierte POI-Auswahl:** Intuitive Card-Swipe Mechanismen für manuelle POI-Auswahl
- **Post-Generation Route-Modifikation:** Flexible Anpassung bestehender Routen durch Hinzufügen/Entfernen von POIs
- **Active Route Management:** Bottom-Sheet-Interface für laufende Routen mit Edit/Delete-Funktionalität
- **Wikipedia-Integration:** Automatische Anreicherung von POIs mit relevanten Informationen

### Performance und Sicherheit Features

- **Multi-Layer Caching:** Memory + Disk Caching für optimale Performance
- **Rate Limiting Management:** Intelligente API-Call-Limitierung für stabile Performance
- **Sichere API-Integration:** Certificate Pinning und sichere Key-Verwaltung
- **Offline-Ready Architecture:** Lokale Datenspeicherung für eingeschränkte Konnektivität
