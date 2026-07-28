import UIKit
import PhoneNumberKit
import SwiftUI

struct PhoneNumberField: UIViewRepresentable {
    @Binding var phoneNumber: String
    let phoneNumberTextField = PhoneNumberTextField()
    
    func makeUIView(context: Context) -> PhoneNumberTextField {
        phoneNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        phoneNumberTextField.withExamplePlaceholder = true
        // phoneNumberTextField.withFlag = true
        phoneNumberTextField.withPrefix = true
        phoneNumberTextField.delegate = context.coordinator
        phoneNumberTextField.textContentType = .telephoneNumber
        phoneNumberTextField.keyboardType = .phonePad
        
        return phoneNumberTextField
    }
    
    func updateUIView(_ uiView: PhoneNumberTextField, context: Context){
        uiView.text = phoneNumber
        uiView.textContentType = .telephoneNumber
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneNumberField
        
        init(_ parent: PhoneNumberField) {
          self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
          if let phoneNumberTextField = textField as? PhoneNumberTextField {
            parent.phoneNumber = phoneNumberTextField.text ?? ""
          }
        }
    }
}
