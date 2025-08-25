//
//  IconTextField.swift
//  L-ark
//
//  Created by Jose Rodriguez on 25-08-25.
//

import SwiftUI
enum InputBackgroundColor {
    case white
    case custom(Color)
    
    var color: Color {
        switch self {
        case .white:
            return Color.customWhite
        case .custom(let c):
            return c
        }
    }
}

struct IconTextField: View {
    var rightIcon: String?
    var leftIcon: String?
    var placeholder: String
    var isPasswordField: Bool? = false
    var isSecureText: Bool? = false
    var inputbackground: InputBackgroundColor = .white
    @State private var isSecureActive: Bool = false
    @FocusState private var isFocused: Bool
    var keyboardType: UIKeyboardType = .default
    
    @Binding var text: String
    var body: some View {
        HStack{
            Image(systemName: rightIcon ?? "")
                .foregroundStyle(Color.customDarkGray)
            
            ZStack(alignment: .leading) {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.customDarkGray))
                    .keyboardType(keyboardType)
                    .opacity(isSecureActive ? 0 : 1)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    

                SecureField(placeholder, text: $text)
                    .opacity(isSecureActive ? 1 : 0)
                    .keyboardType(keyboardType)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
            }
            .frame(height: 44)
            .animation(.none, value: isSecureActive)

            if isPasswordField == true {
                Button(action: {
                    isSecureActive.toggle()
                }){
                    Image(systemName: isSecureActive ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .regular))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.customDarkGray)
                        .contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
            }
            }
     
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(inputbackground.color)
        .cornerRadius(18)
        .padding(.horizontal)
        
        
    }
}

#Preview {
    IconTextField(
        rightIcon: "at",
        leftIcon: "person.circle",
        placeholder: "Email",
        isPasswordField: true,
        isSecureText: true,
//        inputbackground: .custom(Color.red),
        text: .constant("")
    )
}
