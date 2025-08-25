//
//  ContentView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 25-08-25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthenticationViewModel
    @EnvironmentObject var appState: AppState


    var body: some View {
        Group {
            switch appState.isLoggedIn {
            case .loggedIn:
                HomeView()
                
            case .loggedOut:
                AuthView()
                
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
