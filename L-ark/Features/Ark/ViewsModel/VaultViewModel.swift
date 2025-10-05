import Foundation
import Supabase

@MainActor
final class VaultViewModel: ObservableObject {
    @Published var items: [VaultFile] = []
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var uploadProgress: Double = 0
    
    // Estado de campaña
    @Published var activeCampaign: Campaign?
    @Published var hasNoCampaign = false
    
    // Estado de suscripción
    @Published var currentPlan: String = "free"
    @Published var storageUsed: Int64 = 0
    @Published var storageQuota: Int64 = 500 * 1024 * 1024 // 500MB default
    
    private let api: SupabaseVaultManager
    private let supabase: SupabaseClient
    
    init(api: SupabaseVaultManager, supabase: SupabaseClient) {
        self.api = api
        self.supabase = supabase
    }
    
    // MARK: - Lifecycle
    
    func onAppear() async {
        await loadActiveCampaign()
        if activeCampaign != nil {
            await loadSubscriptionInfo()
            await refresh()
        }
    }
    
    // MARK: - Campaign Management
    
    private func loadActiveCampaign() async {
        isLoading = true
        defer { isLoading = false }
        
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
    
    private func loadSubscriptionInfo() async {
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
    
    func refresh() async {
        guard let campaign = activeCampaign else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let res = try await api.listFiles(campaignId: campaign.id)
            items = res.items
            await loadSubscriptionInfo() // Actualizar storage usado
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    func upload(url: URL) async {
        guard let campaign = activeCampaign else {
            errorText = "No hay campaña activa"
            return
        }
        
        isLoading = true
        uploadProgress = 0
        defer {
            isLoading = false
            uploadProgress = 0
        }
        
        do {
            try await api.upload(campaignId: campaign.id, fileURL: url) { progress in
                Task { @MainActor in
                    self.uploadProgress = progress
                }
            }
            // ✅ Siempre refrescar después de subir para obtener los IDs correctos
            await refresh()
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    func delete(id: UUID) async {
        do {
            try await api.deleteFile(fileId: id)
            items.removeAll { $0.id == id }
            await loadSubscriptionInfo() // Actualizar storage usado
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    func downloadURL(for id: UUID) async -> URL? {
        do {
            return try await api.downloadURL(for: id)
        } catch {
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
}

