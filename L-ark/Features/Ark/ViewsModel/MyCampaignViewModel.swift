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
    @Published var viewState: State = .loaded
    @Published var images: [CampaignImage] = []

    private let campaignService: SupabaseCampaignManager =
        SupabaseCampaignManager.shared

    func loadImages() async {  // 👈 Quita throws
        viewState = .loading

        do {
            try await campaignService.getImagesFromCampaign("12345")
            images = campaignService.images ?? [] // No olvides asignar
            viewState = .loaded
        } catch let imageError as CampaignError {
            viewState = .imgError(imageError)
        } catch {  // 👈 Captura TODOS los demás errores
            // Convertir cualquier error a DisplayableError
            let displayableError = error as? DisplayableError ?? CampaignError.imgFailed
            viewState = .imgError(displayableError)
        }
    }

}
