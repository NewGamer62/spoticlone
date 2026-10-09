class LyricsLine {
  final Duration timestamp;
  final String text;

  const LyricsLine({
    required this.timestamp,
    required this.text,
  });

  /// Parse an LRC string line like: [00:15.30] Never gonna give you up
  static List<LyricsLine> parseLrc(String? lrcContent) {
    if (lrcContent == null || lrcContent.trim().isEmpty) {
      return [];
    }

    final lines = <LyricsLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.?(\d{0,3})\](.*)');

    for (final rawLine in lrcContent.split('\n')) {
      final match = regex.firstMatch(rawLine.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3) ?? '0';
        final millis = millisStr.isEmpty ? 0 : int.parse(millisStr.padRight(3, '0').substring(0, 3));

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );
        final text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          lines.add(LyricsLine(timestamp: duration, text: text));
        }
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }
}
