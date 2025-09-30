//import AuthenticationServices
//import GoogleSignIn
//import CryptoKit
//
//@MainActor
//final class AuthenticationViewModel: NSObject, ObservableObject {
//
//    // Guarda el nonce de la sesión actual de Apple
//    private var currentNonce: String?
//    private var appleContinuation: CheckedContinuation<Void, Error>?
//    @Published var user: String? = ""
//    @Published var password: String? = ""
//    @Published var isLoading: Bool = false
//
//
//
//    //MARK: With Mail and PassWord
//
//
//
//    // MARK: - Helpers (MainActor)
//    private func rootViewController() -> UIViewController {
//        UIApplication.shared.connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .flatMap { $0.windows }
//            .first { $0.isKeyWindow }?.rootViewController
//        ?? UIViewController()
//    }
//
//    // MARK: - GOOGLE
//    func signInWithGoogle() async throws {
//        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController())
//
//        guard let idToken = result.user.idToken?.tokenString else {
//            throw URLError(.badServerResponse)
//        }
//        let accessToken = result.user.accessToken.tokenString
//        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
//
//        let authResult = try await Auth.auth().signIn(with: credential)
//        print("✅ Google OK: \(authResult.user.uid)")
//    }
//
//    // MARK: - APPLE (para botón CUSTOM)
//    /// Llama esto desde tu botón custom. Maneja todo el flujo y loguea en Firebase.
//    func signInWithApple() async throws {
//        // 1) Prepara request + nonce
//        let nonce = randomNonceString()
//        currentNonce = nonce
//
//        let request = ASAuthorizationAppleIDProvider().createRequest()
//        request.requestedScopes = [.fullName, .email]
//        request.nonce = sha256(nonce)
//
//        // 2) Lanza el controlador
//        let controller = ASAuthorizationController(authorizationRequests: [request])
//        controller.delegate = self
//        controller.presentationContextProvider = self
//
//        // 3) Espera resultado (con continuation)
//        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
//            self.appleContinuation = cont
//            controller.performRequests()
//        }
//    }
//
//    // MARK: - APPLE (si usas SignInWithAppleButton)
//    /// Úsalo en `onRequest` del SignInWithAppleButton
//    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
//        let nonce = randomNonceString()
//        currentNonce = nonce
//        request.requestedScopes = [.fullName, .email]
//        request.nonce = sha256(nonce)
//    }
//
//    /// Úsalo en `onCompletion` del SignInWithAppleButton
//    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
//        switch result {
//        case .success(let auth):
//            Task { await finishAppleSignIn(from: auth) }
//        case .failure(let error):
//            print("❌ Apple completion error: \(error)")
//        }
//    }
//
//    // MARK: - Internos Apple
//    private func finishAppleSignIn(from authorization: ASAuthorization) async {
//        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
//            appleContinuation?.resume(throwing: URLError(.badServerResponse)); appleContinuation = nil
//            return
//        }
//        guard let tokenData = credential.identityToken,
//              let idToken = String(data: tokenData, encoding: .utf8),
//              let nonce = currentNonce else {
//            appleContinuation?.resume(throwing: URLError(.badServerResponse)); appleContinuation = nil
//            return
//        }
//
//        let credentialFirebase = OAuthProvider.appleCredential(
//            withIDToken: idToken,
//            rawNonce: nonce,
//            fullName: credential.fullName
//        )
//
//        do {
//            let result = try await Auth.auth().signIn(with: credentialFirebase)
//            print("✅ Apple/Firebase OK: \(result.user.uid)")
//            appleContinuation?.resume(returning: ())
//        } catch {
//            appleContinuation?.resume(throwing: error)
//        }
//        appleContinuation = nil
//    }
//
//    // MARK: - Helpers nonce
//    private func randomNonceString(length: Int = 32) -> String {
//        precondition(length > 0)
//        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//        var result = ""
//        var remaining = length
//
//        while remaining > 0 {
//            var random: UInt8 = 0
//            let err = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
//            if err != errSecSuccess { fatalError("Unable to generate nonce.") }
//            if random < charset.count {
//                result.append(charset[Int(random) % charset.count])
//                remaining -= 1
//            }
//        }
//        return result
//    }
//
//    private func sha256(_ input: String) -> String {
//        let data = Data(input.utf8)
//        let hashed = SHA256.hash(data: data)
//        return hashed.map { String(format: "%02x", $0) }.joined()
//    }
//}
//
//// MARK: - Delegates (aislados al MainActor por la clase)
//extension AuthenticationViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
//
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        UIApplication.shared.connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .flatMap { $0.windows }
//            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
//    }
//
//    func authorizationController(controller: ASAuthorizationController,
//                                 didCompleteWithAuthorization authorization: ASAuthorization) {
//        Task { await finishAppleSignIn(from: authorization) }
//    }
//
//    func authorizationController(controller: ASAuthorizationController,
//                                 didCompleteWithError error: Error) {
//        appleContinuation?.resume(throwing: error)
//        appleContinuation = nil
//        print("❌ Apple auth error: \(error)")
//    }
//}
import Supabase
import SwiftUI
@MainActor
final class AuthenticationViewModel: ObservableObject {
    enum AuthSteps: Equatable {
        case enterEmail
        case codeSent(exist: Bool)
        case verifying
        case loggedIn
        case error(String)
    }
    @Published var step: AuthSteps = .enterEmail
    @Published var code: String = ""
    @Published var email: String = ""
    @Published var isEmailValid = false
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var openModal: Bool = false
    @Published var loginError: Bool = false
    @Published var isChecked: Bool = false
    @Published var userExist: Bool = false
    @Published var resendCooldown: Int = 0
    
    private var authStateTask: Task<Void, Never>?
    private var resendTimer: Timer?
    
    private let appState: AppState
    private let supabase: SupabaseClient

    init(
        appState: AppState,
        supabaseClient: SupabaseClient = SupabaseClientManager.shared.client,
    ) {
        self.appState = appState
        self.supabase = supabaseClient
        
        setupAuthStateListener()
    }
    
    

    //MARK: Functions:
    private func setupAuthStateListener() {
        authStateTask = Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .signedIn, .initialSession:
                    if let session = session {
                        appState.setUser(session.user)
                        appState.isLoggedIn = .loggedIn
                    }
                    
                case .signedOut:
                    appState.isLoggedIn = .loggedOut
                    appState.currentUser = nil
                    reset()
                    
                case .userUpdated:
                    if let session = session {
                        appState.setUser(session.user)
                    }
                    
                case .tokenRefreshed:
                    if let session = session {
                        appState.setUser(session.user)
                    }
                    
                case .userDeleted:
                    appState.isLoggedIn = .loggedOut
                    appState.currentUser = nil
                                        
                case .passwordRecovery:
                    print("🔑 Recuperación de contraseña")
                    
                case .mfaChallengeVerified:
                    print("MFA")
                @unknown default:
                    print("⚠️ Evento de auth desconocido")
                }
            }
        }
    }
       
       deinit {
           authStateTask?.cancel()
       }
    func bootstrapSession() async {
        do{
            if let session = try? await supabase.auth.session {
                print(session)
                appState.setUser(session.user)
                appState.isLoggedIn = .loggedIn  // ✅ Asegurar que se marca como loggeado
            } else {
                appState.isLoggedIn = .loggedOut
                appState.currentUser = nil
                
                step = .enterEmail
            }
        }catch{
            try? await supabase.auth.signOut()
                   appState.isLoggedIn = .loggedOut
                   appState.currentUser = nil
                   step = .enterEmail
        }
    }
    
    func checkIfUserExist(_ email: String) async throws {
        let response: UserCheckResponse = try await supabase.functions
            .invoke(
                "check-user-exists",
                options: FunctionInvokeOptions(
                    body: ["email": email]
                )
            )

        self.userExist = response.userExist

    }

    func sendOTP() async {
        guard email.isValidEmail else {
            step = .error("Email inválido")
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signInWithOTP(
                email: email.lowercased(),
                shouldCreateUser: true
            )
            step = .codeSent(exist: self.userExist)
        } catch {
            step = .error(error.localizedDescription)
        }
    }

    func verifyCodeOTP() async {
        guard case let .codeSent(exist) = step else { return }
        guard code.count == 6 else {
            step = .error("El código debe tener 6 dígitos")
            return
        }
        step = .verifying
        isLoading = true
        do {
            let session = try await supabase.auth.verifyOTP(
                email: self.email.lowercased(),
                token: code,
                type: .email
            )
            step = .loggedIn
            appState.setUser(session.user)  // Guardar usuario
            appState.isLoggedIn = .loggedIn
        } catch {
            step = .error(error.localizedDescription)
            loginError = true
        }
        isLoading = false
    }

    func resendOTP() async {
        guard resendCooldown == 0 else { return }
        await sendOTP()
    }

    func reset() {
        email = ""
        code = ""
        step = .enterEmail
        stopResendCooldown()
    }
    private func startResendCooldown(seconds: Int) {
        resendCooldown = seconds
        stopResendCooldown()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] timer in
            guard let self = self else { return }
            if self.resendCooldown > 0 {
                self.resendCooldown -= 1
            } else {
                timer.invalidate()
            }
        }
        RunLoop.main.add(resendTimer!, forMode: .common)
    }

    private func stopResendCooldown() {
        resendTimer?.invalidate()
        resendTimer = nil
        resendCooldown = 0
    }
    
    // ✅ Agregar esta función a AuthenticationViewModel
    func goBackToPreviousStep() {
        switch step {
        case .codeSent:
            step = .enterEmail
            code = "" // Limpiar código
            
        case .verifying:
            step = .codeSent(exist: userExist)
            
        case .error:
            // Dependiendo del contexto, podrías volver a .enterEmail o .codeSent
            step = .enterEmail
            
        default:
            step = .enterEmail
        }
    }
    
    private func performSignOut() async throws {
        try await supabase.auth.signOut()
        
    }
    
    private func clearUserState () {
        reset()
        appState.isLoggedIn = .loggedOut
        appState.currentUser = nil
        
    }
    
    func signOutSupabase ()async{
        self.isLoading = true
        defer {isLoading = false}
        do{
            try await performSignOut()
            clearUserState( )
        }catch{
            step = .error("Error Al cerrar Sesion")
        }
    }
}

struct UserCheckResponse: Decodable {
    let userExist: Bool
}
