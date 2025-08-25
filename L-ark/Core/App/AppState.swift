//
//  AppState.swift
//  L-ark
//
//  Created by Jose Rodriguez on 01-09-25.
//

import Foundation

@MainActor
class AppState: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var currentUser: Any? = nil
    @Published var kycStatus: KYCStatus? = .unknown
    @Published var isLoggedIn: AuthStatus = .loggedOut
    
    
    func setUser(_ user: Any) {
        self.currentUser = user
    }
}

struct User: Identifiable, Hashable { let id: String; let name: String }
enum KYCStatus { case unknown, pending, verified, rejected }
enum AuthStatus : Equatable { case loggedIn, loggedOut}
