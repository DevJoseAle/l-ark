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
               guard let campaignId = campaignManager.firstOwnCampaign?.id.uuidString else {
                   print("Por acá está el error")
                   throw CampaignError.imgFailed
               }
               print("Antes del getimages")
               try await campaignManager.getImagesFromCampaign(campaignId)
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
