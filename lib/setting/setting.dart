import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentora/providers/language_provider.dart';
import 'package:mentora/screens/auth/main_auth.dart';
import 'package:mentora/screens/profile/profile_screen.dart';
import 'package:mentora/screens/skills/my_skill_screen.dart';
import 'package:mentora/services/setting_service.dart';
import 'package:mentora/providers/theme_provider.dart';
import 'package:mentora/setting/about.dart';
import 'package:mentora/setting/help_supporst.dart';
import 'package:mentora/setting/privacy_policy.dart';
import 'package:provider/provider.dart';

/// Settings screen with professional UI and organized sections
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;

  /// Handles user logout with confirmation
  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutConfirmation();
    if (!confirmed) return;

    setState(() => _isLoggingOut = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainAuth()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoggingOut = false);
      _showErrorSnackBar('Failed to logout. Please try again.');
    }
  }

  /// Shows logout confirmation dialog
  Future<bool> _showLogoutConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.logout, color: Colors.red[700]),
                const SizedBox(width: 12),
                const Text('Logout'),
              ],
            ),
            content: const Text(
              'Are you sure you want to logout from Mentora?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Handles password reset
  Future<void> _handlePasswordReset() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.email == null) {
      _showErrorSnackBar('No email associated with this account.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;

      _showSuccessSnackBar(
        'Password reset email sent to ${user.email}. Check your inbox.',
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to send password reset email.');
    }
  }

  /// Shows success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Gets localized text based on current language
  String _getLocalizedText(String en, String ur, String ar) {
    final lang = context.read<LanguageProvider>().languageCode;
    switch (lang) {
      case 'ur':
        return ur;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? null : Colors.grey[50],
      appBar: AppBar(
        title: Text(_getLocalizedText('Settings', 'ترتیبات', 'إعدادات')),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoggingOut
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Logging out...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Account Section
                _SettingsSection(
                  title: _getLocalizedText('Account', 'اکاؤنٹ', 'الحساب'),
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: _getLocalizedText(
                        'My Profile',
                        'میری پروفائل',
                        'ملفي',
                      ),
                      subtitle: 'View and edit your profile',
                      iconColor: Colors.blueAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.school_rounded,
                      title: _getLocalizedText(
                        'My Skills',
                        'میری مہارتیں',
                        'مهاراتي',
                      ),
                      subtitle: 'Manage offered and wanted skills',
                      iconColor: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MySkillsScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: _getLocalizedText(
                        'Change Password',
                        'پاس ورڈ تبدیل کریں',
                        'تغيير كلمة المرور',
                      ),
                      subtitle: 'Reset your password via email',
                      iconColor: Colors.orange,
                      onTap: _handlePasswordReset,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Preferences Section
                _SettingsSection(
                  title: _getLocalizedText(
                    'Preferences',
                    'ترجیحات',
                    'التفضيلات',
                  ),
                  children: [
                    // Notifications Toggle
                    StreamBuilder<bool>(
                      stream: SettingsService().notificationStatus(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const _LoadingTile(title: 'Notifications');
                        }

                        return _SettingsSwitchTile(
                          icon: Icons.notifications_outlined,
                          title: _getLocalizedText(
                            'Notifications',
                            'اطلاعات',
                            'إشعارات',
                          ),
                          subtitle: 'Receive updates and alerts',
                          iconColor: Colors.purple,
                          value: snapshot.data!,
                          onChanged: (value) {
                            SettingsService().updateNotification(value);
                            _showSuccessSnackBar(
                              value
                                  ? 'Notifications enabled'
                                  : 'Notifications disabled',
                            );
                          },
                        );
                      },
                    ),

                    // Dark Mode Toggle
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return _SettingsSwitchTile(
                          icon: themeProvider.isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          title: _getLocalizedText(
                            'Dark Mode',
                            'ڈارک موڈ',
                            'الوضع الداكن',
                          ),
                          subtitle: themeProvider.isDarkMode
                              ? 'Dark theme enabled'
                              : 'Light theme enabled',
                          iconColor: themeProvider.isDarkMode
                              ? Colors.indigo
                              : Colors.amber,
                          value: themeProvider.isDarkMode,
                          onChanged: themeProvider.toggleTheme,
                        );
                      },
                    ),

                    // Language Selector
                    Consumer<LanguageProvider>(
                      builder: (context, langProvider, _) {
                        return _SettingsDropdownTile(
                          icon: Icons.language_rounded,
                          title: _getLocalizedText('Language', 'زبان', 'اللغة'),
                          subtitle: _getLanguageName(langProvider.languageCode),
                          iconColor: Colors.teal,
                          value: langProvider.languageCode,
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'ur',
                              child: Text('اردو (Urdu)'),
                            ),
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text('العربية (Arabic)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              langProvider.setLanguage(value);
                              _showSuccessSnackBar('Language changed');
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // App Information Section
                _SettingsSection(
                  title: _getLocalizedText('App', 'ایپ', 'التطبيق'),
                  children: [
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: _getLocalizedText(
                        'Privacy Policy',
                        'پرائیویسی پالیسی',
                        'سياسة الخصوصية',
                      ),
                      subtitle: 'Read our privacy policy',
                      iconColor: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: _getLocalizedText(
                        'Help & Support',
                        'مدد اور تعاون',
                        'المساعدة والدعم',
                      ),
                      subtitle: 'Get help or contact support',
                      iconColor: Colors.cyan,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: _getLocalizedText(
                        'About Mentora',
                        'منٹورا کے بارے میں',
                        'حول منتورا',
                      ),
                      subtitle: 'Learn more about Mentora',
                      iconColor: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutMentoraScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _LogoutButton(onPressed: _handleLogout),
                ),

                const SizedBox(height: 16),

                // App Version (Optional)
                Center(
                  child: Text(
                    'Mentora v1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ur':
        return 'اردو (Urdu)';
      case 'ar':
        return 'العربية (Arabic)';
      default:
        return 'English';
    }
  }
}

// ==================== WIDGETS ====================

/// Settings section with title and children
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Standard settings tile with icon, title, and arrow
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings tile with switch toggle
class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings tile with dropdown
class _SettingsDropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _SettingsDropdownTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading tile placeholder
class _LoadingTile extends StatelessWidget {
  final String title;

  const _LoadingTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(title),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Logout button with destructive styling
class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
