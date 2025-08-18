# Route Performance Optimization – Feature Spezifikation
**Datum**: 17.08.2025  
**Priorität**: Hoch  
**Bereich**: Performance, Core Algorithm

## Problem Statement
Aktuell werden `MKDirections.calculate()` Aufrufe strikt sequenziell ausgeführt in drei Services:
- `RouteService.generateRoutesBetweenWaypoints()` (Zeile 710-728)
- `ManualRouteService.generateRoutesBetweenWaypoints()` (Zeile 162-183) 
- `RouteEditService.generateRoutesBetweenWaypoints()` (Zeile 238-268)

**Performance-Impact**:
- Bei 8 Stopps: 7 sequenzielle MKDirections-Calls + 7 × 0.2s Rate-Limiting = ~5-10s Wartezeit
- Latenz steigt linear mit Anzahl Waypoints
- User Experience: Lange Loading-Zeiten bei komplexeren Routen
- UX-Problem besonders bei "Quick Planning" und Manual Route Building

**Risiken**:
- User Abandonment bei langen Route-Generierungs-Zeiten
- Schlechte App-Performance-Wahrnehmung
- Rate-Limiting von Apple MapKit wenn unkontrolliert parallel

## Zielbild
✅ **Kontrollierte Parallelisierung**: Max. 2-3 gleichzeitige `MKDirections` Tasks  
✅ **Rate-Limiting beibehalten**: 0.2s Delay zwischen Task-Starts, nicht zwischen Task-Completion  
✅ **Performance-Metriken**: Laufzeit-Tracking vor/nach Optimierung  
✅ **Graceful Degradation**: Fallback zu sequenziell bei Fehlern  
✅ **Frühabbruch**: `Task.isCancelled` Support für alle parallel Tasks  

## Technische Spezifikation

### 1. AsyncSemaphore für Concurrency Control
```swift
actor AsyncSemaphore {
  private var count: Int
  private var waiters: [CheckedContinuation<Void, Never>] = []
  
  init(maxConcurrent: Int) {
    self.count = maxConcurrent
  }
  
  func acquire() async {
    if count > 0 {
      count -= 1
    } else {
      await withCheckedContinuation { continuation in
        waiters.append(continuation)
      }
    }
  }
  
  func release() {
    if !waiters.isEmpty {
      let continuation = waiters.removeFirst()
      continuation.resume()
    } else {
      count += 1
    }
  }
}
```

### 2. Parallele Route-Generierung Pattern
```swift
private func generateRoutesBetweenWaypointsParallel(_ waypoints: [RoutePoint]) async throws -> [MKRoute] {
  let startTime = CFAbsoluteTimeGetCurrent()
  let semaphore = AsyncSemaphore(maxConcurrent: 3)
  var routes: [MKRoute?] = Array(repeating: nil, count: waypoints.count - 1)
  
  try await withThrowingTaskGroup(of: (Int, MKRoute).self) { group in
    for i in 0..<waypoints.count-1 {
      group.addTask {
        await semaphore.acquire()
        defer { Task { await semaphore.release() } }
        
        if Task.isCancelled { throw CancellationError() }
        
        // Rate limiting only for task start, not completion
        try await RateLimiter.awaitRouteCalculationTick()
        
        let route = try await generateSingleRoute(
          from: waypoints[i].coordinate,
          to: waypoints[i+1].coordinate
        )
        return (i, route)
      }
    }
    
    for try await (index, route) in group {
      routes[index] = route
    }
  }
  
  let duration = CFAbsoluteTimeGetCurrent() - startTime
  logPerformanceMetrics(waypoints: waypoints.count, duration: duration, parallel: true)
  
  return routes.compactMap { $0 }
}
```

### 3. Performance-Logging Erweiterung
```swift
extension SecureLogger {
  func logRoutePerformance(
    waypoints: Int, 
    duration: TimeInterval, 
    parallel: Bool,
    category: LogCategory = .performance
  ) {
    let mode = parallel ? "parallel" : "sequential"
    let throughput = Double(waypoints) / duration
    logInfo("🏎️ Route calc: \(waypoints) waypoints in \(String(format: "%.2f", duration))s (\(mode), \(String(format: "%.1f", throughput)) wp/s)", category: category)
  }
}
```

## Implementation Plan

### Task 1: Shared Utility Creation
- [ ] `AsyncSemaphore` actor in `Utilities/` erstellen
- [ ] `SecureLogger.logRoutePerformance()` extension hinzufügen
- [ ] Unit-Tests für AsyncSemaphore

### Task 2: RouteService Migration
- [ ] `generateRoutesBetweenWaypointsParallel()` implementieren
- [ ] Feature-Flag für parallel vs. sequential
- [ ] A/B-Testing-Infrastruktur
- [ ] Backward-Compatibility sicherstellen

### Task 3: ManualRouteService & RouteEditService
- [ ] Gleiche Parallelisierung in `ManualRouteService`
- [ ] `RouteEditService` parallel optimization
- [ ] Shared interface/protocol für consistency

### Task 4: Performance-Monitoring
- [ ] Baseline-Metriken sammeln (sequential)
- [ ] A/B-Test mit parallel implementation
- [ ] Dashboard/Logging für Performance-Tracking

### Task 5: Error Handling & Fallback
- [ ] Graceful degradation bei parallel failures
- [ ] Retry-Logic mit sequential fallback
- [ ] Rate-limiting edge cases abfangen

## User Stories
**Als User möchte ich...**
- ...dass Route-Generierung deutlich schneller wird (< 3s statt 5-10s)
- ...dass "Quick Planning" wirklich "quick" ist
- ...dass Manual Route Building responsive bleibt bei vielen Stopps
- ...dass die App nicht "hängt" bei komplexeren Routen

## Test Plan

### Performance Tests
1. **Baseline Measurement**: 8-Stopp-Route sequential vs. parallel
2. **Concurrency Stress Test**: 3 gleichzeitige Route-Generierungen
3. **Rate Limiting Verification**: Keine MapKit-API-Limits überschritten
4. **Memory Usage**: Parallel Tasks verbrauchen nicht zu viel RAM
5. **Cancellation**: Task.isCancelled funktioniert für alle parallel tasks

### Functional Tests
```swift
func testParallelRouteGeneration() {
  let waypoints = createTest8StopRoute()
  let startTime = CFAbsoluteTimeGetCurrent()
  
  let routes = await routeService.generateRoutesBetweenWaypoints(waypoints)
  
  let duration = CFAbsoluteTimeGetCurrent() - startTime
  XCTAssertLessThan(duration, 4.0, "Parallel route generation should be < 4s")
  XCTAssertEqual(routes.count, waypoints.count - 1)
}

func testConcurrencyLimit() {
  // Verify max 3 concurrent MKDirections calls
  // Mock MKDirections to track concurrent calls
}
```

### A/B Test Metrics
- **Sequential Baseline**: Durchschnittliche Generierungszeit
- **Parallel Optimized**: Performance-Verbesserung in %
- **Error Rate**: Fehlerrate parallel vs. sequential
- **User Satisfaction**: Subjektive Wahrnehmung "App fühlt sich schneller an"

## Risk Assessment

**Risiko 1**: Mehr parallele Requests → MapKit Rate-Limiting  
→ *Mitigation*: Max 3 concurrent, RateLimiter für Task-Starts

**Risiko 2**: Memory Overhead durch parallel Tasks  
→ *Mitigation*: Semaphore begrenzt aktive Tasks, kein unbegrenztes Spawning

**Risiko 3**: Komplexere Error-Handling-Logik  
→ *Mitigation*: Feature-Flag für Rollback, sequential fallback

**Risiko 4**: Inkonsistente Results bei Race-Conditions  
→ *Mitigation*: Index-basierte Result-Assignment, deterministisches Mapping

## Success Metrics
✅ **Route-Generierung 40-60% schneller** bei 5+ Stopps  
✅ **Build-Zeit unverändert** (keine Breaking Changes)  
✅ **Fehlerrate ≤ sequenzielle Version**  
✅ **Memory Usage < +20%** peak memory  
✅ **A/B-Test zeigt User-Satisfaction-Verbesserung**  

## Rollback Plan
- **Feature-Flag**: `FeatureFlags.parallelRouteGeneration = false`
- **Graceful Fallback**: Bei parallel failures → automatic sequential retry
- **Performance Regression**: Revert bei > 20% Slowdown in edge cases

## Implementation Notes
- **Rate-Limiting**: Beibehalten für Task-Starts, nicht Task-Completions
- **Semaphore Size**: Start mit 3, experimentieren mit 2/4 je nach Performance
- **Logging**: Detaillierte Metriken für Performance-Comparison
- **Testing**: Sowohl Unit-Tests als auch Real-Device-Performance-Tests

## Related Files
- `ios/SmartCityGuide/Services/RouteService.swift` (Zeilen 710-728)
- `ios/SmartCityGuide/Services/ManualRouteService.swift` (Zeilen 162-183)
- `ios/SmartCityGuide/Services/RouteEditService.swift` (Zeilen 238-268)
- `ios/SmartCityGuide/Utilities/RateLimiter.swift`
- `ios/SmartCityGuide/Services/SecureLogger.swift`

---
**Nach Implementierung**: Performance-Dashboards für langfristige Überwachung einrichten
