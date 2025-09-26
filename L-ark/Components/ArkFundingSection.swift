import SwiftUI

struct ArkFundingSection: View {
    let campaign: Campaign
    @State private var showDetails = false
    
    // MARK: - Computed Properties
    private var progressPercentage: Double {
        guard let goal = campaign.goalAmount, goal > 0 else { return 0 }
        return min(Double(campaign.totalRaised) / Double(goal), 1.0)
    }
    
    private var progressText: String {
        let percentage = Int(progressPercentage * 100)
        return "¡Llevas un \(percentage)% de tu meta!"
    }
    
    private var formattedTotal: String {
        showDetails ? Formatters.formatAmount(campaign.totalRaised) : "---.---"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ArkUI.Spacing.s) {
            totalRaisedSection
            progressSection
            actionButtons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, ArkUI.Spacing.m)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: ArkUI.Radius.card))
    }
}

// MARK: - View Components
private extension ArkFundingSection {
    
    var totalRaisedSection: some View {
        VStack(alignment: .leading, spacing: ArkUI.Spacing.s) {
            Text("Total Recaudado:")
                .foregroundStyle(.customWhite)
                .font(.system(size: 18, weight: .bold))
                .padding()

            HStack(alignment: .firstTextBaseline) {
                Text("CLP:")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.customWhite)
                
                Text(formattedTotal)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color.customWhite.opacity(0.9))
                
                Spacer()
                
                visibilityToggle
            }
            .padding(.horizontal, ArkUI.Spacing.m)
        }
    }
    
    var visibilityToggle: some View {
        Button {
            showDetails.toggle()
        } label: {
            Image(systemName: showDetails ? "eye.slash" : "eye")
                .foregroundStyle(.customWhite)
                .imageScale(.medium)
                .padding(8)
                .background(.customWhite.opacity(0.3), in: Circle())
        }
    }
    
    var progressSection: some View {
        VStack(alignment: .leading, spacing: ArkUI.Spacing.s) {
            Text("Tu meta:")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.customWhite)

            HStack {
                Text("CLP: 0")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.customWhite)
                
                Spacer()
                
                if let goalAmount = campaign.goalAmount {
                    Text("CLP: \(Formatters.formatAmount(goalAmount))")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color.customWhite.opacity(0.9))
                }
            }
            
            GradientProgressBar(value: progressPercentage)
            
            Text(progressText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.customWhite.opacity(0.9))
        }
        .padding(ArkUI.Spacing.m)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.customWhite.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, ArkUI.Spacing.m)
    }
    
    var actionButtons: some View {
        VStack(alignment: .center, spacing: ArkUI.Spacing.s) {
            ArkCapsuleButton(
                title: "Ver mi Campaña",
                systemImage: "list.bullet.clipboard",
                destination: MyCampaignView()
            )
            
            HStack(spacing: ArkUI.Spacing.m) {
                ArkCapsuleButton(
                    title: "Compartir",
                    systemImage: "square.and.arrow.up"
                ) {
                    shareCampaign()
                }
                
                ArkCapsuleButton(
                    title: "Enviar Link",
                    systemImage: "link"
                ) {
                    sendDonorLink()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ArkUI.Spacing.m)
    }
    
    var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.cardMediumBlue,
                Color.cardDarkBlue,
                Color.cardLightBlue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Actions
private extension ArkFundingSection {
    func shareCampaign() {
        // Implementar lógica de compartir
        print("Compartir campaña: \(campaign.title)")
    }
    
    func sendDonorLink() {
        // Implementar lógica de enviar link
        print("Enviar link de donación")
    }
}

// MARK: - Separate Component: ArkCapsuleButton
struct ArkCapsuleButton: View {
    let title: String
    let systemImage: String
    let fontSize: CGFloat
    let action: (() -> Void)?
    let destination: AnyView?
    
    // Action initializer
    init(
        title: String,
        systemImage: String,
        fontSize: CGFloat = 15,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.fontSize = fontSize
        self.action = action
        self.destination = nil
    }
    
    // Navigation initializer
    init<Destination: View>(
        title: String,
        systemImage: String,
        fontSize: CGFloat = 15,
        destination: Destination
    ) {
        self.title = title
        self.systemImage = systemImage
        self.fontSize = fontSize
        self.action = nil
        self.destination = AnyView(destination)
    }
    
    var body: some View {
        if let destination = destination {
            NavigationLink(destination: destination) {
                buttonContent
            }
            .buttonStyle(.plain)
        } else if let action = action {
            Button(action: action) {
                buttonContent
            }
        }
    }
    
    private var buttonContent: some View {
        HStack(spacing: ArkUI.Spacing.s) {
            Text(title)
            Image(systemName: systemImage)
        }
        .frame(maxWidth: .infinity, minHeight: 30)
        .font(.system(size: fontSize, weight: .medium))
        .padding(.horizontal, ArkUI.Spacing.l)
        .padding(.vertical, ArkUI.Spacing.m)
        .background(Color.customWhite, in: Capsule())
        .foregroundStyle(.black)
        .contentShape(Capsule())
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ArkFundingSection(campaign: Campaign.mock)
    }
}
