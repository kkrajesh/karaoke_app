import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HostSecurityState {
  final String pin;
  final List<String> activeTokens;

  HostSecurityState({required this.pin, this.activeTokens = const []});

  HostSecurityState copyWith({String? pin, List<String>? activeTokens}) {
    return HostSecurityState(
      pin: pin ?? this.pin,
      activeTokens: activeTokens ?? this.activeTokens,
    );
  }
}

class HostSecurityNotifier extends Notifier<HostSecurityState> {
  @override
  HostSecurityState build() {
    final random = Random();
    final pin = (1000 + random.nextInt(9000)).toString(); // 4 digit pin
    return HostSecurityState(pin: pin);
  }

  String generateToken() {
    final token = List.generate(6, (_) => "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"[Random().nextInt(36)]).join();
    state = state.copyWith(activeTokens: [...state.activeTokens, token]);
    return token;
  }

  bool verifyPinOrToken(String input) {
    if (input == state.pin) return true;
    if (state.activeTokens.contains(input)) {
      final newTokens = List<String>.from(state.activeTokens)..remove(input);
      state = state.copyWith(activeTokens: newTokens);
      return true;
    }
    return false;
  }
}

final hostSecurityProvider = NotifierProvider<HostSecurityNotifier, HostSecurityState>(() {
  return HostSecurityNotifier();
});
