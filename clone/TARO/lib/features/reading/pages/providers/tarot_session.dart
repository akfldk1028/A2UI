import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/ai_config.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../models/tarot_card_data.dart';
import '../../catalog/tarot_catalog.dart';
import '../../models/oracle_persona.dart';
import '../../models/tarot_message.dart';
import '../../services/ai_client.dart';
import '../../services/transport.dart';

enum ConsultationPhase { question, personaPick, picking, reading, chatting }

final tarotSessionProvider =
    ChangeNotifierProvider.autoDispose<TarotSession>((ref) {
  return TarotSession();
});

class TarotSession extends ChangeNotifier {
  TarotSession({AiClient? aiClient}) {
    _client = aiClient ??
        (AiConfig.useEdgeFunction
            ? EdgeFunctionAiClient()
            : GeminiAiClient());
  }

  late final AiClient _client;
  TaroContentGenerator? _contentGenerator;
  A2uiMessageProcessor? _processor;
  GenUiConversation? _conversation;
  bool _initialized = false;

  final Logger _logger = Logger('TarotSession');

  // --- Consultation state ---
  ConsultationPhase _phase = ConsultationPhase.question;
  ConsultationPhase get phase => _phase;

  String? _userQuestion;
  String get userQuestion => _userQuestion ?? '';

  OraclePersona _persona = OraclePersona.mystic;
  OraclePersona get persona => _persona;
  set persona(OraclePersona value) {
    _persona = value;
    notifyListeners();
  }

  String _locale = 'en';

  final List<DrawnCard> _allDrawnCards = [];
  List<DrawnCard> get allDrawnCards => List.unmodifiable(_allDrawnCards);

  SpreadType? _currentSpread;
  SpreadType? get currentSpread => _currentSpread;

  int _activeCardIndex = -1;
  int get activeCardIndex => _activeCardIndex;

  int _revealedCount = 0;

  // --- GenUI state ---
  GenUiHost? get host => _conversation?.host;
  bool get isProcessing => _conversation?.isProcessing.value ?? false;

  final List<TarotMessage> _messages = [];
  List<TarotMessage> get messages => List.unmodifiable(_messages);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final systemPrompt = await rootBundle.loadString(
      'assets/prompts/oracle_system.txt',
    );

    _contentGenerator = TaroContentGenerator(
      aiClient: _client,
      systemPrompt: systemPrompt,
    );
    _processor = A2uiMessageProcessor(catalogs: [taroCatalog]);
    _conversation = GenUiConversation(
      contentGenerator: _contentGenerator!,
      a2uiMessageProcessor: _processor!,
      onSurfaceAdded: _onSurfaceAdded,
      onSurfaceUpdated: _onSurfaceUpdated,
      onTextResponse: _onTextResponse,
      onError: _onError,
    );

    _conversation!.isProcessing.addListener(notifyListeners);
    _conversation!.conversation.addListener(notifyListeners);
    _initialized = true;
  }

  // --- Public API ---

  /// Start consultation — no AI call, just set up state.
  void startConsultation({required String locale}) {
    _locale = locale;
    _phase = ConsultationPhase.question;
    notifyListeners();
  }

  /// User submitted their question → go to persona pick (no AI call).
  void handleUserQuestion(String question) {
    _userQuestion = question;
    _phase = ConsultationPhase.personaPick;
    notifyListeners();
  }

  /// User confirmed persona → transition to card picking.
  void confirmPersona() {
    _phase = ConsultationPhase.picking;
    notifyListeners();
  }

  /// Cards drawn — brief acknowledgement only, no interpretation.
  Future<void> handleCardsDrawn(
    List<DrawnCard> cards,
    SpreadType spread,
  ) async {
    _currentSpread = spread;
    _allDrawnCards.addAll(cards);
    _revealedCount = 0;
    _phase = ConsultationPhase.reading;
    notifyListeners();

    final langHint = _locale != 'en' ? '[Please respond in language code: $_locale]\n' : '';

    await _sendToAi(
      '${langHint}PERSONA: ${_persona.aiPrompt}\n'
      'The seeker drew ${cards.length} cards for a ${spread.displayName} spread.\n'
      'Give a BRIEF OracleMessage (1-2 sentences) saying the cards are laid out. '
      'Invite them to tap a card to begin the reading. Do NOT interpret any cards yet.',
    );
  }

  /// User tapped/flipped a card — interpret ONLY this card.
  Future<void> interpretCard(int cardIndex) async {
    if (cardIndex >= _allDrawnCards.length) return;
    if (isProcessing) return; // prevent concurrent AI calls

    final card = _allDrawnCards[cardIndex];
    _activeCardIndex = cardIndex;
    _revealedCount++;
    notifyListeners();

    final isLast = _revealedCount >= _allDrawnCards.length;
    final langHint = _locale != 'en' ? '[Please respond in language code: $_locale]\n' : '';

    try {
      await _sendToAi(
        '${langHint}PERSONA: ${_persona.aiPrompt}\n'
        'SEEKER\'S QUESTION: "${_userQuestion ?? "general reading"}"\n'
        'The seeker revealed: ${card.card.name} in the "${card.position}" position'
        '${card.isReversed ? " (Reversed)" : ""}.\n'
        'Interpret ONLY this one card with a TarotCard component + brief OracleMessage.\n'
        'Interpret specifically in context of their question.\n'
        '${isLast ? "This is the LAST card. After interpreting, also give a ReadingSummary tying all cards to their question, then a DrawPrompt." : "Do NOT give a summary yet — more cards to come."}',
      );
    } finally {
      _activeCardIndex = -1;
      if (isLast) {
        _phase = ConsultationPhase.chatting;
        _saveReadingHistory();
      }
      notifyListeners();
    }
  }

  void _saveReadingHistory() {
    final cache = CacheService.instance;
    cache.saveReading(
      question: _userQuestion ?? '',
      cards: _allDrawnCards.map((c) => {
        'name': c.card.name,
        'position': c.position,
        'isReversed': c.isReversed,
      }).toList(),
      persona: _persona.name,
      timestamp: DateTime.now(),
    );
  }

  /// Follow-up message from user.
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;
    await _ensureInitialized();

    _messages.add(TarotMessage(isUser: true, text: text));
    notifyListeners();

    final message = UserMessage.text(text);
    await _conversation!.sendRequest(message);
  }

  /// Additional card draw.
  Future<void> handleAdditionalDraw(List<DrawnCard> cards) async {
    _allDrawnCards.addAll(cards);
    _activeCardIndex = _allDrawnCards.length - cards.length;
    notifyListeners();

    final langHint = _locale != 'en' ? '[Please respond in language code: $_locale]\n' : '';

    final buffer = StringBuffer();
    buffer.writeln('${langHint}PERSONA: ${_persona.aiPrompt}');
    buffer.writeln('SEEKER\'S QUESTION: "${_userQuestion ?? "general reading"}"');
    buffer.writeln('The seeker drew ${cards.length} additional card(s):');
    for (final drawn in cards) {
      buffer.write('- ${drawn.card.name}');
      if (drawn.isReversed) buffer.write(' (Reversed)');
      buffer.writeln();
    }
    buffer.writeln('Interpret in context of the previous reading and their question.');

    await _sendToAi(buffer.toString());
    _activeCardIndex = -1;
    notifyListeners();
  }

  // --- Private ---

  Future<void> _sendToAi(String text) async {
    await _ensureInitialized();
    final message = UserMessage.text(text);
    await _conversation!.sendRequest(message);
  }

  void _onSurfaceAdded(SurfaceAdded update) {
    final exists = _messages.any((m) => m.surfaceId == update.surfaceId);
    if (!exists) {
      _messages.add(TarotMessage(isUser: false, surfaceId: update.surfaceId));
      notifyListeners();
    }
  }

  void _onSurfaceUpdated(SurfaceUpdated update) => notifyListeners();

  void _onTextResponse(String text) {
    if (text.trim().isEmpty) return;
    _messages.add(TarotMessage(isUser: false, text: text));
    notifyListeners();
  }

  void _onError(ContentGeneratorError error) {
    _logger.severe('Error', error.error);
    _messages.add(TarotMessage(isUser: false, text: 'reading.error'.tr()));
    notifyListeners();
  }

  @override
  void dispose() {
    if (_initialized) {
      _conversation!.isProcessing.removeListener(notifyListeners);
      _conversation!.conversation.removeListener(notifyListeners);
      _conversation!.dispose();
    }
    _client.dispose();
    super.dispose();
  }
}
