import Foundation
import Supabase

private func isPreview() -> Bool {
  ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

enum Secrets {
  static var supabaseURL: URL {

    let scheme = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SCHEME") as? String) ?? "https"
    let host   = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_HOST")   as? String) ?? "example.com"
    var comps = URLComponents()
    comps.scheme = scheme
    comps.host   = host
    return comps.url!   // ahora no hay %5C ni comillas
  }

  static var supabaseAnonKey: String {
//    if isPreview() { return "preview_anon_key" }
    return (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String) ?? ""
  }
}
final class SupabaseClientManager {
    static let shared = SupabaseClientManager()
    let client: SupabaseClient

    private init() {
       client = SupabaseClient(
            supabaseURL: Secrets.supabaseURL,
            supabaseKey: Secrets.supabaseAnonKey
        )
    }
}
