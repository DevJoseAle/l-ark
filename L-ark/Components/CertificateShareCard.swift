//
//  CertificateShare.swift
//  L-ark
//
//  Crea una tarjeta de “Certificado Digital”, la renderiza a UIImage
//  (1080x1350 para RRSS) y permite compartirla con UIActivityViewController.
//  Incluye wrapper escalable para previews/UI y Previews listas.
//

import SwiftUI

// MARK: - Modelo de datos
struct CertificateData: Sendable, Hashable {
    var title: String = "CERTIFICADO DIGITAL"
    var personName: String
    var protectorCode: String   // ej: "#847"
    var date: Date
    var amountCLP: Int
    var beneficiariesCount: Int
    var filesCount: Int
    var brandTitle: String = "l-ark app"
    var brandSubtitle: String = "Herencia Digital"
}

// MARK: - Formateadores (CLP y fecha)
enum CLPLocaleFormatter {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "es_CL")
        f.numberStyle = .currency
        f.currencyCode = "CLP"
        f.maximumFractionDigits = 0
        return f
    }()
    static func formatCLP(_ amount: Int) -> String {
        CLPLocaleFormatter.currency.string(from: NSNumber(value: amount)) ?? "CLP $\(amount)"
    }
}

enum DateESFormatter {
    static let long: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_CL")
        df.dateFormat = "d 'de' MMMM, yyyy"
        return df
    }()
    static func format(_ date: Date) -> String { long.string(from: date) }
}

// MARK: - Vista principal (canvas a tamaño real RRSS)
struct CertificateShareCard: View {
    let data: CertificateData
    let canvasSize = CGSize(width: 1080, height: 1350) // IG portrait

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 28) {
                // Encabezado
                Text(data.title)
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .kerning(1)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)

                // Texto descriptivo
                VStack(spacing: 10) {
                    Text("Este documento certifica")
                    Text("que \(data.personName.uppercased()) ha")
                    Text("asegurado su legado")
                    Text("digital para sus seres")
                    Text("queridos")
                }
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)

                Divider().padding(.horizontal, 40)

                // Detalles
                VStack(spacing: 22) {
                    HStack {
                        Label("Protector \(data.protectorCode)", systemImage: "shield.checkerboard")
                        Spacer()
                        Text(DateESFormatter.format(data.date))
                    }
                    HStack {
                        Label(CLPLocaleFormatter.formatCLP(data.amountCLP), systemImage: "coloncurrencysign.circle")
                        Spacer()
                        Text("\(data.beneficiariesCount) beneficiarios")
                    }
                    HStack {
                        Label("\(data.filesCount) archivos protegidos", systemImage: "lock.doc")
                        Spacer()
                        Text("Código verificado")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .padding(.horizontal, 50)

                Spacer(minLength: 12)

                // Marca
                VStack(spacing: 6) {
                    Text(data.brandTitle)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text(data.brandSubtitle)
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(60)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .background(
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .strokeBorder(.primary.opacity(0.12), lineWidth: 6)
                    .background(
                        RoundedRectangle(cornerRadius: 48, style: .continuous)
                            .fill(.background)
                            .shadow(radius: 24, y: 12)
                    )
                    .padding(24)
            )
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .preferredColorScheme(.light) // Forzar claro para RRSS
    }
}

// MARK: - Render a UIImage (iOS 17+ con fallback 15/16)
@MainActor
func renderCertificateImage(
    data: CertificateData,
    size: CGSize = CGSize(width: 1080, height: 1350)
) -> UIImage {
    let view = CertificateShareCard(data: data)
        .frame(width: size.width, height: size.height)

    if #available(iOS 17.0, *) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = true
        return renderer.uiImage ?? UIImage()
    } else {
        // Fallback para iOS 15/16
        let hosting = UIHostingController(rootView: view)
        hosting.view.bounds = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Share Sheet nativo
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Wrapper escalable para UI/Previews
/// Renderiza el canvas 1080x1350 pero escalado al `targetWidth` que le pases.
struct CertificateCardScaled: View {
    let data: CertificateData
    let targetWidth: CGFloat

    private let canvasSize = CGSize(width: 1080, height: 1350)

    var body: some View {
        let aspect = canvasSize.height / canvasSize.width
        let targetHeight = targetWidth * aspect
        let scale = targetWidth / canvasSize.width

        CertificateShareCard(data: data)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: targetWidth, height: targetHeight, alignment: .topLeading)
            .clipped()
    }
}

// MARK: - Ejemplo de uso en pantalla
struct ShareCertificateExampleView: View {
    @State private var showShare = false
    @State private var sharedImage: UIImage?

    let exampleData = CertificateData(
        personName: "JOSÉ BRANCOLI",
        protectorCode: "#847",
        date: {
            var comps = DateComponents()
            comps.year = 2025; comps.month = 10; comps.day = 3
            return Calendar(identifier: .gregorian).date(from: comps) ?? Date()
        }(),
        amountCLP: 15_000_000,
        beneficiariesCount: 3,
        filesCount: 47
    )

    var body: some View {
        VStack(spacing: 24) {
            Text("Previsualización")
                .font(.title2.bold())

            // Vista escalada para caber en la pantalla/preview
            CertificateCardScaled(data: exampleData, targetWidth: 340)

            Button {
                let img = renderCertificateImage(data: exampleData) // PNG nítido 1080x1350
                self.sharedImage = img
                self.showShare = true
            } label: {
                Label("Compartir Certificado", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .sheet(isPresented: $showShare) {
            if let img = sharedImage { ShareSheet(items: [img]) }
        }
        .padding()
    }
}

// MARK: - Previews
#if DEBUG
struct CertificateShare_Previews: PreviewProvider {

    static let exampleData = CertificateData(
        personName: "JOSÉ BRANCOLI",
        protectorCode: "#847",
        date: {
            var comps = DateComponents()
            comps.year = 2025; comps.month = 10; comps.day = 3
            return Calendar(identifier: .gregorian).date(from: comps) ?? Date()
        }(),
        amountCLP: 15_000_000,
        beneficiariesCount: 3,
        filesCount: 47
    )

    static var previews: some View {
        Group {
            // Pantalla de ejemplo (con botón de compartir)
            ShareCertificateExampleView()
                .previewDisplayName("Example Screen – Light")
                .preferredColorScheme(.light)
                .previewDevice("iPhone 15 Pro")

            ShareCertificateExampleView()
                .previewDisplayName("Example Screen – Dark")
                .preferredColorScheme(.dark)
                .previewDevice("iPhone 15 Pro")

            // Tarjeta escalada (ligero para el canvas)
            CertificateCardScaled(data: exampleData, targetWidth: 360)
                .previewDisplayName("Card Scaled – Light")
                .preferredColorScheme(.light)

            CertificateCardScaled(data: exampleData, targetWidth: 360)
                .previewDisplayName("Card Scaled – Dark")
                .preferredColorScheme(.dark)

            // (Opcional) Tamaño real 1080x1350 — puede ser pesado
            CertificateShareCard(data: exampleData)
                .frame(width: 1080, height: 1350)
                .previewDisplayName("Card Full 1080×1350")
                .preferredColorScheme(.light)
        }
    }
}
#endif
