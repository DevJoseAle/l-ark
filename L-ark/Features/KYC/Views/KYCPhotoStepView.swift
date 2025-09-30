//
//  KYCPhotoStepView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 29-09-25.
//

import SwiftUI

import PhotosUI

struct KYCPhotoStepView: View {
    let step: KYCStep
    @ObservedObject var viewModel: KYCOnboardingViewModel
    @State private var showCamera = false
    @State private var showImagePicker = false
    
    var body: some View {
        MainBGContainer {
            VStack(spacing: 24) {
                // Header con título
                VStack(spacing: 8) {
                    Text(stepTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(stepDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Preview de la imagen o placeholder
                if let image = currentImage {
                    VStack(spacing: 16) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Label("Tomar otra foto", systemImage: "camera")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    // Placeholder cuando no hay imagen
                    Button {
                        showImagePicker = true
                    } label: {
                        VStack(spacing: 16) {
                            Image(systemName: stepIcon)
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)
                            
                            Text("Toca para tomar foto")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2, )
                        )
                    }
                }
                
                Spacer()
                
                // Botones de navegación
                VStack(spacing: 12) {
                    Button {
                        viewModel.nextStep()
                    } label: {
                        Text("Continuar")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentImage != nil ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(currentImage == nil)
                    
                    Button {
                        viewModel.previousStep()
                    } label: {
                        Text("Regresar")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: bindingForCurrentStep)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // Helpers
    private var stepTitle: String {
        switch step {
        case .dniFront:
            return "Cédula - Lado Frontal"
        case .dniBack:
            return "Cédula - Lado Reverso"
        case .selfie:
            return "Selfie"
        default:
            return ""
        }
    }
    
    private var stepDescription: String {
        switch step {
        case .dniFront:
            return "Toma una foto clara del frente de tu cédula de identidad"
        case .dniBack:
            return "Toma una foto clara del reverso de tu cédula de identidad"
        case .selfie:
            return "Toma una selfie para verificar tu identidad"
        default:
            return ""
        }
    }
    
    private var stepIcon: String {
        switch step {
        case .dniFront:
            return "creditcard"
        case .dniBack:
            return "creditcard.fill"
        case .selfie:
            return "person.crop.circle"
        default:
            return "camera"
        }
    }
    
    private var currentImage: UIImage? {
        switch step {
        case .dniFront:
            return viewModel.dniFrontImage
        case .dniBack:
            return viewModel.dniBackImage
        case .selfie:
            return viewModel.selfieImage
        default:
            return nil
        }
    }
    
    private var bindingForCurrentStep: Binding<UIImage?> {
        switch step {
        case .dniFront:
            return $viewModel.dniFrontImage
        case .dniBack:
            return $viewModel.dniBackImage
        case .selfie:
            return $viewModel.selfieImage
        default:
            return .constant(nil)
        }
    }
}

// Image Picker para capturar fotos
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Preview
#Preview("DNI Frontal - Sin foto") {
    NavigationStack {
        KYCPhotoStepView(
            step: .dniFront,
            viewModel: KYCOnboardingViewModel()
        )
    }
}

#Preview("Selfie - Con foto") {
    let viewModel = KYCOnboardingViewModel()
    viewModel.selfieImage = UIImage(systemName: "person.circle.fill")
    
    return NavigationStack {
        KYCPhotoStepView(
            step: .selfie,
            viewModel: viewModel
        )
    }
}
#Preview("DNI Frontal - Sin foto") {
    NavigationStack {
        KYCPhotoStepView(
            step: .dniFront,
            viewModel: KYCOnboardingViewModel()
        )
    }
}

#Preview("Selfie - Con foto") {
    let viewModel = KYCOnboardingViewModel()
    viewModel.selfieImage = UIImage(systemName: "person.circle.fill")
    
    return NavigationStack {
        KYCPhotoStepView(
            step: .selfie,
            viewModel: viewModel
        )
    }
}
