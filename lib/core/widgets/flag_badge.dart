import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Emoji flags of UK constituent countries (Northern Ireland has none).
const Map<String, String> _subdivisionFlags = {
  'XEN': 'gbeng',
  'XSC': 'gbsct',
  'XWA': 'gbwls',
};

/// Flag emoji for a two-letter ISO 3166-1 [code]; null for anything else
/// (user-assigned or alpha-3 codes), which have no emoji flag.
String? flagEmoji(String code) {
  final subdivision = _subdivisionFlags[code];
  if (subdivision != null) {
    // Black flag + tag letters + cancel tag (e.g. gbeng).
    return String.fromCharCodes([
      0x1F3F4,
      for (final u in subdivision.codeUnits) 0xE0000 + u,
      0xE007F,
    ]);
  }
  if (code.length != 2) return null;
  final upper = code.toUpperCase();
  const a = 0x41, regionalA = 0x1F1E6;
  final units = upper.codeUnits;
  if (units.any((u) => u < a || u > a + 25)) return null;
  return String.fromCharCodes([for (final u in units) u - a + regionalA]);
}

/// Fixed-size flag shown at the start of every row; a muted flag icon stands
/// in when the entry has no flag emoji.
class FlagBadge extends StatelessWidget {
  const FlagBadge({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final flag = flagEmoji(code);
    return SizedBox(
      width: 32,
      child: Center(
        child: flag != null
            ? Text(flag, style: const TextStyle(fontSize: 24))
            : const Icon(
                Icons.flag_outlined,
                size: 22,
                color: AppColors.textMuted,
              ),
      ),
    );
  }
}
