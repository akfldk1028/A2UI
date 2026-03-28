class TarotMessage {
  TarotMessage({this.text, this.surfaceId, this.isUser = false});

  final String? text;
  final String? surfaceId;
  final bool isUser;
}
