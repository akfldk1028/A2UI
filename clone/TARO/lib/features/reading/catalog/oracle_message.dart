import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['OracleMessage']),
    'text': S.string(
      description: 'The Oracle\'s message text. Use mystical, warm tone.',
    ),
  },
  required: ['component', 'text'],
);

final oracleMessage = CatalogItem(
  name: 'OracleMessage',
  dataSchema: _schema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    return _OracleMessageWidget(
      text: data['text']?.toString() ?? '',
    );
  },
);

class _OracleMessageWidget extends StatefulWidget {
  const _OracleMessageWidget({required this.text});

  final String text;

  @override
  State<_OracleMessageWidget> createState() => _OracleMessageWidgetState();
}

class _OracleMessageWidgetState extends State<_OracleMessageWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oracle avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    TaroColors.gold.withAlpha(60),
                    TaroColors.gold.withAlpha(15),
                  ],
                ),
                border: Border.all(
                  color: TaroColors.gold.withAlpha(80),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: TaroColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            // Message
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TaroColors.gold.withAlpha(12),
                      theme.colorScheme.surfaceContainerHigh,
                    ],
                  ),
                  border: Border.all(
                    color: TaroColors.gold.withAlpha(25),
                  ),
                ),
                child: Text(
                  widget.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withAlpha(220),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
