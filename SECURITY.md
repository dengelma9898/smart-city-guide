# Security Guidelines 🔒

## Reporting Security Issues

**Bitte melde Sicherheitslücken NICHT über öffentliche GitHub Issues.**

Stattdessen:
- **Email**: [security@yourcompany.com]  
- **Subject**: "[SECURITY] Smart City Guide - [Kurze Beschreibung]"
- **Encryption**: GPG Key verfügbar auf Anfrage

Wir reagieren normalerweise **innerhalb von 24 Stunden** auf Security-Reports.

## Security Best Practices für Entwickler

### ✅ DO's
- **API Keys** immer in separaten Konfigurationsdateien (APIKeys.plist)
- **Sensitive Dateien** in .gitignore aufnehmen
- **HERE API Key Restrictions** verwenden (Domain, Rate Limits)
- **Regular Security Reviews** vor jedem Release
- **Dependencies** regelmäßig auf Vulnerabilities prüfen

### ❌ DON'Ts  
- **NIE** API Keys im Source Code hardcodieren
- **NIE** .plist Files mit Secrets committen
- **NIE** sensitive Daten in Logs ausgeben
- **NIE** unvalidierte User Inputs an APIs weiterleiten

## API Key Management

### HERE API Key Setup
1. **Erstelle** einen HERE Developer Account
2. **Generiere** einen neuen API Key mit Restrictions:
   - **Domain Restrictions**: Nur deine App Bundle ID
   - **Rate Limits**: Angemessen für App-Usage  
   - **Services**: Nur benötigte APIs (Search, Geocoding)
3. **Konfiguriere** in APIKeys.plist (nie committen!)
4. **Widerrufe** alte/compromised Keys sofort

### APIKeys.plist Template
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>HERE_API_KEY</key>
    <string>YOUR_HERE_API_KEY_HERE</string>
    <!-- Füge weitere API Keys hier hinzu -->
</dict>
</plist>
```

## Security Incidents

### ⚠️ SECURITY ADVISORY - August 2025
**CVE**: N/A (Internal)  
**Severity**: Medium  
**Issue**: HERE API Key war hardcodiert im Source Code  
**Affected**: Commits vor `83996a9` (Aug 3, 2025)  
**Status**: ✅ **RESOLVED**  

**Timeline**:
- **2025-08-03 21:00**: Issue identified durch Security Audit
- **2025-08-03 21:05**: Alter API Key widerrufen
- **2025-08-03 21:10**: Neuer API Key mit Restrictions erstellt  
- **2025-08-03 21:15**: Sichere APIKeys.plist Implementation
- **2025-08-03 21:20**: Security commit & .gitignore erstellt
- **2025-08-03 21:25**: Security Plan & Guidelines dokumentiert

**Lessons Learned**:
- ✅ **Automated Secret Scanning** in CI/CD Pipeline implementieren
- ✅ **Pre-commit Hooks** für Secret Detection
- ✅ **Developer Security Training** verbessern
- ✅ **Regular Security Audits** etablieren

## Security Checklist für Pull Requests

### Code Review Checklist
- [ ] **Keine hardcodierten Secrets** im Code
- [ ] **Sensitive Dateien** in .gitignore 
- [ ] **Input Validation** für alle User Inputs
- [ ] **Error Messages** enthalten keine sensitive Informationen
- [ ] **Dependencies** sind aktuell und sicher
- [ ] **API Calls** sind rate-limited und authenticated

### Testing Checklist  
- [ ] **Secret Detection** scan passed
- [ ] **Dependency Vulnerability** scan passed
- [ ] **Unit Tests** für Security-relevante Funktionen
- [ ] **Integration Tests** mit Mock APIs (keine echten Keys)
- [ ] **Manual Security Review** durchgeführt

## Automated Security

### CI/CD Pipeline
```yaml
# Beispiel GitHub Actions Security Job
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Secret Detection
      uses: trufflesecurity/trufflehog@main
    - name: Dependency Check
      uses: dependency-check/Dependency-Check_Action@main
    - name: SAST Scan
      uses: securecodewarrior/github-action-add-sarif@v1
```

### Pre-commit Hooks
```bash
# Setup pre-commit hooks
pip install pre-commit
pre-commit install

# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
```

## Emergency Response

### Security Incident Response Plan
1. **Immediate**: Widerrufe compromised API Keys
2. **Assessment**: Scope und Impact analysieren  
3. **Containment**: Weitere Ausbreitung verhindern
4. **Communication**: Stakeholder informieren
5. **Recovery**: Sichere Konfiguration implementieren
6. **Lessons Learned**: Post-Incident Review

### Emergency Contacts
- **Security Team**: [security@yourcompany.com]
- **HERE API Support**: HERE Developer Support Portal
- **Apple Security**: security@apple.com (für App Store Issues)

## Compliance

### GDPR/DSGVO
- **Location Data**: Nur mit User Consent verwenden
- **Data Minimization**: Nur notwendige Daten sammeln
- **Right to Deletion**: User Data Deletion implementieren
- **Privacy Policy**: Transparent Data Usage offenlegen

### App Store Guidelines
- **Data Use**: Klar in App Store Description erklären
- **Permissions**: Nur notwendige Permissions anfordern
- **Third-party Services**: HERE API Usage transparent machen

---

**Letzte Aktualisierung**: 2025-08-03  
**Nächste Review**: 2025-11-03 (Quarterly Review)