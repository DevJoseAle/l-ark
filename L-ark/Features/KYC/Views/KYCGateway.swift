//
//  KYCGateway.swift
//  L-ark
//
//  Created by Jose Rodriguez on 29-09-25.
//

import SwiftUI

struct KYCGateway: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        Group {
            switch appState.currentUser?.kycStatus {
            case .kycPending, .kycRejected:
                KYCOnboardingFlow()
            case .kycReview, .kycVerified:
                if let userId = appState.currentUser?.id {
                    CreateCampaignView()
                } else {
                    Text("Error: Usuario no encontrado")
                }
             default:
                KYCOnboardingFlow()
            }
        }
    }
}

#Preview {
    KYCGateway()
        .environmentObject(AppState())
}
#Preview("Review") {
    KYCGateway()
        .environmentObject(AppState.mockPending)
}
