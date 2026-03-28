import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart' show GenUiSurface;
import 'package:go_router/go_router.dart';

import '../../../../core/config/ai_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/tarot_card_data.dart';
import '../../../../router/routes.dart';
import '../../../../shared/widgets/card_face.dart';
import '../../../../shared/widgets/flip_card.dart';
import '../providers/tarot_session.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/persona_pick_phase.dart';
import '../widgets/question_phase.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key, required this.spreadType});
  final SpreadType spreadType;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen>
    with SingleTickerProviderStateMixin {
  late final TarotSession _session;
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  // Card picking
  TarotDeck? _deck;
  List<TarotCardData> _shuffled = [];
  final List<int> _selectedIndices = [];
  final List<DrawnCard> _drawnCards = [];
  final Set<int> _revealedCards = {};
  final Random _rng = Random();
  late final AnimationController _fanAnim;
  int _cardCount = 0;
  int _hoveredIndex = -1;
  bool _cardsSubmitted = false;

  bool get _pickingDone => _drawnCards.length >= widget.spreadType.cardCount;

  @override
  void initState() {
    super.initState();
    _session = TarotSession();
    _session.addListener(_onSessionChanged);
    _fanAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _initSession();
  }

  Future<void> _initSession() async {
    _deck = await TarotDeck.load();
    _shuffled = _deck!.shuffled();
    _cardCount = _shuffled.length;
    if (mounted) {
      _session.startConsultation(locale: context.locale.languageCode);
    }
    setState(() {});
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
    final count = _session.messages.length;
    if (count > _lastMessageCount) {
      _lastMessageCount = count;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectCard(int index) {
    if (_selectedIndices.contains(index) || _pickingDone) return;
    setState(() {
      _selectedIndices.add(index);
      _drawnCards.add(DrawnCard(
        card: _shuffled[index],
        position: widget.spreadType.positions[_drawnCards.length],
        isReversed: _rng.nextDouble() < AiConfig.reversalProbability,
      ));
    });
    if (_pickingDone && !_cardsSubmitted) {
      _cardsSubmitted = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _session.handleCardsDrawn(_drawnCards, widget.spreadType);
      });
    }
  }

  void _onCardFlipped(int idx) {
    if (_revealedCards.contains(idx)) return;
    setState(() => _revealedCards.add(idx));
    _session.interpretCard(idx);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 500;
    final phase = _session.phase;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: TaroColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(theme, phase),

              // --- Phase-specific content ---
              if (phase == ConsultationPhase.question) ...[
                Expanded(child: QuestionPhase(
                  onChipTap: (label) => _session.handleUserQuestion(label),
                )),
              ] else if (phase == ConsultationPhase.personaPick) ...[
                Expanded(child: PersonaPickPhase(
                  question: _session.userQuestion,
                  selectedPersona: _session.persona,
                  onPersonaChanged: (p) => _session.persona = p,
                  onConfirm: () {
                    _session.confirmPersona();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) _fanAnim.forward();
                    });
                  },
                )),
              ] else if (phase == ConsultationPhase.picking) ...[
                // Card fan fills screen
                Expanded(child: _buildCardFan(size, isMobile)),
              ] else ...[
                // reading / chatting — spread + messages
                _buildSpreadDisplay(isMobile),
                Expanded(child: _buildMessageList(theme)),
              ],

              // Chat input (hidden during personaPick and picking)
              if (phase == ConsultationPhase.question ||
                  phase == ConsultationPhase.reading ||
                  phase == ConsultationPhase.chatting)
                ChatInputField(
                  enabled: !_session.isProcessing && phase != ConsultationPhase.picking,
                  onSend: (text) {
                    if (phase == ConsultationPhase.question) {
                      _session.handleUserQuestion(text);
                    } else {
                      _session.sendMessage(text);
                    }
                    _scrollToBottom();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ──── App Bar ────
  Widget _buildAppBar(ThemeData theme, ConsultationPhase phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TaroColors.gold.withAlpha(15)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: TaroColors.gold.withAlpha(180),
            onPressed: () => context.go(Routes.menu),
          ),
          Text(
            phase == ConsultationPhase.question || phase == ConsultationPhase.personaPick
                ? 'reading.title'.tr()
                : widget.spreadType.displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'NotoSerifKR',
              color: TaroColors.gold.withAlpha(220),
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (phase == ConsultationPhase.picking)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.spreadType.cardCount, (i) {
                final filled = i < _drawnCards.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: filled ? 10 : 6, height: filled ? 10 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? TaroColors.gold : Colors.transparent,
                    border: Border.all(
                      color: TaroColors.gold.withAlpha(filled ? 255 : 60),
                      width: 1,
                    ),
                    boxShadow: filled
                        ? [BoxShadow(color: TaroColors.gold.withAlpha(40), blurRadius: 6)]
                        : null,
                  ),
                );
              }),
            ),
          if (phase == ConsultationPhase.chatting || phase == ConsultationPhase.reading)
            GestureDetector(
              onTap: () => context.go(Routes.menu),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TaroColors.gold.withAlpha(40)),
                ),
                child: Text('reading.newReading'.tr(),
                    style: TextStyle(color: TaroColors.gold.withAlpha(160), fontSize: 12, letterSpacing: 0.5)),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ──── Message List ────
  Widget _buildMessageList(ThemeData theme) {
    if (_session.messages.isEmpty && !_session.isProcessing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nights_stay_outlined, color: TaroColors.gold.withAlpha(60), size: 28),
            const SizedBox(height: 12),
            CircularProgressIndicator(color: TaroColors.gold.withAlpha(80), strokeWidth: 1.5),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _session.messages.length + (_session.isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator
        if (index >= _session.messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(Icons.nights_stay_outlined, size: 14, color: TaroColors.violet.withAlpha(120)),
                const SizedBox(width: 8),
                _buildPulsingDots(),
              ],
            ),
          );
        }
        final msg = _session.messages[index];
        if (msg.surfaceId != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _session.host != null
                ? GenUiSurface(host: _session.host!, surfaceId: msg.surfaceId!)
                : const SizedBox.shrink(),
          );
        }
        // User message — gold glass bubble, right-aligned
        if (msg.isUser) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TaroColors.gold.withAlpha(25),
                    TaroColors.gold.withAlpha(12),
                  ],
                ),
                border: Border.all(color: TaroColors.gold.withAlpha(40)),
              ),
              child: Text(msg.text ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(220),
                    height: 1.4,
                  )),
            ),
          );
        }
        // Oracle message — star icon + italic text
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(Icons.nights_stay_outlined,
                    size: 14, color: TaroColors.violet.withAlpha(140)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(msg.text ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(190),
                  height: 1.6,
                  letterSpacing: 0.2,
                ))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPulsingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return _PulsingDot(delay: i * 200);
      }),
    );
  }

  // ──── Card Fan (picking phase) ────
  Widget _buildCardFan(Size screenSize, bool isMobile) {
    if (_cardCount == 0) {
      return const Center(child: CircularProgressIndicator(color: TaroColors.gold));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final availH = constraints.maxHeight;
      final availW = constraints.maxWidth;
      final cardW = isMobile ? 34.0 : 46.0;
      final cardH = cardW * 1.5;
      final perRow = (_cardCount / 3).ceil();
      final row1Count = perRow.clamp(0, _cardCount);
      final row2Count = perRow.clamp(0, _cardCount - row1Count);
      final row3Count = (_cardCount - row1Count - row2Count).clamp(0, _cardCount);
      final totalAngle = pi * 0.28;
      final maxRadius = (availW / 2 - cardW) / sin(totalAngle / 2);
      final radius = maxRadius;
      final centerX = availW / 2;
      final startAngle = -pi / 2 - totalAngle / 2;
      final row1CenterY = availH * 0.25 + radius;
      final row2CenterY = availH * 0.50 + radius;
      final row3CenterY = availH * 0.75 + radius;

      return AnimatedBuilder(
        animation: _fanAnim,
        builder: (context, _) {
          final progress = Curves.easeOutCubic.transform(_fanAnim.value.clamp(0.0, 1.0));
          return Stack(
            children: [
              ...List.generate(row1Count, (i) => _buildFanCard(
                index: i, localIndex: i, centerX: centerX,
                centerY: row1CenterY, radius: radius,
                startAngle: startAngle, totalAngle: totalAngle,
                rowCardCount: row1Count, cardW: cardW, cardH: cardH, progress: progress)),
              ...List.generate(row2Count, (i) => _buildFanCard(
                index: row1Count + i, localIndex: i, centerX: centerX,
                centerY: row2CenterY, radius: radius,
                startAngle: startAngle, totalAngle: totalAngle,
                rowCardCount: row2Count, cardW: cardW, cardH: cardH, progress: progress)),
              ...List.generate(row3Count, (i) => _buildFanCard(
                index: row1Count + row2Count + i, localIndex: i, centerX: centerX,
                centerY: row3CenterY, radius: radius,
                startAngle: startAngle, totalAngle: totalAngle,
                rowCardCount: row3Count, cardW: cardW, cardH: cardH, progress: progress)),
            ],
          );
        },
      );
    });
  }

  Widget _buildFanCard({
    required int index, required int localIndex,
    required double centerX, required double centerY,
    required double radius, required double startAngle,
    required double totalAngle, required int rowCardCount,
    required double cardW, required double cardH, required double progress,
  }) {
    final selected = _selectedIndices.contains(index);
    final hovered = _hoveredIndex == index;
    final t = rowCardCount > 1 ? localIndex / (rowCardCount - 1) : 0.5;
    final angle = startAngle + totalAngle * t;
    final x = centerX + radius * cos(angle) * progress;
    final y = centerY + radius * sin(angle) * progress;
    final rotation = (angle + pi / 2) * progress;
    final liftY = selected ? -20.0 : hovered ? -10.0 : 0.0;

    return Positioned(
      left: x - cardW / 2, top: y - cardH / 2 + liftY,
      child: Transform.rotate(
        angle: rotation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = index),
          onExit: (_) => setState(() => _hoveredIndex = -1),
          child: GestureDetector(
            onTap: () => _selectCard(index),
            child: AnimatedScale(
              scale: hovered && !selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedOpacity(
                opacity: selected ? 0.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: cardW, height: cardH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [hovered ? const Color(0xFF5A3DBF) : const Color(0xFF3D2B79), const Color(0xFF1A0A2E)],
                    ),
                    border: Border.all(
                      color: hovered ? TaroColors.gold : TaroColors.gold.withAlpha(80),
                      width: hovered ? 1.5 : 0.8),
                    boxShadow: [BoxShadow(color: TaroColors.gold.withAlpha(hovered ? 60 : 8), blurRadius: hovered ? 12 : 3)],
                  ),
                  child: Center(child: Icon(Icons.auto_awesome,
                    color: TaroColors.gold.withAlpha(hovered ? 180 : 40), size: cardW * 0.35)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──── Spread Display (reading/chatting phase) ────
  Widget _buildSpreadDisplay(bool isMobile) {
    final cardW = isMobile ? 48.0 : 64.0;
    final cardH = cardW * 1.5;
    final cards = _session.allDrawnCards.isEmpty ? _drawnCards : _session.allDrawnCards;
    final twoRows = cards.length > 5;
    final row1 = twoRows ? cards.sublist(0, (cards.length + 1) ~/ 2) : cards;
    final row2 = twoRows ? cards.sublist((cards.length + 1) ~/ 2) : <DrawnCard>[];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0520), Color(0xFF1A0A2E)]),
        border: Border(bottom: BorderSide(color: Color(0x30D4AF37))),
      ),
      child: Column(
        children: [
          _buildCardRow(row1, 0, cardW, cardH),
          if (row2.isNotEmpty) ...[const SizedBox(height: 4), _buildCardRow(row2, row1.length, cardW, cardH)],
        ],
      ),
    );
  }

  Widget _buildCardRow(List<DrawnCard> cards, int startIndex, double cardW, double cardH) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cards.length, (i) {
        final idx = startIndex + i;
        final drawn = cards[i];
        final isRevealed = _revealedCards.contains(idx);
        final isActive = idx == _session.activeCardIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? TaroColors.gold.withAlpha(60) : TaroColors.gold.withAlpha(15),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(drawn.position, style: TextStyle(
                  color: isActive ? TaroColors.gold : TaroColors.gold.withAlpha(100),
                  fontSize: 8, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isActive ? [BoxShadow(color: TaroColors.gold.withAlpha(80), blurRadius: 10)] : null),
                child: FlipCard(
                  isFlipped: isRevealed,
                  onFlip: () => _onCardFlipped(idx),
                  size: Size(cardW, cardH),
                  front: CardFace(card: drawn.card, isReversed: drawn.isReversed, size: Size(cardW, cardH)),
                ),
              ),
              if (isRevealed) ...[
                const SizedBox(height: 2),
                SizedBox(width: cardW, child: Text(drawn.card.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: drawn.isReversed ? Colors.redAccent.shade100 : Colors.white60,
                    fontSize: 7, fontWeight: FontWeight.bold))),
              ],
            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    _scrollController.dispose();
    _fanAnim.dispose();
    super.dispose();
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.delay});
  final int delay;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + widget.delay),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = 0.3 + 0.7 * _controller.value;
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TaroColors.gold.withAlpha((value * 150).round()),
          ),
        );
      },
    );
  }
}
