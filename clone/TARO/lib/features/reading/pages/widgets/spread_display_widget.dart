import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/tarot_card_data.dart';
import '../../../../shared/widgets/card_face.dart';
import '../../../../shared/widgets/flip_card.dart';

class SpreadDisplayWidget extends StatelessWidget {
  const SpreadDisplayWidget({
    super.key,
    required this.drawnCards,
    required this.activeCardIndex,
    required this.revealedCards,
    required this.onCardTap,
    required this.isMobile,
  });

  final List<DrawnCard> drawnCards;
  final int activeCardIndex;
  final Set<int> revealedCards;
  final ValueChanged<int> onCardTap;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cardW = isMobile ? 48.0 : 64.0;
    final cardH = cardW * 1.5;
    final cards = drawnCards;
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
        final isRevealed = revealedCards.contains(idx);
        final isActive = idx == activeCardIndex;
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
                  onFlip: () => onCardTap(idx),
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
}
