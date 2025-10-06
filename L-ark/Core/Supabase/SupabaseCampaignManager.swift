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
    case uploadFailed(String)
    case beneficiaryAlreadyInCampaign(String, String) // (beneficiaryName, campaignTitle)
    case multipleBeneficiariesInUse([String]) // [beneficiaryNames]

    var userMessage: String {
        switch self {
        case .failed:
            return "Error al Consultar Campañas"
        case .imgFailed:
            return "Error al Consultar Imagenes"
        case .uploadFailed(let detail):
            return "Error al subir archivo: \(detail)"
        case .beneficiaryAlreadyInCampaign(let name, let campaign):
            return "\(name) ya es beneficiario de la campaña '\(campaign)'"
        case .multipleBeneficiariesInUse(let names):
            return "Los siguientes beneficiarios ya están en otras campañas: \(names.joined(separator: ", "))"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .failed:
            return true
        case .imgFailed, .uploadFailed, .beneficiaryAlreadyInCampaign, .multipleBeneficiariesInUse:
            return false
        }
    }
}

struct BeneficiaryConflict {
    let beneficiaryName: String
    let beneficiaryId: UUID
    let campaignId: UUID
    let campaignTitle: String
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
            hasLoadedOwnCampaigns = true
            campaignLoadedAt = Date()
            currentError = nil
        } catch {
            let error = CampaignError.failed
            currentError = error
            throw error
        }
    }
    
    func getImagesFromCampaign(_ campaignId: String) async throws {
        if hasLoadedImages && isCacheValid(loadedAt: imagesLoadedAt) {
            return
        }
        
        guard !isLoadingImages else { return }
        isLoadingImages = true
        defer { isLoadingImages = false }
        
        do {
            print("gimages 1")
            let cImages: [CampaignImage] =
                try await supabase
                .from("campaign_images")
                .select()
                .eq("campaign_id", value: campaignId)
                .order("display_order", ascending: true)
                .execute()
                .value
            
            print("Post images: ", cImages)
            images = cImages
            hasLoadedImages = true
            imagesLoadedAt = Date()
            imageError = nil
        } catch {
            print(error)
            images = []
            let error = CampaignError.imgFailed
            imageError = error
            throw error
        }
    }
    
    var firstOwnCampaign: Campaign? {
        ownCampaigns.first
    }
    
    func forceReload() {
        campaignLoadedAt = nil
        imagesLoadedAt = nil
        hasLoadedOwnCampaigns = false
        hasLoadedImages = false
    }
    
    func invalidateOwnCampaigns() {
        hasLoadedOwnCampaigns = false
        campaignLoadedAt = nil
    }
    
    func invalidateImages() {
        hasLoadedImages = false
        imagesLoadedAt = nil
    }
    
    func searchUsersByEmail(_ email: String) async throws -> [SupabaseUser] {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !trimmedEmail.isEmpty else {
            return []
        }
        
        let response: [SupabaseUser] = try await supabase
            .from("users")
            .select()
            .ilike("email", value: "%\(trimmedEmail)%")
            .limit(5)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Subida de Imágenes/Documentos
    
    func uploadCampaignImage(_ document: DocumentUpload, campaignId: UUID, index: Int) async throws -> String {
        let fileName = "\(campaignId.uuidString)_\(index)_\(UUID().uuidString)_\(document.fileName)"
        let filePath = "campaigns/\(campaignId.uuidString)/images/\(fileName)"
        
        do {
            try await supabase.storage
                .from("campaign-media")
                .upload(
                    path: filePath,
                    file: document.data,
                    options: FileOptions(
                        contentType: document.mimeType
                    )
                )
            
            let publicURL = try supabase.storage
                .from("campaign-media")
                .getPublicURL(path: filePath)
            
            return publicURL.absoluteString
        } catch {
            throw CampaignError.uploadFailed("No se pudo subir \(document.fileName)")
        }
    }
    
    func uploadBeneficiaryDocument(_ document: DocumentUpload, campaignId: UUID, beneficiaryUserId: UUID, index: Int) async throws -> String {
        let fileName = "\(beneficiaryUserId.uuidString)_\(index)_\(UUID().uuidString)_\(document.fileName)"
        let filePath = "beneficiaries/\(campaignId.uuidString)/\(beneficiaryUserId.uuidString)/\(fileName)"
        
        print("📤 Subiendo documento de beneficiario \(index):")
        print("  - Path: \(filePath)")
        
        do {
            try await supabase.storage
                .from("campaign-media")
                .upload(
                    path: filePath,
                    file: document.data,
                    options: FileOptions(
                        contentType: document.mimeType,
                        upsert: false
                    )
                )
            
            print("✅ Documento de beneficiario subido")
            
            let publicURL = try supabase.storage
                .from("campaign-media")
                .getPublicURL(path: filePath)
            
            return publicURL.absoluteString
        } catch {
            print("❌ Error subiendo documento beneficiario: \(error)")
            throw CampaignError.uploadFailed("Documento beneficiario: \(error.localizedDescription)")
        }
    }
    // ✅ CORRECCIÓN 3: Agregar función para obtener beneficiarios
    func getBeneficiariesForCampaign(campaignId: UUID) async throws -> [CampaignBeneficiary] {
        let beneficiaries: [CampaignBeneficiary] = try await supabase
            .from("campaign_beneficiaries")
            .select("""
                *,
                users!beneficiary_user_id (
                    id,
                    display_name,
                    email,
                    phone,
                    country,
                    kyc_status,
                    default_currency,
                    pin_set,
                    created_at,
                    updated_at
                )
            """)
            .eq("campaign_id", value: campaignId.uuidString)
            .eq("is_active", value: true)
            .order("priority", ascending: true)
            .execute()
            .value
        
        return beneficiaries
    }

    // ✅ CORRECCIÓN 4: Agregar función para actualizar campaña
    func updateCampaign(
        campaignId: UUID,
        title: String,
        description: String?,
        goalAmount: Double?,
        softCap: Double?,
        hardCap: Double?,
        currency: String,
        visibility: CampaignVisibility,
        startAt: Date?,
        endAt: Date?,
        beneficiaryRule: BeneficiaryRule?,
        hasDiagnosis: Bool
    ) async throws {
        struct CampaignUpdate: Codable {
            let title: String
            let description: String?
            let goalAmount: Double?
            let softCap: Double?
            let hardCap: Double?
            let currency: String
            let visibility: String
            let startAt: Date?
            let endAt: Date?
            let beneficiaryRule: String?
            let hasDiagnosis: Bool
            
            enum CodingKeys: String, CodingKey {
                case title
                case description
                case goalAmount = "goal_amount"
                case softCap = "soft_cap"
                case hardCap = "hard_cap"
                case currency
                case visibility
                case startAt = "start_at"
                case endAt = "end_at"
                case beneficiaryRule = "beneficiary_rule"
                case hasDiagnosis = "has_diagnosis"
            }
        }
        
        let update = CampaignUpdate(
            title: title,
            description: description,
            goalAmount: goalAmount,
            softCap: softCap,
            hardCap: hardCap,
            currency: currency,
            visibility: visibility.rawValue,
            startAt: startAt,
            endAt: endAt,
            beneficiaryRule: beneficiaryRule?.rawValue,
            hasDiagnosis: hasDiagnosis
        )
        
        let _: Campaign = try await supabase
            .from("campaigns")
            .update(update)
            .eq("id", value: campaignId.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        invalidateOwnCampaigns()
    }
    // MARK: - Validaciones
    
    func validateBeneficiaries(_ beneficiaries: [BeneficiaryDraft]) -> Bool {
        let percentBeneficiaries = beneficiaries.filter { $0.shareType == .percent }
        
        if percentBeneficiaries.isEmpty {
            return true
        }
        
        let totalPercent = percentBeneficiaries.reduce(0.0) { $0 + $1.shareValue }
        return abs(totalPercent - 100.0) < 0.01
    }
    
    func checkBeneficiaryAvailability(userId: UUID) async throws -> BeneficiaryConflict? {
        let beneficiaries: [CampaignBeneficiary] = try await supabase
            .from("campaign_beneficiaries")
            .select("""
                *,
                campaigns (
                    id,
                    title,
                    status
                )
            """)
            .eq("beneficiary_user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .execute()
            .value
        
        if let existingBeneficiary = beneficiaries.first,
           let campaign = existingBeneficiary.campaign {
            
            let user: SupabaseUser = try await supabase
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            return BeneficiaryConflict(
                beneficiaryName: user.displayName,
                beneficiaryId: userId,
                campaignId: campaign.id,
                campaignTitle: campaign.title
            )
        }
        
        return nil
    }
    
    func checkMultipleBeneficiariesAvailability(userIds: [UUID]) async throws -> [BeneficiaryConflict] {
        var conflicts: [BeneficiaryConflict] = []
        
        for userId in userIds {
            if let conflict = try await checkBeneficiaryAvailability(userId: userId) {
                conflicts.append(conflict)
            }
        }
        
        return conflicts
    }
    
    // MARK: - Crear Campaña
    
    func createCampaign(
        ownerUserId: UUID,
        title: String,
        description: String?,
        goalAmount: Double?,
        softCap: Double?,
        hardCap: Double?,
        currency: String,
        visibility: CampaignVisibility,
        startAt: Date?,
        hasDiagnosis: Bool,
        endAt: Date?,
        beneficiaryRule: BeneficiaryRule?,
        campaignImages: [DocumentUpload],
        diagnosisImages: [DocumentUpload], 
        beneficiaries: [BeneficiaryDraft]
    ) async throws -> Campaign {
        
        // Validar porcentajes/montos
        guard validateBeneficiaries(beneficiaries) else {
            throw CampaignError.failed
        }
        
        // Validar que ningún beneficiario esté en otra campaña
        let beneficiaryIds = beneficiaries.compactMap { $0.user?.id }
        let conflicts = try await checkMultipleBeneficiariesAvailability(userIds: beneficiaryIds)
        
        if !conflicts.isEmpty {
            if conflicts.count == 1 {
                let conflict = conflicts[0]
                throw CampaignError.beneficiaryAlreadyInCampaign(
                    conflict.beneficiaryName,
                    conflict.campaignTitle
                )
            } else {
                let names = conflicts.map { $0.beneficiaryName }
                throw CampaignError.multipleBeneficiariesInUse(names)
            }
        }
        
        // Crear la campaña en estado draft
        let campaignInsert = CampaignInsert(
            ownerUserId: ownerUserId,
            title: title,
            description: description,
            goalAmount: goalAmount,
            softCap: softCap,
            hardCap: hardCap,
            currency: currency,
            status: CampaignStatus.draft.rawValue,
            visibility: visibility.rawValue,
            startAt: startAt,
            hasDiagnosis: hasDiagnosis,
            endAt: endAt,
            beneficiaryRule: beneficiaryRule?.rawValue
        )
        
        let createdCampaign: Campaign = try await supabase
            .from("campaigns")
            .insert(campaignInsert)
            .select()
            .single()
            .execute()
            .value
        
        // Subir imágenes de campaña si existen
        if !campaignImages.isEmpty {
            for (index, image) in campaignImages.enumerated() {
                let imageUrl = try await uploadCampaignImage(
                    image,
                    campaignId: createdCampaign.id,
                    index: index
                )
                
                let campaignImageInsert = CampaignImageInsert(
                    userId: ownerUserId,
                    campaignId: createdCampaign.id,
                    imageUrl: imageUrl,
                    displayOrder: index,
                    isPrimary: index == 0
                )
                
                let _: CampaignImage = try await supabase
                    .from("campaign_images")
                    .insert(campaignImageInsert)
                    .select()
                    .single()
                    .execute()
                    .value
            }
        }
        // Subir imágenes de diagnóstico si existen
        if hasDiagnosis && !diagnosisImages.isEmpty {
            for (index, image) in diagnosisImages.enumerated() {
                _ = try await uploadDiagnosisImage(
                    image,
                    campaignId: createdCampaign.id,
                    index: index
                )
            }
        }
        // Crear beneficiarios
        for (index, beneficiary) in beneficiaries.enumerated() {
            guard let user = beneficiary.user else { continue }
            
            let beneficiaryInsert = CampaignBeneficiaryInsert(
                campaignId: createdCampaign.id,
                beneficiaryUserId: user.id,
                shareType: beneficiary.shareType.rawValue,
                shareValue: beneficiary.shareValue,
                priority: beneficiary.priority ?? index + 1,
                isActive: true
            )
            
            let _: CampaignBeneficiary = try await supabase
                .from("campaign_beneficiaries")
                .insert(beneficiaryInsert)
                .select()
                .single()
                .execute()
                .value
            
            // Subir documentos de relación del beneficiario
            if !beneficiary.relationshipDocs.isEmpty {
                for (docIndex, doc) in beneficiary.relationshipDocs.enumerated() {
                    _ = try await uploadBeneficiaryDocument(
                        doc,
                        campaignId: createdCampaign.id,
                        beneficiaryUserId: user.id,
                        index: docIndex
                    )
                }
            }
        }
        
        invalidateOwnCampaigns()
        
        return createdCampaign
    }
    
    func uploadDiagnosisImage(_ document: DocumentUpload, campaignId: UUID, index: Int) async throws -> String {
        let fileName = "\(campaignId.uuidString)_diagnosis_\(index)_\(UUID().uuidString)_\(document.fileName)"
        let filePath = "campaigns/\(campaignId.uuidString)/diagnosis/\(fileName)"
        
        print("📤 Subiendo diagnóstico \(index):")
        print("  - Bucket: campaign-diagnosis")
        print("  - Path: \(filePath)")
        print("  - Size: \(document.data.count) bytes")
        print("  - MIME: \(document.mimeType)")
        
        do {
            try await supabase.storage
                .from("campaign-diagnosis")
                .upload(
                    filePath,
                    data: document.data,
                    options: FileOptions(
                        contentType: document.mimeType,
                        upsert: false
                    )
                )
            
            print("✅ Diagnóstico subido exitosamente")
            
            let publicURL = try supabase.storage
                .from("campaign-diagnosis")
                .getPublicURL(path: filePath)
            
            print("✅ URL pública generada: \(publicURL.absoluteString)")
            
            return publicURL.absoluteString
        } catch {
            print("❌ Error detallado subiendo diagnóstico:")
            print("  - Error: \(error)")
            print("  - Descripción: \(error.localizedDescription)")
            throw CampaignError.uploadFailed("Diagnóstico \(document.fileName): \(error.localizedDescription)")
        }
    }
}

