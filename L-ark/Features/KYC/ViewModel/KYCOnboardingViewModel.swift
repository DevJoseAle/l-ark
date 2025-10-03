//
//  KYCOnboardingViewModel.swift
//  L-ark
//
//  Created by Jose Rodriguez on 30-09-25.
//

import Foundation
import PhotosUI

enum KYCStep {
    case welcome      // ← Nueva pantalla de bienvenida
    case dniFront
    case dniBack
    case selfie
    case uploading
    case success
}
@MainActor
class KYCOnboardingViewModel: ObservableObject {
    @Published var currentStep: KYCStep = .welcome  // ← Comienza en welcome
    @Published var dniFrontImage: UIImage?
    @Published var dniBackImage: UIImage?
    @Published var selfieImage: UIImage?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var error: KYCError?
    private let kycManager = SupabaseKYCManager.shared

    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .dniFront
        case .dniFront:
            currentStep = .dniBack
        case .dniBack:
            currentStep = .selfie
        case .selfie:
            currentStep = .uploading
            Task { await submitDocuments() }
        case .uploading:
            currentStep = .success
        case .success:
            break
        }
    }
    
    func previousStep() {
        switch currentStep {
        case .welcome:
            break
        case .dniFront:
            currentStep = .welcome
        case .dniBack:
            currentStep = .dniFront
        case .selfie:
            currentStep = .dniBack
        default:
            break
        }
    }
    
    func submitDocuments() async {
        print("SubmitDocuments")
            guard let dniFront = dniFrontImage,
                  let dniBack = dniBackImage,
                  let selfie = selfieImage else {
                error = .invalidImage
                return
            }
            
            guard let userId = SupabaseClientManager.shared.client.auth.currentUser?.id.uuidString else {
                return
            }
            
            isUploading = true
            
            do {
                try await kycManager.submitKYCDocuments(
                    userId: userId,
                    dniFront: dniFront,
                    dniBack: dniBack,
                    selfie: selfie,
                    onProgress: { [weak self] progress in
                        self?.uploadProgress = progress
                    }
                )
                
                currentStep = .success
            } catch {
                print(error)
                print("SubmitDocuments4")
                self.error = error as? KYCError ?? .uploadFailed
                currentStep = .selfie // Volver al último paso
            }
            
            isUploading = false
        }
}
