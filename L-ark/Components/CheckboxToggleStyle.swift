//
//  CheckboxToggleStyle.swift
//  L-ark
//
//  Created by Jose Rodriguez on 09-09-25.
//

import Foundation
import SwiftUI
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(
                systemName: configuration.isOn
                    ? "checkmark.square.fill" : "square"
            )
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(configuration.isOn ? .accentColor : .gray)
            configuration.label
                .font(.body)
        }
        .frame(minHeight: 44)  // accesibilidad
        .onTapGesture {
            withAnimation { configuration.isOn.toggle() }
        }
    }
}
