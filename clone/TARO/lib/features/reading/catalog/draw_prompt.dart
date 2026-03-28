import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['DrawPrompt']),
    'prompt': S.string(
      description: 'Text above the button, e.g. "Shall we look deeper?"',
    ),
    'buttonText': S.string(
      description: 'Button label, e.g. "Draw one more card"',
    ),
  },
  required: ['component', 'buttonText'],
);

final drawPrompt = CatalogItem(
  name: 'DrawPrompt',
  dataSchema: _schema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    return _DrawPromptWidget(
      prompt: data['prompt']?.toString(),
      buttonText: data['buttonText']?.toString() ?? 'Draw more cards',
      componentId: context.id,
      surfaceId: context.surfaceId,
      dispatchEvent: context.dispatchEvent,
    );
  },
);

class _DrawPromptWidget extends StatelessWidget {
  const _DrawPromptWidget({
    this.prompt,
    required this.buttonText,
    required this.componentId,
    required this.surfaceId,
    required this.dispatchEvent,
  });

  final String? prompt;
  final String buttonText;
  final String componentId;
  final String surfaceId;
  final DispatchEventCallback dispatchEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: TaroColors.gold.withAlpha(50),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              TaroColors.gold.withAlpha(8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            if (prompt != null && prompt!.isNotEmpty) ...[
              Text(
                prompt!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: TaroColors.gold.withAlpha(180),
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: () {
                dispatchEvent(UserActionEvent(
                  name: 'drawMore',
                  sourceComponentId: componentId,
                  surfaceId: surfaceId,
                  context: {},
                ));
              },
              icon: const Icon(Icons.style, size: 20),
              label: Text(buttonText),
              style: FilledButton.styleFrom(
                backgroundColor: TaroColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
