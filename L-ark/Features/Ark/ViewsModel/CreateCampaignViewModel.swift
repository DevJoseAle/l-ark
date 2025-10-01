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
    
    private let service = SupabaseCampaignManager()
    private var searchTask: Task<Void, Never>?
    
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
    
    func addBeneficiary(_ user: SupabaseUser) {
        guard !beneficiaries.contains(where: { $0.user?.id == user.id }) else {
            return
        }
        
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
    
    // MARK: - Create Campaign
    
    func createCampaign(ownerUserId: UUID) async {
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
            
            let campaign = try await service.createCampaign(
                ownerUserId: ownerUserId,
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
                campaignImages: campaignImages,
                beneficiaries: beneficiaries
            )
            
            campaignCreated = true
            print("✅ Campaña creada: \(campaign.id)")
            
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
    }
}
