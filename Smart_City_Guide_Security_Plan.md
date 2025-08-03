# Smart City Guide - Sicherheitsanalyse & Behebungsplan

## 🔍 Executive Summary

Diese Sicherheitsanalyse der Smart City Guide iOS-App identifizierte **6 kritische bis niedrige Sicherheitslücken**. Das Hauptrisiko liegt in hardcodierten API-Credentials und unzureichender Datenverschlüsselung. Alle Probleme sind lösbar und dieser Plan bietet eine schrittweise Anleitung zur Behebung.

---

## 🚨 Identifizierte Sicherheitslücken

### **KRITISCH** 🔴

#### 1. Hardcodierter HERE API Key
- **Location**: `ios/SmartCityGuide/Services/HEREAPIService.swift:8`
- **Risk Level**: 🔴 CRITICAL
- **Code**: 
  ```swift
  private let apiKey = "IJQ_FHors1UT0Bf-Ekex9Sgg41jDWgOWgcW58EedIWo"
  ```
- **Impact**: 
  - API-Key ist öffentlich im Code sichtbar
  - Potenzielle Kostenverursachung durch Missbrauch
  - Reputation damage if API is abused
  - Compliance-Verletzungen (DSGVO, App Store Guidelines)

---

### **HOCH** 🟠

#### 2. Unverschlüsselte UserDefaults für persönliche Daten
- **Location**: 
  - `ios/SmartCityGuide/Models/UserProfile.swift:46`
  - `ios/SmartCityGuide/Models/ProfileSettings.swift:38`
  - `ios/SmartCityGuide/Models/RouteHistory.swift:115`
- **Risk Level**: 🟠 HIGH
- **Impact**:
  - Benutzer-E-Mail, Name und Verlauf unverschlüsselt gespeichert
  - Bei Device-Kompromittierung vollständig lesbar
  - DSGVO-Compliance-Problem

#### 3. Excessive Debug Logging mit sensitiven Daten
- **Location**: Multiple files (47 print statements gefunden)
- **Risk Level**: 🟠 HIGH
- **Examples**:
  ```swift
  print("HEREAPIService: Using cached coordinates for '\(cleanCityName)': \(coordinates)")
  print("HEREAPIService: 🌐 Using HERE Browse API: \(urlString)")
  ```
- **Impact**:
  - API-URLs mit Keys in Logs
  - Location-Daten in Logs
  - Debugging-Information für Angreifer

---

### **MITTEL** 🟡

#### 4. Fehlende Input-Validierung
- **Location**: 
  - `ios/SmartCityGuide/Services/HEREAPIService.swift:86`
  - `ios/SmartCityGuide/Services/OverpassAPIService.swift:150`
- **Risk Level**: 🟡 MEDIUM
- **Impact**:
  - Potenzielle URL-Injection bei User-Input
  - Unvalidierte API-Parameter
  - XXS über API-Response parsing

#### 5. Keine Certificate Pinning
- **Location**: All HTTPS connections
- **Risk Level**: 🟡 MEDIUM
- **Impact**:
  - MITM-Angriffe möglich
  - API-Datenabfangung in unsicheren Netzwerken

---

### **NIEDRIG** 🟢

#### 6. Unzureichende Error Handling für Security
- **Location**: Multiple error handling blocks
- **Risk Level**: 🟢 LOW
- **Impact**:
  - Information Disclosure durch verbose error messages
  - Timing-Attacks durch unterschiedliche Response-Zeiten

---

## 🛠 Schritt-für-Schritt Behebungsplan

### **Phase 1: Kritische Sofortmaßnahmen (Woche 1)**

#### ✅ **1.1 HERE API Key Security**
**Priorität**: 🔴 SOFORT

**Schritte**:
1. **Neuen HERE API Key generieren**
   - Alten Key sofort in HERE Developer Portal widerrufen
   - Neuen Key mit Rate Limits und Domain-Restrictions erstellen

2. **Secure Configuration implementieren**
   ```swift
   // HEREAPIService.swift - Neue Implementierung
   class HEREAPIService: ObservableObject {
       private var apiKey: String {
           guard let key = Bundle.main.object(forInfoDictionaryKey: "HERE_API_KEY") as? String,
                 !key.isEmpty else {
               fatalError("HERE API Key not found in configuration")
           }
           return key
       }
   }
   ```

3. **Build Configuration setup**
   - Info.plist Konfiguration
   - Build Settings für verschiedene Environments
   - `.xcconfig` Files für Key-Management

**Aufwand**: 4 Stunden
**Verantwortlich**: iOS Developer
**Verification**: Build test, API functionality test

#### ✅ **1.2 Repository Cleanup**
**Priorität**: 🔴 SOFORT

**Schritte**:
1. **Git History cleanen**
   ```bash
   # Remove sensitive data from Git history
   git filter-branch --force --index-filter \
   "git rm --cached --ignore-unmatch ios/SmartCityGuide/Services/HEREAPIService.swift" \
   --prune-empty --tag-name-filter cat -- --all
   ```

2. **Security.md erstellen** mit Guidelines für zukünftige Entwicklung

**Aufwand**: 2 Stunden
**Verantwortlich**: DevOps/Lead Developer

---

### **Phase 2: Daten-Security (Woche 2)**

#### ✅ **2.1 UserDefaults Verschlüsselung**
**Priorität**: 🟠 HOCH

**Implementation**:
```swift
// SecureStorageService.swift - NEU
import Security
import Foundation

class SecureStorageService {
    private let service = "SmartCityGuide"
    
    func save<T: Codable>(_ data: T, forKey key: String) throws {
        let encoded = try JSONEncoder().encode(data)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: encoded
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStorageError.saveFailed
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        // Keychain implementation
    }
}
```

**Migration Plan**:
1. UserProfile → Keychain
2. ProfileSettings → Keychain  
3. RouteHistory → Core Data mit Encryption

**Aufwand**: 8 Stunden
**Verantwortlich**: iOS Developer

#### ✅ **2.2 Logging Security**
**Priorität**: 🟠 HOCH

**Implementation**:
```swift
// Logger.swift - NEU
import os.log

class SecureLogger {
    private static let subsystem = "de.dengelma.smartcity-guide"
    
    static func logAPI(_ message: String, sensitive: Bool = false) {
        #if DEBUG
        if sensitive {
            os_log("[API-SENSITIVE] %{private}@", log: .default, type: .debug, message)
        } else {
            os_log("[API] %@", log: .default, type: .debug, message)
        }
        #endif
    }
}
```

**Aufwand**: 4 Stunden
**Verantwortlich**: iOS Developer

---

### **Phase 3: Network Security (Woche 3)**

#### ✅ **3.1 Certificate Pinning**
**Priorität**: 🟡 MITTEL

**Implementation**:
```swift
// NetworkSecurityManager.swift - NEU
class NetworkSecurityManager: NSObject, URLSessionDelegate {
    private let pinnedCertificates = [
        "discover.search.hereapi.com": "SHA256_HASH_HERE",
        "overpass-api.de": "SHA256_HASH_HERE"
    ]
    
    func urlSession(_ session: URLSession, 
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Certificate pinning implementation
    }
}
```

**Aufwand**: 6 Stunden
**Verantwortlich**: iOS Developer

#### ✅ **3.2 Input Validation**
**Priorität**: 🟡 MITTEL

**Implementation**:
```swift
// InputValidator.swift - NEU
struct InputValidator {
    static func validateCityName(_ city: String) throws -> String {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        guard trimmed.count <= 100 else {
            throw ValidationError.inputTooLong
        }
        
        // Sanitize für URL-Sicherheit
        return trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
    }
}
```

**Aufwand**: 4 Stunden
**Verantwortlich**: iOS Developer

---

### **Phase 4: Monitoring & Compliance (Woche 4)**

#### ✅ **4.1 Security Monitoring**
**Priorität**: 🟢 NIEDRIG

**Implementation**:
- API Rate Limiting Überwachung
- Anomalie-Detection für API-Calls
- Error-Reporting ohne sensitive Daten

**Aufwand**: 3 Stunden
**Verantwortlich**: iOS Developer

#### ✅ **4.2 DSGVO Compliance**
**Priorität**: 🟠 HOCH

**Maßnahmen**:
- Datenschutzerklärung Update
- User Consent für Location-Tracking
- Data Deletion auf User-Request
- Transparent Data Usage Disclosure

**Aufwand**: 6 Stunden
**Verantwortlich**: Legal + iOS Developer

---

## 🧪 Testing & Verification Plan

### **Security Tests**
1. **API Key Test**: Sicherstellen dass kein hardcodierter Key existiert
2. **Data Encryption Test**: Keychain-Speicherung verifizieren
3. **Certificate Pinning Test**: MITM-Test mit Proxy-Tools
4. **Input Validation Test**: Fuzzing der API-Endpoints
5. **Privacy Test**: Data-Flow-Analyse für DSGVO-Compliance

### **Automated Security Scanning**
```bash
# Neue Security Pipeline - zu implementieren
- name: Security Scan
  run: |
    # Semgrep Security Rules
    semgrep --config=p/security-audit .
    
    # API Key Detection
    truffleHog --regex --entropy=False .
    
    # OWASP Dependency Check
    dependency-check --project SmartCityGuide --scan .
```

---

## 📊 Implementation Timeline

| Phase | Duration | Priority | Resources |
|-------|----------|----------|-----------|
| **Phase 1** | Woche 1 | 🔴 Critical | 1 Developer, 6h |
| **Phase 2** | Woche 2 | 🟠 High | 1 Developer, 12h |
| **Phase 3** | Woche 3 | 🟡 Medium | 1 Developer, 10h |
| **Phase 4** | Woche 4 | 🟠 High | 1 Developer + Legal, 9h |
| **Total** | 4 Wochen | | **37 Stunden** |

---

## 💰 Kosten-Nutzen-Analyse

### **Kosten**:
- Entwicklungszeit: ~37 Stunden
- Geschätzte Kosten: €3.700 (bei €100/h)
- Testing: €1.000
- **Gesamt: €4.700**

### **Nutzen**:
- API-Missbrauch vermeiden: €10.000+ potential Schaden
- DSGVO-Compliance: €20.000+ potential Strafen vermeiden
- User-Trust & App Store Reputation: Unbezahlbar
- **ROI: 600%+**

---

## 🎯 Success Metrics

### **Phase 1 Success Criteria**:
- [ ] Keine hardcodierten API-Keys in Codebase
- [ ] Build Pipeline mit secure configuration
- [ ] Git History cleaned

### **Phase 2 Success Criteria**:
- [ ] UserDefaults durch Keychain ersetzt
- [ ] Logging ohne sensitive Daten
- [ ] Automated security scans passing

### **Phase 3 Success Criteria**:
- [ ] Certificate Pinning aktiv
- [ ] Input Validation für alle APIs
- [ ] Manual security testing erfolgreich

### **Phase 4 Success Criteria**:
- [ ] DSGVO-compliant data handling
- [ ] Security monitoring dashboard
- [ ] Compliance documentation komplett

---

## 🔄 Wartung & Updates

### **Monatlich**:
- Security Dependency Updates
- API Key Rotation (quarterly)
- Security Scan Reports Review

### **Quartalsweise**:
- Penetration Testing
- Compliance Audit
- Security Training für Team

### **Jährlich**:
- Full Security Assessment
- Third-party Security Audit
- DSGVO Compliance Review

---

## 📞 Kontakt & Verantwortlichkeiten

| Rolle | Verantwortlich | Aufgaben |
|-------|---------------|----------|
| **Security Lead** | Lead Developer | Overall security implementation |
| **iOS Developer** | iOS Team | Code implementation |
| **DevOps** | DevOps Team | Pipeline & infrastructure security |
| **Legal** | Legal Team | DSGVO compliance |
| **QA** | QA Team | Security testing |

---

## 📚 Appendix

### **A. Security Tools**
- Semgrep für Static Analysis
- TruffleHog für Secret Detection
- OWASP Dependency Check
- iOS Security Testing mit Objection

### **B. Compliance Frameworks**
- OWASP Mobile Top 10
- iOS Security Guidelines
- DSGVO/GDPR Requirements
- App Store Security Guidelines

### **C. Emergency Contacts**
- **Security Incident Response**: [security@company.com]
- **API Provider Support**: HERE Technologies Support
- **Legal Emergency**: [legal@company.com]

---

*Diese Sicherheitsanalyse wurde am [DATUM] erstellt und sollte alle 6 Monate aktualisiert werden.*