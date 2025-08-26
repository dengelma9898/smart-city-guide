# Spec Requirements Document

> Spec: Intro Permission Screens für SmartCityGuide
> Created: 2025-08-26

## Overview

Implementierung eines benutzerfreundlichen Onboarding-Flows mit Intro-Screens für Erstnutzer, die den App-Zweck erklären und notwendige Permissions (Location When In Use, Location Always, Notifications) mit entsprechenden Erklärungen vor der Berechtigung anfordern. Das System ersetzt das aktuelle Ad-hoc Permission-Handling und bietet eine einmalige, überspringbare Einführung mit Fallback-Optionen im Profil.

## User Stories

### Erstnutzer Onboarding
Als neuer App-Nutzer möchte ich verstehen, was die App macht und warum sie bestimmte Berechtigungen benötigt, damit ich informierte Entscheidungen treffen kann und vertrauen in die App entwickle.

Der User wird durch eine Sequenz von Screens geführt:
1. Welcome Screen mit App-Zweck-Erklärung
2. Location When In Use Permission Erklärung → Permission Dialog
3. Location Always Permission Erklärung → Permission Dialog
4. Notification Permission Erklärung → Permission Dialog  
5. Completion Screen → Weiterleitung zur Hauptapp

### Permission Verweigerung & Skip-Funktionalität
Als Nutzer möchte ich die Möglichkeit haben, das Onboarding zu überspringen oder einzelne Permissions zu verweigern, während ich darüber informiert werde, dass ich diese später im Profil aktivieren kann.

Bei Skip oder verweigerter Permission wird der User über eingeschränkte Funktionalität informiert und auf Profil-Einstellungen hingewiesen.

### Wiederkehrende Nutzer
Als wiederkehrender Nutzer möchte ich die Intro-Screens nur beim ersten App-Start sehen, damit meine App-Nutzung nicht bei jedem Start unterbrochen wird.

UserDefaults-Flag verhindert Wiederholung der Intro-Screens bei bereits onboardeten Nutzern.

## Spec Scope

1. **Welcome Screen** - Einführung mit App-Zweck und Funktionalität, intro_background.png als blurred/darkened Hintergrund
2. **Location When In Use Permission Flow** - Erklärungsscreen + iOS Permission Dialog für "When In Use" Location
3. **Location Always Permission Flow** - Erklärungsscreen + iOS Permission Dialog für "Always" Location (Background-Benachrichtigungen)
4. **Notification Permission Flow** - Erklärungsscreen + iOS Permission Dialog für Push Notifications
5. **Completion Screen** - Erfolgs-Screen mit Übergang zur Hauptapp
6. **Skip-Funktionalität** - Skip-Button auf allen Screens außer Completion, mit Warndialog bei Skip
7. **Permission Fallback** - Profile-Integration für nachträgliche Permission-Erteilung
8. **First-Launch-Detection** - UserDefaults-basierte Einmal-Anzeige der Intro-Screens

## Out of Scope

- Face ID/Touch ID Permission (nicht erforderlich für Kernfunktionalität)
- Animationen zwischen Screens (zukünftige Verbesserung)
- Multi-Language Support (aktuell nur Deutsch)
- Detaillierte Analytics/Tracking der Onboarding-Performance
- Bedingte Permission-Flows (alle drei Permissions werden immer angeboten)

## Expected Deliverable

1. **Funktionale Intro-Screen Sequenz** - Vollständiger 5-Screen Flow mit Navigation und alle drei Permission-Requests testbar im iOS Simulator
2. **Permission Integration** - Entfernung des alten Permission-Codes und Integration in Profil-Settings für Skip-Szenarien  
3. **Background Image Implementation** - intro_background.png korrekt als blurred/darkened Hintergrund auf allen Intro-Screens
