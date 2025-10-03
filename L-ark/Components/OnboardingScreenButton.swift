import SwiftUI

enum ButtonFill {
    case none
    case color(Color)
    case gradient(LinearGradient)
}

enum ButtonIcon {
    case system(String)  // SF Symbol
    case asset(String)   // Asset multicolor
}

struct OnboardingScreenButton: View {
    var title: String
    var fill: ButtonFill = .none
    var icon: ButtonIcon? = nil
    var isDisabled: Bool? = false
    var textColor : Color? = .white
    var action: () -> Void = {}



    private let radius: CGFloat = 20
    private let strokeColor: Color = .white
    private let strokeWidth: CGFloat = 3

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    iconView(icon)
                        .frame(width: 25, height: 25)
                }
                Text(title)
                    .font(.title3.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .foregroundStyle(foregroundColor) // solo tinea texto y SF Symbols
            .background(backgroundView)       // fondo condicional
            .overlay(outlineView)             // borde condicional
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .contentShape(RoundedRectangle(cornerRadius: radius))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func iconView(_ icon: ButtonIcon) -> some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .resizable()
                .scaledToFit()
        case .asset(let name):
            Image(name)
                .resizable()
                .renderingMode(.original) // 👈 evita tintado en logos multicolor
                .scaledToFit()
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch fill {
        case .none:
            Color.clear
        case .color(let c):
            RoundedRectangle(cornerRadius: radius).fill(c)
        case .gradient(let g):
            RoundedRectangle(cornerRadius: radius).fill(g)
        }
    }

    @ViewBuilder
    private var outlineView: some View {
        if case .none = fill {
            RoundedRectangle(cornerRadius: radius)
                .stroke(strokeColor, lineWidth: strokeWidth)
        } else {
            EmptyView()
        }
    }

    private var foregroundColor: Color {
            return textColor ?? .white
        }
    
}

#Preview {
    MainBGContainer {
        VStack(spacing: 16) {
            OnboardingScreenButton(
                title: "Continuar con Apple",
                fill: .color(.black),
                icon: .system("apple.logo")
            ) {}
            
            OnboardingScreenButton(
                title: "Continuar con Google",
                fill: .color(.white),
                icon: .asset("googleLogo"),
                textColor: .black.opacity(0.6)
            ) 
            
            OnboardingScreenButton(
                title: "Continuar", 
                fill: .gradient(
                    LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                ),
                icon: .system("arrow.right")
            ) {}
        }
        .padding()
    }
}
