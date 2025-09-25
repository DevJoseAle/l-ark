//
//  MyCampaignViewModel.swift
//  L-ark
//
//  Created by Jose Rodriguez on 17-09-25.
//

import Foundation

@MainActor
final class MyCampaignViewModel: ObservableObject {
    enum State {
        case loading, loaded, idle
        case imgError(any DisplayableError)
    }
    @Published var viewState: State = .idle

    private let campaignManager = SupabaseCampaignManager.shared
    private var hasLoaded = false
       
       func loadImages() async {
           guard !hasLoaded else { return }
           hasLoaded = true
           
           viewState = .loading
           do {
               // Usa el ID real de la campaña
//               guard let campaignId = campaignManager.ownCampaign?.id.uuidString else {
//                   print(campaignManager.ownCampaign?.id.uuidString)
//                   print("Por acá está el error")
//                   throw CampaignError.imgFailed
//               }
               print("Antes del getimages")
               try await campaignManager.getImagesFromCampaign("89bf4646-3e2a-4900-b0d4-fee2a318aa8f")
               viewState = .loaded
           } catch let imageError as CampaignError {
               print("Fue aqui en vm1")
               print(imageError)
               viewState = .imgError(imageError)
           } catch {
               print("Fue aqui en vm2")
               viewState = .imgError(CampaignError.imgFailed)
           }
       }
}
