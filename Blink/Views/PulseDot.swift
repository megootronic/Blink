//
//  PulseDot.swift
//  Blink
//
//  Green breathing dot for active servers
//

import SwiftUI

struct PulseDot: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(.green)
            .frame(width: 6, height: 6)
            .opacity(isPulsing ? 1.0 : 0.4)
            .scaleEffect(isPulsing ? 1.15 : 0.85)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
