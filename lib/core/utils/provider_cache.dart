import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension ProviderCache on Ref {
  /// Keeps an autoDispose provider's state alive for [duration] after the last
  /// listener is removed. Re-navigating to the screen within this window reuses
  /// the cached data instead of triggering a new API/DB request. Once the
  /// window elapses with no listeners, the provider disposes normally.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
