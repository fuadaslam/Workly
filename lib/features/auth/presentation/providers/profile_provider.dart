import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/profile.dart' as model;

final profileProvider = FutureProvider<model.Profile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  // Let real fetch failures (network/RLS) surface through AsyncValue.error
  // instead of being reported as "no profile" — callers (DashboardScreen)
  // already distinguish error/data states and need the real error to do so.
  final response = await Supabase.instance.client
      .from('profiles')
      .select('*, offices(name)')
      .eq('id', user.id)
      .single();

  return model.Profile.fromJson(response);
});
