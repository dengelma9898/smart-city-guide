# 📚 Wikipedia-Integration Testing Guide
## Smart City Guide - 2-Phasen Enrichment

### 🎯 **Was wurde implementiert:**

#### **2-Phasen Wikipedia-Enrichment:**
1. **Phase 1 (Sofort)**: Route-POIs enrichen → User sieht schnell Wikipedia-Daten
2. **Phase 2 (Hintergrund)**: Alle anderen POIs enrichen → Bereit für zukünftige Features

#### **UI-Features:**
- **Wikipedia-Badge** mit Qualitäts-Indikator (⭐)
- **Wikipedia-Beschreibung** (gekürzt, 120 Zeichen)
- **Wikipedia-Bilder** (60px hoch, AsyncImage)
- **Link zu Wikipedia-Artikel** (arrow.up.right.square Button)
- **Loading-States** während Enrichment
- **Background-Progress** für Phase 2

---

## 🧪 **Wie testen:**

### **Test 1: Grundfunktion**
1. **App starten** → `ContentView`
2. **Route planen**: 
   - 📍 Stadt: `"Nürnberg"`
   - 🏛️ Anzahl Stopps: `3-4`
   - 🎯 Endpunkt: `"Zurück zum Start"`
   - 📏 Länge: `"Kurze Tour (5km)"`
3. **"Los, planen wir!" drücken**
4. **Beobachte Loading-Phasen**:
   - ✅ "Entdecke coole Orte..." (Geoapify)
   - ✅ "Optimiere deine Route..." (TSP)
   - ✅ "Lade Wikipedia-Infos..." (Phase 1) ← **NEU!**

### **Test 2: Wikipedia-Daten in Route-Anzeige**
Nach erfolgreicher Route-Generierung:

#### **Erwartete POIs in Nürnberg:**
- 🏰 **Kaiserburg Nürnberg**
- 🏛️ **Germanisches Nationalmuseum**  
- ⛪ **St. Sebaldus (Nürnberg)**
- ⛪ **Lorenzkirche (Nürnberg)**
- ⛲ **Schöner Brunnen**

#### **Für jeden POI prüfen:**
1. **Wikipedia-Badge**: `📖 Wikipedia` in blau
2. **Qualitäts-Stern**: ⭐ für hochwertige Matches
3. **Beschreibung**: Kurzer Wikipedia-Extract (max 120 Zeichen)
4. **Bild**: Wikipedia-Thumbnail (falls verfügbar)
5. **Link-Button**: ↗️ öffnet Wikipedia-Artikel

#### **Screenshots machen von:**
- ✅ Kaiserburg mit Wikipedia-Bild
- ✅ Museum mit Wikipedia-Beschreibung
- ✅ Kirche mit Qualitäts-Stern

### **Test 3: Background-Enrichment**
Nach Phase 1 (Route-POIs enriched):

1. **Background-Status beobachten**:
   - 🔄 "Wikipedia-Daten für weitere POIs werden im Hintergrund geladen..."
   - 📊 Progress-Bar mit Prozent-Anzeige
   - 💙 Blauer Hintergrund

2. **Console-Logs prüfen** (Xcode):
   ```
   📚 [Phase 1] Enriching 3 route POIs with Wikipedia...
   📚 [Phase 1] Route enrichment completed: 2/3 successful
   📚 [Phase 2] Background enriching 7 additional POIs...
   📚 [Phase 2] Background enrichment completed: 8/10 total enriched
   ```

### **Test 4: Error Handling**
1. **Offline-Test**: WLAN ausschalten → App sollte funktionieren, aber keine Wikipedia-Daten
2. **Invalid City**: `"Xyz123Stadt"` → App sollte graceful fallback zeigen
3. **Wikipedia-Fail**: POIs ohne Wikipedia-Match → "Keine Wikipedia-Info gefunden"

### **Test 5: Performance-Test**
1. **Große Tour**: 7-8 Stopps wählen
2. **Timing messen**:
   - ⏱️ Phase 1 sollte < 5 Sekunden dauern
   - ⏱️ Phase 2 läuft im Hintergrund, blockiert UI nicht
   - ⏱️ "Zeig mir die Tour!" Button sofort verfügbar nach Phase 1

---

## 📱 **Konkrete Test-Schritte:**

### **Schritt 1: App-Launch & Route-Planning**
```
1. Open SmartCityGuide App
2. Tap "Route planen"
3. Enter: "Nürnberg"
4. Select: "4 Stopps"
5. Select: "Zurück zum Start"
6. Select: "Kurze Tour"
7. Tap "Los, planen wir!"
8. OBSERVE: Loading states transition
```

### **Schritt 2: Wikipedia-Data Verification**
```
Nach erfolgreicher Route-Generation:
1. SCROLL through waypoints
2. CHECK each POI for:
   - [x] Blue Wikipedia badge
   - [x] Star indicator (if high quality)
   - [x] Short description text
   - [x] Thumbnail image (if available)
   - [x] Link button works
3. TAP Link button → should open Safari/Wikipedia
```

### **Schritt 3: Background Process Monitoring**
```
1. LOOK for blue background section
2. OBSERVE progress bar filling up
3. CHECK percentage text updating
4. WAIT for completion (should be < 30 seconds)
5. VERIFY section disappears when done
```

### **Schritt 4: Console Log Analysis**
```
In Xcode Debug Console, look for:
✅ "Enriching X route POIs with Wikipedia..."
✅ "Route enrichment completed: Y/X successful"
✅ "Background enriching Z additional POIs..."
✅ "Background enrichment completed"
```

---

## 🎯 **Erwartete Wikipedia-Matches für Nürnberg:**

| POI Name | Wikipedia-Artikel | Beschreibung | Bild |
|----------|-------------------|--------------|------|
| **Kaiserburg Nürnberg** | ✅ Kaiserburg Nürnberg | "Die Kaiserburg Nürnberg ist eine Doppelburg..." | ✅ Burg-Foto |
| **Germanisches Nationalmuseum** | ✅ Germanisches Nationalmuseum | "Das Germanische Nationalmuseum ist das größte..." | ✅ Museum-Foto |
| **St. Sebaldus** | ✅ St. Sebaldus (Nürnberg) | "Die Sebalduskirche ist die ältere..." | ✅ Kirche-Foto |
| **Lorenzkirche** | ✅ Lorenzkirche (Nürnberg) | "Die Lorenzkirche ist die größte Kirche..." | ✅ Kirche-Foto |
| **Schöner Brunnen** | ✅ Schöner Brunnen (Nürnberg) | "Der Schöne Brunnen ist ein gotischer..." | ✅ Brunnen-Foto |

---

## 🚨 **Häufige Test-Probleme & Lösungen:**

### **Problem: "Keine Wikipedia-Info gefunden"**
- ✅ **Normal** für manche POIs
- ✅ Check Console-Logs für Details
- ✅ Teste mit bekannten POIs (Kaiserburg, etc.)

### **Problem: Wikipedia-Bilder laden nicht**
- ⚠️ Langsame Internet-Verbindung
- ⚠️ Wikipedia-Server-Issues
- ✅ AsyncImage zeigt Fallback (photo icon)

### **Problem: Background-Enrichment hängt**
- ⚠️ Rate-Limiting von Wikipedia
- ⚠️ Network-Issues
- ✅ Check Console für Error-Messages

### **Problem: Performance ist langsam**
- ⚠️ Zu viele POIs gleichzeitig
- ⚠️ Schlechte Netzwerk-Verbindung
- ✅ Rate-Limiting funktioniert korrekt (100ms/200ms Delays)

---

## 📊 **Success-Kriterien:**

### ✅ **Must-Have:**
- [x] Route wird generiert (wie vorher)
- [x] Wikipedia-Daten erscheinen für mindestens 50% der Route-POIs
- [x] UI bleibt responsive während Enrichment
- [x] Background-Process läuft ohne UI-Block
- [x] "Zeig mir die Tour!" Button funktioniert sofort nach Phase 1

### ✅ **Nice-to-Have:**
- [x] Hochqualitäts-Wikipedia-Matches (⭐ Sterne)
- [x] Schöne Wikipedia-Bilder werden geladen
- [x] Prozent-Anzeige für Background-Progress
- [x] Alle POIs haben Wikipedia-Daten (auch Background-enriched)

### ✅ **Performance:**
- [x] Phase 1 < 5 Sekunden
- [x] UI nie eingefroren
- [x] Memory-Usage stabil
- [x] App crasht nicht bei Network-Fehlern

---

## 🔧 **Debug-Commands:**

### **Xcode Console Filters:**
```
📚 - Alle Wikipedia-Logs
🌐 - API-Requests  
⚠️ - Errors/Warnings
```

### **Test mit verschiedenen Städten:**
```swift
// Test-Cases:
"Nürnberg"    // ✅ Viele bekannte POIs
"München"     // ✅ Große Stadt, viele Matches
"Bamberg"     // ✅ Kleinere Stadt, weniger POIs
"Xyz123"      // ❌ Error-Case
```

---

**🎉 Happy Testing! Die Wikipedia-Integration sollte die POI-Experience deutlich verbessern!**

*Bei Fragen oder Problemen: Console-Logs checken und Error-Messages dokumentieren.*