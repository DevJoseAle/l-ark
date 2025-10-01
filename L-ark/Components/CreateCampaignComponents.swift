// CustomTextField.swift
import SwiftUI

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .frame(width: 20)
                }
                
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// CustomTextEditor.swift
import SwiftUI

struct CustomTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
            }
            .frame(height: height)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// ImagePickerCard.swift
import SwiftUI
import PhotosUI

struct ImagePickerCard: View {
    @Binding var selectedImages: [PhotosPickerItem]
    let images: [DocumentUpload]
    let onRemove: (Int) -> Void
    let maxImages: Int = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Imágenes de la campaña (máx. 3)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                        ZStack(alignment: .topTrailing) {
                            if let uiImage = UIImage(data: image.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                onRemove(index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(6)
                        }
                    }
                    
                    if images.count < maxImages {
                        PhotosPicker(
                            selection: $selectedImages,
                            maxSelectionCount: maxImages - images.count,
                            matching: .images
                        ) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                                
                                Text("Agregar")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}
