//// CreateCampaignViewModel.swift
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
class CreateCampaignViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var goalAmount: String = ""
    @Published var softCap: String = ""
    @Published var hardCap: String = ""
    @Published var currency: String = "CLP"
    @Published var visibility: CampaignVisibility = .publicCampaign
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60) // +30 días
    @Published var beneficiaryRule: BeneficiaryRule = .fixedShares
    
    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var campaignImages: [DocumentUpload] = []
    
    @Published var beneficiaries: [BeneficiaryDraft] = []
    @Published var currentBeneficiaryEmail: String = ""
    @Published var searchResults: [SupabaseUser] = []
    @Published var isSearching: Bool = false
    
    @Published var isCreating: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var campaignCreated: Bool = false
    @Published var showSuccessToast = false
    @Published var successMessage = ""
    
    @Published var hasDiagnosis: Bool = false
    @Published var selectedDiagnosisImages: [PhotosPickerItem] = []
    @Published var diagnosisImages: [DocumentUpload] = []
    private let service = SupabaseCampaignManager()
    private var searchTask: Task<Void, Never>?
    @Published var hasExistingImages = false
    
    private var editingCampaignId: UUID?
    var isEditMode: Bool { editingCampaignId != nil }
       
       // ✅ Init por defecto (crear nueva)
       init() {
           self.editingCampaignId = nil
       }
       
       // ✅ Init para edición

    init(editingCampaign: Campaign) {
        
        
        self.editingCampaignId = editingCampaign.id
        
        // Cargar datos existentes
        self.title = editingCampaign.title
        self.description = editingCampaign.description ?? ""
        self.goalAmount = editingCampaign.goalAmount.map { String(Int($0)) } ?? ""
        self.softCap = editingCampaign.softCap.map { String(Int($0)) } ?? ""
        self.hardCap = editingCampaign.hardCap.map { String(Int($0)) } ?? ""
        self.currency = editingCampaign.currency
        
        if let vis = CampaignVisibility(rawValue: editingCampaign.visibility.rawValue) {
            self.visibility = vis
        } else {
            self.visibility = .publicCampaign
        }
        
        self.startDate = editingCampaign.startAt ?? Date()
        self.endDate = editingCampaign.endAt ?? Date()
        

        if let ruleRaw = editingCampaign.beneficiaryRule,
           let rule = BeneficiaryRule(rawValue: ruleRaw.rawValue) {
            self.beneficiaryRule = rule
        } else {
            self.beneficiaryRule = .fixedShares
        }
        
        self.hasDiagnosis = editingCampaign.hasDiagnosis
        
        // Cargar imágenes y beneficiarios en Task
        Task {
                await loadExistingData(campaignId: editingCampaign.id)
                // Marcar que hay imágenes existentes
                await MainActor.run {
                    self.hasExistingImages = !self.campaignImages.isEmpty
                }
            }
    }
    //MARK: LoadExistingData
    private func loadExistingData(campaignId: UUID) async {
        // Cargar imágenes de campaña
        do {
            try await service.getImagesFromCampaign(campaignId.uuidString)
            
            // 🔥 NUEVA LÓGICA: Convertir CampaignImage a DocumentUpload
            let loadedImages = service.images
            var documentUploads: [DocumentUpload] = []
            
            for (index, campaignImage) in loadedImages.enumerated() {
                do {
                    // Descargar la imagen desde la URL
                    let imageData = try await service.downloadImageData(from: campaignImage.imageUrl)
                    
                    // Crear DocumentUpload con los datos descargados
                    let document = DocumentUpload(
                        data: imageData,
                        fileName: "image_\(index).jpg",
                        mimeType: "image/jpeg"
                    )
                    documentUploads.append(document)
                } catch {
                    print("Error descargando imagen \(index): \(error)")
                    // Continuar con las demás imágenes
                }
            }
            
            // Actualizar en el MainActor
            await MainActor.run {
                self.campaignImages = documentUploads
            }
            
        } catch {
            print("Error cargando imágenes: \(error)")
        }
        
        // Cargar beneficiarios
        do {
            let beneficiariesData = try await service.getBeneficiariesForCampaign(campaignId: campaignId)
            
            await MainActor.run {
                self.beneficiaries = beneficiariesData.compactMap { beneficiary in
                    guard let user = beneficiary.user else { return nil }
                    
                    let shareType = BeneficiaryShareType(rawValue: beneficiary.shareType.rawValue) ?? .percent
                        
                    return BeneficiaryDraft(
                        email: user.email,
                        user: user,
                        shareType: shareType,
                        shareValue: beneficiary.shareValue,
                        priority: beneficiary.priority
                    )
                }
            }
        } catch {
            print("Error cargando beneficiarios: \(error)")
        }
    }
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !beneficiaries.isEmpty &&
        beneficiaries.allSatisfy { $0.user != nil } &&
        isSharesValid
    }
    
    var totalSharePercentage: Double {
        beneficiaries
            .filter { $0.shareType == .percent }
            .reduce(0) { $0 + $1.shareValue }
    }
    
    var isSharesValid: Bool {
        let percentBeneficiaries = beneficiaries.filter { $0.shareType == .percent }
        if percentBeneficiaries.isEmpty { return true }
        return abs(totalSharePercentage - 100.0) < 0.01
    }
    
    var canAddMoreImages: Bool {
        campaignImages.count < 3
    }
    
    // MARK: - Image Handling
    
    func loadSelectedImages() async {
        for item in selectedImages {
            guard canAddMoreImages else { break }
            
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                
                let fileName = "\(UUID().uuidString).jpg"
                let document = DocumentUpload(
                    data: compressedData,
                    fileName: fileName,
                    mimeType: "image/jpeg"
                )
                campaignImages.append(document)
            }
        }
        
        // Limpiar selección
        selectedImages.removeAll()
    }
    
    func loadSelectedDiagnosisImages() async {
        for item in selectedDiagnosisImages {
            guard canAddMoreDiagnosisImages else { break }
            
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                
                let fileName = "\(UUID().uuidString)_diagnosis.jpg"
                let document = DocumentUpload(
                    data: compressedData,
                    fileName: fileName,
                    mimeType: "image/jpeg"
                )
                diagnosisImages.append(document)
            }
        }
        
        selectedDiagnosisImages.removeAll()
    }

    func removeDiagnosisImage(at index: Int) {
        guard index < diagnosisImages.count else { return }
        diagnosisImages.remove(at: index)
    }
    func removeImage(at index: Int) {
        guard index < campaignImages.count else { return }
        campaignImages.remove(at: index)
    }
    
    // MARK: - Beneficiary Search
    
    func searchUsers() {
        searchTask?.cancel()
        
        guard !currentBeneficiaryEmail.isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            isSearching = true
            
            try? await Task.sleep(nanoseconds: 500_000_000) // Debounce 0.5s
            
            if Task.isCancelled { return }
            
            do {
                let results = try await service.searchUsersByEmail(currentBeneficiaryEmail)
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch {
                searchResults = []
            }
            
            isSearching = false
        }
    }
    
    // Modificar la función addBeneficiary existente

    func addBeneficiary(_ user: SupabaseUser) {
        guard !beneficiaries.contains(where: { $0.user?.id == user.id }) else {
            return
        }
        
        // ✅ OPCIONAL: Validar antes de agregar
        Task {
            do {
                if let conflict = try await SupabaseCampaignManager.shared.checkBeneficiaryAvailability(userId: user.id) {
                    errorMessage = "\(conflict.beneficiaryName) ya es beneficiario de '\(conflict.campaignTitle)'"
                    showError = true
                    return
                }
                
                // Si no hay conflicto, agregar
                let shareValue: Double = beneficiaryRule == .fixedShares ? (beneficiaries.isEmpty ? 100.0 : 0.0) : 0.0
                
                let beneficiary = BeneficiaryDraft(
                    email: user.email,
                    user: user,
                    shareType: .percent,
                    shareValue: shareValue,
                    priority: beneficiaries.count + 1
                )
                
                beneficiaries.append(beneficiary)
                currentBeneficiaryEmail = ""
                searchResults = []
            } catch {
                errorMessage = "Error al validar beneficiario"
                showError = true
            }
        }
    }
    
    func removeBeneficiary(_ beneficiary: BeneficiaryDraft) {
        beneficiaries.removeAll { $0.id == beneficiary.id }
    }
    
    func updateBeneficiaryShare(_ beneficiary: BeneficiaryDraft, value: Double) {
        if let index = beneficiaries.firstIndex(where: { $0.id == beneficiary.id }) {
            beneficiaries[index].shareValue = min(max(value, 0), 100)
        }
    }
    
    func updateBeneficiaryShareType(_ beneficiary: BeneficiaryDraft, type: BeneficiaryShareType) {
        if let index = beneficiaries.firstIndex(where: { $0.id == beneficiary.id }) {
            beneficiaries[index].shareType = type
        }
    }
    
    func addDocumentToBeneficiary(_ beneficiary: BeneficiaryDraft, document: DocumentUpload) {
        if let index = beneficiaries.firstIndex(where: { $0.id == beneficiary.id }) {
            guard beneficiaries[index].relationshipDocs.count < 3 else { return }
            beneficiaries[index].relationshipDocs.append(document)
        }
    }
    
    func removeDocumentFromBeneficiary(_ beneficiary: BeneficiaryDraft, documentId: UUID) {
        if let index = beneficiaries.firstIndex(where: { $0.id == beneficiary.id }) {
            beneficiaries[index].relationshipDocs.removeAll { $0.id == documentId }
        }
    }
    var canAddMoreDiagnosisImages: Bool {
        diagnosisImages.count < 3
    }
    
    // MARK: - Create Campaign
    
    // En CreateCampaignViewModel.swift

//    func createCampaign(ownerUserId: UUID) async {
//        guard isFormValid else {
//            errorMessage = "Por favor completa todos los campos requeridos"
//            showError = true
//            return
//        }
//        
//        isCreating = true
//        errorMessage = nil
//        
//        do {
//            let goal = Double(goalAmount.replacingOccurrences(of: ",", with: "")) ?? nil
//            let soft = Double(softCap.replacingOccurrences(of: ",", with: "")) ?? nil
//            let hard = Double(hardCap.replacingOccurrences(of: ",", with: "")) ?? nil
//            
//            let campaign = try await SupabaseCampaignManager.shared.createCampaign(
//                ownerUserId: ownerUserId,
//                title: title,
//                description: description.isEmpty ? nil : description,
//                goalAmount: goal,
//                softCap: soft,
//                hardCap: hard,
//                currency: currency,
//                visibility: visibility,
//                startAt: startDate,
//                endAt: endDate,
//                beneficiaryRule: beneficiaryRule,
//                campaignImages: campaignImages,
//                beneficiaries: beneficiaries
//            )
//            
//            campaignCreated = true
//            print("✅ Campaña creada: \(campaign.id)")
//            
//        } catch let error as CampaignError {  // ✅ CAMBIO: Catch específico para CampaignError
//            errorMessage = error.userMessage
//            showError = true
//        } catch {
//            errorMessage = error.localizedDescription
//            showError = true
//        }
//        
//        isCreating = false
//    }
    func createCampaign(ownerUserId: UUID, homeViewModel: HomeViewModel, appState: AppState) async {
            guard isFormValid else {
                errorMessage = "Por favor completa todos los campos requeridos"
                showError = true
                return
            }
            
            isCreating = true
            errorMessage = nil
            
            do {
                let goal = Double(goalAmount.replacingOccurrences(of: ",", with: "")) ?? nil
                let soft = Double(softCap.replacingOccurrences(of: ",", with: "")) ?? nil
                let hard = Double(hardCap.replacingOccurrences(of: ",", with: "")) ?? nil
                
                let campaign = try await SupabaseCampaignManager.shared.createCampaign(
                    ownerUserId: ownerUserId,
                    title: title,
                    description: description.isEmpty ? nil : description,
                    goalAmount: goal,
                    softCap: soft,
                    hardCap: hard,
                    currency: currency,
                    visibility: visibility,
                    startAt: startDate,
                    hasDiagnosis: hasDiagnosis,
                    endAt: endDate,
                    beneficiaryRule: beneficiaryRule,
                    campaignImages: campaignImages,
                    diagnosisImages: diagnosisImages,
                    beneficiaries: beneficiaries
                )
                
                print("✅ Campaña creada: \(campaign.id)")
                
                // Recargar datos iniciales
                await homeViewModel.loadInitialData(appState)
                
                // Mostrar toast de éxito
                successMessage = "Campaña creada exitosamente. Te avisaremos cuando esté activa después de la validación."
                showSuccessToast = true
                
                // Ocultar toast después de 4 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.showSuccessToast = false
                }
                
                // Marcar como creada para cerrar la vista
                campaignCreated = true
                
            } catch let error as CampaignError {
                errorMessage = error.userMessage
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
            isCreating = false
        }

    func reset() {
        title = ""
        description = ""
        goalAmount = ""
        softCap = ""
        hardCap = ""
        currency = "CLP"
        visibility = .publicCampaign
        startDate = Date()
        endDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        beneficiaryRule = .fixedShares
        selectedImages = []
        campaignImages = []
        beneficiaries = []
        currentBeneficiaryEmail = ""
        searchResults = []
        isCreating = false
        errorMessage = nil
        showError = false
        campaignCreated = false
        hasDiagnosis = false
        selectedDiagnosisImages = []
        diagnosisImages = []
    }
    func updateCampaign(homeViewModel: HomeViewModel, appState: AppState) async {
        guard let campaignId = editingCampaignId else {
            await createCampaign(
                ownerUserId: appState.currentUser!.id,
                homeViewModel: homeViewModel,
                appState: appState
            )
            return
        }
        
        // Lógica de actualización
        isCreating = true
        errorMessage = nil
        
        do {
            let goal = Double(goalAmount.replacingOccurrences(of: ",", with: "")) ?? nil
            let soft = Double(softCap.replacingOccurrences(of: ",", with: "")) ?? nil
            let hard = Double(hardCap.replacingOccurrences(of: ",", with: "")) ?? nil
            
            try await service.updateCampaign(
                campaignId: campaignId,
                title: title,
                description: description.isEmpty ? nil : description,
                goalAmount: goal,
                softCap: soft,
                hardCap: hard,
                currency: currency,
                visibility: visibility,
                startAt: startDate,
                endAt: endDate,
                beneficiaryRule: beneficiaryRule,
                hasDiagnosis: hasDiagnosis
                // Las imágenes y beneficiarios se manejan por separado
            )
            
            await homeViewModel.loadInitialData(appState)
            
            successMessage = "Campaña actualizada exitosamente"
            showSuccessToast = true
            campaignCreated = true
            
        } catch let error as CampaignError {
            errorMessage = error.userMessage
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isCreating = false
    }
}
