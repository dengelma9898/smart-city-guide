import SwiftUI

/// Full-screen image modal with Photos-like zoom and gesture interactions
struct FullScreenImageView: View {
  let imageURL: String
  let title: String
  let wikipediaURL: String
  let imageZoomNamespace: Namespace.ID
  
  @State private var zoomDragOffset: CGSize = .zero
  @State private var zoomScale: CGFloat = 1.0
  
  let onDismiss: () -> Void
  
  var body: some View {
    ZStack {
      Color.black.opacity(max(0.0, 0.95 - Double(abs(zoomDragOffset.height) / 800)))
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            onDismiss()
          }
        }

      VStack(spacing: 16) {
        if let url = URL(string: imageURL) {
          AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: imageURL, in: imageZoomNamespace, isSource: true)
                .cornerRadius(8)
                .scaleEffect(zoomScale)
                .offset(zoomDragOffset)
                .highPriorityGesture(
                  DragGesture()
                    .onChanged { value in
                      zoomDragOffset = value.translation
                      let progress = 1 - min(0.5, abs(value.translation.height) / 600)
                      zoomScale = max(0.85, progress)
                    }
                    .onEnded { value in
                      let shouldDismiss = abs(value.translation.height) > 140
                      withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                        if shouldDismiss {
                          onDismiss()
                        }
                        zoomDragOffset = .zero
                        zoomScale = 1.0
                      }
                    }
                )
            default:
              ProgressView()
            }
          }
        }

        if !title.isEmpty {
          Text(title)
            .font(.footnote)
            .foregroundColor(.white.opacity(0.9))
        }

        HStack(spacing: 20) {
          Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
              onDismiss()
            }
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 28))
              .foregroundColor(.white.opacity(0.95))
          }

          if let page = URL(string: wikipediaURL), !wikipediaURL.isEmpty {
            Button { UIApplication.shared.open(page) } label: {
              Image(systemName: "safari")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.95))
            }
          }
        }
      }
      .padding(.horizontal, 16)
    }
    .transition(.opacity)
    .onAppear {
      // Reset zoom state when appearing
      zoomDragOffset = .zero
      zoomScale = 1.0
    }
  }
}