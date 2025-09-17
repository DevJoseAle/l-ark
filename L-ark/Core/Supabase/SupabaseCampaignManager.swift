//
//  SupabaseCampaignManager.swift
//  L-ark
//
//  Created by Jose Rodriguez on 10-09-25.
//

import Foundation
import Supabase

enum CampaignError: DisplayableError {
    case failed
    case imgFailed
    

    var userMessage: String {
        switch self {
        case .failed: return "Error al Consultar Campañas"
        case .imgFailed: return "Error al Consultar Imagenes"

        }
    }

    var isRetryable: Bool {
        switch self {
        case .failed: return true
        case .imgFailed: return false

        }

    }
}

@MainActor
final class SupabaseCampaignManager: ObservableObject {
    static let shared = SupabaseCampaignManager()
    @Published var campaigns: [Campaign] = []
    @Published var ownCampaign: Campaign?
    @Published var currentError: CampaignError?
    @Published var imageError: CampaignError?
    @Published var images: [CampaignImage]?

    //MARK: properties
    private let supabase: SupabaseClient
    init(supabaseClient: SupabaseClient = SupabaseClientManager.shared.client) {
        self.supabase = supabaseClient
    }

    //MARK: methods

    func getOwnCampaignAction(_ ownerId: String) async throws {
        do {
            let campaigns: [Campaign] =
                try await supabase
                .from("campaigns")
                .select()
                .eq("owner_user_id", value: ownerId)
                .execute()
                .value

            // No error si está vacío, simplemente nil
            ownCampaign = campaigns.first
            currentError = nil
            print(ownCampaign)

        } catch {
            let error = CampaignError.failed
            currentError = error
            throw error
        }
    }
    
    func getImagesFromCampaign(_ campaignId: String) async throws {
           let id = "200e088f-1a65-45e0-afef-067afc5cb4c7"
           do {
               let cImages: [CampaignImage] =
                   try await supabase
                   .from("campaign_images")
                   .select()
                   .eq("campaign_id", value: id)
                   .order("display_order", ascending: true)
                   .execute()
                   .value

               images = cImages
           } catch {
               let error = CampaignError.imgFailed
               imageError = error
               throw error
           }

       }

}
