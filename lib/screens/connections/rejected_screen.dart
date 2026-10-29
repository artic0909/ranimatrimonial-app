import 'package:flutter/widgets.dart';
import 'declined_screen.dart';

export 'declined_screen.dart';

/// Backward-compatible alias for RaniDeclinedConnectionsScreen
class RaniRejectedConnectionsScreen extends StatelessWidget {
  final bool showAppBar;
  final VoidCallback? onCountChanged;

  const RaniRejectedConnectionsScreen({
    super.key,
    this.showAppBar = false,
    this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RaniDeclinedConnectionsScreen(
      showAppBar: showAppBar,
      onCountChanged: onCountChanged,
    );
  }
}
