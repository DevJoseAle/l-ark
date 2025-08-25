//
//  ErrorView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 12-09-25.
//

import Foundation
import SwiftUI

struct ErrorView: View {
    let error: any DisplayableError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(error.userMessage)
                .multilineTextAlignment(.center)
            
            HStack {
                Button("Cerrar") {
                    onDismiss()
                }
                
                if error.isRetryable, let onRetry = onRetry {
                    Button("Reintentar") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}


#Preview {
    ErrorView(error: CampaignError.failed, onRetry:{print("Print1")}, onDismiss: {print("Print1")} )
}
