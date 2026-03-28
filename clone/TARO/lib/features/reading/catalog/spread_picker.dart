import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['SpreadPicker']),
    'title': S.string(
      description: 'A prompt text above the choices, e.g. "Choose your spread".',
    ),
    'options': S.list(
      description: 'The spread options to choose from.',
      items: S.object(
        properties: {
          'label': S.string(description: 'Display label, e.g. "Three Card"'),
          'description': S.string(
            description: 'Short description, e.g. "Past / Present / Future"',
          ),
          'icon': S.string(
            description: 'Icon hint: "one_card", "three_card", "celtic_cross"',
          ),
        },
        required: ['label'],
      ),
    ),
  },
  required: ['component', 'options'],
);

final spreadPicker = CatalogItem(
  name: 'SpreadPicker',
  dataSchema: _schema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final title = data['title']?.toString() ?? '';
    final rawOptions = data['options'] as List<Object?>? ?? [];
    final options = <Map<String, Object?>>[];
    for (final item in rawOptions) {
      if (item is Map<String, Object?>) options.add(item);
    }

    return _SpreadPickerWidget(
      title: title,
      options: options,
      componentId: context.id,
      surfaceId: context.surfaceId,
      dispatchEvent: context.dispatchEvent,
    );
  },
);

class _SpreadPickerWidget extends StatelessWidget {
  const _SpreadPickerWidget({
    required this.title,
    required this.options,
    required this.componentId,
    required this.surfaceId,
    required this.dispatchEvent,
  });

  final String title;
  final List<Map<String, Object?>> options;
  final String componentId;
  final String surfaceId;
  final DispatchEventCallback dispatchEvent;

  IconData _iconFor(String? hint) {
    return switch (hint) {
      'one_card' => Icons.looks_one_rounded,
      'three_card' => Icons.looks_3_rounded,
      'celtic_cross' => Icons.grid_view_rounded,
      'relationship' => Icons.favorite_rounded,
      'career' => Icons.work_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  String _cardCount(String? hint) {
    return switch (hint) {
      'one_card' => '1 card',
      'three_card' => '3 cards',
      'celtic_cross' => '10 cards',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: TaroColors.gold.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 18, color: TaroColors.gold.withAlpha(180)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: TaroColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final opt = entry.value;
              final label = opt['label'] as String? ?? '';
              final desc = opt['description'] as String?;
              final icon = opt['icon'] as String?;
              final count = _cardCount(icon);

              return Padding(
                padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      dispatchEvent(UserActionEvent(
                        name: 'spreadSelected',
                        sourceComponentId: componentId,
                        surfaceId: surfaceId,
                        context: {'selectedSpread': label},
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: TaroColors.gold.withAlpha(60)),
                        gradient: LinearGradient(
                          colors: [
                            TaroColors.gold.withAlpha(10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: TaroColors.gold.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconFor(icon),
                              color: TaroColors.gold,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (desc != null && desc.isNotEmpty)
                                  Text(
                                    desc,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(160),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (count.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: TaroColors.gold.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                count,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: TaroColors.gold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: TaroColors.gold.withAlpha(120),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
