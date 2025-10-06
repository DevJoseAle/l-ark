import SwiftUI

// MARK: - TabItem
struct TabItem {
    let name: String
    let systemImage: String
    var color: Color
}

// MARK: - TabViewEnum
enum TabViewEnum: Identifiable, CaseIterable {
    var id: Self { self }

    case home, vault, favorites, profile
    
    var tabItem: TabItem {
        switch self {
        case .home:
            .init(name: "Arca", systemImage: "shippingbox.fill", color: .cardDarkBlue)
        case .vault:
            .init(name: "Bóveda", systemImage: "lock.shield.fill", color: .cardDarkBlue)
        case .favorites:
            .init(name: "Favoritos", systemImage: "heart.fill", color: .cardDarkBlue)
        case .profile:
            .init(name: "Perfil", systemImage: "person.fill", color: .cardDarkBlue)
        }
    }
    
    // ✅ Método que retorna la vista con el ViewModel inyectado
    @ViewBuilder
    func view(vaultVM: VaultViewModel) -> some View {
        switch self {
        case .home:
            ArkHomeView()
        case .vault:
            VaultHomeView(vm: vaultVM)
        case .favorites:
            ProfileHomeView()
        case .profile:
            ProfileHomeView()
        }
    }
}

// MARK: - CustomTabBar
struct CustomTabBar: View {
    @Binding var selectedIndex: TabViewEnum
    
    var body: some View {
        HStack(spacing: 30) {
            ForEach(TabViewEnum.allCases) { tab in
                Button {
                    withAnimation {
                        selectedIndex = tab
                    }
                } label: {
                    Image(systemName: tab.tabItem.systemImage)
                        .font(.system(size: 20))
                        .bold()
                        .padding()
                        .frame(width: 50)
                        .foregroundColor(.white)
                        .background(tab == selectedIndex ? Color.iconDisableBG : tab.tabItem.color)
                        .clipShape(Circle())
                }
                .disabled(tab == selectedIndex)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.8))
        .clipShape(Capsule())
        .padding()
    }
}

// MARK: - MainTabView
struct MainTabView: View {
    @State private var selectedTab: TabViewEnum = .home
    @StateObject private var vaultVM: VaultViewModel
    
    // ✅ Init sin parámetros, usa el shared
    init() {
        let supabase = SupabaseClientManager.shared.client
        let api = SupabaseVaultManager(supabase: supabase)
        _vaultVM = StateObject(wrappedValue: VaultViewModel(api: api, supabase: supabase))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Contenido basado en tab seleccionado
            Group {
                switch selectedTab {
                case .home:
                    ArkHomeView()
                case .vault:
                    VaultHomeView(vm: vaultVM)
                case .favorites:
                    ProfileHomeView()
                case .profile:
                    ProfileHomeView()
                }
            }
            
            // Tab bar
            CustomTabBar(selectedIndex: $selectedTab)
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
