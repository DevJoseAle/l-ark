import SwiftUI

struct VaultHomeView: View {
    @StateObject var vm: VaultViewModel
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
                
                if vm.isLoading && vm.uploadProgress == 0 {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
        .task {
            await vm.onAppear()
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
                    Task {
                        if let url = await vm.downloadURL(for: file.id) {
                            await UIApplication.shared.open(url)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                
                Button(role: .destructive) {
                    Task { await vm.delete(id: file.id) }
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
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
            VStack(spacing: 24) {
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
                
                VStack(alignment: .leading, spacing: 16) {
                    featureRow(icon: "opticaldiscdrive", text: "5 GB de almacenamiento")
                    featureRow(icon: "bolt.fill", text: "Subidas más rápidas")
                    featureRow(icon: "lock.shield.fill", text: "Seguridad mejorada")
                    featureRow(icon: "star.fill", text: "Soporte prioritario")
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        // Implementar compra IAP
                    } label: {
                        Text("Actualizar a Pro - $9.99/mes")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    Button("Más tarde") {
                        showingUpgradeToPro = false
                    }
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        showingUpgradeToPro = false
                    }
                }
            }
        }
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
