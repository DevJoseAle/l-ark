// CreateCampaignView.swift
import SwiftUI
import PhotosUI

struct CreateCampaignView: View {
    @StateObject private var viewModel = CreateCampaignViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            MainBGContainer {
                ScrollView {
                    VStack(spacing: 24) {
                        basicInfoSection
                        imagesSection
                        amountsSection
                        datesSection
                        configurationSection
                        beneficiariesSection
                        createButton
                    }
                    .padding()
                }
                .navigationTitle("Crear Campaña")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    toolbarContent
                }
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    errorMessage
                }
                .onChange(of: viewModel.selectedImages) { _ in
                    Task { await viewModel.loadSelectedImages() }
                }
                .onChange(of: viewModel.currentBeneficiaryEmail) { _ in
                    viewModel.searchUsers()
                }
                .onChange(of: viewModel.campaignCreated) { created in
                    if created { dismiss() }
                }
                .overlay {
                    if viewModel.isCreating {
                        loadingOverlay
                    }
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancelar") {
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private var errorMessage: some View {
        if let error = viewModel.errorMessage {
            Text(error)
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            loadingContent
        }
    }
    
    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Creando campaña...")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(32)
        .background(Color.red)
        .cornerRadius(16)
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "Título de la campaña *",
                placeholder: "Ej: Ayuda para María",
                text: $viewModel.title,
                icon: "text.alignleft"
            )
            
            CustomTextEditor(
                title: "Descripción",
                placeholder: "Cuéntanos sobre la campaña...",
                text: $viewModel.description,
                height: 140
            )
        }
        .cardStyle()
    }
    
    private var imagesSection: some View {
        VStack(spacing: 16) {
            ImagePickerCard(
                selectedImages: $viewModel.selectedImages,
                images: viewModel.campaignImages,
                onRemove: { index in
                    viewModel.removeImage(at: index)
                }
            )
        }
        .cardStyle()
    }
    
    private var amountsSection: some View {
        VStack(spacing: 16) {
            sectionTitle("Montos")
            
            CustomTextField(
                title: "Meta de recaudación",
                placeholder: "1000000",
                text: $viewModel.goalAmount,
                keyboardType: .numberPad,
                icon: "dollarsign.circle"
            )
            
            capsSection
            currencyPicker
        }
        .cardStyle()
    }
    
    private var capsSection: some View {
        HStack(spacing: 12) {
            CustomTextField(
                title: "Soft Cap",
                placeholder: "500000",
                text: $viewModel.softCap,
                keyboardType: .numberPad
            )
            
            CustomTextField(
                title: "Hard Cap",
                placeholder: "2000000",
                text: $viewModel.hardCap,
                keyboardType: .numberPad
            )
        }
    }
    
    private var currencyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Moneda")
                .font(.system(size: 15, weight: .semibold))
            
            Picker("Moneda", selection: $viewModel.currency) {
                Text("CLP - Peso Chileno").tag("CLP")
                Text("USD - Dólar").tag("USD")
                Text("EUR - Euro").tag("EUR")
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var datesSection: some View {
        VStack(spacing: 16) {
            sectionTitle("Fechas")
            
            DatePicker(
                "Fecha de inicio",
                selection: $viewModel.startDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            
            DatePicker(
                "Fecha de fin",
                selection: $viewModel.endDate,
                in: viewModel.startDate...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
        }
        .cardStyle()
    }
    
    private var configurationSection: some View {
        VStack(spacing: 16) {
            sectionTitle("Configuración")
            visibilityPicker
            beneficiaryRulePicker
        }
        .cardStyle()
    }
    
    private var visibilityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Visibilidad")
                .font(.system(size: 15, weight: .semibold))
            
            Picker("Visibilidad", selection: $viewModel.visibility) {
                Text("Pública").tag(CampaignVisibility.publicCampaign)
                Text("No listada").tag(CampaignVisibility.unlisted)
                Text("Privada").tag(CampaignVisibility.privateCampaign)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var beneficiaryRulePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Regla de distribución")
                .font(.system(size: 15, weight: .semibold))
            
            Picker("Regla", selection: $viewModel.beneficiaryRule) {
                Text("Partes fijas").tag(BeneficiaryRule.fixedShares)
                Text("Prioridad").tag(BeneficiaryRule.priority)
                Text("Un beneficiario").tag(BeneficiaryRule.singleBeneficiary)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var beneficiariesSection: some View {
        VStack(spacing: 16) {
            beneficiariesHeader
            
            BeneficiarySearchView(
                email: $viewModel.currentBeneficiaryEmail,
                searchResults: viewModel.searchResults,
                isSearching: viewModel.isSearching,
                onSelect: { user in
                    viewModel.addBeneficiary(user)
                }
            )
            
            beneficiariesList
        }
        .cardStyle()
    }
    
    private var beneficiariesHeader: some View {
        HStack {
            Text("Beneficiarios *")
                .font(.system(size: 17, weight: .bold))
            
            Spacer()
            
            if viewModel.beneficiaries.contains(where: { $0.shareType == .percent }) {
                percentageIndicator
            }
        }
    }
    
    private var percentageIndicator: some View {
        Text("\(Int(viewModel.totalSharePercentage))%")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(viewModel.isSharesValid ? .green : .red)
    }
    
    @ViewBuilder
    private var beneficiariesList: some View {
        ForEach(viewModel.beneficiaries) { beneficiary in
            BeneficiaryCard(
                beneficiary: beneficiary,
                onRemove: {
                    viewModel.removeBeneficiary(beneficiary)
                },
                onShareChange: { value in
                    viewModel.updateBeneficiaryShare(beneficiary, value: value)
                },
                onShareTypeChange: { type in
                    viewModel.updateBeneficiaryShareType(beneficiary, type: type)
                },
                onAddDocument: { doc in
                    viewModel.addDocumentToBeneficiary(beneficiary, document: doc)
                },
                onRemoveDocument: { docId in
                    viewModel.removeDocumentFromBeneficiary(beneficiary, documentId: docId)
                }
            )
        }
    }
    
    private var createButton: some View {
        Button {
            Task {
                await viewModel.createCampaign(ownerUserId: appState.currentUser!.id )
            }
        } label: {
            createButtonLabel
        }
        .disabled(!viewModel.isFormValid || viewModel.isCreating)
    }
    
    @ViewBuilder
    private var createButtonLabel: some View {
        HStack {
            if viewModel.isCreating {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Crear Campaña")
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(viewModel.isFormValid ? Color.blue : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(16)
    }
    
    // MARK: - Helpers
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - View Extension

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.campaignSection)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Previews

#Preview {
    CreateCampaignView()
}

#Preview("Beneficiary Card") {
    ScrollView {
        VStack(spacing: 16) {
            BeneficiaryCard(
                beneficiary: BeneficiaryDraft(
                    email: "juan@example.com",
                    user: SupabaseUser(
                        id: UUID(),
                        displayName: "Juan Pérez",
                        email: "juan@example.com",
                        phone: "+56912345678",
                        country: "CL",
                        kycStatus: .kycVerified,
                        defaultCurrency: "CLP",
                        pinSet: true,
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    shareType: .percent,
                    shareValue: 50,
                    priority: 1
                ),
                onRemove: {},
                onShareChange: { _ in },
                onShareTypeChange: { _ in },
                onAddDocument: { _ in },
                onRemoveDocument: { _ in }
            )
        }
    }
}
