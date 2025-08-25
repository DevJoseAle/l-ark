//
//  SupabaseDonationsManager.swift
//  L-ark
//
//  Created by Jose Rodriguez on 12-09-25.
//

import Foundation
import Supabase

enum DonationError: DisplayableError {
    case failed

    var userMessage: String {
        switch self {
        case .failed:
            return "Error al consultar las Donaciones"
        }
    }
    var isRetryable: Bool {
        switch self {
        case .failed:
            return true
        }
    }
}

@MainActor
final class SupabaseDonationsManager: ObservableObject {
    static let shared = SupabaseDonationsManager()
    //MARK: Properties
    @Published var donations: [Donation] = []
    @Published var currentError: DonationError?
    private let supabase: SupabaseClient
    //MARK: methods
    init(supabaseClient: SupabaseClient = SupabaseClientManager.shared.client) {
        self.supabase = supabaseClient
    }
    
    func getDonationsFromCampaignId(_ campaignId: String) async throws {
        do {
            let fetchedDonations: [Donation] = try await supabase.from("donations")
                .select()
                .eq("campaign_id", value: campaignId)
                .eq("status", value: "paid")
                .order("created_at", ascending: false)
                .execute()
                .value
            self.donations = fetchedDonations
        } catch {
            throw DonationError.failed
        }
    }
}
