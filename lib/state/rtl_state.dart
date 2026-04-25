import 'package:flutter_riverpod/flutter_riverpod.dart';

class RtlNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void setEnabled(bool enabled) {
    state = enabled;
  }
}

final rtlEnabledProvider =
    NotifierProvider<RtlNotifier, bool>(RtlNotifier.new);
