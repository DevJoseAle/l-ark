import SwiftUI

struct HomeView: View {
    @State private var router = Router()
    @EnvironmentObject var appState: AppState
    @StateObject private var homeViewModel = ArkHomeViewModel()
    @StateObject private var coordinator = HomeViewModel()
    
    @StateObject private var vaultVM: VaultViewModel
    
    init() {
        let supabase = SupabaseClientManager.shared.client
        let api = SupabaseVaultManager(supabase: supabase)
        _vaultVM = StateObject(wrappedValue: VaultViewModel(api: api, supabase: supabase))
    }
    
    var body: some View {
        MainBGContainer {
            ZStack(alignment: .bottom) {
                router.selectedTab
                    .view(vaultVM: vaultVM)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environment(router)
                    .environmentObject(SupabaseCampaignManager.shared)
                    .environmentObject(SupabaseDonationsManager.shared)
                    .environmentObject(homeViewModel)
                
                // Tab bar
                CustomTabBar(selectedIndex: $router.selectedTab)
            }
        }
        .larkLoadingOverlay(
            isLoading: coordinator.isLoadingInitialData,
            message: "Cargando tus datos..."
        )
        .task {
            await coordinator.loadInitialData(appState)
            if coordinator.loadingError != nil {
                homeViewModel.state = .error(GenericError.loadFailed)
            } else {
                homeViewModel.state = .loaded
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}

@Observable
class Router {
    var selectedTab: TabViewEnum = .home
}

enum GenericError: DisplayableError {
    case loadFailed
    
    var userMessage: String {
        "Error al cargar los datos. Intenta de nuevo."
    }
    
    var isRetryable: Bool {
        true
    }
}
