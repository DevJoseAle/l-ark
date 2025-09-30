//
//  SupabaseUserManager.swift
//  L-ark
//
//  Created by Jose Rodriguez on 29-09-25.
//

import Foundation
import Supabase


final class SupabaseUserManager: ObservableObject {
    
    @Published var user: [SupabaseUser] = []
    @Published var error: Error?
    @Published var isLoadingUser: Bool = false
    @Published var hasLoadedUser: Bool = false
    
    private var supabase: SupabaseClient
    
    init(supabase: SupabaseClient = SupabaseClientManager.shared.client) {
        self.supabase = supabase
    }
    
    func loadSupabaseUser(id: UUID) async throws {
        if hasLoadedUser { return }
        guard !isLoadingUser else { return }
        defer {
            isLoadingUser = false
            hasLoadedUser = true
        }
        
        do{
            let nUser : [SupabaseUser] = try await supabase
                .from("users")
                .select()
                .eq("id", value: id)
                .execute()
                .value

            user = nUser
            print("USER DE SUPABASE: ", user)
            error = nil
        }catch let e {
            error = e
        }
    }
    
    
}
