import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/styled_card.dart';
import 'host_dashboard.dart';
import 'singer_dashboard.dart';
import 'audience_dashboard.dart';
import 'public_display_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _signInLocally() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await ref.read(appStateProvider.notifier).signIn(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );
    setState(() => _isLoading = false);
  }

  void _selectRole(UserRole role) {
    ref.read(appStateProvider.notifier).selectRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Builder(
            builder: (context) {
              if (appState.selectedRole == UserRole.none) {
                return _buildRoleSelection();
              }
              if (appState.user == null) {
                return _buildAuthScreen();
              }

              // Route based on role
              switch (appState.user!.role) {
                case UserRole.host:
                  return const HostDashboard();
                case UserRole.singer:
                  return const SingerDashboard();
                case UserRole.audience:
                  return const AudienceDashboard();
                case UserRole.publicDisplay:
                  return const PublicDisplayScreen();
                default:
                  return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
      floatingActionButton: appState.selectedRole != UserRole.none ? FloatingActionButton(
        backgroundColor: AppTheme.bgInput,
        onPressed: () {
          if (appState.user != null) {
            ref.read(appStateProvider.notifier).signOut();
          } else {
            ref.read(appStateProvider.notifier).clearRole();
          }
        },
        child: Icon(appState.user != null ? Icons.logout : Icons.arrow_back, color: AppTheme.textMuted),
      ) : null,
    );
  }

  Widget _buildAuthScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Join the Party!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (Required)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple))
            else
              ElevatedButton(
                onPressed: _signInLocally,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Join the Party', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GradientText(
                'Karaoke Night Live',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your ultimate karaoke party companion',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const Text(
                'Join the Party! Who are you?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildRoleCard(
                    title: "I'm the Host",
                    icon: Icons.stars,
                    description: 'Manage the queue, control the music, and run the show.',
                    onTap: () => _selectRole(UserRole.host),
                  ),
                  _buildRoleCard(
                    title: "I'm a Singer",
                    icon: Icons.mic,
                    description: 'Browse the song library, pick your anthem, and sign up to perform.',
                    onTap: () => _selectRole(UserRole.singer),
                  ),
                  _buildRoleCard(
                    title: "I'm in the Audience",
                    icon: Icons.people,
                    description: 'Watch performances, send reactions, and request songs for others.',
                    onTap: () => _selectRole(UserRole.audience),
                  ),
                  _buildRoleCard(
                    title: "Public Display",
                    icon: Icons.tv,
                    description: 'Launch the full-screen stage view with live audience reactions overlaid.',
                    onTap: () => _selectRole(UserRole.publicDisplay),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 260,
      height: 260,
      child: StyledCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppTheme.accentPurpleLight),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
