import SwiftUI
import AuthenticationServices
import Supabase
import CryptoKit

// MARK: - Sign in with Apple Coordinator
class AppleSignInCoordinator: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var authService: AuthService
    private var currentNonce: String?
    
    init(authService: AuthService) {
        self.authService = authService
        super.init()
    }
    
    func signInWithApple() {
        isLoading = true
        errorMessage = ""
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        
        // Generate a random nonce for security
        guard let nonce = randomNonceString() else { return }
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            errorMessage = "Failed to generate a secure token. Please try again."
            isLoading = false
            return nil
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            Task {
                await handleAppleSignIn(credential: appleIDCredential)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            self.errorMessage = "Failed to get identity token"
            self.isLoading = false
            return
        }
        
        guard let nonce = currentNonce else {
            self.errorMessage = "Invalid nonce"
            self.isLoading = false
            return
        }
        
        do {
            // Sign in to Supabase using the Apple identity token
            try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nonce // You can add nonce verification here if needed
                )
            )
            
            // Check if we need to create user profile
            await authService.isProfileExist()
            
            self.isLoading = false
            
        } catch {
            self.errorMessage = "Failed to authenticate with Supabase: \(error.localizedDescription)"
            self.isLoading = false
        }
        
        currentNonce = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}


