//
//  MyCampaignView.swift
//  L-ark
//
//  Created by Jose Rodriguez on 15-09-25.
//

import SwiftUI

struct MyCampaignView: View {
    @EnvironmentObject private var campaign: SupabaseCampaignManager
    @StateObject private var vm = MyCampaignViewModel()
    private var supabase = SupabaseClientManager.shared.client
    @State private var images: [CampaignImage] = []
    var body: some View {
        VStack(alignment: .leading) {
            Text("Titulo de la campaña: \(campaign.ownCampaign?.title ?? "No hay un titulo")") 
                .padding(.horizontal)

            content
            Spacer()
            Spacer()
            
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(Text("Mi Campaña"))
        .toolbar {
            ToolbarEditButton(){
                print("desde aqui")
            }
        }
        .task{
            await vm.loadImages()
        }
        
    }
    @ViewBuilder
    private var content: some View{
        switch vm.viewState {
        case .loading, .idle:
            LoadingView()
        case .loaded:
            CampaignImageSlider(images: images)
                .frame(height: 320)
        case .imgError(let displayableError):
            ErrorViewCampaign(error: displayableError){
                Task{}
            }
        }
    }
}


//MARK: TollbarEditBtn
private struct ToolbarEditButton: View {
    
    let action: () -> Void
    
    var body: some View{
        HStack(alignment: .center) {
            Button(
                action: action,
                label: {
                    HStack(alignment: .center) {
                        Text("Editar")
                        Image(systemName: "pencil")
                    }
                }
            )
        }
    }
}
//MARK: CampaignImageSlider
private struct CampaignImageSlider: View {
    var images: [CampaignImage]
    @State var scrollID: Int?
    var body: some View {
        if images.isEmpty {
            EmptyImageView()
        }else{
           
        }
        
    }
}
//MARK: EmptyImageView
private struct EmptyImageView: View {
    var body : some View{
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
private struct ImageSliderContent : View {
    var images: [CampaignImage]
    @Binding var scrollID: Int?
    var body : some View{
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
private struct CampaignImageCard: View{
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
//MARK: Error View
private struct ErrorViewCampaign: View {
    let error: any DisplayableError
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Error al cargar imágenes")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Reintentar", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(height: 320)
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
//MARK: LoadingView
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity)
    }
}
#Preview {
    NavigationStack{
        MyCampaignView()
            .environmentObject(SupabaseCampaignManager.shared)
    }
   
}
