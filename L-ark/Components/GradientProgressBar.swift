import SwiftUI

struct GradientProgressBar: View {
    var value: CGFloat  // 0...1
    var height: CGFloat = 14

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: height/2)
                .fill(Color.gray.opacity(0.15))

            GeometryReader { geo in
                let w = geo.size.width * max(0, min(value, 1))
                RoundedRectangle(cornerRadius: height/2)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray, Color.blue],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: w)
            }
        }
        .frame(height: height)
        .overlay(
            Text("\(Int(value * 100))%")
                .font(.caption).bold()
                .foregroundColor(.customWhite)
                .padding(.horizontal, 6),
            alignment: .center
        )
    }
}


#Preview {
    GradientProgressBar(value: 0.2)
}
