import SwiftUI

/// Erfolgs-View nach Route-Completion mit motivierender Zusammenfassung
/// Zeigt animierte Statistiken und ermöglicht Rückkehr zur Karte
struct RouteSuccessView: View {
    let completedRoute: GeneratedRoute
    let routeStats: RouteCompletionStats
    let onClose: () -> Void
    
    // Animation states
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Close button at top
                HStack {
                    Spacer()
                    Button("Fertig") {
                        onClose()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Success Icon and Title
                successHeader
                
                // Statistics Grid
                statisticsGrid
                
                Spacer()
                
                // Motivational Message and Action Button
                actionSection
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    // MARK: - Success Header
    private var successHeader: some View {
        VStack(spacing: 12) {
            // Animated success icon (smaller)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(showIcon ? 1.0 : 0.3)
            .opacity(showIcon ? 1.0 : 0.0)
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showIcon)
            
            // Title and subtitle (more compact)
            VStack(spacing: 4) {
                Text("Tour abgeschlossen! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Du hast erfolgreich alle Spots von \(routeStats.routeName) besucht!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .opacity(showTitle ? 1.0 : 0.0)
            .offset(y: showTitle ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: showTitle)
        }
    }
    
    // MARK: - Statistics Grid
    private var statisticsGrid: some View {
        VStack(spacing: 12) {
            Text("Deine Tour-Statistiken")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .opacity(showStats ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.6), value: showStats)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCardView(
                    icon: "figure.walk",
                    value: routeStats.formattedDistance,
                    label: "Gehstrecke",
                    color: .blue
                )
                
                StatCardView(
                    icon: "clock",
                    value: routeStats.formattedWalkingTime,
                    label: "Gehzeit",
                    color: .green
                )
                
                StatCardView(
                    icon: "map",
                    value: "\(routeStats.visitedSpotsCount)",
                    label: "Spots besucht",
                    color: .orange
                )
                
                StatCardView(
                    icon: "timer",
                    value: routeStats.formattedExperienceTime,
                    label: "Gesamtzeit",
                    color: .purple
                )
            }
            .opacity(showStats ? 1.0 : 0.0)
            .offset(y: showStats ? 0 : 30)
            .animation(.easeOut(duration: 0.8).delay(0.8), value: showStats)
        }
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 12) {
            // Motivational closing message (smaller)
            Text("Danke, dass du mit uns die Stadt erkundet hast!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Single Action: Close with friendly message (more compact)
            Button(action: onClose) {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Bis bald!")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .accessibilityIdentifier("routeSuccess.action.close")
        }
        .opacity(showButton ? 1.0 : 0.0)
        .offset(y: showButton ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(1.2), value: showButton)
    }
    
    // MARK: - Animation Sequence
    private func startAnimationSequence() {
        // Staggered animations for smooth reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showIcon = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showTitle = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showStats = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showButton = true
        }
    }
}

// MARK: - Preview
#Preview {
            RouteSuccessView(
            completedRoute: GeneratedRoute(
                waypoints: [],
                routes: [],
                totalDistance: 2300,
                totalTravelTime: 2700,
                totalVisitTime: 3600,
                totalExperienceTime: 6300,
                endpointOption: .roundtrip
            ),
        routeStats: RouteCompletionStats(
            totalDistance: 2300,
            totalWalkingTime: 2700,
            totalExperienceTime: 6300,
            visitedSpotsCount: 5,
            completionDate: Date(),
            routeName: "Nürnberg Tour"
        ),
        onClose: {}
    )
}
