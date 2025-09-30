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
    //**MARK: properties**
    static let shared = SupabaseCampaignManager()
    @Published var campaigns: [Campaign] = []
    @Published var ownCampaigns: [Campaign] = []
    @Published var currentError: CampaignError?
    @Published var imageError: CampaignError?
    @Published var images: [CampaignImage] = []
    
    
    private var campaignLoadedAt: Date?
    private var imagesLoadedAt: Date?
    private let cacheLifetime: TimeInterval = 10
    
    private var isLoadingCampaign = false
    private var isLoadingImages = false
    
    // Flags para saber si ya se cargaron datos
    private var hasLoadedOwnCampaigns = false
    private var hasLoadedImages = false
    
    private let supabase: SupabaseClient
    init(supabaseClient: SupabaseClient = SupabaseClientManager.shared.client) {
        self.supabase = supabaseClient
    }

    //**MARK: methods**
    
    private func isCacheValid(loadedAt: Date?) -> Bool {
        guard let loadedAt = loadedAt else { return false }
        return Date().timeIntervalSince(loadedAt) < cacheLifetime
    }

    func getOwnCampaignAction(_ ownerId: String) async throws {
        if hasLoadedOwnCampaigns && isCacheValid(loadedAt: campaignLoadedAt) {
            return
        }
        guard !isLoadingCampaign else { return }
        isLoadingCampaign = true
        defer { isLoadingCampaign = false }
        do {
            let campaigns: [Campaign] =
                try await supabase
                .from("campaigns")
                .select()
                .eq("owner_user_id", value: ownerId)
                .execute()
                .value
            
            ownCampaigns = campaigns
            hasLoadedOwnCampaigns = true // ✅
            campaignLoadedAt = Date()
            currentError = nil
        } catch {
            let error = CampaignError.failed
            currentError = error
            throw error
        }
    }
    
    func getImagesFromCampaign(_ campaignId: String) async throws {
        // ✅ Verifica si ya se cargaron Y el cache es válido
        if hasLoadedImages && isCacheValid(loadedAt: imagesLoadedAt) {
            return
        }
        
        guard !isLoadingImages else { return }
        isLoadingImages = true
        defer { isLoadingImages = false }
        
        do {
            let cImages: [CampaignImage] =
                try await supabase
                .from("campaign_images")
                .select()
                .eq("campaign_id", value: campaignId)
                .order("display_order", ascending: true)
                .execute()
                .value
            images = cImages
            hasLoadedImages = true // ✅ Marca que ya se cargaron
            imagesLoadedAt = Date()
            imageError = nil
        } catch {
            images = []
            let error = CampaignError.imgFailed
            imageError = error
            throw error
        }
    }
    
    // ✅ Propiedad helper para obtener la primera campaña
    var firstOwnCampaign: Campaign? {
        ownCampaigns.first
    }
    
    // ✅ Función para forzar recarga completa (útil para pull-to-refresh)
    func forceReload() {
        campaignLoadedAt = nil
        imagesLoadedAt = nil
        hasLoadedOwnCampaigns = false
        hasLoadedImages = false
    }
    
    // ✅ Función para limpiar solo las campañas (útil cuando se crea/elimina una campaña)
    func invalidateOwnCampaigns() {
        hasLoadedOwnCampaigns = false
        campaignLoadedAt = nil
    }
    
    // ✅ Función para limpiar solo las imágenes (útil cuando se actualiza una imagen)
    func invalidateImages() {
        hasLoadedImages = false
        imagesLoadedAt = nil
    }
}
