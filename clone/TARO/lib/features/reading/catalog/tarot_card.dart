import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['TarotCard']),
    'cardName': S.string(
      description: 'The name of the tarot card, e.g. "The Fool", "Ten of Cups".',
    ),
    'position': S.string(
      description:
          'The position meaning in the spread, e.g. "Past", "Present", "Future".',
    ),
    'isReversed': S.boolean(
      description: 'Whether the card is reversed (upside-down).',
    ),
    'interpretation': S.string(
      description:
          'The interpretation of this card in context of the question and position. 2-4 sentences.',
    ),
    'cardDescription': S.string(
      description: 'A vivid visual description of the card imagery. 1-2 sentences.',
    ),
  },
  required: ['component', 'cardName', 'position', 'interpretation'],
);

final tarotCard = CatalogItem(
  name: 'TarotCard',
  dataSchema: _schema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    return _TarotCardWidget(
      cardName: data['cardName']?.toString() ?? '',
      position: data['position']?.toString() ?? '',
      isReversed: data['isReversed'] as bool? ?? false,
      interpretation: data['interpretation']?.toString() ?? '',
      cardDescription: data['cardDescription']?.toString(),
    );
  },
);

class _TarotCardWidget extends StatefulWidget {
  const _TarotCardWidget({
    required this.cardName,
    required this.position,
    required this.isReversed,
    required this.interpretation,
    this.cardDescription,
  });

  final String cardName;
  final String position;
  final bool isReversed;
  final String interpretation;
  final String? cardDescription;

  @override
  State<_TarotCardWidget> createState() => _TarotCardWidgetState();
}

class _TarotCardWidgetState extends State<_TarotCardWidget>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;

  static const _majorArcana = {
    'The Fool', 'The Magician', 'The High Priestess', 'The Empress',
    'The Emperor', 'The Hierophant', 'The Lovers', 'The Chariot',
    'Strength', 'The Hermit', 'Wheel of Fortune', 'Justice',
    'The Hanged Man', 'Death', 'Temperance', 'The Devil',
    'The Tower', 'The Star', 'The Moon', 'The Sun',
    'Judgement', 'The World',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMajor = _majorArcana.contains(widget.cardName);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: Opacity(opacity: _fadeIn.value, child: child),
        );
      },
      child: Card(
        elevation: _revealed ? 8 : 4,
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isMajor
                ? TaroColors.gold
                : theme.colorScheme.outline.withAlpha(80),
            width: isMajor ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _revealed = !_revealed),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Position badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: TaroColors.gold.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.position,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: TaroColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!_revealed)
                      Text(
                        'common.tapToReveal'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: TaroColors.gold.withAlpha(150),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Card name with icon
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            TaroColors.gold.withAlpha(60),
                            TaroColors.gold.withAlpha(20),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: TaroColors.gold.withAlpha(100)),
                      ),
                      child: Center(
                        child: widget.isReversed
                            ? Transform.rotate(
                                angle: math.pi,
                                child: const Icon(Icons.style,
                                    size: 22, color: TaroColors.gold),
                              )
                            : const Icon(Icons.style,
                                size: 22, color: TaroColors.gold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.cardName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.isReversed)
                            Text(
                              'common.reversed'.tr(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.redAccent.shade100,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _revealed ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: TaroColors.gold.withAlpha(150),
                      ),
                    ),
                  ],
                ),

                // Card imagery description (always visible)
                if (widget.cardDescription != null &&
                    widget.cardDescription!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.cardDescription!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                ],

                // Interpretation (revealed on tap)
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: _revealed
                      ? Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  TaroColors.gold.withAlpha(15),
                                  theme.colorScheme.surfaceContainerHighest,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: TaroColors.gold.withAlpha(40)),
                            ),
                            child: Text(
                              widget.interpretation,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
