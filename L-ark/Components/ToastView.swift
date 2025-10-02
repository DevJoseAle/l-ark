// ToastView.swift
import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let icon: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text(message)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill") -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, message: message, icon: icon))
    }
}

