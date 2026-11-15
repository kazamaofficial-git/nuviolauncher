/// Splits a command-line style string into arguments, honouring quotes.
List<String> splitArguments(String input) {
  final out = <String>[];
  final buf = StringBuffer();
  String? quote;
  var pending = false;

  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    if (quote != null) {
      if (ch == quote) {
        quote = null;
      } else {
        buf.write(ch);
      }
    } else if (ch == '"' || ch == "'") {
      quote = ch;
      pending = true;
    } else if (ch.trim().isEmpty) {
      if (pending || buf.isNotEmpty) {
        out.add(buf.toString());
        buf.clear();
        pending = false;
      }
    } else {
      buf.write(ch);
      pending = true;
    }
  }
  if (pending || buf.isNotEmpty) out.add(buf.toString());
  return out;
}
