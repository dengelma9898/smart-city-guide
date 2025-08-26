# Spec Tasks

## Tasks

- [ ] 1. Create Core Intro Flow Infrastructure
  - [ ] 1.1 Write tests for IntroStep enum and navigation logic
  - [ ] 1.2 Create IntroStep enum (welcome, locationWhenInUse, locationAlways, notificationPermission, completion)
  - [ ] 1.3 Create IntroFlowView with NavigationStack container
  - [ ] 1.4 Implement UserDefaults "hasCompletedIntro" flag and first-launch detection
  - [ ] 1.5 Add intro_background.png to Assets.xcassets
  - [ ] 1.6 Create shared background view component with blur and dark overlay
  - [ ] 1.7 Verify navigation flow and UserDefaults integration tests pass

- [ ] 2. Implement Individual Intro Screen Views
  - [ ] 2.1 Write tests for each intro screen view rendering and user interactions
  - [ ] 2.2 Create WelcomeIntroView with app purpose explanation
  - [ ] 2.3 Create LocationWhenInUseIntroView with permission explanation
  - [ ] 2.4 Create LocationAlwaysIntroView with background permission explanation
  - [ ] 2.5 Create NotificationPermissionIntroView with notification explanation
  - [ ] 2.6 Create CompletionIntroView with success message and app transition
  - [ ] 2.7 Implement consistent German UI texts with conversational tone
  - [ ] 2.8 Verify all intro screen views render correctly with background

- [ ] 3. Integrate Permission Requests and Skip Functionality
  - [ ] 3.1 Write tests for permission request flows and skip dialog behavior
  - [ ] 3.2 Integrate LocationManagerService.requestLocationPermission() for When In Use
  - [ ] 3.3 Integrate LocationManagerService.requestAlwaysLocationPermission() for Always
  - [ ] 3.4 Integrate ProximityService notification permission requests
  - [ ] 3.5 Implement SkipConfirmationDialog with profile settings hint
  - [ ] 3.6 Add skip button to all screens except completion screen
  - [ ] 3.7 Handle permission denial scenarios with helpful user guidance
  - [ ] 3.8 Verify permission integration and skip functionality tests pass

- [ ] 4. Update App Launch Logic and Remove Legacy Permission Code
  - [ ] 4.1 Write tests for app launch flow with intro vs direct to main app
  - [ ] 4.2 Update SmartCityGuideApp.swift or ContentView.swift to show intro flow on first launch
  - [ ] 4.3 Remove permission requests from ContentView.swift (locationButtonTapped method)
  - [ ] 4.4 Remove permission requests from HomeCoordinator.swift (initializeServices method)
  - [ ] 4.5 Remove automatic Always permission requests from ProximityService.requestBackgroundLocationIfNeeded()
  - [ ] 4.6 Update app entry point to conditionally show IntroFlowView vs ContentView
  - [ ] 4.7 Verify legacy code removal and new launch logic tests pass

- [ ] 5. Extend Profile Settings for Permission Management
  - [ ] 5.1 Write tests for profile permission settings UI and navigation to Settings app
  - [ ] 5.2 Add Location When In Use settings section to ProfileSettingsView
  - [ ] 5.3 Add Location Always settings section to ProfileSettingsView
  - [ ] 5.4 Add Notification settings section to ProfileSettingsView
  - [ ] 5.5 Implement Settings app navigation links for denied permissions
  - [ ] 5.6 Add informational text about limited functionality without permissions
  - [ ] 5.7 Create FAQ updates for new permission workflow (as per .cursorrules)
  - [ ] 5.8 Verify profile permission management and FAQ updates are complete

- [ ] 6. Build Verification and UI Testing
  - [ ] 6.1 Use MCP XcodeBuildMCP tools to build and verify compilation success
  - [ ] 6.2 Test intro flow in iPhone 16 Simulator with first launch scenario
  - [ ] 6.3 Test skip functionality and profile fallback navigation
  - [ ] 6.4 Test permission grant/denial scenarios across all three permissions
  - [ ] 6.5 Verify background image implementation and visual consistency
  - [ ] 6.6 Test repeat app launches to ensure intro shows only once
  - [ ] 6.7 Perform UI testing with MCP simulator control tools
  - [ ] 6.8 Verify all MCP build verification and simulator testing complete
