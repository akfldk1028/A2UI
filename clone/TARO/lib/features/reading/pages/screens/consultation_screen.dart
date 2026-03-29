import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/ai_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/reading_category.dart';
import '../../../../models/spread_type.dart';
import '../../../../models/tarot_card_data.dart';
import '../../../../router/routes.dart';
import '../providers/tarot_session.dart';
import '../widgets/card_fan_widget.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_list_widget.dart';
import '../widgets/persona_pick_phase.dart';
import '../widgets/question_phase.dart';
import '../widgets/spread_display_widget.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  const ConsultationScreen({super.key, required this.spreadType, required this.category});
  final SpreadType spreadType;
  final ReadingCategory category;

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  void _checkAutoScroll(int currentCount) {
    if (currentCount > _lastMessageCount) {
      _lastMessageCount = currentCount;
      _scrollToBottom();
    }
  }

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
    _fanAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _initSession();
  }

  Future<void> _initSession() async {
    _deck = await TarotDeck.load();
    _shuffled = _deck!.shuffled();
    _cardCount = _shuffled.length;
    if (mounted) {
      ref.read(tarotSessionProvider).startConsultation(
        locale: context.locale.languageCode,
        category: widget.category,
      );
    }
    setState(() {});
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
      final session = ref.read(tarotSessionProvider);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) session.handleCardsDrawn(_drawnCards, widget.spreadType);
      });
    }
  }

  void _onCardFlipped(int idx) {
    if (_revealedCards.contains(idx)) return;
    setState(() => _revealedCards.add(idx));
    ref.read(tarotSessionProvider).interpretCard(idx);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tarotSessionProvider);
    _checkAutoScroll(session.messages.length);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 500;
    final phase = session.phase;

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
                  onChipTap: (label) => ref.read(tarotSessionProvider).handleUserQuestion(label),
                )),
              ] else if (phase == ConsultationPhase.personaPick) ...[
                Expanded(child: PersonaPickPhase(
                  question: session.userQuestion,
                  selectedPersona: session.persona,
                  onPersonaChanged: (p) => ref.read(tarotSessionProvider).persona = p,
                  onConfirm: () {
                    ref.read(tarotSessionProvider).confirmPersona();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) _fanAnim.forward();
                    });
                  },
                )),
              ] else if (phase == ConsultationPhase.picking) ...[
                // Card fan fills screen
                Expanded(child: CardFanWidget(
                  shuffledCards: _shuffled,
                  cardCount: _cardCount,
                  selectedIndices: _selectedIndices,
                  requiredCount: widget.spreadType.cardCount,
                  hoveredIndex: _hoveredIndex,
                  fanAnimation: _fanAnim,
                  onCardSelected: _selectCard,
                  onHoverChanged: (index) => setState(() => _hoveredIndex = index),
                  isMobile: isMobile,
                )),
              ] else ...[
                // reading / chatting \u2014 spread + messages
                SpreadDisplayWidget(
                  drawnCards: session.allDrawnCards.isEmpty ? _drawnCards : session.allDrawnCards,
                  activeCardIndex: session.activeCardIndex,
                  revealedCards: _revealedCards,
                  onCardTap: _onCardFlipped,
                  isMobile: isMobile,
                ),
                Expanded(child: MessageListWidget(
                  messages: session.messages,
                  scrollController: _scrollController,
                  isProcessing: session.isProcessing,
                  host: session.host,
                  buildPulsingDots: _buildPulsingDots,
                )),
              ],

              // Chat input (hidden during personaPick and picking)
              if (phase == ConsultationPhase.question ||
                  phase == ConsultationPhase.reading ||
                  phase == ConsultationPhase.chatting)
                ChatInputField(
                  enabled: !session.isProcessing && phase != ConsultationPhase.picking,
                  onSend: (text) {
                    final s = ref.read(tarotSessionProvider);
                    if (phase == ConsultationPhase.question) {
                      s.handleUserQuestion(text);
                    } else {
                      s.sendMessage(text);
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

  // \u2500\u2500\u2500\u2500 App Bar \u2500\u2500\u2500\u2500
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

  Widget _buildPulsingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return _PulsingDot(delay: i * 200);
      }),
    );
  }

  @override
  void dispose() {
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
