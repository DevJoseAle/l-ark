import Foundation
import StoreKit
import Supabase

@MainActor
final class StoreManager: ObservableObject {
    
    enum PurchaseState {
        case idle
        case purchasing
        case success(Product)
        case failed(Error)
    }
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var purchaseState: PurchaseState = .idle
    private var supabase: SupabaseClient
    

    var currentCampaignId: UUID?
    private var updateListenerTask: Task<Void, Error>?
    
    init(supabase: SupabaseClient = SupabaseClientManager.shared.client) {
        self.supabase = supabase
        // Escuchar cambios en transacciones
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        print("🔍 Intentando cargar productos...")
        
        // Intentar hasta 3 veces con delay
        for attempt in 1...3 {
            do {
                let productIdentifiers = VaultProduct.allCases.map { $0.rawValue }
                print("🔍 Intento \(attempt) - Product IDs: \(productIdentifiers)")
                
                products = try await Product.products(for: productIdentifiers)
                print("✅ Productos cargados: \(products.count)")
                
                if products.isEmpty {
                    print("⚠️ Array vacío en intento \(attempt)")
                    
                    if attempt < 3 {
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
                        continue
                    }
                } else {
                    // Éxito
                    for product in products {
                        print("  - \(product.displayName): \(product.displayPrice)")
                    }
                    return
                }
            } catch {
                errorMessage = "Error cargando productos: \(error.localizedDescription)"
                print("❌ Error en intento \(attempt): \(error)")
                
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
        
        if products.isEmpty {
            errorMessage = "No se encontraron productos después de 3 intentos"
        }
    }
    // MARK: - Purchase



    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        
        // ✅ Necesitamos el campaignId, lo pasaremos como parámetro
        guard let campaignId = currentCampaignId else {
            purchaseState = .failed(StoreError.purchaseFailed)
            errorMessage = "No hay campaña activa"
            return
        }
        
        do {
            print("🛒 Iniciando compra: \(product.displayName)")
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                print("✅ Compra exitosa: \(transaction.productID)")
                
                // ✅ Sincronizar con backend
                do {
                    try await syncSubscriptionWithBackend(
                        transaction: transaction,
                        campaignId: campaignId
                    )
                } catch {
                    print("⚠️ Error sincronizando con backend: \(error)")
                    // No fallar la compra, solo logear
                }
                
                await updatePurchasedProducts()
                await transaction.finish()
                
                purchaseState = .success(product)
                
            case .userCancelled:
                print("❌ Usuario canceló la compra")
                purchaseState = .idle
                
            case .pending:
                print("⏳ Compra pendiente de aprobación")
                purchaseState = .idle
                
            @unknown default:
                print("⚠️ Resultado de compra desconocido")
                purchaseState = .idle
            }
            
        } catch {
            print("❌ Error en compra: \(error)")
            purchaseState = .failed(error)
            errorMessage = "Error en la compra: \(error.localizedDescription)"
        }
    }


    // MARK: - Check Subscription Status

    @Published private(set) var activeSubscription: Product?

    func updatePurchasedProducts() async {
        print("🔄 Actualizando estado de suscripciones...")
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Buscar el producto correspondiente
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscription = product
                    print("✅ Suscripción activa encontrada: \(product.displayName)")
                    return
                }
            } catch {
                print("❌ Error verificando transacción: \(error)")
            }
        }
        
        activeSubscription = nil
        print("ℹ️ No hay suscripción activa")
    }
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    await MainActor.run {
                        print("🔄 Nueva transacción detectada: \(transaction.productID)")
                    }
                    
                    // Finalizar la transacción
                    await transaction.finish()
                } catch {
                    print("❌ Error procesando transacción: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification Helper
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    // MARK: - Check and Sync Subscription
        
        func checkAndSyncSubscription() async {
            print("🔍 Verificando suscripciones con Apple...")
            
            guard let campaignId = currentCampaignId else {
                print("⚠️ No hay campaignId configurado")
                return
            }
            
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    
                    print("✅ Suscripción activa encontrada: \(transaction.productID)")
                    
                    // Sincronizar con backend
                    try await syncSubscriptionWithBackend(
                        transaction: transaction,
                        campaignId: campaignId
                    )
                    
                    // Actualizar estado local
                    await updatePurchasedProducts()
                    
                    return // Solo procesar la primera válida
                    
                } catch {
                    print("❌ Error verificando transacción: \(error)")
                }
            }
            
            print("ℹ️ No se encontraron suscripciones activas")
        }
    // MARK: - Sync with Backend

    func syncSubscriptionWithBackend(transaction: Transaction, campaignId: UUID) async throws {
        let supabase = SupabaseClientManager.shared.client
        
        struct Body: Codable {
            let campaignId: String
            let productId: String
            let transactionId: String
            let originalTransactionId: String
            let purchaseDate: String
            let expirationDate: String?
        }
        
        let body = Body(
            campaignId: campaignId.uuidString,
            productId: transaction.productID,
            transactionId: String(transaction.id),
            originalTransactionId: String(transaction.originalID),
            purchaseDate: ISO8601DateFormatter().string(from: transaction.purchaseDate),
            expirationDate: transaction.expirationDate.map { ISO8601DateFormatter().string(from: $0) }
        )
        
        struct Response: Codable {
            let ok: Bool
            let plan: String
            let quota: Int64
        }
        
        print("🔄 Sincronizando con backend...")
        
        let response: Response = try await supabase.functions.invoke(
            "vault-sync-subscription",
            options: FunctionInvokeOptions(body: body)
        )
        
        print("✅ Sincronización exitosa: \(response.plan) - \(response.quota) bytes")
    }
    func checkVerifiedPublic<T>(_ result: VerificationResult<T>) throws -> T {
        return try checkVerified(result)
    }
}

// MARK: - Error Types

enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "La verificación de la compra falló"
        case .productNotFound:
            return "Producto no encontrado"
        case .purchaseFailed:
            return "La compra no se pudo completar"
        case .restoreFailed:
            return "No se pudieron restaurar las compras"
        }
    }
}

extension StoreManager.PurchaseState: Equatable {
    static func == (lhs: StoreManager.PurchaseState,
                    rhs: StoreManager.PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.purchasing, .purchasing):
            return true

        case let (.success(a), .success(b)):
            // Product de StoreKit tiene id estable
            return a.id == b.id

        case let (.failed(e1), .failed(e2)):
            let n1 = e1 as NSError
            let n2 = e2 as NSError
            // Igualamos por dominio+code (opcional: comparar descripción)
            return n1.domain == n2.domain && n1.code == n2.code

        default:
            return false
        }
    }
}
