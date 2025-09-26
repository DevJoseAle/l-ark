//
//  CustomTabBar.swift
//  L-ark
//
//  Created by Jose Rodriguez on 26-09-25.
//

import SwiftUI

//MARK:EnumTabView
struct TabItem {
    let name: String
    let systemImage: String
    var color: Color
}
enum TabViewEnum: Identifiable, CaseIterable, View {
    var id: Self { self }

    case home, vault, favorites, profile

    var tabItem: TabItem {
        switch self {
        case .home:
            .init(
                name: "Arca",
                systemImage: "shippingbox.fill",
                color: .cardDarkBlue
            )
        case .vault:
            .init(
                name: "Bóveda",
                systemImage: "lock.shield.fill",
                color: .cardDarkBlue
            )
        case .favorites:
            .init(
                name: "Favoritos",
                systemImage: "heart.fill",
                color: .cardDarkBlue
            )
        case .profile:
            .init(
                name: "Perfil",
                systemImage: "person.fill",
                color: .cardDarkBlue
            )
        }
    }

    var body: some View {
        switch self {
        case .home:
            ArkHomeView()
        case .vault:
            VaultHomeView()
        case .favorites:
            ProfileHomeView()
        case .profile:
            ProfileHomeView()
        }
    }

}

struct CustomTabBar: View {
    @Binding var selectedIndex: TabViewEnum

    var body: some View {
        HStack(spacing:30){
            ForEach(TabViewEnum.allCases) { tab in
                Button {
                    withAnimation{
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

#Preview {
    @Previewable @State var selectedIndex: TabViewEnum = .home
    MainBGContainer {
        VStack {
            Spacer()
            CustomTabBar(selectedIndex: $selectedIndex)
        }
    }
}
//ArkHomeView()
//    .tabItem { Label("Arca", systemImage: "shippingbox.fill") }
//
//VaultHomeView()
//    .tabItem { Label("Bóveda", systemImage: "lock.shield.fill") }
//
//ProfileHomeView()
//    .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
//ProfileHomeView()
//    .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
//}
