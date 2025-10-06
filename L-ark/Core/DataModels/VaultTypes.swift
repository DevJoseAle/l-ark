//import Foundation
//
//enum VaultError: LocalizedError {
//    case unauthorized, badRequest, forbidden, notFound
//    case mimeNotAllowed, quotaExceeded
//    case fileTooLarge(max: Int)
//    case storageError(String), dbError(String), network(String), unknown
//    var errorDescription: String? {
//        switch self {
//        case .unauthorized: return "No autorizado."
//        case .badRequest: return "Solicitud inválida."
//        case .forbidden: return "No tienes acceso."
//        case .notFound: return "No encontrado."
//        case .mimeNotAllowed: return "Tipo de archivo no permitido."
//        case .quotaExceeded: return "Se excede la cuota de almacenamiento."
//        case .fileTooLarge(let max): return "Archivo excede el máximo permisible (\(ByteCountFormatter.string(fromByteCount: Int64(max), countStyle: .file)))."
//        case .storageError(let m): return "Error de almacenamiento: \(m)"
//        case .dbError(let m): return "Error de base de datos: \(m)"
//        case .network(let m): return "Error de red: \(m)"
//        case .unknown: return "Error desconocido."
//        }
//    }
//}
//
//enum VaultFileType: String, Codable { case image, pdf, video, audio, document, other }
//
//struct VaultFile: Codable, Identifiable, Hashable {
//    let id: UUID
//    let file_name: String
//    let file_type: VaultFileType
//    let mime_type: String
//    let file_size_bytes: Int
//    let created_at: String
//}
//
//struct VaultListResponse: Codable {
//    let items: [VaultFile]
//    let total: Int
//    let page: Int
//    let pageSize: Int
//}
//
//struct SignedUpload: Codable {
//    let bucket: String
//    let path: String
//    let dir: String
//    let objectName: String
//    let uploadUrl: String
//    let token: String
//    let expiresIn: Int
//}
//
//extension ByteCountFormatter {
//    static func fileString(_ bytes: Int) -> String {
//        let f = ByteCountFormatter()
//        f.allowedUnits = [.useKB, .useMB, .useGB]
//        f.countStyle = .file
//        return f.string(fromByteCount: Int64(bytes))
//    }
//}
