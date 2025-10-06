import Foundation
import Supabase

// MARK: - Configuración del Cliente Supabase
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "TU_SUPABASE_URL")!
        let supabaseKey = "TU_SUPABASE_ANON_KEY"
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}

// MARK: - Enums basados en tu esquema

enum CampaignStatus: String, CaseIterable, Codable {
    case draft = "draft"
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum CampaignVisibility: String, CaseIterable, Codable {
    case publicCampaign = "public"
    case unlisted = "unlisted"
    case privateCampaign = "private"
}

enum BeneficiaryRule: String, CaseIterable, Codable {
    case fixedShares = "fixed_shares"
    case priority = "priority"
    case singleBeneficiary = "single_beneficiary"
}

enum BeneficiaryShareType: String, CaseIterable, Codable {
    case percent = "percent"
    case fixedAmount = "fixed_amount"
}

enum DonationStatus: String, CaseIterable, Codable {
    case initiated = "initiated"
    case authorized = "authorized"
    case paid = "paid"
    case refunded = "refunded"
    case chargeback = "chargeback"
    case failed = "failed"
    case cancelled = "cancelled"
}

enum PaymentProvider: String, CaseIterable, Codable {
    case mercadoPago = "mercado_pago"
    case stripe = "stripe"
    case manual = "manual"
}

enum KYCStatusSupabase: String, CaseIterable, Codable {
    case kycPending = "kyc_pending"
    case kycReview = "kyc_review"
    case kycVerified = "kyc_verified"
    case kycRejected = "kyc_rejected"
}

enum KYCDocType: String, CaseIterable, Codable {
    case selfie = "selfie"
    case dniFront = "dni_front"
    case dniBack = "dni_back"
    case proofOfResidence = "proof_of_residence"
}

enum KYCDocStatus: String, CaseIterable, Codable {
    case uploaded = "uploaded"
    case inReview = "in_review"
    case approved = "approved"
    case rejected = "rejected"
}

enum VaultVisibility: String, CaseIterable, Codable {
    case privateCampaign = "private"
    case beneficiaries = "beneficiaries"
    case publicCampaign = "public"
}

enum VaultEncryption: String, CaseIterable, Codable {
    case none = "none"
    case serverSide = "server_side"
    case clientSide = "client_side"
}

 //MARK: - Modelos principales

struct SupabaseUser: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let email: String
    let phone: String?
    let country: String?
    var kycStatus: KYCStatusSupabase
    let defaultCurrency: String
    var pinSet: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Relaciones opcionales (no incluidas en Codable por defecto)
    var campaigns: [Campaign]?
    var devices: [UserDevice]?
    var kycDocuments: [KYCDocument]?
    var donations: [Donation]?
    var beneficiaries: [CampaignBeneficiary]?
    var vaultItems: [VaultItem]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case phone
        case country
        case kycStatus = "kyc_status"
        case defaultCurrency = "default_currency"
        case pinSet = "pin_set"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

}

struct Campaign: Codable, Identifiable {
    let id: UUID
    let ownerUserId: UUID
    let title: String
    let description: String?
    let goalAmount: Double?
    let softCap: Double?
    let hardCap: Double?
    let currency: String
    let status: CampaignStatus
    let visibility: CampaignVisibility
    let startAt: Date?
    let endAt: Date?
    let totalRaised: Double
    let beneficiaryRule: BeneficiaryRule?
    var hasDiagnosis: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Relaciones opcionales
    var owner: User?
    var beneficiaries: [CampaignBeneficiary]?
    var donations: [Donation]?
    var vaultItems: [VaultItem]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserId = "owner_user_id"
        case title
        case description
        case goalAmount = "goal_amount"
        case softCap = "soft_cap"
        case hardCap = "hard_cap"
        case currency
        case status
        case visibility
        case startAt = "start_at"
        case endAt = "end_at"
        case totalRaised = "total_raised"
        case beneficiaryRule = "beneficiary_rule"
        case hasDiagnosis = "has_diagnosis"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
extension Campaign {
    static var mock: Campaign {
        Campaign(
            id: UUID(),
            ownerUserId: UUID(),
            title: "Ayuda para María",
            description: "Campaña para ayudar con gastos médicos",
            goalAmount: 500000,
            softCap: nil,
            hardCap: nil,
            currency: "CLP",
            status: .cancelled,
            visibility: .publicCampaign,
            startAt: Date(),
            endAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            totalRaised: 150000,
            beneficiaryRule: .singleBeneficiary,
            hasDiagnosis: true,
            createdAt: Date(),
            updatedAt: Date(),
            owner: nil,
            beneficiaries: nil,
            donations: nil,
            vaultItems: nil
        )
    }
}
struct CampaignBeneficiary: Codable, Identifiable {
    let id: UUID
    let campaignId: UUID
    let beneficiaryUserId: UUID
    let shareType: BeneficiaryShareType
    let shareValue: Double
    let priority: Int?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let user: SupabaseUser? 
    
    // Relaciones opcionales
    var campaign: Campaign?
    var beneficiaryUser: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case campaignId = "campaign_id"
        case beneficiaryUserId = "beneficiary_user_id"
        case shareType = "share_type"
        case shareValue = "share_value"
        case priority
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user = "users"
    }
}

struct Donation: Codable, Identifiable {
    let id: UUID
    let campaignId: UUID
    let donorUserId: UUID?
    var amount: Double
    let currency: String
    let exchangeRate: Double?
    let amountInCampaignCurrency: Double
    let status: DonationStatus
    let provider: PaymentProvider
    let providerPaymentId: String?
    let providerChargeId: String?
    let providerFee: Double?
    let netAmount: Double?
    let receiptUrl: String?
    let message: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Relaciones opcionales
    var campaign: Campaign?
    var donor: User?
    var paymentEvents: [PaymentEvent]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case campaignId = "campaign_id"
        case donorUserId = "donor_user_id"
        case amount
        case currency
        case exchangeRate = "exchange_rate"
        case amountInCampaignCurrency = "amount_in_campaign_ccy"
        case status
        case provider
        case providerPaymentId = "provider_payment_id"
        case providerChargeId = "provider_charge_id"
        case providerFee = "provider_fee"
        case netAmount = "net_amount"
        case receiptUrl = "receipt_url"
        case message
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Para manejar JSON dinámico de manera Codable
struct PaymentEventPayload: Codable {
    let data: [String: AnyCodable]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dict = try container.decode([String: AnyCodable].self)
        self.data = dict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

// Wrapper para Any que sea Codable
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
    }
}

struct PaymentEvent: Codable, Identifiable {
    let id: UUID
    let donationId: UUID
    let provider: PaymentProvider
    let eventType: String
    let rawPayload: PaymentEventPayload
    let signatureValid: Bool
    let createdAt: Date
    
    // Relación opcional
    var donation: Donation?
    
    enum CodingKeys: String, CodingKey {
        case id
        case donationId = "donation_id"
        case provider
        case eventType = "event_type"
        case rawPayload = "raw_payload"
        case signatureValid = "signature_valid"
        case createdAt = "created_at"
    }
}

struct KYCDocument: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let docType: KYCDocType
    let storagePath: String
    let status: KYCDocStatus
    let rejectionReason: String?
    let issuedAt: Date?
    let verifiedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Relación opcional
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case docType = "doc_type"
        case storagePath = "storage_path"
        case status
        case rejectionReason = "rejection_reason"
        case issuedAt = "issued_at"
        case verifiedAt = "verified_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserDevice: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let deviceId: String
    let platform: String
    let deviceModel: String?
    let osVersion: String?
    let appVersion: String?
    let pushToken: String?
    let isActive: Bool
    let lastSeenAt: Date
    let createdAt: Date
    let updatedAt: Date
    
    // Relación opcional
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case deviceId = "device_id"
        case platform
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case appVersion = "app_version"
        case pushToken = "push_token"
        case isActive = "is_active"
        case lastSeenAt = "last_seen_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct VaultItem: Codable, Identifiable {
    let id: UUID
    let ownerUserId: UUID
    let campaignId: UUID?
    let label: String
    let storagePath: String
    let visibility: VaultVisibility
    let encryption: VaultEncryption
    let createdAt: Date
    let updatedAt: Date
    
    // Relaciones opcionales
    var owner: User?
    var campaign: Campaign?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserId = "owner_user_id"
        case campaignId = "campaign_id"
        case label
        case storagePath = "storage_path"
        case visibility
        case encryption
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Todo: Codable, Identifiable {
    let id: Int
    let uuidId: UUID
    let title: String
    let isComplete: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuidId = "uuid_id"
        case title
        case isComplete = "is_complete"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CampaignImage: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let campaignId: UUID
    let imageUrl: String
    let displayOrder: Int
    let isPrimary: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case campaignId = "campaign_id"
        case imageUrl = "image_url"
        case displayOrder = "display_order"
        case isPrimary = "is_primary"
    }
}
// Modelo para beneficiario en creación
struct BeneficiaryDraft: Identifiable, Equatable {
    let id = UUID()
    var email: String
    var user: SupabaseUser?
    var shareType: BeneficiaryShareType = .percent
    var shareValue: Double = 0
    var priority: Int?
    var relationshipDocs: [DocumentUpload] = []
    
    static func == (lhs: BeneficiaryDraft, rhs: BeneficiaryDraft) -> Bool {
        lhs.id == rhs.id
    }
}

// Modelo para documentos a subir
struct DocumentUpload: Identifiable, Equatable {
    let id = UUID()
    let data: Data
    let fileName: String
    let mimeType: String
    var uploadURL: String?
    
    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }
    
    var isPDF: Bool {
        mimeType == "application/pdf"
    }
    
    static func == (lhs: DocumentUpload, rhs: DocumentUpload) -> Bool {
        lhs.id == rhs.id
    }
}

// Modelo para insertar campaña
struct CampaignInsert: Encodable {
    let ownerUserId: UUID
    let title: String
    let description: String?
    let goalAmount: Double?
    let softCap: Double?
    let hardCap: Double?
    let currency: String
    let status: String
    let visibility: String
    let startAt: Date?
    let hasDiagnosis: Bool?
    let endAt: Date?
    let beneficiaryRule: String?
    
    enum CodingKeys: String, CodingKey {
        case ownerUserId = "owner_user_id"
        case title
        case description
        case goalAmount = "goal_amount"
        case softCap = "soft_cap"
        case hardCap = "hard_cap"
        case currency
        case status
        case visibility
        case startAt = "start_at"
        case hasDiagnosis = "has_diagnosis" 
        case endAt = "end_at"
        case beneficiaryRule = "beneficiary_rule"
        
    }
}

// Modelo para insertar beneficiario
struct CampaignBeneficiaryInsert: Encodable {
    let campaignId: UUID
    let beneficiaryUserId: UUID
    let shareType: String
    let shareValue: Double
    let priority: Int?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case campaignId = "campaign_id"
        case beneficiaryUserId = "beneficiary_user_id"
        case shareType = "share_type"
        case shareValue = "share_value"
        case priority
        case isActive = "is_active"
    }
}

// Modelo para insertar imagen de campaña
struct CampaignImageInsert: Encodable {
    let userId: UUID
    let campaignId: UUID
    let imageUrl: String
    let displayOrder: Int
    let isPrimary: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case campaignId = "campaign_id"
        case imageUrl = "image_url"
        case displayOrder = "display_order"
        case isPrimary = "is_primary"
    }
}
