import SwiftUI
import PhoneNumberKit

struct SigninDetailModal: View {
    @Environment(\.dismiss) var dismiss
    var signinMethod: SigninScreen
    @State private var offset: CGFloat = 0
    @State private var email = ""
    @State private var phone = ""
    @EnvironmentObject var authService: AuthService
    @FocusState private var isFocused: Bool
    @State private var emailErrMsg = ""
    @State private var isTouchedEmail = false
    @State private var isTouchedPhone = false
    @State private var isLoading = false
    @State private var showVerification = false
    @State private var authErrorMsg = ""
    @State private var phoneNumberField: PhoneNumberField?
    var isInitialSignin: Bool // initial sign in or update
    
    var phoneNumberUtility = PhoneNumberUtility()
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                VStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.black.opacity(0.2))
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                
                VStack(alignment: .leading) {
                    Group {
                        if isInitialSignin {
                            Text(signinMethod == .email ? "Continue with Email" : "Continue with phone number")
                                .font(.title2)
                                .padding(.vertical, 5)
                        } else {
                            Text(signinMethod == .email ? "Update Email" : "Update phone number")
                                .font(.title2)
                                .padding(.vertical, 5)
                        }
                    }
                    
                    Group {
                        if isInitialSignin {
                            Text(signinMethod == .email ? "Sign in / Sign up with email" : "Sign in / Sign up with phone number")
                                .font(.caption)
                                .padding(.vertical)
                        } else {
                            Text(signinMethod == .email ? "Enter your new email. We will send you a code to verify" : "Update your new phone number. We will send you a code to verify")
                                .font(.caption)
                                .padding(.vertical)
                        }
                    }
                    
                    if signinMethod == .email {
                        TextField("Email", text: $email, onEditingChanged: { began in
                            if !began {isTouchedEmail = true}
                        })
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .overlay (
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isValidEmail(email) || email.isEmpty ? Color.black.opacity(0.5) : Color.red, lineWidth: 2)
                        )
                        
                        if isTouchedEmail && !isValidEmail(email) && !email.isEmpty {
                            Text("Invalid email format")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        phoneNumberField
                            .frame(maxWidth: .infinity, maxHeight: 20)
                            .padding()
                            .overlay (
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isValidPhone(phone) || phone.isEmpty ? Color.black.opacity(0.5) : Color.red, lineWidth: 2)
                            )
                        
                        if !isValidPhone(phone) && !phone.isEmpty {
                            Text("Invalid phone number")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if !authErrorMsg.isEmpty {
                        Text(authErrorMsg)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    Button("Next"){
                        Task {
                            isLoading = true
                            authErrorMsg = ""
                            
                            if signinMethod == .email {
                                if isInitialSignin {
                                    await authService.sendOtpToEmail(email: email)
                                } else {
                                    await authService.requestEmailChange(email: email)
                                }
                            } else {
                                do {
                                    let phoneNumber = try phoneNumberUtility.parse(phone)
                                    let formattedNumber = phoneNumberUtility.format(phoneNumber, toType: .e164)
                                    
                                    if isInitialSignin {
                                        await authService.sendOtpToPhone(phone: formattedNumber)
                                    } else {
                                        await authService.requestPhoneChange(phone: formattedNumber)
                                    }
                                } catch {
                                    authErrorMsg = "Invalid phone number format."
                                    isLoading = false
                                    return
                                }
                            }
                            
                            if case .success = authService.result {
                                showVerification = true
                            } else if case .failure(let error) = authService.result {
                                authErrorMsg = error.localizedDescription
                            }
                            
                            isLoading = false
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid() ? Color(white: 0.2) : Color.black.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.bottom)
                    .disabled(isLoading || !isFormValid())
                }
                .padding()
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showVerification){
                    OtpFormFieldView(
                        email: signinMethod == .email ? email: nil,
                        phone: signinMethod == .phone ? phone: nil,
                        isInitialSignin: isInitialSignin
                    )
                }
                .onAppear {
                    phoneNumberField = PhoneNumberField(phoneNumber: self.$phone)
                }
            }
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Allow dragging in both directions but only apply negative offset for left swipe
                        if isInitialSignin && value.translation.height > 0 {
                            offset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100 // Minimum distance to trigger dismiss
                        
                        if isInitialSignin {
                            if value.translation.height > threshold {
                                // Swipe was far enough to the left, dismiss the modal
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset = geometry.size.height // Animate off screen
                                    dismiss()
                                }
                            } else {
                                // Swipe wasn't far enough, snap back to original position
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset = 0
                                }
                            }
                        }
                    }
            )
        }
    }
        
    func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let predicate = NSPredicate(format:"SELF MATCHES[c] %@", pattern)
        return predicate.evaluate(with: trimmed)
    }
    
    func isValidPhone(_ phone: String) -> Bool {
        return phoneNumberUtility.isValidPhoneNumber(phone)
    }
    
    func isFormValid() -> Bool {
        if signinMethod == .email {
            return !email.isEmpty && isValidEmail(email)
        } else {
            return !phone.isEmpty && isValidPhone(phone)
        }
    }
}
