import SwiftUI
import StoreKit

struct VaultHomeView: View {
    @StateObject var vm: VaultViewModel
    @StateObject private var storeManager = StoreManager()
    @State private var showingPurchaseSuccess = false
    @State private var showingPurchaseError = false// ✅ Agregar
    @State private var showingPicker = false
    @State private var showingUpgradeToPro = false

    var body: some View {
        MainBGContainer {
            ZStack {
                if vm.hasNoCampaign {
                    noCampaignView
                } else {
                    mainVaultView
                }
                
                // ✅ Mostrar loading para cualquier operación
                if vm.isPerformingOperation && vm.uploadProgress == 0 {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
                if vm.isUploading && vm.uploadProgress > 0 {
                               VStack(spacing: 16) {
                                   ProgressView(value: vm.uploadProgress)
                                       .progressViewStyle(.linear)
                                       .frame(width: 200)
                                   
                                   Text("Subiendo \(Int(vm.uploadProgress * 100))%")
                                       .font(.subheadline)
                                       .foregroundStyle(.white)
                               }
                               .padding(24)
                               .background(Color.black.opacity(0.8))
                               .cornerRadius(16)
                           }
                           
                           // ✅ Overlay específico de delete
                if vm.isDeleting {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Eliminando archivo...")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                }
            }
        }
        .task {
            await vm.onAppear()
            storeManager.currentCampaignId = vm.activeCampaign?.id
            await storeManager.loadProducts()
            await storeManager.checkAndSyncSubscription()
            await vm.loadSubscriptionInfo()
        }
        .fileImporter(
            isPresented: $showingPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { res in
            if case .success(let urls) = res, let url = urls.first {
                Task { await vm.upload(url: url) }
            }
        }
        .sheet(isPresented: $showingUpgradeToPro) {
            upgradeToProSheet
        }
        .alert("Compra exitosa", isPresented: $showingPurchaseSuccess) {
            Button("Continuar") {
                showingUpgradeToPro = false
                Task { await vm.refresh() }
            }
        } message: {
            Text("Tu suscripción Pro está activa. Disfruta de 5 GB de almacenamiento!")
        }
        .alert("Error en la compra", isPresented: $showingPurchaseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(storeManager.errorMessage ?? "Ocurrió un error desconocido")
        }
        .onChange(of: storeManager.purchaseState) { oldValue, newValue in
            if case .success = newValue {
                showingPurchaseSuccess = true
            } else if case .failed = newValue {
                showingPurchaseError = true
            }
        }
    }
    
    // MARK: - No Campaign View
    
    private var noCampaignView: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("No tienes campañas")
                .font(.title2)
                .bold()
            
            Text("Crea tu primera campaña para comenzar a usar la Bóveda")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                // Navegar a crear campaña
                // NavigationLink o presentar modal
            } label: {
                Text("Crear Campaña")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Main Vault View
    
    private var mainVaultView: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
            
            // Storage Info
            storageInfoView
                .padding(.horizontal)
                .padding(.bottom, 12)
            
            // Upload Progress
            if vm.uploadProgress > 0 && vm.uploadProgress < 1 {
                uploadProgressView
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            
            // Files List
            if vm.items.isEmpty && !vm.isLoading {
                emptyStateView
            } else {
                fileListView
            }
            
            // Error Message
            if let error = vm.errorText {
                errorView(error)
                    .padding()
            }
        }.padding(.bottom, 70)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bóveda")
                    .font(.largeTitle)
                    .bold()
                
                if let campaign = vm.activeCampaign {
                    Text(campaign.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if vm.isFreePlan {
                Button {
                    showingUpgradeToPro = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                        Text("Pro")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                }
            }
            
            Button {
                showingPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Subir")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(20)
            }
            .disabled(vm.storagePercentage >= 1.0)
        }
    }
    
    // MARK: - Storage Info
    
    private var storageInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Almacenamiento")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(vm.storageUsedFormatted) de \(vm.storageQuotaFormatted)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(storageColor)
                        .frame(width: geo.size.width * vm.storagePercentage)
                }
            }
            .frame(height: 8)
            
            if vm.storagePercentage >= 0.9 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(vm.storagePercentage >= 1.0 ? "Almacenamiento lleno" : "Casi sin espacio")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var storageColor: Color {
        if vm.storagePercentage >= 1.0 { return .red }
        if vm.storagePercentage >= 0.9 { return .orange }
        return .blue
    }
    
    // MARK: - Upload Progress
    
    private var uploadProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Subiendo archivo...")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(vm.uploadProgress * 100))%")
                    .font(.subheadline.monospacedDigit())
            }
            
            ProgressView(value: vm.uploadProgress)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No hay archivos")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Sube tu primer archivo para comenzar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                showingPicker = true
            } label: {
                Text("Subir Archivo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - File List
    
    private var fileListView: some View {
        List {
            ForEach(vm.items) { file in
                fileRow(file)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .refreshable {
            await vm.refresh()
        }
    }
    
    private func fileRow(_ file: VaultFile) -> some View {
        HStack(spacing: 12) {
            // Icono del tipo de archivo
            fileIcon(for: file.file_type)
            
            // Info del archivo
            VStack(alignment: .leading, spacing: 4) {
                Text(file.file_name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(file.mime_type) • \(ByteCountFormatter.fileString(file.file_size_bytes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Botones de acción
            HStack(spacing: 16) {
                Button {
                    print("🔽 BOTÓN DESCARGA PRESIONADO para: \(file.file_name)")
                    Task {
                        if let url = await vm.downloadURL(for: file.id) {
                            print("✅ Abriendo URL: \(url)")
                            await UIApplication.shared.open(url)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless) // ✅ CRÍTICO: Evita propagación del tap
                
                Button(role: .destructive) {
                    print("🗑️ BOTÓN DELETE PRESIONADO para: \(file.file_name)")
                    Task { await vm.delete(id: file.id) }
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless) // ✅ CRÍTICO: Evita propagación del tap
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // ✅ Define el área tappable explícitamente
    }
    
    private func fileIcon(for type: VaultFileType) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case .image: return ("photo", .blue)
            case .pdf: return ("doc.fill", .red)
            case .video: return ("video.fill", .purple)
            case .audio: return ("music.note", .green)
            case .document: return ("doc.text.fill", .orange)
            case .other: return ("doc", .gray)
            }
        }()
        
        return Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(color)
            .frame(width: 40, height: 40)
            .background(color.opacity(0.1))
            .cornerRadius(8)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)
            Spacer()
            Button {
                vm.errorText = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Upgrade Sheet
    
    private var upgradeToProSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Image(systemName: "crown.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 40)
                    
                    Text("Actualiza a Pro")
                        .font(.title.bold())
                    
                    Text("Desbloquea todo el potencial de tu Bóveda")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "opticaldiscdrive", text: "5 GB de almacenamiento")
                        featureRow(icon: "bolt.fill", text: "Subidas más rápidas")
                        featureRow(icon: "lock.shield.fill", text: "Seguridad mejorada")
                        featureRow(icon: "star.fill", text: "Soporte prioritario")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Products
                    if storeManager.isLoading {
                        ProgressView("Cargando planes...")
                            .padding()
                    } else if storeManager.products.isEmpty {
                        Text("No se pudieron cargar los planes")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(storeManager.products, id: \.id) { product in
                                productCard(for: product)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if let error = storeManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    
                    // Dismiss button
                    Button("Más tarde") {
                        showingUpgradeToPro = false
                    }
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        showingUpgradeToPro = false
                    }
                }
            }
        }.overlay {
            if case .purchasing = storeManager.purchaseState {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Procesando compra...")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(16)
                    }
            }
        }
    }

    private func productCard(for product: Product) -> some View {
        Button {
            Task {
                await storeManager.purchase(product)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if product.id == VaultProduct.proYearly.rawValue {
                            Text("10% OFF")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .bold()
                    
                    if product.id == VaultProduct.proYearly.rawValue {
                        Text("CLP 6.750/mes")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("por mes")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(storeManager.purchaseState == .purchasing) // Deshabilitar durante compra
        .opacity(storeManager.purchaseState == .purchasing ? 0.6 : 1.0)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    VaultHomeView(
        vm: VaultViewModel(
            api: SupabaseVaultManager(supabase: SupabaseClientManager.shared.client),
            supabase: SupabaseClientManager.shared.client
        )
    )
}
