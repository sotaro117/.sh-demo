import SwiftUI
import Combine

struct OtpFormFieldView: View {
    @EnvironmentObject var authService: AuthService
    @State private var otpCode: String = ""
    @State private var isVerifying = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var email: String?
    var phone: String?
    var isInitialSignin: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(email != nil ? "Verify your Email Address" : "Verify your phone number")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter the 6-digit code we sent to \(email ?? phone ?? "")")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Single TextField for better auto-fill support
            TextField("", text: $otpCode)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .tracking(8) // Space out the characters
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(otpCode.count == 6 ? Color.green : Color.gray.opacity(0.5), lineWidth: 2)
                )
                .focused($isTextFieldFocused)
                .onChange(of: otpCode) { _, newValue in
                    // Limit to 6 digits
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(6))
                    if filtered != newValue {
                        otpCode = filtered
                    }
                    
                    // Auto-verify when 6 digits are entered
                    if filtered.count == 6 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            Task {
                                await processOtp()
                            }
                        }
                    }
                }
            
            if !authService.errorMsg.isEmpty {
                Text(authService.errorMsg)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            Button {
                Task {
                    await processOtp()
                }
            } label: {
                if isVerifying {
                    HStack {
                        ProgressView()
                        Text("Verifying...")
                    }
                    .font(.caption)
                } else {
                    Text("Verify")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(otpCode.count == 6 && !isVerifying ? Color.black : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(otpCode.count != 6 || isVerifying)
        }
        .padding()
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func processOtp() async {
        guard otpCode.count == 6 else { return }
        
        isVerifying = true
        
        if let email = email {
            if isInitialSignin {
                await authService.verifyOtpEmail(email: email, token: otpCode)
            } else {
                await authService.updateEmail(email: email, token: otpCode)
            }
            
        } else if let phone = phone {
            if isInitialSignin {
                await authService.verifyOtpPhone(phone: phone, token: otpCode)
            } else {
                await authService.updatePhone(phone: phone, token: otpCode)
            }
        }
        
        isVerifying = false
        
        if case .success = authService.result, !isInitialSignin{
            dismiss()
            dismiss()
        }
    }
}
