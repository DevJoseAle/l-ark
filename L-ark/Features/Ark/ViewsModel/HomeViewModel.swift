//
//  HomeViewModel.swift
//  L-ark
//
//  Created by Jose Rodriguez on 29-09-25.
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isLoadingInitialData = false
    @Published var loadingError: Error?
        private let campaignManager = SupabaseCampaignManager.shared
        private let donationManager = SupabaseDonationsManager.shared

    
    func loadInitialData(_ appState: AppState) async {

         guard let userId = SupabaseClientManager.shared.client.auth.currentUser?.id.uuidString else { return }
            isLoadingInitialData = true
        defer {
            isLoadingInitialData = false
        }
            
        // ✅ Prueba cada llamado por separado
           do {
               print("1️⃣ Cargando perfil de usuario...")
               try await appState.loadUserProfile(userId)
               print("✅ Perfil cargado")
           } catch {
               print("❌ Error en loadUserProfile:", error)
               loadingError = error
               return
           }
           
           do {
               print("2️⃣ Cargando campañas...")
               try await SupabaseCampaignManager.shared.getOwnCampaignAction(userId)
               print("✅ Campañas cargadas")
           } catch {
               print("❌ Error en getOwnCampaignAction:", error)
               loadingError = error
               return
           }
           
           if let campaignId = SupabaseCampaignManager.shared.firstOwnCampaign?.id.uuidString {
               do {
                   print("3️⃣ Cargando donaciones...")
                   try await SupabaseDonationsManager.shared.getDonationsFromCampaignId(campaignId)
                   print("✅ Donaciones cargadas")
               } catch {
                   print("❌ Error en getDonationsFromCampaignId:", error)
                   loadingError = error
                   return
               }
           }
           
           loadingError = nil
           print("✅ Todo cargado exitosamente")
        }
}
