//
//  KYCUploadStatusView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 29-09-25.
//

import SwiftUI

struct KYCUploadStatusView: View {
    @Environment(\.dismiss) private var dismiss
    let onContinue: () -> Void
    
    var body: some View {
        MainBGContainer {
            VStack(spacing: 32) {
                Spacer()
                
                // Ícono de éxito
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.green)
                
                // Título
                Text("¡Documentos enviados!")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Descripción
                VStack(spacing: 12) {
                    Text("Tus documentos están en revisión")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Te notificaremos cuando sean verificados. Mientras tanto, puedes crear tu campaña.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Botón
                Button {
                    onContinue()
                } label: {
                    Text("Continuar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
#Preview {
    KYCUploadStatusView(){
        print("Forzar")
    }
}
