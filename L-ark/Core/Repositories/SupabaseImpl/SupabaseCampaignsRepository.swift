//
//  SupabaseCampaignsRepository.swift
//  L-ark
//
//  Created by Jose Rodriguez on 08-09-25.
//

import Foundation

import Supabase

//class SupabaseCampaignsRepository: CampaignsRepository {
//    private let client: SupabaseClient
//    
//    init( client: SupabaseClient = SupabaseClientManager.shared.client){
//        self.client = client
//    }
////    func fetchActiveCampaigns(limit: Int?) async throws ->[Campaign]{
////        return[]
////    }
////    func fetchCampaign(by id: UUID) async throws -> Campaign? {
////        return "" as Campaign
////    }
//    func checkIfUserExist(_ email: String)async throws -> Bool {
//        let response: UserCheckResponse = try await client.functions
//          .invoke(
//            "check-user-exists",
//            options: FunctionInvokeOptions(
//              body: ["email": email]
//            )
//          )
//        print(response)
//       return response.userExist
//        
//        
//    }
//}
