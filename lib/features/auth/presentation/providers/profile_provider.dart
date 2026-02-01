import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/profile.dart' as model;

final profileProvider = FutureProvider<model.Profile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return model.Profile.fromJson(response);
  } catch (e) {
    debugPrint('Error fetching profile: $e');
    return null; 
  }
});
