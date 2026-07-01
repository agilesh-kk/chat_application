class EmojiUtils {
  static bool isOnlyEmojis(String text) {
    final cleaned = text.replaceAll(_vsAndZwj, '');
    if (cleaned.isEmpty) return false;
    for (final rune in cleaned.runes) {
      if (!_isEmojiCodePoint(rune)) return false;
    }
    return true;
  }

  static int countEmojis(String text) {
    final cleaned = text.replaceAll(_vsAndZwj, '');
    int count = 0;
    for (final rune in cleaned.runes) {
      if (_isEmojiCodePoint(rune)) count++;
    }
    return count;
  }

  static String? extractSingleEmoji(String text) {
    final cleaned = text.replaceAll(_vsAndZwj, '');
    final emojis = <String>[];
    final sb = StringBuffer();
    for (final rune in cleaned.runes) {
      if (_isEmojiCodePoint(rune)) {
        sb.writeCharCode(rune);
      } else {
        if (sb.isNotEmpty) {
          emojis.add(sb.toString());
          sb.clear();
        }
      }
    }
    if (sb.isNotEmpty) {
      emojis.add(sb.toString());
    }
    return emojis.length == 1 ? emojis.first : null;
  }

  static final RegExp _vsAndZwj = RegExp(r'[\uFE0F\u200D]');

  static bool _isEmojiCodePoint(int code) {
    return (code >= 0x1F600 && code <= 0x1F64F) || // Emoticons
        (code >= 0x1F300 && code <= 0x1F5FF) || // Misc Symbols
        (code >= 0x1F680 && code <= 0x1F6FF) || // Transport
        (code >= 0x1F1E0 && code <= 0x1F1FF) || // Regional Indicators (flags)
        (code >= 0x2600 && code <= 0x27BF) || // Misc + Dingbats
        (code >= 0x2300 && code <= 0x23FF) || // Misc Technical
        (code >= 0x24C2 && code <= 0x24C2) || // Ⓜ
        (code >= 0x25AA && code <= 0x25AB) || // ▪ ▫
        (code >= 0x25B6 && code <= 0x25B6) || // ▶
        (code >= 0x25C0 && code <= 0x25C0) || // ◀
        (code >= 0x25FB && code <= 0x25FE) || // ◻ ◼ ◽ ◾
        (code >= 0x2600 && code <= 0x27BF) || // Misc Symbols + Dingbats
        (code >= 0x2934 && code <= 0x2935) || // ⤴ ⤵
        (code >= 0x2B05 && code <= 0x2B07) || // ⬅ ⬆ ⬇
        (code >= 0x2B1B && code <= 0x2B1C) || // ⬛ ⬜
        (code >= 0x2B50 && code <= 0x2B50) || // ⭐
        (code >= 0x2B55 && code <= 0x2B55) || // ⭕
        (code >= 0x3030 && code <= 0x3030) || // 〰
        (code >= 0x303D && code <= 0x303D) || // 〽
        (code >= 0x3297 && code <= 0x3297) || // ㊗
        (code >= 0x3299 && code <= 0x3299) || // ㊙
        (code >= 0xFE00 && code <= 0xFE0F) || // Variation Selectors
        (code >= 0x1F900 && code <= 0x1F9FF) || // Supplemental
        (code >= 0x1FA00 && code <= 0x1FA6F) || // Chess
        (code >= 0x1FA70 && code <= 0x1FAFF) || // Extended-A
        (code >= 0x200D && code <= 0x200D) || // ZWJ
        code == 0x00A9 || code == 0x00AE || // © ®
        code == 0x203C || code == 0x2049 || // ‼ ⁉
        code == 0x2122 || code == 0x2139 || // ™ ℹ
        code == 0x2194 || code == 0x2195 || // ↔ ↕
        code == 0x2196 || code == 0x2197 || // ↖ ↗
        code == 0x2198 || code == 0x2199 || // ↘ ↙
        code == 0x21A9 || code == 0x21AA || // ↩ ↪
        code == 0x231A || code == 0x231B || // ⌚ ⌛
        code == 0x2328 || code == 0x23CF || // ⌨ ⏏
        code == 0x23E9 || code == 0x23EA || // ⏩ ⏪
        code == 0x23EB || code == 0x23EC || // ⏫ ⏬
        code == 0x23ED || code == 0x23EE || // ⏭ ⏮
        code == 0x23EF || code == 0x23F0 || // ⏯ ⏰
        code == 0x23F1 || code == 0x23F2 || // ⏱ ⏲
        code == 0x23F3 || code == 0x23F8 || // ⏳ ⏸
        code == 0x23F9 || code == 0x23FA || // ⏹ ⏺
        code == 0x2648 || code == 0x2649 || // ♈ ♉
        code == 0x264A || code == 0x264B || // ♊ ♋
        code == 0x264C || code == 0x264D || // ♌ ♍
        code == 0x264E || code == 0x264F || // ♎ ♏
        code == 0x2650 || code == 0x2651 || // ♐ ♑
        code == 0x2652 || code == 0x2653 || // ♒ ♓
        code == 0x2660 || code == 0x2663 || // ♠ ♣
        code == 0x2665 || code == 0x2666 || // ♥ ♦
        code == 0x2668 || code == 0x267B || // ♨ ♻
        code == 0x267E || code == 0x267F || // ♾ ♿
        code == 0x2692 || code == 0x2693 || // ⚒ ⚓
        code == 0x2694 || code == 0x2695 || // ⚔ ⚕
        code == 0x2696 || code == 0x2697 || // ⚖ ⚗
        code == 0x2698 || code == 0x2699 || // ⚘ ⚙
        code == 0x269A || code == 0x269B || // ⚚ ⚛
        code == 0x269C || code == 0x26A0 || // ⚜ ⚠
        code == 0x26A1 || code == 0x26A7 || // ⚡ ⚧
        code == 0x26AA || code == 0x26AB || // ⚪ ⚫
        code == 0x26B0 || code == 0x26B1 || // ⚰ ⚱
        code == 0x26BD || code == 0x26BE || // ⚽ ⚾
        code == 0x26C4 || code == 0x26C5 || // ⛄ ⛅
        code == 0x26CE || code == 0x26CF || // ⛎ ⛏
        code == 0x26D1 || code == 0x26D3 || // ⛑ ⛓
        code == 0x26D4 || code == 0x26E9 || // ⛔ ⛩
        code == 0x26EA || code == 0x26F0 || // ⛪ ⛰
        code == 0x26F1 || code == 0x26F2 || // ⛱ ⛲
        code == 0x26F3 || code == 0x26F4 || // ⛳ ⛴
        code == 0x26F5 || code == 0x26F7 || // ⛵ ⛷
        code == 0x26F8 || code == 0x26F9 || // ⛸ ⛹
        code == 0x26FA || code == 0x26FB || // ⛺ ⛻
        code == 0x26FC || code == 0x26FD || // ⛼ ⛽
        code == 0x26FE || code == 0x26FF || // ⛾ ⛿
        code == 0x2702 || code == 0x2705 || // ✂ ✅
        code == 0x2708 || code == 0x2709 || // ✈ ✉
        code == 0x270A || code == 0x270B || // ✊ ✋
        code == 0x270C || code == 0x270D || // ✌ ✍
        code == 0x270F || code == 0x2712 || // ✏ ✒
        code == 0x2714 || code == 0x2716 || // ✔ ✖
        code == 0x271D || code == 0x2721 || // ✝ ✡
        code == 0x2728 || code == 0x2733 || // ✨ ✳
        code == 0x2734 || code == 0x2744 || // ✴ ❄
        code == 0x2747 || code == 0x274C || // ❇ ❌
        code == 0x274E || code == 0x2753 || // ❎ ❓
        code == 0x2754 || code == 0x2755 || // ❔ ❕
        code == 0x2757 || code == 0x2763 || // ❗ ❣
        code == 0x2764 || code == 0x2795 || // ❤ ➕
        code == 0x2796 || code == 0x2797 || // ➖ ➗
        code == 0x27A1 || code == 0x27B0 || // ➡ ➰
        code == 0x27BF ||                      // ➿
        code == 0x2934 || code == 0x2935 || // ⤴ ⤵
        code == 0x2B05 || code == 0x2B06 || // ⬅ ⬆
        code == 0x2B07 || code == 0x2B1B || // ⬇ ⬛
        code == 0x2B1C || code == 0x2B50 || // ⬜ ⭐
        code == 0x2B55 || code == 0x3030 || // ⭕ 〰
        code == 0x303D || code == 0x3297 || // 〽 ㊗
        code == 0x3299;                         // ㊙
  }
}
