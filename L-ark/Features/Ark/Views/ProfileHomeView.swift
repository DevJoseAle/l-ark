import SwiftUI

struct ProfileHomeView:View{
    @EnvironmentObject var auth: AuthenticationViewModel
    private let supabase = SupabaseClientManager.shared.client
    var body: some View{
        VStack {
            Text("ProfileHomeView")
            
            Button(action: {
                Task{ await auth.signOutSupabase()}
            }) {
            Text("Logout")
            }
        }
    }
}


#Preview {
    ProfileHomeView()
}
