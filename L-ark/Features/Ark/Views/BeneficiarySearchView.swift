//
//  BeneficiarySearchView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 01-10-25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct BeneficiarySearchView: View {
    @Binding var email: String
    let searchResults: [SupabaseUser]
    let isSearching: Bool
    let onSelect: (SupabaseUser) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchBar
            
            if !searchResults.isEmpty {
                searchResultsList
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField("Buscar por email del beneficiario", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
            
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var searchResultsList: some View {
        VStack(spacing: 0) {
            ForEach(searchResults) { user in
                SearchResultRow(
                    user: user,
                    isLast: user.id == searchResults.last?.id,
                    onSelect: { onSelect(user) }
                )
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let user: SupabaseUser
    let isLast: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    userAvatar
                    userInfo
                    Spacer()
                    rightAccessories
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            if !isLast {
                Divider()
                    .padding(.leading, 68)
            }
        }
    }
    
    private var userAvatar: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay {
                Text(user.displayName.prefix(2).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
    }
    
    private var userInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.displayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(user.email)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var rightAccessories: some View {
        if user.kycStatus == .kycVerified {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))
        }
        
        Image(systemName: "plus.circle.fill")
            .foregroundColor(.blue)
            .font(.system(size: 20))
    }
}

// MARK: - Beneficiary Card

struct BeneficiaryCard: View {
    let beneficiary: BeneficiaryDraft
    let onRemove: () -> Void
    let onShareChange: (Double) -> Void
    let onShareTypeChange: (BeneficiaryShareType) -> Void
    let onAddDocument: (DocumentUpload) -> Void
    let onRemoveDocument: (UUID) -> Void
    
    @State private var shareText: String = ""
    @State private var showingDocumentPicker = false
    @State private var selectedDocItems: [PhotosPickerItem] = []
    @State private var showShareTypePicker = false
    
    init(
        beneficiary: BeneficiaryDraft,
        onRemove: @escaping () -> Void,
        onShareChange: @escaping (Double) -> Void,
        onShareTypeChange: @escaping (BeneficiaryShareType) -> Void,
        onAddDocument: @escaping (DocumentUpload) -> Void,
        onRemoveDocument: @escaping (UUID) -> Void
    ) {
        self.beneficiary = beneficiary
        self.onRemove = onRemove
        self.onShareChange = onShareChange
        self.onShareTypeChange = onShareTypeChange
        self.onAddDocument = onAddDocument
        self.onRemoveDocument = onRemoveDocument
        _shareText = State(initialValue: String(format: "%.0f", beneficiary.shareValue))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            headerSection
            shareSection
            documentsSection
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .confirmationDialog("Tipo de participación", isPresented: $showShareTypePicker, titleVisibility: .visible) {
            shareTypeButtons
        }
        .photosPicker(
            isPresented: $showingDocumentPicker,
            selection: $selectedDocItems,
            maxSelectionCount: 3 - beneficiary.relationshipDocs.count,
            matching: .any(of: [.images])
        )
        .onChange(of: selectedDocItems) { newItems in
            Task {
                await loadDocuments(newItems)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            userAvatar
            userDetails
            Spacer()
            removeButton
        }
    }
    
    private var userAvatar: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 50, height: 50)
            .overlay {
                if let user = beneficiary.user {
                    Text(user.displayName.prefix(2).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
    }
    
    @ViewBuilder
    private var userDetails: some View {
        if let user = beneficiary.user {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                if user.kycStatus == .kycVerified {
                    verificationBadge
                }
            }
        }
    }
    
    private var verificationBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 11))
            Text("Verificado")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.green)
    }
    
    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 24))
        }
    }
    
    // MARK: - Share Section
    
    private var shareSection: some View {
        VStack(spacing: 12) {
            shareTypeHeader
            shareValueInput
        }
    }
    
    private var shareTypeHeader: some View {
        HStack {
            Text("Tipo de participación")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { showShareTypePicker = true }) {
                HStack(spacing: 4) {
                    Text(shareTypeText)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private var shareTypeText: String {
        beneficiary.shareType == .percent ? "Porcentaje" : "Monto fijo"
    }
    
    private var shareValueInput: some View {
        HStack(spacing: 12) {
            TextField("0", text: $shareText)
                .keyboardType(.decimalPad)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .onChange(of: shareText) { newValue in
                    if let value = Double(newValue) {
                        onShareChange(value)
                    }
                }
            
            Text(shareValueSuffix)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var shareValueSuffix: String {
        beneficiary.shareType == .percent ? "%" : (beneficiary.user?.defaultCurrency ?? "CLP")
    }
    
    @ViewBuilder
    private var shareTypeButtons: some View {
        Button("Porcentaje") {
            onShareTypeChange(.percent)
        }
        
        Button("Monto fijo") {
            onShareTypeChange(.fixedAmount)
        }
        
        Button("Cancelar", role: .cancel) {}
    }
    
    // MARK: - Documents Section
    
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            documentsHeader
            
            if !beneficiary.relationshipDocs.isEmpty {
                documentsScrollView
            }
            
            if beneficiary.relationshipDocs.count < 3 {
                addDocumentButton
            }
        }
    }
    
    private var documentsHeader: some View {
        HStack {
            Text("Documentos de relación")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(beneficiary.relationshipDocs.count)/3")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var documentsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(beneficiary.relationshipDocs) { doc in
                    DocumentThumbnail(document: doc) {
                        onRemoveDocument(doc.id)
                    }
                }
            }
        }
    }
    
    private var addDocumentButton: some View {
        Menu {
            Button {
                showingDocumentPicker = true
            } label: {
                Label("Seleccionar foto", systemImage: "photo")
            }
            
            Button {
                // Implementar document picker para PDFs
            } label: {
                Label("Seleccionar PDF", systemImage: "doc")
            }
        } label: {
            HStack {
                Image(systemName: "paperclip")
                Text("Agregar documento")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Load Documents
    
    private func loadDocuments(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let document = createDocument(from: data)
                if let document = document {
                    onAddDocument(document)
                }
            }
        }
        selectedDocItems.removeAll()
    }
    
    private func createDocument(from data: Data) -> DocumentUpload? {
        if let _ = UIImage(data: data) {
            // Es una imagen
            if let compressedData = UIImage(data: data)?.jpegData(compressionQuality: 0.7) {
                let fileName = "\(UUID().uuidString).jpg"
                return DocumentUpload(
                    data: compressedData,
                    fileName: fileName,
                    mimeType: "image/jpeg"
                )
            }
        } else {
            // Asumir que es PDF
            let fileName = "\(UUID().uuidString).pdf"
            return DocumentUpload(
                data: data,
                fileName: fileName,
                mimeType: "application/pdf"
            )
        }
        return nil
    }
}

// MARK: - Document Thumbnail

struct DocumentThumbnail: View {
    let document: DocumentUpload
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailContent
            removeButton
        }
    }
    
    @ViewBuilder
    private var thumbnailContent: some View {
        if document.isImage, let uiImage = UIImage(data: document.data) {
            imageView(uiImage)
        } else if document.isPDF {
            pdfView
        }
    }
    
    private func imageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var pdfView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.fill")
                .font(.system(size: 30))
                .foregroundColor(.red)
            
            Text("PDF")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.white)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
        .padding(6)
    }
}
