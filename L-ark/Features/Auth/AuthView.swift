//
//  AuthView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 01-09-25.
//

import SwiftUI

struct AuthView: View {
    @State private var goToLogin = false
    @State private var goToProfile = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var authVM: AuthenticationViewModel
    
    var body: some View {
        NavigationStack {
            MainBGContainer {
                VStack {
                    Spacer()
                    VStack {
                        
                        OnboardingScreenButton(
                            title: "Iniciar con Email y Contraseña",
                            fill: .none,
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
    AuthView().environmentObject(AppState())
}
