//
//  RouteEditBackgroundView.swift
//  SmartCityGuide
//
//  Background gradient for Route Edit interface
//

import SwiftUI

struct RouteEditBackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.systemGray6).opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    RouteEditBackgroundView()
}
