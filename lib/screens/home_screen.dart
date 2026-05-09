import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../providers/session_state_provider.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/styled_card.dart';
import 'host_dashboard.dart';
import 'singer_dashboard.dart';
import 'audience_dashboard.dart';
import 'public_display_screen.dart';
import '../services/local_server_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _instaController = TextEditingController();
  final TextEditingController _clientIpController = TextEditingController();
  bool _isLoading = false;
  bool _showJoinScreen = false;
  UserRole? _selectedRoleUi;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final roleStr = Uri.base.queryParameters['role'];
          if (roleStr != null) {
            UserRole? selected;
            if (roleStr == 'singer') selected = UserRole.singer;
            else if (roleStr == 'audience') selected = UserRole.audience;
            else if (roleStr == 'display') selected = UserRole.publicDisplay;
            
            if (selected != null) {
              ref.read(appStateProvider.notifier).selectRole(selected);
              ref.read(appStateProvider.notifier).signIn(name: 'Display Screen');
            }
          }
          
          final host = Uri.base.host;
          if (host.isNotEmpty) {
            ref.read(clientHostIpProvider.notifier).setIp(host);
          }
        } catch (e) {
          // ignore uri parsing errors
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _instaController.dispose();
    _clientIpController.dispose();
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
              if (appState.user != null) {
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
              }

              if (kIsWeb) {
                return _buildWebLandingScreen();
              } else {
                if (_showJoinScreen) return _buildJoinEventScreen();
                return _buildNativeLandingScreen();
              }
            },
          ),
        ),
      ),
      floatingActionButton: (appState.user != null || _showJoinScreen) ? FloatingActionButton(
        backgroundColor: AppTheme.bgInput,
        onPressed: () {
          if (appState.user != null) {
            ref.read(appStateProvider.notifier).signOut();
          } else if (_showJoinScreen) {
            setState(() => _showJoinScreen = false);
          }
        },
        child: Icon(appState.user != null ? Icons.logout : Icons.arrow_back, color: AppTheme.textMuted),
      ) : null,
    );
  }

  Widget _buildCompactRoleButton(String title, IconData icon, UserRole role, {bool isJoinScreen = false}) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentPurple,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        if (role == UserRole.publicDisplay && _nameController.text.trim().isEmpty) {
          _nameController.text = "Public Display";
        }
        if (role == UserRole.host && _nameController.text.trim().isEmpty) {
          _nameController.text = "Co-Host";
        }
        if (role == UserRole.audience && _nameController.text.trim().isEmpty) {
          _nameController.text = "Audience Member";
        }
        
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();
        final insta = _instaController.text.trim();

        if (role == UserRole.singer) {
          if (name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter your name')),
            );
            return;
          }
          if (email.isEmpty && phone.isEmpty && insta.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Singers must provide at least one contact method (Email, Phone, or Insta)')),
            );
            return;
          }
        } else {
          if (name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter your name first')),
            );
            return;
          }
        }
        
        if (isJoinScreen) {
          final ip = _clientIpController.text.trim();
          if (ip.isNotEmpty) {
            ref.read(clientHostIpProvider.notifier).setIp(ip);
          }
        }

        setState(() => _isLoading = true);
        ref.read(appStateProvider.notifier).selectRole(role);
        await ref.read(appStateProvider.notifier).signIn(
          name: name,
          email: email.isEmpty ? null : email,
          phone: phone.isEmpty ? null : phone,
          insta: insta.isEmpty ? null : insta,
        );
        setState(() => _isLoading = false);
      },
    );
  }

  Widget _buildWebLandingScreen() {
    final eventName = ref.watch(sessionStateProvider).eventName ?? 'Karaoke Night Live';
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to\n$eventName!',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textMain, height: 1.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (Required for Singers)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instaController,
              decoration: const InputDecoration(
                labelText: 'Instagram Handle',
                prefixText: '@',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Join as:', style: TextStyle(color: AppTheme.textMuted, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple))
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildCompactRoleButton('Singer', Icons.mic, UserRole.singer),
                  _buildCompactRoleButton('Audience', Icons.people, UserRole.audience),
                  _buildCompactRoleButton('Host', Icons.stars, UserRole.host),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinEventScreen() {
    final connectedHostIp = ref.watch(clientHostIpProvider);
    final isClientConnected = connectedHostIp != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Join a Party',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _clientIpController,
              decoration: InputDecoration(
                labelText: 'Event ID (Host IP Address)',
                hintText: 'e.g. 192.168.1.5',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, color: AppTheme.accentPurple),
                  onPressed: () {
                    final ip = _clientIpController.text.trim();
                    if (ip.isNotEmpty) {
                      ref.read(clientHostIpProvider.notifier).setIp(ip);
                    }
                  },
                ),
              ),
            ),
            if (isClientConnected) ...[
              const SizedBox(height: 8),
              Text('Connected to Host: $connectedHostIp', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (Required for Singers)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instaController,
              decoration: const InputDecoration(
                labelText: 'Instagram Handle',
                prefixText: '@',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Join as:', style: TextStyle(color: AppTheme.textMuted, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple))
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildCompactRoleButton('Singer', Icons.mic, UserRole.singer, isJoinScreen: true),
                  _buildCompactRoleButton('Audience', Icons.people, UserRole.audience, isJoinScreen: true),
                  _buildCompactRoleButton('Display', Icons.tv, UserRole.publicDisplay, isJoinScreen: true),
                  _buildCompactRoleButton('Host', Icons.stars, UserRole.host, isJoinScreen: true),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeLandingScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
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
            const SizedBox(height: 64),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _buildRoleCard(
                  title: "Start a Party (Host)",
                  icon: Icons.stars,
                  description: 'Start the server, manage the queue, and control the room.',
                  onTap: () async {
                    setState(() => _isLoading = true);
                    ref.read(appStateProvider.notifier).selectRole(UserRole.host);
                    await ref.read(appStateProvider.notifier).signIn(name: 'Host', isPrimaryHost: true);
                    setState(() => _isLoading = false);
                  },
                ),
                _buildRoleCard(
                  title: "Join a Party",
                  icon: Icons.people,
                  description: 'Connect to an existing host on your local network.',
                  onTap: () => setState(() => _showJoinScreen = true),
                ),
              ],
            ),
          ],
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
