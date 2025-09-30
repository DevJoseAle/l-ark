//
//  MyCampaignView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 15-09-25.
//

import SwiftUI

struct MyCampaignView: View {
    @EnvironmentObject private var campaign: SupabaseCampaignManager
    @StateObject private var vm = MyCampaignViewModel()
    private var supabase = SupabaseClientManager.shared.client
    var body: some View {
        MainBGContainer {
            VStack(alignment: .leading) {
                content
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle(Text(campaign.firstOwnCampaign?.title ?? "Sin Título"))
            .toolbar {
                ToolbarEditButton(text: "Editar", icon: "pencil") {
                }
            }
            .task(id: "load-images") {
                await vm.loadImages()
                
            }
        }

    }
    @ViewBuilder
    private var content: some View {
        switch vm.viewState {
        case .loading, .idle:
            LoadingView()
        case .loaded:
            ScrollView {
                VStack {
                    CampaignImageSlider(images: campaign.images)
                        .frame(height: 320)
                    Divider()
                    //MARK: Descripcion de Camapaña
                    if let ownCampaign = campaign.firstOwnCampaign {
                                   MyCampaignProgress(campaign: ownCampaign)
                                   
                                   VStack(alignment: .leading) {
                                       Text("Descripcion:")
                                           .padding(.horizontal)
                                           .padding(.bottom, 8)
                                           .font(.title2)
                                           .fontWeight(.bold)

                                       Text(ownCampaign.description ?? "Sin Descripción")
                                   }
                                   .padding()
                               } else {
                                   Text("No se pudo cargar la información de la campaña")
                                       .foregroundStyle(.secondary)
                                       .padding()
                               }
                    Divider()
                    VStack(alignment: .leading){
                        Text("Beneficiario/s:")
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                            .font(.title2)
                            .fontWeight(.bold)
                        BeneficiaryCard()
                        BeneficiaryCard()

                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 10)
                    .padding(.bottom, 75)
                    
                }
            }
            .scrollIndicators(.never)
        case .imgError(let displayableError):
            ErrorViewCampaign(error: displayableError) {
                Task {}
            }
        }
    }
}

//MARK: Error View
private struct ErrorViewCampaign: View {
    let error: any DisplayableError
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Error al cargar imágenes")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Reintentar", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(height: 320)
    }
}

#Preview {
    let manager = SupabaseCampaignManager.shared

    NavigationStack {
        MyCampaignView()
            .environmentObject(manager)
            .task {
                if manager.firstOwnCampaign == nil {
                    try? await manager.getOwnCampaignAction(
                        "b7a5e3b2-1111-4f1a-9d01-000000000001"
                    )
                }
            }

    }
}

//#Preview {
//    BeneficiaryCard()
//}
struct BeneficiaryCard: View {
    
    //MARK: Cambiar por user
    var body: some View{
        HStack {
            AsyncImage(url: URL(string:"https://picsum.photos/800/600?random=10") , scale: 0.9)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            VStack(alignment: .leading){
                Text("Nombre y Apellido")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Parentesco")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
            }
            .padding()
            
            VStack{
                Text("%")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("50%")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: 100)
        .overlay(){
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        }
        .padding(.horizontal, 15)
    }
}
struct MyCampaignProgress: View {
    var campaign: Campaign
    private var progressPercentage: Double {
        guard let goal = campaign.goalAmount, goal > 0 else { return 0 }
        return min(Double(campaign.totalRaised) / Double(goal), 1.0)
    }
    private var progressText: String {
        let percentage = Int(progressPercentage * 100)
        return "¡Llevas un \(percentage)% de tu meta!"
    }
    var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.cardMediumBlue,
                Color.cardDarkBlue,
                Color.cardLightBlue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {

        VStack(alignment: .leading, spacing: ArkUI.Spacing.s) {
            Text("Tu meta:")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.customWhite.opacity(0.9))

            HStack {
                Text("CLP: 0")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.customWhite.opacity(0.9))

                Spacer()

                if let goalAmount = campaign.goalAmount {
                    Text("CLP: \(Formatters.formatAmount(goalAmount))")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.customWhite.opacity(0.9))
                }
            }

            GradientProgressBar(value: progressPercentage)

            Text(progressText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.customWhite.opacity(0.9))
            HStack {
                Text("Status de la campaña: ")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.customWhite.opacity(0.9))
                CampaignStatusLabel(.cancelled)
            }
        }
        .padding(ArkUI.Spacing.m)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, ArkUI.Spacing.m)
    }
}


struct CampaignStatusLabel: View {
    let status: CampaignStatus
    init(_ status: CampaignStatus){
        self.status = status
    }
    private var labelBackground: Color {
        switch status {
        case .active:
            return Color.green.opacity(0.7)
        case .cancelled:
            return Color.red.opacity(0.7)
        case .draft:
            return Color.purple.opacity(0.7)
        case .completed:
            return  .customWhite.opacity(0.8)
        case .paused:
            return Color.yellow.opacity(0.7)
        }
    }
    var body: some View{
//        switch status {
//        case .active:
//            Text("Activo")
//        }
        Text("\(status.rawValue.capitalized)")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.customWhite.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.horizontal, 3)
            .background(labelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
