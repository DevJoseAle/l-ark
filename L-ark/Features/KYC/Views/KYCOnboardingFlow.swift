//
//  KYCOnboardingFlow.swift
//  L-ark
//
//  Created by Jose Rodriguez on 29-09-25.
//

import SwiftUI
import PhotosUI
struct KYCOnboardingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = KYCOnboardingViewModel()
    @EnvironmentObject private var appState: AppState
    var body: some View {
        NavigationStack {
            switch viewModel.currentStep {
            case .welcome:
                KYCWelcomeView(onContinue: { viewModel.nextStep() }, onGoBack: {dismiss()})
                
            case .dniFront:
                KYCPhotoStepView(step: .dniFront, viewModel: viewModel)
                
            case .dniBack:
                KYCPhotoStepView(step: .dniBack, viewModel: viewModel)
                
            case .selfie:
                KYCPhotoStepView(step: .selfie, viewModel: viewModel)
                
            case .uploading:
                KYCUploadingView()
                    .environmentObject(viewModel)
                
            case .success:
                KYCUploadStatusView {
                    appState.currentUser?.kycStatus = .kycReview
                    dismiss() // Cierra el modal y vuelve al home
                }
            }
        }
    }
}
#Preview {
    KYCOnboardingFlow()
}
