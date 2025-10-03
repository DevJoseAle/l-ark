//
//  CampaignStatus.swift
//  L-ark
//
//  Created by Jose Rodriguez on 02-10-25.
//
import SwiftUI

struct CampaignStatusLabel: View {
    let status: CampaignStatus
    init(_ status: CampaignStatus){
        self.status = status
    }
    private var labelBackground: Color {
        switch status {
        case .active:
            return Color.green.opacity(0.7)
        case .cancelled:
            return Color.red.opacity(0.7)
        case .draft:
            return Color.purple.opacity(0.7)
        case .completed:
            return  .customWhite.opacity(0.8)
        case .paused:
            return Color.yellow.opacity(0.7)
        }
    }
    
    private var labelText: String {
        switch status {
        case .draft:
            "En revision"
        case .active:
            "Activa"
        case .paused:
            "Pausada"
        case .completed:
            "Finalizada"
        case .cancelled:
            "Cancelada"
        }
    }
    var body: some View{
//        switch status {
//        case .active:
//            Text("Activo")
//        }
        Text("\(labelText.capitalized)")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.customWhite.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.horizontal, 3)
            .background(labelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
#Preview {
    CampaignStatusLabel(.active)
}
