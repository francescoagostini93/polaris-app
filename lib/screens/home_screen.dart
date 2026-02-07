import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/polaris_logo.dart';
import 'session_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Theme toggle at top right
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    settings.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : settings.themeMode == ThemeMode.light
                            ? Icons.dark_mode
                            : Icons.brightness_auto,
                  ),
                  tooltip: 'Cambia tema',
                  onPressed: () {
                    // Cycle: system -> light -> dark -> system
                    final next = switch (settings.themeMode) {
                      ThemeMode.system => ThemeMode.light,
                      ThemeMode.light => ThemeMode.dark,
                      ThemeMode.dark => ThemeMode.system,
                    };
                    settings.setThemeMode(next);
                  },
                ),
              ),

              const Spacer(flex: 1),

              // Neuron Logo
              const PolarisLogo(size: 100),

              const SizedBox(height: 24),

              // Title
              Text(
                'Polaris',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Stimolazione cognitiva con intelligenza artificiale',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Large round START button with logo overlay
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SessionScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'INIZIA',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Info Cards
              _buildInfoRow(
                context,
                icon: Icons.speed,
                label: 'Difficolt\u00e0',
                value: '${settings.defaultDifficulty}/10',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.email,
                label: 'Email',
                value: settings.isEmailConfigured
                    ? settings.email
                    : 'Non configurata',
                warning: !settings.isEmailConfigured,
              ),

              const SizedBox(height: 16),

              // Settings Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Impostazioni'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool warning = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: warning
            ? Colors.orange.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: warning ? Colors.orange : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: warning ? Colors.orange : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
