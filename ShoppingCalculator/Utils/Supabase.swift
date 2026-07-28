import Foundation
import Supabase

let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String ?? ""

/* local dev settings
let supabase = SupabaseClient(
  supabaseURL: URL(string: "url")!,
  supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_KEY"] ?? ""
)
*/
let supabase = SupabaseClient(
    supabaseURL: URL(string: supabaseURL) ?? URL(string: "https://placeholder.supabase.co")!,
    supabaseKey: supabaseKey
)

// database password: 5tkFZDGwZRX2d8cr
// ref: bigppiyvfasyitajjqnw
// connection string: postgresql://postgres:5tkFZDGwZRX2d8cr@db.bigppiyvfasyitajjqnw.supabase.co:5432/postgres
// pooler: postgresql://postgres.bigppiyvfasyitajjqnw:5tkFZDGwZRX2d8cr@aws-1-eu-central-1.pooler.supabase.com:5432/postgres
