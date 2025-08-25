import SwiftUI

struct DonationHomeTile: View {
    var initials: String
    var donatorName: String
    var donationTime: String
    var donationAmount: String
    
    var body: some View {
        HStack(spacing: ArkUI.Spacing.m) {
            ZStack{
                Text(initials)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundStyle(Color.customWhite)
            }
            .frame(width: 50, height: 50)
            .background(Color.cardLightBlue)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(donatorName)
                    .font(.system(size: 18, weight: .medium))
                Text(donationTime)
                    .font(.system(size: 13, weight: .regular))
            }
            
            Spacer()
            Text("CLP: \(donationAmount)")
                .font(.system(size: 15, weight: .medium))
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(.horizontal)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview{
    DonationHomeTile(initials: "JA", donatorName: "José Rodriguez", donationTime:"01/09/25", donationAmount: "50.000")
    DonationHomeTile(initials: "JA", donatorName: "José Rodriguez", donationTime:"01/09/25", donationAmount: "50.000")
    DonationHomeTile(initials: "JA", donatorName: "José Rodriguez", donationTime:"01/09/25", donationAmount: "50.000")
    DonationHomeTile(initials: "JA", donatorName: "José Rodriguez", donationTime:"01/09/25", donationAmount: "50.000")
    
}
