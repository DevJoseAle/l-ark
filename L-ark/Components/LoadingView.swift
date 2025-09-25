//
//  LoadingView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 25-09-25.
//

import Foundation
import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
