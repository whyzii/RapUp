import SwiftUI

struct LiquidGlassButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14
    var blurRadius: CGFloat = 12
    var strokeOpacity: CGFloat = 0.22
    var highlightOpacity: CGFloat = 0.55
    var sheenOpacity: CGFloat = 0.35

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .foregroundStyle(.primary)
            .background {
                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 0.75)
                            )
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(colors: [
                                    Color.white.opacity(highlightOpacity),
                                    Color.white.opacity(0.0)
                                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .blendMode(.softLight)
                            .padding(1.0)

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(colors: [
                                    Color.blue.opacity(0.18),
                                    Color.cyan.opacity(0.10),
                                    Color.clear
                                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .blendMode(.overlay)

                        SheenView()
                            .frame(width: size.width * 1.2, height: size.height * 1.8)
                            .opacity(sheenOpacity)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    }
                    .compositingGroup()
                    .blur(radius: configuration.isPressed ? blurRadius * 0.6 : blurRadius)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: configuration.isPressed)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityAddTraits(.isButton)
    }

    private struct SheenView: View {
        @State private var phase: CGFloat = -1.0

        var body: some View {
            Rectangle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.00),
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.00)
                        ]),
                        center: .topLeading,
                        angle: .degrees(30)
                    )
                )
                .mask(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white,
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .hueRotation(.degrees(phase * 60))
                )
                .offset(x: phase * 60)
                .onAppear {
                    withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                        phase = 2.0
                    }
                }
        }
    }
}

extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle { LiquidGlassButtonStyle() }
}
