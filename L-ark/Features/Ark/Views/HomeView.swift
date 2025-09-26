//
import SwiftUI

struct HomeView: View {
    @State private var router = Router()
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
            
        }
    }

}
#Preview {
    HomeView()
}

@Observable
class Router {
    var selectedTab: TabViewEnum = .home
}
