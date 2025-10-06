// CustomTextField.swift
import SwiftUI
import PhotosUI

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
                .foregroundColor(Color.invertedText)
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(Color.invertedText)
                        .frame(width: 20)
                }
                
                TextField(placeholder, text: $text)
                    
                    .keyboardType(keyboardType)
                    .foregroundStyle(Color.invertedText)
                    
            }
            .padding()
            .background(Color.campaignTexfield)
            .cornerRadius(12)
        }
    }
}

struct CustomTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.invertedText)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.invertedText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
            }
            .frame(height: height)
            .background(Color.campaignTexfield)
            .cornerRadius(12)
        }
    }
}

struct ImagePickerCard: View {
    @Binding var selectedImages: [PhotosPickerItem]
    let images: [DocumentUpload]
    let onRemove: (Int) -> Void
    let maxImages: Int = 3
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(title) (máx. 3)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                        imagePreview(image: image, index: index)
                    }
                    
                    if images.count < maxImages {
                        addImageButton
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
    
    private func imagePreview(image: DocumentUpload, index: Int) -> some View {
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
                    .background(Color.campaignTexfield)
                    .clipShape(Circle())
            }
            .padding(6)
        }
    }
    
    private var addImageButton: some View {
        PhotosPicker(
            selection: $selectedImages,
            maxSelectionCount: maxImages - images.count,
            matching: .images
        ) {
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 30))
                    .foregroundColor(.invertedText)
                
                Text("Agregar")
                    .font(.system(size: 12))
                    .foregroundColor(.invertedText)
            }
            .frame(width: 100, height: 100)
            .background(Color.campaignTexfield)
            .cornerRadius(12)
        }
    }
}

// MARK: - Previews

#Preview("CustomTextField - Simple") {
    MainBGContainer {
        VStack(spacing: 20) {
            CustomTextField(
                title: "Título",
                placeholder: "Escribe aquí...",
                text: .constant("")
            )
            
            CustomTextField(
                title: "Email",
                placeholder: "tu@email.com",
                text: .constant("usuario@ejemplo.com"),
                keyboardType: .emailAddress
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview("CustomTextField - Con Iconos") {
    VStack(spacing: 20) {
        CustomTextField(
            title: "Nombre",
            placeholder: "Tu nombre",
            text: .constant("Juan Pérez"),
            icon: "person.fill"
        )
        
        CustomTextField(
            title: "Email",
            placeholder: "tu@email.com",
            text: .constant(""),
            keyboardType: .emailAddress,
            icon: "envelope.fill"
        )
        
        CustomTextField(
            title: "Monto",
            placeholder: "1000000",
            text: .constant("3000000"),
            keyboardType: .numberPad,
            icon: "dollarsign.circle"
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("CustomTextEditor - Vacío") {
    CustomTextEditor(
        title: "Descripción",
        placeholder: "Escribe una descripción detallada...",
        text: .constant("")
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("CustomTextEditor - Con Texto") {
    CustomTextEditor(
        title: "Descripción de la campaña",
        placeholder: "Escribe aquí...",
        text: .constant("Me llamo Ernesto, tengo 67 años y recientemente me diagnosticaron insuficiencia renal crónica avanzada. Sé que mi tiempo es limitado, pero también sé que mi tercer hijo no."),
        height: 180
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("CustomTextEditor - Alturas") {
    ScrollView {
        VStack(spacing: 20) {
            CustomTextEditor(
                title: "Descripción corta",
                placeholder: "Texto corto...",
                text: .constant(""),
                height: 80
            )
            
            CustomTextEditor(
                title: "Descripción media",
                placeholder: "Texto medio...",
                text: .constant(""),
                height: 140
            )
            
            CustomTextEditor(
                title: "Descripción larga",
                placeholder: "Texto largo...",
                text: .constant(""),
                height: 200
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("ImagePickerCard - Vacío") {
    ImagePickerCard(
        selectedImages: .constant([]),
        images: [],
        onRemove: { _ in },
        title: "Cualquier String"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("ImagePickerCard - Con Imágenes") {
    ImagePickerCard(
        selectedImages: .constant([]),
        images: [
            DocumentUpload(
                data: UIImage(systemName: "photo")?.pngData() ?? Data(),
                fileName: "image1.jpg",
                mimeType: "image/jpeg"
            ),
            DocumentUpload(
                data: UIImage(systemName: "photo.fill")?.pngData() ?? Data(),
                fileName: "image2.jpg",
                mimeType: "image/jpeg"
            )
        ],
        onRemove: { index in
            print("Removiendo imagen en index: \(index)")
        },
        title: "Cualquier String"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("ImagePickerCard - Completo (3 imágenes)") {
    ImagePickerCard(
        selectedImages: .constant([]),
        images: [
            DocumentUpload(
                data: UIImage(systemName: "photo")?.pngData() ?? Data(),
                fileName: "image1.jpg",
                mimeType: "image/jpeg"
            ),
            DocumentUpload(
                data: UIImage(systemName: "photo.fill")?.pngData() ?? Data(),
                fileName: "image2.jpg",
                mimeType: "image/jpeg"
            ),
            DocumentUpload(
                data: UIImage(systemName: "photo.circle")?.pngData() ?? Data(),
                fileName: "image3.jpg",
                mimeType: "image/jpeg"
            )
        ],
        onRemove: { _ in },
        title: "Cualquier String"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Formulario Completo") {
    ScrollView {
        VStack(spacing: 24) {
            CustomTextField(
                title: "Título de la campaña",
                placeholder: "Ej: Ayuda para María",
                text: .constant("Campaña de prueba"),
                icon: "text.alignleft"
            )
            
            CustomTextEditor(
                title: "Descripción",
                placeholder: "Cuéntanos sobre la campaña...",
                text: .constant("Esta es una campaña de ejemplo para mostrar los componentes.")
            )
            
            ImagePickerCard(
                selectedImages: .constant([]),
                images: [
                    DocumentUpload(
                        data: UIImage(systemName: "photo")?.pngData() ?? Data(),
                        fileName: "image1.jpg",
                        mimeType: "image/jpeg"
                    )
                ],
                onRemove: { _ in },
                title: "Cualquier String"
            )
            
            CustomTextField(
                title: "Meta de recaudación",
                placeholder: "1000000",
                text: .constant("3000000"),
                keyboardType: .numberPad,
                icon: "dollarsign.circle"
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
