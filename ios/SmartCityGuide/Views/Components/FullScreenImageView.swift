//
//  FullScreenImageView.swift
//  SmartCityGuide
//
//  Created by Assistant on 2025-01-05.
//  Full-Screen Image Viewer für Wikipedia-Bilder mit Pinch-to-Zoom
//

import SwiftUI

/// Full-Screen Image Viewer mit Zoom-Funktionalität und UX-Best-Practices
struct FullScreenImageView: View {
    let imageURL: String
    let title: String?
    let wikipediaURL: String?
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @GestureState private var magnification: CGFloat = 1.0
    @GestureState private var panOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Schwarzer Hintergrund für bessere Bildwirkung
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    // Tap außerhalb des Bildes → Schließen
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                // Navigation Bar
                topNavigationBar
                
                // Hauptbild mit Zoom-Funktionalität
                GeometryReader { geometry in
                    AsyncImage(url: URL(string: imageURL)) { imagePhase in
                        switch imagePhase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale * magnification)
                                .offset(
                                    x: offset.width + panOffset.width,
                                    y: offset.height + panOffset.height
                                )
                                .gesture(
                                    SimultaneousGesture(
                                        // Pinch-to-Zoom Gesture
                                        MagnificationGesture()
                                            .updating($magnification) { value, state, _ in
                                                state = value
                                            }
                                            .onEnded { value in
                                                scale *= value
                                                // Zoom-Limits
                                                scale = min(max(scale, 0.5), 4.0)
                                                
                                                // Auto-Reset bei zu kleinem Zoom
                                                if scale < 1.0 {
                                                    withAnimation(.spring()) {
                                                        scale = 1.0
                                                        offset = .zero
                                                    }
                                                }
                                            },
                                        
                                        // Pan Gesture für Bildverschiebung
                                        DragGesture()
                                            .updating($panOffset) { value, state, _ in
                                                state = value.translation
                                            }
                                            .onEnded { value in
                                                offset.width += value.translation.width
                                                offset.height += value.translation.height
                                                
                                                // Bounds-Checking für bessere UX
                                                let maxOffset = calculateMaxOffset(
                                                    imageSize: geometry.size,
                                                    scale: scale
                                                )
                                                
                                                withAnimation(.spring()) {
                                                    offset.width = min(max(offset.width, -maxOffset.width), maxOffset.width)
                                                    offset.height = min(max(offset.height, -maxOffset.height), maxOffset.height)
                                                }
                                            }
                                    )
                                )
                                .onTapGesture(count: 2) {
                                    // Double-Tap → Zoom Toggle
                                    withAnimation(.spring()) {
                                        if scale > 1.0 {
                                            scale = 1.0
                                            offset = .zero
                                        } else {
                                            scale = 2.0
                                        }
                                    }
                                }
                                .clipped()
                        
                        case .failure(_):
                            errorImageView
                        
                        case .empty:
                            loadingImageView
                        
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom Info Bar (optional)
                if let title = title {
                    bottomInfoBar(title: title)
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(true)
    }
    
    // MARK: - UI Components
    
    private var topNavigationBar: some View {
        HStack {
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Zoom-Info
            Text("\(Int(scale * 100))%")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
            
            Spacer()
            
            // Wikipedia-Link Button
            if let wikipediaURL = wikipediaURL,
               let url = URL(string: wikipediaURL) {
                Button(action: {
                    UIApplication.shared.open(url)
                }) {
                    Image(systemName: "safari.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
    
    private func bottomInfoBar(title: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("Pinch zum Zoomen • Doppeltipp für 2x • Ziehen zum Verschieben")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
    }
    
    private var loadingImageView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Lade Wikipedia-Bild...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorImageView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Bild konnte nicht geladen werden")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private func calculateMaxOffset(imageSize: CGSize, scale: CGFloat) -> CGSize {
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        return CGSize(
            width: max(0, (scaledSize.width - imageSize.width) / 2),
            height: max(0, (scaledSize.height - imageSize.height) / 2)
        )
    }
}

// MARK: - Preview

struct FullScreenImageView_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenImageView(
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Hauptkirche_St._Petri_%28Hamburg%29_2020.jpg/1200px-Hauptkirche_St._Petri_%28Hamburg%29_2020.jpg",
            title: "Schöner Brunnen (Nürnberg)",
            wikipediaURL: "https://de.wikipedia.org/wiki/Sch%C3%B6ner_Brunnen",
            isPresented: .constant(true)
        )
    }
}