# Technical Stack

## Platform & Core Technologies

- **application_framework**: iOS 17.5+ Native
- **programming_language**: Swift 5.0
- **ui_framework**: SwiftUI 
- **development_environment**: Xcode 15.0+
- **minimum_ios_version**: iOS 17.5

## Architecture & Patterns

- **architecture_pattern**: MVVM + Coordinator Pattern
- **dependency_injection**: Protocol-Oriented Programming
- **state_management**: SwiftUI (@State, @StateObject, @Published)
- **navigation_pattern**: Coordinator Pattern with SwiftUI NavigationStack
- **concurrency_model**: Modern Swift Concurrency (async/await, @MainActor)

## External APIs & Services

- **mapping_service**: MapKit (Apple Native)
- **geocoding_api**: Geoapify API
- **places_api**: Geoapify Places API
- **content_enrichment**: Wikipedia API (OpenSearch + REST Summary)
- **location_services**: CoreLocation (Apple Native)

## Data Management

- **local_storage**: File System + UserDefaults
- **caching_strategy**: Multi-Layer (Memory + Disk)
- **secure_storage**: Keychain Services
- **data_persistence**: Custom Cache Services (POI, Route, Wikipedia)

## Security

- **api_key_management**: Secure APIKeys.plist (Certificate Pinning)
- **network_security**: NetworkSecurityManager with SHA-256 Validation
- **input_validation**: Custom InputValidator Service
- **logging_system**: SecureLogger with Privacy Protection

## Performance Optimization

- **route_optimization**: Traveling Salesman Problem (TSP) Algorithm
- **api_rate_limiting**: Custom RateLimiter with AsyncSemaphore
- **lazy_loading**: Service-based Lazy Initialization
- **background_processing**: Timer-based Cache Maintenance

## Testing Framework

- **ui_testing**: XCUITest
- **test_architecture**: Page Object Pattern
- **mock_services**: Protocol-based Mocks for Development
- **accessibility_testing**: Accessibility IDs for UI Automation

## Development Tools

- **ide**: Xcode 15.0+ + Cursor AI Assistant
- **version_control**: Git (Local Repository)
- **simulator**: iOS Simulator
- **physical_testing**: iPhone (Development Device)
- **project_management**: Xcode Project (.xcodeproj)
- **feature_flags**: Custom FeatureFlags.swift
- **build_configuration**: Debug/Release with Secure Certificate Settings
- **code_organization**: MARK-based Section Organization
- **development_approach**: Solo Development with AI-Assisted Coding

## Deployment

- **target_platforms**: iPhone, iPad
- **bundle_identifier**: de.dengelma.smartcity-guide
- **code_signing**: Automatic (Team: 4T9BXP692G)
- **asset_management**: Xcode Assets.xcassets
- **localization**: German Primary with Localization Framework

## Database

- **database_system**: n/a (File System + Cache-based)
- **database_hosting**: n/a (Local Device Storage)

## Hosting & Infrastructure

- **application_hosting**: n/a (Native iOS App)
- **asset_hosting**: n/a (Bundle Resources)
- **deployment_solution**: App Store Distribution
- **code_repository_url**: Local Development Repository
