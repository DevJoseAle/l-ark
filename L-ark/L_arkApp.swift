//
//  L_arkApp.swift
//  L-ark
//
//  Created by Jose Rodriguez on 25-08-25.
//

import SwiftData
import SwiftUI

@main
struct LarkApp: App {

    @StateObject private var appState: AppState
    @StateObject private var auth: AuthenticationViewModel

    init() {
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        _auth = StateObject(
            wrappedValue: AuthenticationViewModel(appState: appState)
        )
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(auth)
                .task {
                    await auth.bootstrapSession()  // ← Verificar sesión existente
                }
                .modelContainer(sharedModelContainer)

        }
    }
}
