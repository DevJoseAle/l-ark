//
//  AuthView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 01-09-25.
//

import SwiftUI

struct AuthView: View {
    @State private var goToLogin = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var authVM: AuthenticationViewModel
    
    var body: some View {
        NavigationStack {
            MainBGContainer {
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Image("LarkLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Text("L-Ark")
                            .font(.system(size: 52, weight: .regular, design: .rounded))
                            .italic(true)
                            .foregroundColor(.invertedText)
                        Text("Digital Heritage")
                            .font(.system(size: 22, weight: .light, design: .rounded))
                            .italic(true)
                            .foregroundColor(.invertedText)
                    }
                    
                    Spacer()
                    VStack {
                        
                        OnboardingScreenButton(
                            title: "Iniciar con Email y Contraseña",
                            fill: .color(.customWhite),
                            textColor: .black.opacity(0.6)
                        ){
                            goToLogin = true
                        }
                    }
                    
                        OnboardingScreenButton(
                            title: "Iniciar con Apple",
                            fill: .color(.black),
                            icon: .system("apple.logo")
                        ) {}
                        
                        OnboardingScreenButton(
                            title: "Iniciar con Google",
                            fill: .color(Color.linearBGBlue),
                            icon: .asset("googleLogo")
                        ) {
                            print(appState.isLoggedIn)
                        }
                    }
                    .padding(.bottom, 60)
                    .navigationDestination(isPresented: $goToLogin) {
                        LoginView()
                        
                    }
                }
            }
            
        }
}

#Preview {
    AuthView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationViewModel(appState: AppState()))
}
