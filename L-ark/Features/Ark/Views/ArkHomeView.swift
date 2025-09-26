import SwiftUI

struct ArkHomeView: View {
    @StateObject private var viewModel = ArkHomeViewModel()
    @EnvironmentObject private var campaign: SupabaseCampaignManager
    @EnvironmentObject private var donations: SupabaseDonationsManager
    
    var body: some View {
        NavigationStack {
            MainBGContainer {
                content
                    .navigationBarBackButtonHidden(true)
                    .navigationTitle(Text("Home"))
                    .navigationBarTitleDisplayMode(.large)
            }
        }
        .task {
            await viewModel.loadInitialData(
                userId: "b7a5e3b2-1111-4f1a-9d01-000000000001",
                campaignId: "89bf4646-3e2a-4900-b0d4-fee2a318aa8f"
            )
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
            
        case .loading:
            loadingView
            
        case .loaded:
            loadedContent
            
        case .error(let error):
            errorView(error)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Cargando...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadedContent: some View {
        
        VStack{
            if campaign.ownCampaign == nil {
                VStack{
                    Text("Aun no tienes campaña. Debes crear una")
                    
                }
            }else{
                loadedContentWithData
            }
        }
    }
    
    private var loadedContentWithData: some View{
        ScrollView {
            VStack(spacing: ArkUI.Spacing.l) {
                ArkFundingSection(campaign: campaign.ownCampaign!)
                
                Divider()
                    .frame(height: 1)
                    .overlay(Color.customDarkGray.opacity(0.2))
                
                donationsSection
            }
            .padding(.horizontal, ArkUI.Spacing.m)
            .padding(.bottom, 60)
        }
        .scrollIndicators(.hidden)
        
    }
    private var donationsSection: some View {
        
        VStack(alignment: .leading, spacing: ArkUI.Spacing.m) {
            Text("Donaciones:")
                .font(.system(size: 18, weight: .medium))
                .padding(.horizontal, ArkUI.Spacing.m)
                .padding(.top, ArkUI.Spacing.m)
            
            if donations.donations.isEmpty {
                
                emptyDonationsView
            } else {
                donationsList
            }
                
        }
    }
    
    private var donationsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(donations.donations) { donation in
                DonationHomeTile(
                    initials: String("AN"),
                    donatorName:  "Anónimo",
                    donationTime: Formatters.formatDate(donation.createdAt),
                    donationAmount: Formatters.formatAmount(donation.amount)
                )
                Divider().padding(.leading, 74)
            }
        }
    }
    
    private var emptyDonationsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Aún no tienes donaciones")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func errorView(_ error: any DisplayableError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(error.userMessage)
                .multilineTextAlignment(.center)
            
            if error.isRetryable {
                Button("Reintentar") {
                    Task {
                        await viewModel.loadInitialData(
                            userId: "b7a5e3b2-1111-4f1a-9d01-0000000000p1",
                            campaignId: "89bf4646-3e2a-4900-b0d4-fee2a318aa8f"
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#Preview {
    ArkHomeView()
        .environmentObject(SupabaseCampaignManager.shared)
        .environmentObject(SupabaseDonationsManager.shared)
}


