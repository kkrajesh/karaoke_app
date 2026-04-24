import 'dart:async';
import '../models/app_user.dart';

class AuthService {
  // Simulating Auth State with a simple stream
  final _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  AppUser? get currentUser => _currentUser;

  Future<AppUser?> signIn({
    required String name,
    String? email,
    String? phone,
  }) async {
    // Generate a simple ID based on timestamp
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    _currentUser = AppUser(
      id: id,
      name: name,
      role: UserRole.none,
      email: email,
      phone: phone,
    );
    
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }
}
