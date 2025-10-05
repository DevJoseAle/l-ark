import Foundation
import Supabase
import UniformTypeIdentifiers

// MARK: - Models

enum VaultError: LocalizedError {
    case unauthorized, badRequest, forbidden, notFound
    case mimeNotAllowed, quotaExceeded, failed
    case fileTooLarge(max: Int)
    case storageError(String), dbError(String), network(String), unknown(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "No autorizado."
        case .badRequest: return "Solicitud inválida."
        case .forbidden: return "No tienes acceso."
        case .failed: return "Fallo subida"
        case .notFound: return "No encontrado."
        case .mimeNotAllowed: return "Tipo de archivo no permitido."
        case .quotaExceeded: return "Se excede la cuota de almacenamiento."
        case .fileTooLarge(let max): return "Archivo excede el máximo permisible (\(ByteCountFormatter.string(fromByteCount: Int64(max), countStyle: .file)))."
        case .storageError(let m): return "Error de almacenamiento: \(m)"
        case .dbError(let m): return "Error de base de datos: \(m)"
        case .network(let m): return "Error de red: \(m)"
        case .unknown(let m): return "Error desconocido.\(m)"
        }
    }
}
extension SupabaseClient {
    /// Invoca una Edge Function y decodifica la respuesta a `T`.
    /// Usa `body` como `Encodable` (struct o diccionario).
    func invokeDecodable<T: Decodable, B: Encodable>(
        _ name: String,
        body: B,
        headers: [String: String] = [:]
    ) async throws -> T {
        do {
            return try await self.functions.invoke(
                name,
                options: FunctionInvokeOptions(
                    headers: headers,
                    body: body
                )
            )
        } catch FunctionsError.httpError(let code, let data) {
            let msg = String(data: data, encoding: .utf8) ?? "Sin mensaje"
            throw VaultError.failed
        } catch let e {
            throw VaultError.unknown(e.localizedDescription)
        }
    }
}
enum VaultFileType: String, Codable { case image, pdf, video, audio, document, other }

struct VaultFile: Codable, Identifiable, Hashable {
    let id: UUID
    let file_name: String
    let file_type: VaultFileType
    let mime_type: String
    let file_size_bytes: Int
    let created_at: String
}

struct VaultListResponse: Codable {
    let items: [VaultFile]
    let total: Int
    let page: Int
    let pageSize: Int
}

struct SignedUpload: Codable {
    let bucket: String
    let path: String
    let dir: String
    let objectName: String
    let uploadUrl: String
    let token: String
    let expiresIn: Int
}

extension ByteCountFormatter {
    static func fileString(_ bytes: Int) -> String {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB, .useGB]
        f.countStyle = .file
        return f.string(fromByteCount: Int64(bytes))
    }
}

import Foundation
import Supabase
import UniformTypeIdentifiers

// MARK: - Manager

final class SupabaseVaultManager {
    private let supabase: SupabaseClient
    init(supabase: SupabaseClient) { self.supabase = supabase }

    // MARK: - Helpers

    private func mapFunctionError(_ error: Error) -> VaultError {
        // 1. Intentar capturar FunctionsError directamente
        if let functionsError = error as? FunctionsError {
            switch functionsError {
            case .httpError(let code, let data):
                // Intentar decodificar la respuesta de error del backend
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    return mapBackendError(errorResponse)
                }
                
                // Si no se puede decodificar, devolver mensaje genérico con código
                let message = String(data: data, encoding: .utf8) ?? "Sin mensaje"
                return .unknown("HTTP \(code): \(message)")
                
            case .relayError:
                return .network("Error de conexión con el servidor")
                
            @unknown default:
                return .unknown("Error de función: \(functionsError.localizedDescription)")
            }
        }
        
        // 2. Intentar extraer data del NSError
        if let data = (error as NSError).userInfo["data"] as? Data,
           let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return mapBackendError(errorResponse)
        }
        
        // 3. Fallback a códigos HTTP estándar
        let nsError = error as NSError
        let statusCode = nsError.userInfo["statusCode"] as? Int ?? 0
        
        if statusCode == 401 { return .unauthorized }
        if statusCode == 403 { return .forbidden }
        if statusCode == 404 { return .notFound }
        
        // 4. Error completamente desconocido
        return .unknown("Error inesperado: \(error.localizedDescription)")
    }

    // ✅ Agregar esta función helper
    private func mapBackendError(_ errorResponse: ErrorResponse) -> VaultError {
        switch errorResponse.error {
        case "missing_bearer": return .unauthorized
        case "bad_request": return .badRequest
        case "campaign_not_found_or_forbidden", "campaign_forbidden": return .forbidden
        case "not_found", "object_not_found": return .notFound
        case "mime_not_allowed": return .mimeNotAllowed
        case "quota_exceeded": return .quotaExceeded
        case "file_too_large": return .fileTooLarge(max: errorResponse.max ?? (10*1024*1024))
        case "storage_delete_error", "storage_list_error":
            return .storageError(errorResponse.details ?? "Error de almacenamiento")
        case "db_insert_error", "db_delete_error":
            return .dbError(errorResponse.details ?? "Error de base de datos")
        default:
            return .unknown("Error del servidor: \(errorResponse.error ?? "desconocido")")
        }
    }
    
    private struct ErrorResponse: Codable {
        let error: String?
        let details: String?
        let max: Int?
    }

    private func mimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension),
           let mime = type.preferredMIMEType { return mime }
        return "application/octet-stream"
    }
    
    private func inferFileType(from mimeType: String) -> VaultFileType {
        if mimeType.hasPrefix("image/") { return .image }
        if mimeType == "application/pdf" { return .pdf }
        if mimeType.hasPrefix("video/") { return .video }
        if mimeType.hasPrefix("audio/") { return .audio }
        if mimeType.hasPrefix("application/") || mimeType == "text/plain" { return .document }
        return .other
    }

    // MARK: - Functions

    func getSignedUpload(campaignId: UUID, fileName: String, mimeType: String, expectedBytes: Int) async throws -> SignedUpload {
        struct Body: Codable {
            let campaignId: String
            let fileName: String
            let mimeType: String
            let expectedBytes: Int
        }
        let body = Body(
            campaignId: campaignId.uuidString,
            fileName: fileName,
            mimeType: mimeType,
            expectedBytes: expectedBytes
        )

        do {
            let response: SignedUpload = try await supabase.functions.invoke(
                "vault-upload-url",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
            return response
        } catch {
            throw mapFunctionError(error)
        }
    }

    func commitUpload(campaignId: UUID, path: String, fileName: String, mimeType: String) async throws {
        struct Body: Codable {
            let campaignId: String
            let path: String
            let fileName: String
            let mimeType: String
        }
        struct CommitResponse: Codable {
            let ok: Bool
            let fileId: UUID
            let created_at: String
        }
        
        let body = Body(
            campaignId: campaignId.uuidString,
            path: path,
            fileName: fileName,
            mimeType: mimeType
        )

        do {
            let _: CommitResponse = try await supabase.functions.invoke(
                "vault-commit-upload",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
            // No retornar nada, solo confirmar que fue exitoso
        } catch {
            throw mapFunctionError(error)
        }
    }

    func listFiles(campaignId: UUID, page: Int = 1, pageSize: Int = 20) async throws -> VaultListResponse {
        struct Body: Codable {
            let campaignId: String
            let page: Int
            let pageSize: Int
        }
        let body = Body(
            campaignId: campaignId.uuidString,
            page: page,
            pageSize: pageSize
        )

        do {
            let response: VaultListResponse = try await supabase.functions.invoke(
                "vault-list",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
            return response
        } catch {
            throw mapFunctionError(error)
        }
    }

    func deleteFile(fileId: UUID) async throws {
        struct Body: Codable {
            let fileId: String
        }
        struct DeleteResponse: Codable {
            let ok: Bool
        }
        
        let body = Body(fileId: fileId.uuidString)

        do {
            let _: DeleteResponse = try await supabase.functions.invoke(
                "vault-delete",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
        } catch {
            throw mapFunctionError(error)
        }
    }

    func downloadURL(for fileId: UUID, expiresIn: Int = 120) async throws -> URL {
        struct Body: Codable {
            let fileId: String
            let expiresIn: Int
        }
        struct UrlResponse: Codable {
            let url: String
        }
        
        let body = Body(fileId: fileId.uuidString, expiresIn: expiresIn)

        do {
            let response: UrlResponse = try await supabase.functions.invoke(
                "vault-download-url",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
            
            guard let url = URL(string: response.url) else {
                throw VaultError.unknown("Error en downloadURL: no se pudo crear el URL")
            }
            return url
        } catch {
            throw mapFunctionError(error)
        }
    }

    // MARK: - High level upload

    // MARK: - High level upload

    func upload(campaignId: UUID,
                fileURL: URL,
                progress: ((Double) -> Void)? = nil) async throws {

        let fileName = fileURL.lastPathComponent
        let mime = mimeType(for: fileURL)
        
        print("📤 Iniciando subida: \(fileName)")
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_" + fileName)
        
        guard fileURL.startAccessingSecurityScopedResource() else {
            print("❌ No se pudo acceder al archivo")
            throw VaultError.forbidden
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        do {
            try FileManager.default.copyItem(at: fileURL, to: tempURL)
            print("✅ Archivo copiado a temporal")
        } catch {
            print("❌ Error copiando: \(error.localizedDescription)")
            throw VaultError.network("No se pudo copiar el archivo: \(error.localizedDescription)")
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: tempURL)
            print("✅ Archivo leído: \(data.count) bytes")
        } catch {
            print("❌ Error leyendo: \(error.localizedDescription)")
            throw VaultError.network("No se pudo leer el archivo: \(error.localizedDescription)")
        }

        let signed: SignedUpload
        do {
            signed = try await getSignedUpload(
                campaignId: campaignId,
                fileName: fileName,
                mimeType: mime,
                expectedBytes: data.count
            )
            print("✅ URL firmada obtenida")
        } catch {
            print("❌ Error obteniendo URL: \(error)")
            throw error
        }

        var req = URLRequest(url: URL(string: signed.uploadUrl)!)
        req.httpMethod = "PUT"
        req.setValue(mime, forHTTPHeaderField: "Content-Type")
        req.setValue("true", forHTTPHeaderField: "x-upsert")

        do {
            if let progressCallback = progress {
                let delegate = UploadProgressDelegate(totalBytes: Int64(data.count), onProgress: progressCallback)
                let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
                _ = try await session.upload(for: req, from: data)
            } else {
                _ = try await URLSession.shared.upload(for: req, from: data)
            }
            print("✅ Archivo subido a storage")
        } catch {
            print("❌ Error subiendo a storage: \(error)")
            throw VaultError.network("Error subiendo: \(error.localizedDescription)")
        }

        do {
            try await commitUpload(
                campaignId: campaignId,
                path: signed.path,
                fileName: fileName,
                mimeType: mime
            )
            print("✅ Commit exitoso")
        } catch {
            print("❌ Error en commit: \(error)")
            throw error
        }
    }
    
    
    
}

private class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    let totalBytes: Int64
    let onProgress: (Double) -> Void
    
    init(totalBytes: Int64, onProgress: @escaping (Double) -> Void) {
        self.totalBytes = totalBytes
        self.onProgress = onProgress
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytes)
        DispatchQueue.main.async {
            self.onProgress(progress)
        }
    }
}
