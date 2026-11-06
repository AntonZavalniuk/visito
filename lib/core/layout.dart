import 'package:flutter/widgets.dart';

/// Approximate height of the floating bottom navigation bar.
const double kNavBarHeight = 60;

/// Gap between the bottom of the screen (above the system inset) and the navbar.
const double kNavBarBottomMargin = 16;

/// Space that floating content must leave at the bottom so it is not covered
/// by the navbar, including the device's bottom safe-area inset.
double navBarClearance(BuildContext context, {double gap = 16}) {
  return MediaQuery.paddingOf(context).bottom +
      kNavBarBottomMargin +
      kNavBarHeight +
      gap;
}
