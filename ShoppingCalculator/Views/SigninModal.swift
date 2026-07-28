import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "SigninModal")

struct SigninModal: View {
    @EnvironmentObject var authService: AuthService
    @Binding var showModal: Bool
    @State private var signinMethod: SigninScreen?

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Image(.signup)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding()
                    .overlay {
                        Circle()
                            .fill(.purple.opacity(0.1))
                            .stroke(.primary.opacity(0.2), lineWidth: 1)
                    }
                    .padding(.vertical)
                
                Text("Welcome to .sh!")
                    .font(.title2)
                    .padding(.bottom, 4)
                Text("Please sign in below")
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Button {
                signinMethod = .phone
                logger.debug("Opening phone sign-in")
            } label: {
                Text("Continue with Phone Number")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color(.systemBackground))
                    .padding()
                    .background(.primary)
                    .cornerRadius(25)
            }

            Button {
                signinMethod = .email
                logger.debug("Opening email sign-in")
            } label: {
                Text("Continue with Email")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color(.systemBackground))
                    .padding()
                    .background(.primary)
                    .cornerRadius(25)
            }

            AppleSignInButton(authService: authService)
        }
        .padding()
        .fullScreenCover(item: $signinMethod) { method in
            SigninDetailModal(
                signinMethod: method,
                isInitialSignin: true
            )
            .presentationDragIndicator(.visible)
        }
        .navigationTitle("Sign up")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum SigninScreen: String, Identifiable {
    case email
    case phone

    var id: String { rawValue }
}

// MARK: - Custom Apple Sign In Button
struct AppleSignInButton: View {
    @StateObject private var coordinator: AppleSignInCoordinator
    
    init(authService: AuthService) {
        self._coordinator = StateObject(wrappedValue: AppleSignInCoordinator(authService: authService))
    }
    
    var body: some View {
        Button(action: {
            coordinator.signInWithApple()
        }) {
            HStack {
                Image(systemName: "applelogo")
                    .font(.title2)
                    .foregroundStyle(.primary)

                if coordinator.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(0.8)
                } else {
                    Text("Continue with Apple")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemFill))
            .cornerRadius(25)
        }
        .disabled(coordinator.isLoading)
        .alert("Sign In Error", isPresented: .constant(!coordinator.errorMessage.isEmpty)) {
            Button("OK") {
                coordinator.errorMessage = ""
            }
        } message: {
            Text(coordinator.errorMessage)
        }
    }
}
