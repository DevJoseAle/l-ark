//
//  ArkHomeViewModel.swift
//  L-ark
//
//  Created by Jose Rodriguez on 12-09-25.
//

import Foundation
enum ArkHomeViewModelError: DisplayableError {
    case generic(String)
    
    var isRetryable: Bool {
        return true
    }
    
    var userMessage: String {
        return "Error al iniciar. Intenta nuevamente"
    }
}
@MainActor
final class ArkHomeViewModel: ObservableObject {
    enum ViewState {
        case idle, loading, loaded
        case error(any DisplayableError)
    }
    @Published var state: ViewState = .idle
    private let campaignManager = SupabaseCampaignManager.shared
    private let donationManager = SupabaseDonationsManager.shared
    
    func loadInitialData(userId: String, campaignId: String) async {
        state = .loading
        
        do {
            async let campaignTask: () = try await campaignManager.getOwnCampaignAction(userId)
            async let donationTask: () = try await donationManager.getDonationsFromCampaignId(campaignId)
            
            try await campaignTask
            try await donationTask
            
            state = .loaded
        }catch let cError as CampaignError{
            state = .error(cError)
        } catch let dError as DonationError{
            state = .error(dError)
        } catch {
            state = .error(.generic("Error inesperado") as ArkHomeViewModelError)
        }
        
    }

}
