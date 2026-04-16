// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _districtController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DiagnosisProvider>();
    _nameController     = TextEditingController(text: provider.farmerName);
    _districtController = TextEditingController(text: provider.farmerDistrict);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(
            title: const Text('Settings'),
            leading: BackButton(
              onPressed: () => context.go(AppRoutes.home),
            ),
          ),
          body: Column(
            children: [
              if (provider.offlineMode) const OfflineBanner(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Profile Card ────────────────────────────────────────
                    _ProfileCard(
                      nameController:     _nameController,
                      districtController: _districtController,
                      onSave: () {
                        provider.setFarmerName(_nameController.text.trim());
                        provider.setFarmerDistrict(
                            _districtController.text.trim());
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile saved! ✅'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(label: 'App Settings'),
                    const SizedBox(height: 8),

                    // Language
                    _SettingsRow(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.deepGreen,
                      title: 'Language / Bhasha',
                      subtitle: _currentLangName(provider.selectedLanguage),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.lightGrey),
                      onTap: () => _showLanguageSheet(context, provider),
                    ),

                    // Voice output
                    _SettingsRow(
                      icon: Icons.volume_up_rounded,
                      iconColor: AppColors.amber,
                      title: 'Voice Output',
                      subtitle: 'Awaaz se jawab sunein',
                      trailing: Switch(
                        value: provider.voiceEnabled,
                        activeColor: AppColors.deepGreen,
                        onChanged: (val) => provider.setVoiceEnabled(val),
                      ),
                    ),

                    // Text size
                    _SettingsSizeRow(provider: provider),

                    // Offline mode
                    _SettingsRow(
                      icon: Icons.cloud_off_rounded,
                      iconColor: provider.offlineMode
                          ? AppColors.amber
                          : AppColors.lightGrey,
                      title: 'Offline Mode',
                      subtitle: 'Seemit vishleshan (cached data)',
                      trailing: Switch(
                        value: provider.offlineMode,
                        activeColor: AppColors.amber,
                        onChanged: (val) => provider.setOfflineMode(val),
                      ),
                    ),

                    // Anonymous data sharing
                    _SettingsRow(
                      icon: Icons.shield_rounded,
                      iconColor: AppColors.deepGreen,
                      title: 'Anonymous Data Sharing',
                      subtitle:
                          'Aapka data sirf app ko behtar banane ke liye',
                      trailing: Switch(
                        value: false,
                        activeColor: AppColors.deepGreen,
                        onChanged: (_) =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Coming in next version')),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Support'),
                    const SizedBox(height: 8),

                    // Help FAQ
                    _SettingsRow(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppColors.deepGreen,
                      title: 'Help / FAQ',
                      subtitle: 'Sawaal aur jawab',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.lightGrey),
                      onTap: () => _showPlaceholderDialog(
                          context, 'Help', 'FAQ coming soon!'),
                    ),

                    // Contact helpline
                    _SettingsRow(
                      icon: Icons.phone_rounded,
                      iconColor: AppColors.successGreen,
                      title: 'Contact Helpline',
                      subtitle: 'Kisan Helpline: 1800-180-1551',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.lightGrey),
                      onTap: () => _showPlaceholderDialog(
                        context,
                        'Kisan Helpline',
                        'Kisan Helpline Number: 1800-180-1551\n'
                            'KVK Helpline: 1800-103-1136\n'
                            '(Toll Free)',
                      ),
                    ),

                    const SizedBox(height: 30),

                    // App version footer
                    Center(
                      child: Text(
                        'KrishiAvalokan v1.0\nKisan ke liye, Kisan ke saath 🌾',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.lightGrey,
                                  height: 1.6,
                                ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _SettingsBottomNav(),
        );
      },
    );
  }

  String _currentLangName(String code) {
    final lang = AppLanguages.languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'english': 'Hindi'},
    );
    return lang['english'] ?? 'Hindi';
  }

  void _showLanguageSheet(BuildContext ctx, DiagnosisProvider provider) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Bhasha Chuniye',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                children: AppLanguages.languages.map((lang) {
                  final isSelected =
                      provider.selectedLanguage == lang['code'];
                  return ListTile(
                    leading: Text(lang['name']!,
                        style: const TextStyle(fontSize: 18)),
                    title: Text(lang['english']!),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.deepGreen)
                        : null,
                    onTap: () {
                      provider.setLanguage(lang['code']!);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholderDialog(
      BuildContext ctx, String title, String message) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Theek Hai',
                style: TextStyle(color: AppColors.deepGreen)),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController districtController;
  final VoidCallback onSave;

  const _ProfileCard({
    required this.nameController,
    required this.districtController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                    child: Text('🧑‍🌾',
                        style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Kisan Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: onSave,
                child: const Text('Save',
                    style: TextStyle(color: AppColors.deepGreen)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Aapka Naam / Your Name',
              prefixIcon:
                  Icon(Icons.person_rounded, color: AppColors.deepGreen),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: districtController,
            decoration: const InputDecoration(
              labelText: 'Aapka Zila / Your District',
              prefixIcon: Icon(Icons.location_on_rounded,
                  color: AppColors.deepGreen),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Settings Row ─────────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 4,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ── Text Size Row ─────────────────────────────────────────────────────────────
class _SettingsSizeRow extends StatelessWidget {
  final DiagnosisProvider provider;
  const _SettingsSizeRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.text_fields_rounded,
                    color: AppColors.deepGreen, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Text Size',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Aksharon ka aakaar',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text(
                _scaleLabel(provider.textScale),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepGreen),
              ),
            ],
          ),
          Slider(
            value: provider.textScale,
            min: 0.8,
            max: 1.4,
            divisions: 3,
            activeColor: AppColors.deepGreen,
            label: _scaleLabel(provider.textScale),
            onChanged: (val) => provider.setTextScale(val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('A',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 10)),
              Text('A',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 14)),
              Text('A',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 18)),
              Text('A',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }

  String _scaleLabel(double val) {
    if (val <= 0.8) return 'Small';
    if (val <= 1.0) return 'Normal';
    if (val <= 1.2) return 'Large';
    return 'X-Large';
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.midGrey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _SettingsBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: 3,
          elevation: 0,
          backgroundColor: Colors.transparent,
          onTap: (i) {
            switch (i) {
              case 0: context.go(AppRoutes.home);
              case 1:
                context.read<DiagnosisProvider>().resetDiagnosis();
                context.go(AppRoutes.step1);
              case 2: context.go(AppRoutes.history);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.biotech_rounded), label: 'New Analysis'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
