import SwiftUI

/// Loading states for route generation process
struct RouteLoadingStateView: View {
  let loadingStateText: String
  let maximumStops: MaximumStops?
  let startingCity: String
  
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header - only show during generation
        VStack(spacing: 12) {
          Text("Wir basteln deine Route!")
            .font(.title2)
            .fontWeight(.semibold)
          Text("Suchen die coolsten \(maximumStops?.intValue ?? 5) Stopps in \(startingCity) für dich!")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .padding(.top, 20)
        
        // Loading State
        VStack(spacing: 16) {
          ProgressView().scaleEffect(1.2)
          Text(loadingStateText).font(.body).foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
        Spacer(minLength: 20)
      }
      .padding(.horizontal, 12)
    }
  }
}

/// Error state display for route generation failures
struct RouteErrorStateView: View {
  let errorMessage: String
  let onRetry: () -> Void
  
  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 40))
          .foregroundColor(.orange)
        Text("Ups, da lief was schief!")
          .font(.headline)
          .fontWeight(.semibold)
        Text(errorMessage)
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        Button("Nochmal probieren!", action: onRetry)
          .buttonStyle(.borderedProminent)
        Spacer(minLength: 20)
      }
      .padding(.vertical, 40)
      .padding(.horizontal, 12)
    }
  }
}
