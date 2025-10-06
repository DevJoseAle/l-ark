import SwiftUI

struct StoreTestView: View {
    @StateObject private var store = StoreManager()
    
    var body: some View {
        NavigationView {
            List {
                if store.isLoading {
                    ProgressView("Cargando productos...")
                } else if store.products.isEmpty {
                    Text("No hay productos disponibles")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.products, id: \.id) { product in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(product.displayPrice)
                                .font(.subheadline)
                                .bold()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if let error = store.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Productos Vault")
            .task {
                await store.loadProducts()
            }
        }
    }
}

#Preview {
    StoreTestView()
}
