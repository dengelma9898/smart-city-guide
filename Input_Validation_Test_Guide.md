# 🔒 Input Validation Security Test Guide

## 🎯 Testziel
Verifikation dass das InputValidator-System alle Injection-Angriffe erfolgreich blockiert und sichere Fallback-Mechanismen verwendet.

---

## ⚠️ **WICHTIG - SIMULATOR SETUP**

Stelle sicher dass der **iPhone 16 Simulator** läuft:
```bash
# Falls Simulator nicht läuft, starte ihn:
xcrun simctl boot "iPhone 16"
```

Öffne dann die **Smart City Guide App** und bereite dich auf die Tests vor.

---

## 🧪 **TEST 1: Overpass Query Injection (KRITISCH)**

### **Test-Szenario**: Overpass API Command Injection
**Was wir testen**: Verhinderung von Overpass Query Manipulation

### **Malicious Inputs zum Testen**:

1. **Basic Query Termination**:
   ```
   Eingabe: München}}
   Erwartung: ❌ BLOCKIERT oder Fallback auf Bounding Box Search
   ```

2. **Comment Injection**:
   ```
   Eingabe: Berlin//; [out:json]; node(around:100000,52.5,13.4); out; 
   Erwartung: ❌ BLOCKIERT mit Security Log
   ```

3. **Memory Exhaustion**:
   ```
   Eingabe: Hamburg/*maxsize:999999999*/
   Erwartung: ❌ BLOCKIERT 
   ```

4. **Timeout Manipulation**:
   ```
   Eingabe: Köln[timeout:9999]
   Erwartung: ❌ BLOCKIERT
   ```

### **Test-Durchführung**:
1. Öffne die **Route Planning View**
2. Gehe zum **City Input Field**
3. Tippe einen der malicious inputs ein
4. Klicke **"Route generieren"**

### **Erwartete Logs** (Console.app öffnen):
```
🚨 SECURITY: Overpass injection attempt blocked: injectionAttempt(detected: "}}")
🔒 Fallback to bounding box search without city name
```

---

## 🧪 **TEST 2: HERE API URL Injection**

### **Test-Szenario**: URL Parameter Injection in HERE API
**Was wir testen**: Sichere URL-Konstruktion und City Name Validation

### **Malicious Inputs**:

1. **Script Injection**:
   ```
   Eingabe: <script>alert('XSS')</script>
   Erwartung: ❌ BLOCKIERT mit invalidCharacters Error
   ```

2. **Data URI Injection**:
   ```
   Eingabe: data:text/html,<h1>Hacked</h1>
   Erwartung: ❌ BLOCKIERT mit injectionAttempt Error
   ```

3. **Path Traversal**:
   ```
   Eingabe: ../../../etc/passwd
   Erwartung: ❌ BLOCKIERT mit injectionAttempt Error
   ```

4. **Ultra Long Input**:
   ```
   Eingabe: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA (101+ Zeichen)
   Erwartung: ❌ BLOCKIERT mit inputTooLong Error
   ```

### **Test-Durchführung**:
1. Gehe zur **Route Planning**
2. Verwende **Location Search Field**
3. Teste jeden malicious input
4. Überprüfe dass Route-Generierung **NICHT funktioniert**

### **Erwartete Logs**:
```
🚨 SECURITY: Invalid city input rejected: invalidCharacters
🔒 Using sanitized fallback input
```

---

## 🧪 **TEST 3: Valid Input Acceptance**

### **Test-Szenario**: Bestätigung dass valide Inputs akzeptiert werden
**Was wir testen**: System funktioniert normal mit sicherem Input

### **Valide Test-Inputs**:

1. **Normale Stadt**:
   ```
   Eingabe: München
   Erwartung: ✅ AKZEPTIERT, Route wird generiert
   ```

2. **Stadt mit Postleitzahl**:
   ```
   Eingabe: 80331 München
   Erwartung: ✅ AKZEPTIERT, "München" extrahiert
   ```

3. **Stadt mit Adresse**:
   ```
   Eingabe: Nürnberg, Hauptbahnhof 1
   Erwartung: ✅ AKZEPTIERT, "Nürnberg" extrahiert
   ```

4. **Internationale Stadt**:
   ```
   Eingabe: París
   Erwartung: ✅ AKZEPTIERT (auch mit Akzenten)
   ```

### **Test-Durchführung**:
1. Teste jeden validen Input
2. Überprüfe dass **Route erfolgreich generiert wird**
3. Kontrolliere dass **POIs geladen werden**

### **Erwartete Logs**:
```
✅ City name validation successful: München
🔐 Validating certificate for pinned host: discover.search.hereapi.com
```

---

## 🧪 **TEST 4: Edge Cases & Boundary Testing**

### **Grenzwerttests**:

1. **Exakt 100 Zeichen** (Maximum):
   ```
   Eingabe: Antwerpen-Berchem-Sainte-Agathe-Berchem-Woluwe-Saint-Lambert-Woluwe-Saint-Pierre-Schaerbeek-X
   Erwartung: ✅ AKZEPTIERT (exakt 100 Zeichen)
   ```

2. **101 Zeichen**:
   ```
   Eingabe: Antwerpen-Berchem-Sainte-Agathe-Berchem-Woluwe-Saint-Lambert-Woluwe-Saint-Pierre-Schaerbeek-XX
   Erwartung: ❌ BLOCKIERT mit inputTooLong
   ```

3. **Nur Leerzeichen**:
   ```
   Eingabe: "     " (5 Leerzeichen)
   Erwartung: ❌ BLOCKIERT mit emptyInput
   ```

4. **Leerer String**:
   ```
   Eingabe: "" (leer)
   Erwartung: ❌ BLOCKIERT mit emptyInput
   ```

---

## 📊 **Logging Verification**

### **Console.app Setup**:
1. Öffne **Console.app** auf dem Mac
2. Wähle **iPhone 16 Simulator** in der Sidebar
3. Filtere nach: `subsystem:de.dengelma.smartcity-guide`
4. Aktiviere **Include Info Messages**

### **Security Log Categories zu beachten**:
- `🔍 Validating city name input`
- `🚨 SECURITY: Invalid city input rejected`
- `🔒 Validating Overpass query component`
- `✅ City name validation successful`

---

## 🎯 **SUCCESS CRITERIA**

### **✅ Test bestanden wenn**:

1. **Injection Attacks blockiert**:
   - Alle `}}`, `//`, `<script>` Inputs werden abgelehnt
   - Security Logs erscheinen in Console
   - App stürzt NICHT ab

2. **Valide Inputs funktionieren**:
   - Normale Städte-Namen werden akzeptiert
   - Route-Generierung funktioniert normal
   - POI-Loading erfolgreich

3. **Fallback-Mechanismen aktiv**:
   - Bei Overpass-Injection → Bounding Box Fallback
   - Bei City-Name-Injection → Sanitized Fallback
   - App bleibt stabil und funktional

4. **Performance Impact minimal**:
   - Keine merkliche Verzögerung bei Input
   - Route-Generierung wie gewohnt schnell

---

## 🚨 **FEHLSCHLAG-INDIKATOREN**

### **❌ Test fehlgeschlagen wenn**:

1. **Injection erfolgreich**:
   - Malicious Input wird akzeptiert und verarbeitet
   - Route wird mit gefährlichem Input generiert
   - Keine Security Logs erscheinen

2. **App Crash**:
   - App stürzt bei malicious Input ab
   - InputValidator wirft unbehandelte Exceptions

3. **Valide Inputs blockiert**:
   - Normale Städte werden fälschlicherweise abgelehnt
   - Übermäßig aggressive Validierung

---

## 🔧 **Debug Hilfe**

### **Falls Tests fehlschlagen**:

1. **Check Xcode Console**:
   ```
   ⌘ + Shift + C → Console öffnen
   Nach "SECURITY" oder "InputValidator" filtern
   ```

2. **Simulator Reset** (falls nötig):
   ```bash
   xcrun simctl erase "iPhone 16"
   xcrun simctl boot "iPhone 16"
   ```

3. **App neu installieren**:
   - App löschen im Simulator
   - Neu über Xcode installieren

---

## 📈 **Reporting**

Nach den Tests bitte melden:

1. **✅ Erfolgreiche Blocks**: Welche Injection-Versuche wurden korrekt blockiert
2. **❌ Fehlgeschlagene Tests**: Welche Inputs wurden fälschlicherweise akzeptiert/blockiert
3. **📋 Console Logs**: Screenshots der Security Logs
4. **⚡ Performance**: Merkliche Verzögerungen bei Input-Validierung

---

**🎯 ZIEL**: 100% der Injection-Angriffe blockiert, 100% der validen Inputs akzeptiert!