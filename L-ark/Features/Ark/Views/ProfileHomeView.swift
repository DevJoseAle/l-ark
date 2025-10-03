import SwiftUI

struct ProfileHomeView:View{
    @EnvironmentObject var auth: AuthenticationViewModel
    private let supabase = SupabaseClientManager.shared.client
    var body: some View{
        VStack {
            Text("ProfileHomeView")
            
            Button(action: {
//                Task{ await auth.signOutSupabase()}
                Task{
                    do{
                        let user: Any? = try await supabase.auth.user()
                        print("PROFILE",user ?? "nil")
                    }
                }
            }) {
            Text("Logout")
            }
        }
    }
}


#Preview {
    ProfileHomeView()
}
