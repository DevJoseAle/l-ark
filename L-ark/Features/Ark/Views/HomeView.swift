//
import SwiftUI

struct HomeView: View {

    var body: some View {
        TabView {
            ArkHomeView()
                .tabItem { Label("Arca", systemImage: "shippingbox.fill") }
            
            VaultHomeView()
                .tabItem { Label("Bóveda", systemImage: "lock.shield.fill") }
            
            ProfileHomeView()
                .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
            ProfileHomeView()
                .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
        }
        .environmentObject(SupabaseCampaignManager.shared)
        .environmentObject(SupabaseDonationsManager.shared)
    }
        
}
#Preview {
        HomeView()
}
