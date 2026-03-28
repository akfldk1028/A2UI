import 'package:genui/genui.dart';

import 'draw_prompt.dart';
import 'oracle_message.dart';
import 'reading_summary.dart';
import 'spread_picker.dart';
import 'tarot_card.dart';

/// The catalog of UI components for AI-generated tarot consultations.
final Catalog taroCatalog = Catalog([
  CoreCatalogItems.text,
  CoreCatalogItems.column,
  tarotCard,
  readingSummary,
  spreadPicker,
  oracleMessage,
  drawPrompt,
], catalogId: 'taro-catalog');
