//
//  AppState.swift
//  L-ark
//
//  Created by Jose Rodriguez on 01-09-25.
//

import Foundation
import Supabase

@MainActor
class AppState: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var currentUser: SupabaseUser? = nil
    @Published var authUser: Any? = nil
    @Published var isLoggedIn: AuthStatus = .loggedOut
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    
    private var supabase: SupabaseClient
    
    init(supabase: SupabaseClient = SupabaseClientManager.shared.client){
        self.supabase = supabase
    }
    func setUser(_ user: Any) {
        self.authUser = user
    }

    
    func loadUserProfile(_ userID: String) async throws {
        isLoading = true
        defer { isLoading = false}
        
        do {
            let user: SupabaseUser = try await supabase
                .from("users")
                .select()
                .eq("id", value: userID)
                .single()
                .execute()
                .value
            currentUser  = user
        } catch let e {
            print("En el LoadUserProfile: ",e)
            self.error = e
            throw e
        }
        
        
    }
    
    func updateKycStatus(_ newStatus: KYCStatusSupabase) async throws {
            guard var user = currentUser else { return }
            
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await supabase
                    .from("users")
                    .update(["kyc_status": newStatus.rawValue])
                    .eq("id", value: user.id.uuidString)
                    .execute()
                
                // Actualizar localmente
                user.kycStatus = newStatus
                currentUser = user
            } catch {
                self.error = error
                throw error
            }
        }
    
}

struct User: Identifiable, Hashable { let id: String; let name: String }

enum AuthStatus : Equatable { case loggedIn, loggedOut, loading}
