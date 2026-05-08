import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

class AppState {
  final AppUser? user;
  final UserRole selectedRole;

  AppState({this.user, this.selectedRole = UserRole.none});

  AppState copyWith({AppUser? user, UserRole? selectedRole}) {
    return AppState(
      user: user ?? this.user,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    return AppState();
  }

  void selectRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  void clearRole() {
    state = AppState(user: state.user, selectedRole: UserRole.none);
  }

  void changeRole(UserRole role) {
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(role: role),
        selectedRole: role,
      );
    }
  }

  Future<void> signIn({required String name, String? email, String? phone}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = AppUser(
      id: id,
      name: name,
      role: state.selectedRole,
      email: email,
      phone: phone,
    );
    state = state.copyWith(user: user);
  }

  void signOut() {
    state = AppState(); // Resets everything
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(() {
  return AppStateNotifier();
});

// Deprecated: kept for backwards compatibility if needed elsewhere temporarily
final appUserProvider = Provider<AppUser?>((ref) => ref.watch(appStateProvider).user);

// For Native Client Mode: stores the IP address of the Host to connect to
class ClientHostIpNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setIp(String? ip) => state = ip;
}

final clientHostIpProvider = NotifierProvider<ClientHostIpNotifier, String?>(() {
  return ClientHostIpNotifier();
});
