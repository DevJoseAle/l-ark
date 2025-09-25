//
//  ToolbarCustom.swift
//  L-ark
//
//  Created by Jose Rodriguez on 25-09-25.
//

import Foundation
import SwiftUI

struct ToolbarEditButton: View {
   
    let text : String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Button(
                action: action,
                label: {
                    HStack(alignment: .center) {
                        Text(text)
                        Image(systemName: icon)
                    }
                }
            )
        }
    }
}
