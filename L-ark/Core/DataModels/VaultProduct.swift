import Foundation
import StoreKit

enum VaultProduct: String, CaseIterable {
    case proMonthly = "cl.lark.vault.pro.monthly"
    case proYearly = "cl.lark.vault.pro.yearly"
    
    var displayName: String {
        switch self {
        case .proMonthly: return "Pro Mensual"
        case .proYearly: return "Pro Anual"
        }
    }
    
    var description: String {
        switch self {
        case .proMonthly: return "5 GB de almacenamiento, renovación mensual"
        case .proYearly: return "5 GB de almacenamiento, renovación anual (10% descuento)"
        }
    }
    
    var storageGB: Int {
        return 5
    }
    
    var storageBytes: Int64 {
        return Int64(storageGB) * 1024 * 1024 * 1024
    }
}
