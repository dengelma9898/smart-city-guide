# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-26-intro-permission-screens/spec.md

## Technical Requirements

### SwiftUI View Architecture
- **IntroFlowView** - Container view mit NavigationStack für Screen-Navigation
- **WelcomeIntroView** - Erster Screen mit App-Zweck-Erklärung
- **LocationWhenInUseIntroView** - Location When In Use Permission Erklärung vor Dialog
- **LocationAlwaysIntroView** - Location Always Permission Erklärung vor Dialog
- **NotificationPermissionIntroView** - Notification Permission Erklärung vor Dialog
- **CompletionIntroView** - Abschluss-Screen ohne Skip-Option
- **SkipConfirmationDialog** - Alert-Dialog bei Skip mit Profil-Hinweis

### Permission Integration
- Integration mit existierendem **LocationManagerService** für Location When In Use und Always Permissions
- Integration mit existierendem **ProximityService** für Notification Permissions
- Entfernung von Permission-Requests aus **ContentView.swift** (locationButtonTapped)
- Entfernung von Permission-Requests aus **HomeCoordinator.swift** (initializeServices)
- Entfernung von automatischen Always Permission Requests aus **ProximityService.requestBackgroundLocationIfNeeded()**

### Navigation & State Management
- **@State private var currentStep: IntroStep** für Screen-Navigation
- Enum **IntroStep**: welcome, locationWhenInUse, locationAlways, notificationPermission, completion
- **@State private var showSkipConfirmation: Bool** für Skip-Dialog
- Navigation via **NavigationStack** mit programmatischer Navigation

### Background Image Implementation
- **intro_background.png** als ZStack-Hintergrund auf allen Intro-Views
- **Image("intro_background")** mit **.blur(radius: 3)** für Blur-Effekt
- **Color.black.opacity(0.6)** als Overlay für Text-Lesbarkeit
- **.ignoresSafeArea()** für Fullscreen-Background

### UserDefaults Integration
- **UserDefaults Key**: "hasCompletedIntro" (Bool)
- Check in **SmartCityGuideApp.swift** oder **ContentView.swift**
- Flag wird auf **true** gesetzt bei Completion oder Skip mit bestätigter Action

### Profile Screen Integration
- Erweiterung der **ProfileSettingsView** um Permission-Toggles
- **Location When In Use Settings Section** - Status anzeigen + Settings-App Link bei Denial
- **Location Always Settings Section** - Status anzeigen + Settings-App Link bei Denial
- **Notification Settings Section** - Status anzeigen + Re-Request Möglichkeit
- Info-Text über eingeschränkte Funktionalität bei fehlenden Permissions

### UI/UX Specifications
- **Deutsche Texte** mit freundlichem, conversational Ton
- **Button Styling** konsistent mit App-Design (primary/secondary)
- **Loading States** während Permission-Requests
- **Error Handling** bei Permission-Denial mit hilfreichen Hinweisen

### Integration Points
- **App Launch Logic** - Intro vor ContentView anzeigen wenn hasCompletedIntro == false
- **Permission Status Checking** - Bestehende Services nutzen für Status-Queries
- **Profile Navigation** - Navigation zu Settings bei Skip oder späteren Permission-Grants
