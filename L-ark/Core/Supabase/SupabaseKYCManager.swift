//import Foundation
import Supabase
import UIKit


enum KYCError: Error, DisplayableError {
    case uploadFailed
    case invalidImage
    case databaseError
    
    var userMessage: String {
        switch self {
        case .uploadFailed:
            return "Error al subir las imágenes. Intenta de nuevo."
        case .invalidImage:
            return "Una de las imágenes no es válida."
        case .databaseError:
            return "Error al guardar los documentos."
        }
    }
    
    var isRetryable: Bool {
        true
    }
}

@MainActor
final class SupabaseKYCManager {
    static let shared = SupabaseKYCManager()
    private let supabase = SupabaseClientManager.shared.client
    
    // Subir una imagen al Storage
    private func uploadImage(_ image: UIImage, userId: String, docType: KYCDocType) async throws -> String {
        // Convertir UIImage a Data (JPEG con compresión)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw KYCError.invalidImage
        }
        
        print("📤 Subiendo imagen para userId:", userId)
        print("📤 DocType:", docType.rawValue)
        
        let fileName = "\(userId)_\(docType.rawValue)_\(UUID().uuidString).jpg"
        let filePath = "\(userId)/\(fileName)"
        
        print("📤 Path completo:", filePath)
        
        // Subir al bucket de Storage
        try await supabase.storage
            .from("kyc_documents")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg"
                )
            )
        
        return filePath
    }
    
    // Crear registro en la tabla kyc_documents
    private func createDocumentRecord(userId: String, docType: KYCDocType, storagePath: String) async throws {
        struct KYCDocumentInsert: Encodable {
            let userId: String
            let docType: String
            let storagePath: String
            let status: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case docType = "doc_type"
                case storagePath = "storage_path"
                case status
            }
        }
        
        let document = KYCDocumentInsert(
            userId: userId,
            docType: docType.rawValue,
            storagePath: storagePath,
            status: "in_review"
        )
        
        try await supabase
            .from("kyc_documents")
            .insert(document)
            .execute()
    }
    
    // Actualizar el kyc_status del usuario
    private func updateUserKYCStatus(userId: String, status: KYCStatusSupabase) async throws {
        try await supabase
            .from("users")
            .update(["kyc_status": status.rawValue])
            .eq("id", value: userId)
            .execute()
    }
    
    // Función principal que sube todo
    func submitKYCDocuments(
        userId: String,
        dniFront: UIImage,
        dniBack: UIImage,
        selfie: UIImage,
        onProgress: @escaping (Double) -> Void
    ) async throws {
        var progress: Double = 0
        print("1️⃣ Subiendo DNI frontal...")
            let dniFrontPath = try await uploadImage(dniFront, userId: userId, docType: .dniFront)
            print("✅ DNI frontal subido:", dniFrontPath)
            progress = 0.33
            onProgress(progress)
            
            print("2️⃣ Subiendo DNI reverso...")
            let dniBackPath = try await uploadImage(dniBack, userId: userId, docType: .dniBack)
            print("✅ DNI reverso subido:", dniBackPath)
            progress = 0.66
            onProgress(progress)
            
            print("3️⃣ Subiendo selfie...")
            let selfiePath = try await uploadImage(selfie, userId: userId, docType: .selfie)
            print("✅ Selfie subido:", selfiePath)
            progress = 1.0
            onProgress(progress)
            
            print("4️⃣ Creando registros en kyc_documents...")
            try await createDocumentRecord(userId: userId, docType: .dniFront, storagePath: dniFrontPath)
            print("✅ Registro DNI frontal creado")
            
            try await createDocumentRecord(userId: userId, docType: .dniBack, storagePath: dniBackPath)
            print("✅ Registro DNI reverso creado")
            
            try await createDocumentRecord(userId: userId, docType: .selfie, storagePath: selfiePath)
            print("✅ Registro selfie creado")
        
        // 5. Actualizar estado del usuario
        print("5️⃣ Actualizando estado del usuario...")

        try await updateUserKYCStatus(userId: userId, status: .kycReview)
        print("✅ Todo completado")
    }
}
