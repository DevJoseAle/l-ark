//
//  LoadingView.swift
//  L-ark
//
//  Created by Jose Rodriguez
//

import SwiftUI

// MARK: - LoadingView Principal
struct LoadingView: View {
    var message: String = "Cargando..."
    @State private var isPulsing = false
    
    var body: some View {
        MainBGContainer {
            VStack(spacing: 32) {
                ZStack {
                    // Ondas de fondo
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                Color.larkCyan.opacity(0.9),
                                lineWidth: 2
                            )
                            .scaleEffect(isPulsing ? 1.8 : 0.8)
                            .opacity(isPulsing ? 0 : 0.6)
                            .animation(
                                .easeOut(duration: 2.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.8),
                                value: isPulsing
                            )
                            .frame(width: 150, height: 150)
                    }
                    
                    // Logo principal
                    Image("LarkLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .scaleEffect(isPulsing ? 1.05 : 0.95)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }
                
                // Texto suave
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.invertedText)
                    .opacity(isPulsing ? 1 : 0.5)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Colores del logo Lark
extension Color {
    static let larkNavy = Color(red: 0.11, green: 0.23, blue: 0.36) // #1B3A5C
    static let larkCyan = Color(red: 0.36, green: 0.75, blue: 0.87) // #5BC0DE
    static let larkBlue = Color(red: 0.29, green: 0.56, blue: 0.89) // #4A90E2
    static let larkLight = Color(red: 0.87, green: 0.93, blue: 0.97) // #DEF0F7
}

// MARK: - Modifier para usar fácilmente en cualquier vista
extension View {
    func larkLoadingOverlay(isLoading: Bool, message: String = "Cargando...") -> some View {
        ZStack {
            self
            
            if isLoading {
                LoadingView(message: message)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LoadingView(message: "Cargando")
}
