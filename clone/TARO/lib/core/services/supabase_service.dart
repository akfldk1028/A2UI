import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/ai_config.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final _log = Logger('SupabaseService');
  bool _initialized = false;

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    if (_initialized) return;
    if (!AiConfig.useEdgeFunction) {
      _log.info('Supabase not configured — skipping init');
      return;
    }
    await Supabase.initialize(
      url: AiConfig.supabaseUrl,
      anonKey: AiConfig.supabaseAnonKey,
    );
    _initialized = true;
    _log.info('Supabase initialized');
    await _ensureAnonAuth();
  }

  Future<void> _ensureAnonAuth() async {
    final session = client.auth.currentSession;
    if (session == null) {
      try {
        await client.auth.signInAnonymously();
        _log.info('Anonymous auth success');
      } catch (e) {
        _log.warning('Anonymous auth failed: $e');
      }
    }
  }

  String? get userId => client.auth.currentUser?.id;

  /// Save a completed reading to Supabase.
  Future<void> saveReading({
    required String question,
    required List<Map<String, dynamic>> cards,
    required String persona,
    required String? spreadType,
    String locale = 'en',
  }) async {
    if (!_initialized || userId == null) return;

    try {
      await client.from('tarot_readings').insert({
        'user_id': userId,
        'question': question,
        'spread_type': spreadType,
        'cards': cards,
        'persona': persona,
        'locale': locale,
      });
      _log.info('Reading saved to Supabase');
    } catch (e) {
      _log.warning('Failed to save reading: $e');
    }
  }
}
