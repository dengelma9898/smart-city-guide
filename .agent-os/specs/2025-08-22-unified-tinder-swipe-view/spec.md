# Spec Requirements Document

> Spec: Unified Tinder-Style Swipe View
> Created: 2025-08-22

## Overview

Erstelle ein einheitliches Tinder-Style Swipe-Interface, das alle POI-Auswahlflows (manueller Flow, Add-POI-Flow und Edit-POI-Flow) konsolidiert und eine konsistente, benutzerfreundliche Swipe-Experience über die gesamte App bietet.

## User Stories

### Unified POI Selection Experience

Als App-Nutzer möchte ich eine einheitliche Swipe-Erfahrung für alle POI-Auswahlsituationen, damit ich mich nicht an unterschiedliche UI-Patterns gewöhnen muss und immer die gleiche intuitive Bedienung habe.

**Detaillierter Workflow:** Der Nutzer sieht immer die gleichen Swipe-Karten mit identischem Design, egal ob er beim manuellen Planen POIs auswählt, neue POIs zu einer bestehenden Route hinzufügt oder einen POI in einer aktiven Route ersetzt. Die Karten zeigen POI-Bilder, Namen, Beschreibungen und Kategorien-Badges. Bei fehlendem Bild wird das Kategorien-Icon verwendet. Abgelehnte Karten wandern ans Ende des Stapels und bleiben verfügbar.

### Manual Route Planning & Adding POIs

Als Nutzer möchte ich beim manuellen Planen oder beim Hinzufügen von POIs so viele Orte auswählen wie ich möchte und dabei die aktuelle Anzahl sehen, damit ich eine kontrollierte Auswahl treffen kann.

**Detaillierter Workflow:** Der Nutzer sieht während des Swipens die Anzahl der bereits ausgewählten POIs. Er kann weiter swipen und POIs sammeln, bis er auf "Bestätigen" drückt. Bei Abbruch der Ansicht gehen alle Auswahlen verloren. Die Ansicht schließt sich erst bei expliziter Bestätigung.

### Quick POI Replacement

Als Nutzer möchte ich bei der POI-Bearbeitung in einer aktiven Route sofort den ersten passenden Ersatz auswählen können, damit der Ersetzungsvorgang schnell und ohne weitere Bestätigung erfolgt.

**Detaillierter Workflow:** Die Ansicht zeigt nur POIs, die nicht bereits in der Route sind und nicht der zu ersetzende POI. Bei Auswahl eines neuen POIs schließt sich die Ansicht sofort und der Ersatz wird automatisch bestätigt. Keine zusätzlichen Bestätigungsschritte erforderlich.

## Spec Scope

1. **Unified SwipeCardView Component** - Einheitliche Swipe-Karten-Komponente, die SpotSwipeCardView und POISelectionCardStackView ersetzt
2. **Flow-Adaptive Service Layer** - Service-Schicht, die je nach Flow unterschiedliche Verhaltensweisen ermöglicht (Manual/Add vs Edit)
3. **Gesture Recognition & Button Actions** - Tinder-Style Gestures mit Links=Accept, Rechts=Reject plus Buttons, die identische Animationen triggern
4. **Card Stack Management** - Verwaltung von Kartenstapeln mit "rejected cards to back"-Logik für kontinuierliches Swipen
5. **Flow-Specific UI Elements** - POI-Counter und Bestätigungs-Button für Manual/Add-Flows, sofortiges Schließen für Edit-Flow

## Out of Scope

- Änderungen an der POI-Discovery-Logik oder API-Aufrufen
- Modifikationen an bestehenden Wikipedia-Enrichment-Services
- Grundlegende Änderungen an der Route-Generierung oder TSP-Optimierung
- Neue Animations-Frameworks (verwende bestehende SwiftUI-Animationen)
- Änderungen an der Coordinator-Pattern-Implementierung

## Expected Deliverable

1. **Funktionierende Unified SwipeCardView** - Eine SwiftUI-View, die in allen drei Flows verwendbar ist und konsistente Swipe-Gestures bietet
2. **Flow-spezifische Konfiguration** - Testbare Konfigurationsmöglichkeiten für Manual/Add vs Edit-Verhalten über Parameter oder Enums
3. **Backward Compatibility** - Alle bestehenden UI-Tests funktionieren weiterhin mit der neuen Implementierung
