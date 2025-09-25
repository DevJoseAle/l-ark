//
//  CampaignImageSlider.swift
//  L-ark
//
//  Created by Jose Rodriguez on 25-09-25.
//

import Foundation
import SwiftUI

struct CampaignImageSlider: View {
    var images: [CampaignImage]
    @State var scrollID: Int?
    var body: some View {
               if !images.isEmpty {
                   ImageSliderContent(images: images, scrollID: $scrollID)
               }else{
                    EmptyImageView()
                }

    }
}

private struct EmptyImageView: View {
    var body: some View {
        VStack {
            Text("No hay Imágenes en esta campaña")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .padding()
    }
}
//MARK: ImageSliderContent
private struct ImageSliderContent: View {
    var images: [CampaignImage]
    @Binding var scrollID: Int?
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<images.count, id: \.self) { index in
                        let image = images[index]
                        VStack {
                            CampaignImageCard(image: image)
                        }

                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.animated, axis: .horizontal) {
                            content,
                            phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.6)
                        }

                    }

                }.scrollTargetLayout()

            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollID)
            if images.count > 1 {
                ScrollIndicator(
                    imageCount: images.count,
                    currentImageIndex: scrollID
                )
            }

        }
    }
}
//MARK: CampaignImageCard
private struct CampaignImageCard: View {
    let image: CampaignImage
    var body: some View {
        AsyncImage(url: URL(string: image.imageUrl)) {
            image in
            image
                .resizable()
                .scaledToFill()

                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
                .padding()

        } placeholder: {
            ProgressView()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
    }
}

//MARK: SCroll indicator
private struct ScrollIndicator: View {
    var imageCount: Int
    var currentImageIndex: Int?
    var body: some View {
        HStack {
            ForEach(0..<imageCount, id: \.self) { indicator in
                let index = currentImageIndex ?? 0
                Image(systemName: "circle.fill")
                    .foregroundStyle(
                        indicator == index ? Color.customWhite : Color.gray
                    )

            }
        }
        .padding(.all, 5)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(15)
    }
}
