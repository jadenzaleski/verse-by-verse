//
//  ParticleBurst.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/1/25.
//

import SwiftUI

private struct Particle: Identifiable {
    let id = UUID()
    let angle: Angle
    let distance: CGFloat
    let size: CGFloat
    let color: Color
}

struct ParticleBurst: View {
    let count: Int
    let baseColor: Color
    let duration: Double

    @State private var progress: CGFloat = 0
    private var particles: [Particle]

    init(count: Int = 8, baseColor: Color = .orange, duration: Double = 0.5) {
        self.count = count
        self.baseColor = baseColor
        self.duration = duration
        // Precompute particles with random directions and distances
        var parts: [Particle] = []
        for i in 0..<count {
            let angle = Angle(degrees: Double(i) / Double(max(1, count)) * 360.0 + Double.random(in: -8...8))
            let distance = CGFloat.random(in: 15...25)
            let size = CGFloat.random(in: 2.5...4.5)
            let color = baseColor.opacity(Double.random(in: 1.0...1.0))
            parts.append(Particle(angle: angle, distance: distance, size: size, color: color))
        }
        self.particles = parts
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(
                        x: cos(CGFloat(particle.angle.radians)) * particle.distance * progress,
                        y: sin(CGFloat(particle.angle.radians)) * particle.distance * progress
                    )
                    .opacity(1 - Double(progress))
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: duration)) {
                progress = 1
            }
        }
    }
}

#Preview {
    ParticleBurst()
}
