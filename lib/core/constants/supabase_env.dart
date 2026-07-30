class SupabaseEnv {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wwnjrarqeunhqwsgpgem.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_EmdO0a8M3wnCUXU-qaAH-w_Ct1baNM-',
  );
}

