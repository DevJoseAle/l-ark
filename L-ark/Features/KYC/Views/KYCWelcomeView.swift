import SwiftUI
struct KYCWelcomeView: View {
    @Environment(\.dismiss) private var dismiss 
    let onContinue: () -> Void
    let onGoBack: () -> Void
    
    var body: some View {
        MainBGContainer {
            VStack(spacing: 24) {
                Spacer()
                
                // Ícono principal
                Image(systemName: "checkmark.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue)
                
                // Título
                Text("Verificación de identidad")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Descripción
                Text("Para crear campañas necesitamos verificar tu identidad")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Lista de documentos
                VStack(alignment: .leading, spacing: 16) {
                    DocumentRequirementRow(
                        icon: "creditcard",
                        title: "Cédula de identidad - Frontal",
                        description: "Foto clara del frente de tu cédula"
                    )
                    
                    DocumentRequirementRow(
                        icon: "creditcard.fill",
                        title: "Cédula de identidad - Reverso",
                        description: "Foto clara del reverso de tu cédula"
                    )
                    
                    DocumentRequirementRow(
                        icon: "person.crop.circle",
                        title: "Selfie",
                        description: "Una foto tuya para verificar tu identidad"
                    )
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Botones
                VStack(spacing: 12) {
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
                    
                    Button {
                        onGoBack()
                    } label: {
                        Text("Regresar")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
}

// Componente reutilizable para cada requisito
struct DocumentRequirementRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
#Preview {
    KYCWelcomeView(onContinue:{print("Continuar")}, onGoBack: {print("back")})
}
