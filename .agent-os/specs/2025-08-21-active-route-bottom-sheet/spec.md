# Spec Requirements Document

> Spec: Active Route Bottom Sheet Enhancement
> Created: 2025-08-21

## Overview

Enhance the existing Active Route Bottom Sheet with comprehensive POI management capabilities, allowing users to replace, add, and delete POIs from active routes using cached POI data. This feature will provide flexible route customization while maintaining the app's focus on quick, efficient route planning.

## User Stories

### POI Management via Native List Gestures

As a route user, I want to manage POIs in my active route using familiar iOS swipe gestures, so that I can quickly edit or delete POIs using native interaction patterns.

The user swipes left on a POI in the active route list, sees native context menu buttons for "Edit" and "Delete", taps Edit to see alternative POIs from cached data, or taps Delete to remove the POI from the route. Route reoptimization is triggered manually after making changes.

### Adding Additional POIs to Active Route

As a route user, I want to add new POIs to my active route from cached alternatives, so that I can extend my route with interesting stops I discovered.

The user taps the "Stopp hinzufügen" button (visible after the last POI), browses through cached POI alternatives via the existing swipe interface, selects POIs to add, and can manually trigger route optimization when ready.

### Route Optimization Control

As a route user, I want control over when my route gets reoptimized after making changes, so that I can make multiple edits before triggering the computationally expensive TSP optimization and avoid rate limiting issues.

The user makes multiple POI changes, sees a clearly visible "Optimize Route" button, and can trigger reoptimization when satisfied with all changes.

## Spec Scope

1. **Native List Swipe Actions** - Implement iOS swipe gestures on POI list items with "Edit" and "Delete" context menu buttons
2. **POI Replacement Interface** - Edit action opens cached alternatives for POI replacement selection
3. **POI Deletion** - Delete action removes POI from route with pending changes tracking
4. **Add POI Integration** - Maintain existing "Stopp hinzufügen" button functionality with cached POI data source
5. **Manual Route Optimization** - Add prominent "Optimize Route" button for user-controlled TSP reoptimization
6. **Unsaved Changes Warning** - Implement modal warning when closing sheet with unsaved route modifications
7. **Cached POI Utilization** - Use existing cached POI data from route generation for all POI selection operations

## Out of Scope

- POI tap gestures for direct interaction - only swipe gestures for context menus
- Automatic route reoptimization after every change (to avoid rate limiting)
- Advanced POI editing (name, category changes) - only replacement supported
- Extended Wikipedia information display beyond images
- New POI discovery APIs - only cached data from initial route generation
- Route persistence during editing - changes are temporary until optimization

## Expected Deliverable

1. **Enhanced Active Route Bottom Sheet** with native iOS list swipe gestures for POI Edit/Delete actions
2. **POI Context Menu Implementation** with Edit and Delete buttons accessible via left swipe gesture
3. **Integrated Add POI functionality** using existing swipe interface with cached POI data
4. **Manual optimization control** with prominent "Optimize Route" button and clear UX indication
5. **Unsaved changes protection** via modal warning on sheet dismissal with pending modifications
