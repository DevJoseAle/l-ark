import Foundation
import Supabase

@MainActor
final class VaultViewModel: ObservableObject {
    @Published var items: [VaultFile] = []
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var uploadProgress: Double = 0
    
    // ✅ Flags específicos por operación
    @Published var isUploading = false
    @Published var isDeleting = false
    
    // Estado de campaña
    @Published var activeCampaign: Campaign?
    @Published var hasNoCampaign = false
    
    // Estado de suscripción
    @Published var currentPlan: String = "free"
    @Published var storageUsed: Int64 = 0
    @Published var storageQuota: Int64 = 500 * 1024 * 1024
    
    private let api: SupabaseVaultManager
    private let supabase: SupabaseClient
    
    init(api: SupabaseVaultManager, supabase: SupabaseClient) {
        self.api = api
        self.supabase = supabase
    }
    
    // MARK: - Lifecycle
    
    func onAppear() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadActiveCampaign()
        
        if activeCampaign != nil {
            await loadSubscriptionInfo()
            await refreshInternal()
        }
    }
    
    // MARK: - Campaign Management
    
    private func loadActiveCampaign() async {
        do {
            let user = try await supabase.auth.session.user
            
            let campaigns: [Campaign] = try await supabase
                .from("campaigns")
                .select()
                .eq("owner_user_id", value: user.id.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            if let campaign = campaigns.first {
                activeCampaign = campaign
                hasNoCampaign = false
            } else {
                hasNoCampaign = true
            }
        } catch {
            errorText = "Error al cargar campaña: \(error.localizedDescription)"
            hasNoCampaign = true
        }
    }
    
    // MARK: - Subscription Info
    
     func loadSubscriptionInfo() async {
        guard let campaign = activeCampaign else { return }
        
        do {
            let user = try await supabase.auth.session.user
            
            struct Subscription: Codable {
                let plan_type: String
                let storage_used_bytes: Int64
                let storage_quota_bytes: Int64
            }
            
            let subs: [Subscription] = try await supabase
                .from("vault_subscriptions")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .eq("campaign_id", value: campaign.id.uuidString)
                .execute()
                .value
            
            if let sub = subs.first {
                currentPlan = sub.plan_type
                storageUsed = sub.storage_used_bytes
                storageQuota = sub.storage_quota_bytes
            }
        } catch {
            // Silencioso, usar defaults
        }
    }
    
    // MARK: - File Operations
    
    // ✅ Versión pública con loading (para pull-to-refresh)
    func refresh() async {
        guard let campaign = activeCampaign else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await refreshInternal()
    }
    
    // ✅ Versión interna sin loading (para uso interno)
    private func refreshInternal() async {
        guard let campaign = activeCampaign else { return }
        
        do {
            let res = try await api.listFiles(campaignId: campaign.id)
            items = res.items
            await loadSubscriptionInfo()
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    func upload(url: URL) async {
        guard let campaign = activeCampaign else {
            errorText = "No hay campaña activa"
            return
        }
        
        // ✅ Flag específico para upload
        isUploading = true
        uploadProgress = 0
        defer {
            isUploading = false
            uploadProgress = 0
        }
        
        do {
            try await api.upload(campaignId: campaign.id, fileURL: url) { progress in
                Task { @MainActor in
                    self.uploadProgress = progress
                }
            }
            await refreshInternal() // ✅ Sin isLoading adicional
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    func delete(id: UUID) async {
        print("🗑️ DELETE: Iniciando eliminación de archivo ID: \(id)")
        
        // ✅ Flag específico para delete
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            try await api.deleteFile(fileId: id)
            print("✅ DELETE: Archivo eliminado exitosamente")
            items.removeAll { $0.id == id }
            await loadSubscriptionInfo()
        } catch {
            print("❌ DELETE: Error eliminando: \(error)")
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    func downloadURL(for id: UUID) async -> URL? {
        print("🔍 DESCARGA: Solicitando URL para archivo ID: \(id)")
        do {
            let url = try await api.downloadURL(for: id)
            print("✅ DESCARGA: URL obtenida exitosamente: \(url)")
            return url
        } catch {
            print("❌ DESCARGA: Error obteniendo URL: \(error)")
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Helpers
    
    var storagePercentage: Double {
        guard storageQuota > 0 else { return 0 }
        return Double(storageUsed) / Double(storageQuota)
    }
    
    var storageUsedFormatted: String {
        ByteCountFormatter.string(fromByteCount: storageUsed, countStyle: .file)
    }
    
    var storageQuotaFormatted: String {
        ByteCountFormatter.string(fromByteCount: storageQuota, countStyle: .file)
    }
    
    var isFreePlan: Bool {
        currentPlan.lowercased() == "free"
    }
    
    // ✅ Helper para saber si hay alguna operación en curso
    var isPerformingOperation: Bool {
        isLoading || isUploading || isDeleting
    }
}
