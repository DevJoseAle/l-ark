//
//  MyCampaignView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 15-09-25.
//

import SwiftUI

struct MyCampaignView: View {
    private var supabase = SupabaseClientManager.shared.client
    @State private var images: [CampaignImage] = []
    var body: some View {
        VStack(alignment: .leading) {
            CampaignImageSlider(images: images)
                .frame(height: 320)
            Spacer()
            Spacer()

        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(Text("Mi Campaña"))
        .toolbar {
            HStack(alignment: .center) {
                Button(
                    action: {

                    },
                    label: {
                        HStack(alignment: .center) {

                            Text("Editar")
                            Image(systemName: "pencil")
                        }
                    }
                )
            }
        }
        .onAppear {
            Task {
                await getImages()
            }

        }

    }

    private func getImages() async {
        let id = "200e088f-1a65-45e0-afef-067afc5cb4c7"
        do {
            let cImages: [CampaignImage] =
                try await supabase
                .from("campaign_images")
                .select()
                .eq("campaign_id", value: id)
                .order("display_order", ascending: true)
                .execute()
                .value

            print(cImages)
            images = cImages
        } catch let e {
            print(e)
        }

    }

}

#Preview {
    MyCampaignView()
}

struct CampaignImageSlider: View {
    var images: [CampaignImage]
    @State var imageID = 0
    var body: some View {
        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<images.count, id: \.self) { index in
                        let image = images[index]
                        VStack {
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

                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.animated, axis: .horizontal) {
                            content,
                            phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0)
                        }

                    }

                }

            }
            .scrollTargetBehavior(.paging)
            
            ScrollIndicator(
                imageCount: images.count,
                currentImageIndex: imageID
            )
                .position(x: 110, y:110)
        }
    }
}

struct ScrollIndicator: View {
    var imageCount: Int
    var currentImageIndex: Int
    var body: some View {
        HStack{
            ForEach(0..<imageCount, id: \.self){ index in
                let index = currentImageIndex ?? 0
                Image(systemName: "circle.fill")
                    .foregroundStyle(index == currentImageIndex ? Color.blue : Color.gray)
                    
            }
        }
        .padding(.all, 5)
        .background(Color.gray.opacity(0.3))
        
    }
}
