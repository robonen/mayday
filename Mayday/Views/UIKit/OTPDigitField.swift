import SwiftUI
import UIKit

struct OTPDigitField: UIViewRepresentable {
    @Binding var text: String
    let isFocused: Bool
    let onFocus: () -> Void
    let onInsert: () -> Void
    let onDeleteWhenEmpty: () -> Void
    let onPaste: ([String]) -> Void

    func makeUIView(context: Context) -> BackspaceAwareTextField {
        let textField = BackspaceAwareTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        textField.textContentType = .oneTimeCode
        textField.onDeleteWhenEmpty = {
            onDeleteWhenEmpty()
        }
        textField.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: BackspaceAwareTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if isFocused && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: OTPDigitField

        init(parent: OTPDigitField) {
            self.parent = parent
        }

        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            parent.onFocus()
            return true
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onFocus()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty {
                return true
            }

            let digits = string.filter { $0.isNumber }
            guard !digits.isEmpty else {
                return false
            }

            if digits.count > 1 {
                parent.onPaste(digits.map(String.init))
                return false
            }

            parent.text = String(digits.prefix(1))
            parent.onInsert()
            return false
        }

        @objc
        func editingChanged(_ textField: UITextField) {
            let digitsOnly = (textField.text ?? "").filter { $0.isNumber }
            let single = String(digitsOnly.prefix(1))
            if textField.text != single {
                textField.text = single
            }
            parent.text = single
        }
    }
}

final class BackspaceAwareTextField: UITextField {
    var onDeleteWhenEmpty: (() -> Void)?

    override func deleteBackward() {
        let wasEmpty = (text ?? "").isEmpty
        super.deleteBackward()
        if wasEmpty {
            onDeleteWhenEmpty?()
        }
    }
}
