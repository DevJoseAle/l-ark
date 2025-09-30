//
import SwiftUI

struct HomeView: View {
    @State private var router = Router()
    @EnvironmentObject var appState: AppState
    @StateObject private var homeViewModel = ArkHomeViewModel()
    @StateObject private var coordinator = HomeViewModel()
    var body: some View {
        MainBGContainer {
            TabView(selection: $router.selectedTab) {
                ForEach(TabViewEnum.allCases) { tab in
                    let tabItem = tab.tabItem
                    Tab(
                        tabItem.name,
                        systemImage: tabItem.systemImage,
                        value: tab
                    ) {
                        tab
                            .toolbarVisibility(.hidden, for: .tabBar)
                    }

                }
            }
            .safeAreaInset(edge: .bottom){
                CustomTabBar(selectedIndex: $router.selectedTab)
            }
            .environment(router)
            .environmentObject(SupabaseCampaignManager.shared)
            .environmentObject(SupabaseDonationsManager.shared)
            .environmentObject(homeViewModel) 
            
        }
        .larkLoadingOverlay(
            isLoading: coordinator.isLoadingInitialData,
                    message: "Cargando tus datos..."
                )
                .task {
                   
                    await coordinator.loadInitialData(appState)
                    if coordinator.loadingError != nil {
                        homeViewModel.state = .error(GenericError.loadFailed)
                    }else{
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
