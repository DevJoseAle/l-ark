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

    var userMessage: String {
        switch self {
        case .failed: return "Error al Consultar Campañas"

        }
    }

    var isRetryable: Bool {
        switch self {
        case .failed: return true

        }

    }
}

@MainActor
final class SupabaseCampaignManager: ObservableObject {
    static let shared = SupabaseCampaignManager()
    @Published var campaigns: [Campaign] = []
    @Published var ownCampaign: Campaign?
    @Published var currentError: CampaignError?

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

        } catch {
            let error = CampaignError.failed
            currentError = error
            throw error
        }
    }

}
