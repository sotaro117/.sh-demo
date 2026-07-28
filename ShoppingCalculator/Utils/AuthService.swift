import Foundation
import Supabase
import SwiftData
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "AuthService")

@MainActor
class AuthService: ObservableObject {
    // MARK: props
    @Published var signedIn: Bool = false
    @Published var errorMsg = ""
    @Published var result: Result<Void, Error>?
    
    // MARK: - OTP send email
    func sendOtpToEmail(email: String) async {
        errorMsg = ""
        result = nil
        
        do {
            try await supabase.auth.signInWithOTP(email: email)
            result = .success(())
        } catch {
            errorMsg = error.localizedDescription
            result = .failure(error)
        }
    }

    // MARK: - OTP email verification
    func verifyOtpEmail(email: String, token: String) async {
        errorMsg = ""
        result = nil
        
        do {
            try await supabase.auth.verifyOTP(email: email, token: token, type: .email)
            
            if supabase.auth.currentSession != nil {
                signedIn = true
            }
            
            result = .success(())
        } catch {
            errorMsg = error.localizedDescription
            result = .failure(error)
        }
    }
    
    // MARK: Request update email
    func requestEmailChange(email: String) async {
        errorMsg = ""
        result = nil
         
        do {
            // This sends OTP to the NEW email for verification
            try await supabase.auth.update(user: UserAttributes(email: email))
            result = .success(())
            logger.info("Email change OTP sent")
        } catch {
            errorMsg = "Failed to send email change request: \(error.localizedDescription)"
            result = .failure(error)
            logger.error("Email change request failed: \(error)")
        }
    }
    
    // MARK: - Update email
    func updateEmail(email: String, token: String) async {
        errorMsg = ""
        result = nil
        
        do {
            try await supabase.auth.verifyOTP(email: email, token: token, type: .emailChange)
            result = .success(())
        } catch {
            errorMsg = error.localizedDescription
            result = .failure(error)
        }
    }
    
    // MARK: - OTP send phone number
    func sendOtpToPhone(phone: String) async {
        errorMsg = ""
        result = nil
        
        do {
            try await supabase.auth.signInWithOTP(phone: phone)
            result = .success(())
        } catch {
            logger.error("OTP send to phone failed: \(error)")
            errorMsg = error.localizedDescription
            result = .failure(error)
        }
    }

    // MARK: - OTP phone number verification
    func verifyOtpPhone(phone: String, token: String) async {
        errorMsg = ""
        result = nil
        
        do {
            try await supabase.auth.verifyOTP(phone: phone, token: token, type: .sms)
            
            if supabase.auth.currentSession != nil {
                signedIn = true
            }
            
            result = .success(())
        } catch {
            errorMsg = error.localizedDescription
            result = .failure(error)
        }
    }
    
    // MARK: - Request phone number update
    func requestPhoneChange(phone: String) async {
        errorMsg = ""
        result = nil
        
        do {
            // This sends OTP to the NEW phone for verification
            try await supabase.auth.update(user: UserAttributes(phone: phone))
            result = .success(())
            logger.info("Phone change OTP sent")
        } catch {
            errorMsg = "Failed to send phone change request: \(error.localizedDescription)"
            result = .failure(error)
            logger.error("Phone change request failed: \(error)")
        }
    }
    
    // MARK: - OTP verify updated phone number
    func updatePhone(phone: String, token: String) async {
        errorMsg = ""
        result = nil
        
        do {
            try await supabase.auth.verifyOTP(phone: phone, token: token, type: .phoneChange)
            result = .success(())
        } catch {
            errorMsg = error.localizedDescription
            result = .failure(error)
        }
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(idToken: String, nonce: String?) async {
        do {
            try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            
            // Ensure user profile exists
            await isProfileExist()
            
            signedIn = true
            
        } catch {
            errorMsg = "Apple sign in failed: \(error.localizedDescription)"
        }
    }

    
    // MARK: - Sign Out
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            signedIn = false
            result = .success(())
        } catch {
            result = .failure(error)
        }
    }
    
    // MARK: - Soft delete user
    @MainActor
    func deleteUser(modelContext: ModelContext) async {
        do {
            let currentUser = try await supabase.auth.user()
            
            try await supabase
                .from("profiles")
                .update([
                    "deleted_at": Date().ISO8601Format(),
                    "status": Profile.Status.deleted.rawValue
                ])
                .eq("id", value: currentUser.id)
                .execute()
            
            await deleteLocalUserData(userId: currentUser.id.uuidString, modelContext: modelContext)
            
            try await supabase.auth.signOut()
            
            signedIn = false
            
        } catch {
            errorMsg = error.localizedDescription
            logger.error("Delete user failed: \(error)")
        }
    }
}

// MARK: - Updated AuthService
extension AuthService {
    func isProfileExist() async {
        guard let currentUser = supabase.auth.currentUser else { return }
        
        do {
            // Try to fetch existing user profile
            let _: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value
            
            logger.debug("User profile already exists")
            
        } catch {
            // User profile doesn't exist, create it
            do {
                let newProfile = Profile(
                    id: currentUser.id,
                    username: currentUser.email ?? currentUser.phone ?? "User",
                    preference: "default"
                )
                
                try await supabase
                    .from("profiles")
                    .insert(newProfile)
                    .execute()
                
                logger.info("Created new user profile")
                
            } catch {
                logger.error("Failed to create user profile: \(error)")
            }
        }
    }
    
    // MARK: Delete local data
    @MainActor
    private func deleteLocalUserData(userId: String, modelContext: ModelContext) async {
        do {
            let purchaseDescriptor = FetchDescriptor<Purchase>(
                predicate: #Predicate<Purchase> { purchase in
                    purchase.userId == userId
                }
            )
            
            let reportDescriptor = FetchDescriptor<Report>(
                predicate: #Predicate<Report> { report in
                    report.userId == userId
                }
            )
            
            let mealPlanDescriptor = FetchDescriptor<MealPlan>(
                predicate: #Predicate<MealPlan> { mealPlan in
                    mealPlan.userId == userId
                }
            )
            
            let purchases = try modelContext.fetch(purchaseDescriptor)
            let reports = try modelContext.fetch(reportDescriptor)
            let mealPlans = try modelContext.fetch(mealPlanDescriptor)
            
            for purchase in purchases {
                modelContext.delete(purchase)
            }
            
            for report in reports {
                modelContext.delete(report)
            }
            
            for mealPlan in mealPlans {
                modelContext.delete(mealPlan)
            }
            
            try modelContext.save()
            
            logger.info("Local user data deleted")
        } catch {
            logger.error("Failed to delete local data: \(error)")
        }
    }
}
