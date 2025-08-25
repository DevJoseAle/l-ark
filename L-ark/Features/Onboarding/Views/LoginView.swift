import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var vm: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss // ← Agregar esto para navegación
    
    @State private var isChecked = false
    
    var body: some View {
        MainBGContainer {
            VStack(spacing: 16) {
                Spacer()
                Text("Ingresar")
                    .font(.system(size: 30, weight: .bold))
                
                switch vm.step {
                case .enterEmail:
                    IconTextField(
                        rightIcon: "at",
                        placeholder: "Email",
                        text: $vm.email
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    
                    Toggle(
                        "Entiendo que, si no existe una cuenta con este correo, se registrará una nueva",
                        isOn: $isChecked
                    )
                    .toggleStyle(CheckboxToggleStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    let isFormValid = isChecked && vm.email.isValidEmail
                    
                    Button("Continuar") {
                        Task { await vm.sendOTP() }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .disabled(!isFormValid || vm.isLoading)
                    .opacity((isFormValid && !vm.isLoading) ? 1 : 0.5)
                    
                case .codeSent(let exists):
                    Text(
                        exists
                        ? "Ingresa el código para iniciar sesión"
                        : "Ingresa el código para crear tu cuenta"
                    )
                    .font(.subheadline)
                    
                    IconTextField(
                        placeholder: "Ingresa Codigo de 6 digitos",
                        text: $vm.code,
                    )
                    .onChange(of: vm.code) { _, value in
                        if value.count > 6 { vm.code = String(value.prefix(6)) }
                    }
                    
                    HStack {
                        Button("Confirmar código") {
                            Task { await vm.verifyCodeOTP() }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .disabled(vm.code.count != 6 || vm.isLoading)
                        .opacity(
                            (vm.code.count == 6 && !vm.isLoading) ? 1 : 0.5
                        )
                        
                        Button(
                            vm.resendCooldown > 0
                            ? "Reenviar (\(vm.resendCooldown)s)"
                            : "Reenviar"
                        ) {
                            Task { await vm.resendOTP() }
                        }
                        .disabled(vm.resendCooldown > 0 || vm.isLoading)
                    }
                    
                case .verifying:
                    ProgressView("Verificando…")
                    
                case .loggedIn:
                    Text("¡Listo! Sesión iniciada ✅")
                        .font(.headline)
                    // ← No hay botón "Volver" aquí, se maneja automáticamente
                    
                case .error(let msg):
                    Text("Error: \(msg)").foregroundStyle(.red)
                    Button("Volver") {
                        vm.reset()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .foregroundColor(.black)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(.black)
        }
        .toolbar {
            // ✅ Solo mostrar el botón si NO está en .loggedIn
            if vm.step != .loggedIn {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        handleBackButton()
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("Atrás")
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        // ✅ Observar cambios en vm.step para manejar navegación automática
        .onChange(of: vm.step) { _, newStep in
            if case .loggedIn = newStep {
                // Cuando se logea exitosamente, actualizar appState y salir de la vista
                appState.isLoggedIn = .loggedIn
            }
        }
    }
    
    // ✅ Función para manejar el botón "Atrás" correctamente
    private func handleBackButton() {
        switch vm.step {
        case .enterEmail:
            // Si está en el primer paso, salir de LoginView completamente
            vm.reset()
            dismiss() // Esto hace pop de la vista actual
            
        case .codeSent, .verifying, .error:
            // En otros pasos, volver al paso anterior
            vm.goBackToPreviousStep()
            
        case .loggedIn:
            // Este caso no debería ocurrir porque el botón está oculto
            break
        }
    }
}

#Preview {
    LoginView()
}

extension String {
    var isValidEmail: Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(
            with: self
        )
    }
}
