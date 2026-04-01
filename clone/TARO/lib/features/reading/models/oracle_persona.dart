import 'package:flutter/material.dart';

enum OraclePersona {
  mystic(
    '신비 현자', 'Mystical Sage',
    'You speak as an ancient mystical sage. Use cosmic imagery — stars, rivers, shadows, light, crossroads. Warm and gentle, address the seeker as "dear seeker" or "traveler".',
    Icons.auto_awesome,
    'matilda',
  ),
  analyst(
    '분석가', 'The Analyst',
    'You are a logical, structured tarot analyst. Explain card symbolism systematically. Reference elemental associations, numerology, and traditional meanings. Clear and organized.',
    Icons.analytics,
    'river',
  ),
  friend(
    '친구', 'The Friend',
    'You are a warm, casual friend reading cards. Use everyday language, be relatable and encouraging. Speak naturally, not formally. Use humor when appropriate.',
    Icons.emoji_emotions,
    'shimmer',
  ),
  direct(
    '직설가', 'Straight Talker',
    'You are blunt and direct. No flowery language, no sugar-coating. Get straight to the point. Short, impactful sentences. Say what the cards actually mean.',
    Icons.bolt,
    'adam',
  );

  const OraclePersona(this.koName, this.enName, this.aiPrompt, this.icon, this.voiceId);

  final String koName;
  final String enName;
  final String aiPrompt;
  final IconData icon;
  /// ElevenLabs voice preset name.
  final String voiceId;
}
