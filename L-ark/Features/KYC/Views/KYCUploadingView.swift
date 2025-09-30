//
//  KYCUploadingView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 29-09-25.
//

import SwiftUI

struct KYCUploadingView: View {
    @EnvironmentObject var viewModel: KYCOnboardingViewModel
    
    var body: some View {
        MainBGContainer {
            VStack(spacing: 32) {
                Spacer()
                
                // Spinner
                ProgressView()
                    .scaleEffect(1.5)
                
                // Texto
                Text("Subiendo documentos...")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                // Barra de progreso
                ProgressView(value: viewModel.uploadProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                
                Text("\(Int(viewModel.uploadProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
#Preview {
    KYCUploadingView()
}
