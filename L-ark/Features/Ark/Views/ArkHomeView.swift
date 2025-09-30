import SwiftUI

struct ArkHomeView: View {
    @EnvironmentObject private var viewModel: ArkHomeViewModel
    @EnvironmentObject private var campaign: SupabaseCampaignManager
    @EnvironmentObject private var donations: SupabaseDonationsManager
    @EnvironmentObject private var appState: AppState
    @State private var showKYCFlow = false
    var title = """
        Aun no tienes campaña.
        Presiona aquí para crear una
        """
    var body: some View {
        NavigationStack {
            MainBGContainer {
                content
                    .navigationBarBackButtonHidden(true)
                    .navigationTitle(Text("Home"))
                    .navigationBarTitleDisplayMode(.large)
            }
            .fullScreenCover(isPresented: $showKYCFlow) {  // ✅ FullScreenCover en lugar de NavigationLink
                KYCGateway()
                    .environmentObject(appState)
            }

        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .loading:
            LoadingView()

        case .loaded:
            loadedContent

        case .error(let error):
            errorView(error)

        }
    }

    private var loadedContent: some View {

        VStack {
            if campaign.ownCampaigns.isEmpty {
                VStack {
                    Spacer()
                    Button {
                        showKYCFlow = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 62, height: 62)
                            .foregroundStyle(.linearBGBlue, .cardMediumBlue)
                            .symbolEffect(
                                .bounce.down.byLayer,
                                options: .repeat(.continuous)
                            )
                            .foregroundColor(Color.customText)

                    }
                    .buttonStyle(.plain)
                    Text(title)
                        .fontWeight(.medium)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .padding(.bottom, ArkUI.Spacing.l)

                    Spacer()
                }
            } else {
                loadedContentWithData
            }
        }

    }

    private var loadedContentWithData: some View {
        ScrollView {
            VStack(spacing: ArkUI.Spacing.l) {
                ArkFundingSection(campaign: campaign.firstOwnCampaign!)

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
                    donatorName: "Anónimo",
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
//#Preview {
//    ArkHomeView()
//        .environmentObject(ArkHomeViewModel())
//        .environmentObject(SupabaseCampaignManager.shared)
//        .environmentObject(SupabaseDonationsManager.shared)
//}

#Preview("Loading State") {
    let viewModel = ArkHomeViewModel()
    viewModel.state = .loading

    return ArkHomeView()
        .environmentObject(viewModel)
        .environmentObject(SupabaseCampaignManager.shared)
        .environmentObject(SupabaseDonationsManager.shared)
}

#Preview("Loaded State - Empty") {
    let viewModel = ArkHomeViewModel()
    viewModel.state = .loaded

    return ArkHomeView()
        .environmentObject(viewModel)
        .environmentObject(SupabaseCampaignManager.shared)
        .environmentObject(SupabaseDonationsManager.shared)
        .environmentObject(AppState())
}

#Preview("Loaded State - With Data") {
    let viewModel = ArkHomeViewModel()
    viewModel.state = .loaded

    let campaignManager = SupabaseCampaignManager.shared
    // Aquí podrías mockear datos si tuvieras campañas de prueba

    return ArkHomeView()
        .environmentObject(viewModel)
        .environmentObject(campaignManager)
        .environmentObject(SupabaseDonationsManager.shared)
}

#Preview("Error State") {
    let viewModel = ArkHomeViewModel()
    viewModel.state = .error(CampaignError.failed)

    return ArkHomeView()
        .environmentObject(viewModel)
        .environmentObject(SupabaseCampaignManager.shared)
        .environmentObject(SupabaseDonationsManager.shared)
}
