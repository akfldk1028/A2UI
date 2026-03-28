import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  final Function(String) onSend;
  final bool enabled;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final active = _hasText && widget.enabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            TaroColors.background.withAlpha(200),
            TaroColors.background,
          ],
        ),
        border: Border(
          top: BorderSide(color: TaroColors.gold.withAlpha(20)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E1035), Color(0xFF140B28)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: active
                        ? TaroColors.gold.withAlpha(60)
                        : TaroColors.gold.withAlpha(25),
                  ),
                  boxShadow: active
                      ? [BoxShadow(
                          color: TaroColors.gold.withAlpha(8),
                          blurRadius: 12,
                        )]
                      : null,
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'reading.inputHint'.tr(),
                    hintStyle: TextStyle(
                      color: TaroColors.gold.withAlpha(60),
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _handleSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: active
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD4AF37), Color(0xFFB8962E)],
                        )
                      : null,
                  color: active ? null : TaroColors.surface,
                  border: active
                      ? null
                      : Border.all(color: TaroColors.gold.withAlpha(25)),
                  boxShadow: active
                      ? [BoxShadow(
                          color: TaroColors.gold.withAlpha(40),
                          blurRadius: 12,
                        )]
                      : null,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 22,
                  color: active
                      ? const Color(0xFF0D0520)
                      : TaroColors.gold.withAlpha(60),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
