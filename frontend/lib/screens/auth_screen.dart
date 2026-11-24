import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/services/app_settings_provider.dart';
import 'package:ekride_frontend/services/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginEmailController = TextEditingController(text: 'teststudent@univ.edu');
  final _loginPassController = TextEditingController(text: 'password123');

  // Register Controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPassController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regUnivController = TextEditingController(text: 'University of Dhaka');
  final _regStudentIdController = TextEditingController();
  final String _selectedRole = 'PASSENGER';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appSettings = context.watch<AppSettingsProvider>();

    final isDark = appSettings.isDarkMode;
    final isBn = appSettings.isBangla;

    final bg = AppTheme.getBackground(isDark);
    final surface = AppTheme.getSurface(isDark);
    final border = AppTheme.getBorder(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 470),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Action Row: Language + Theme Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Language Switcher Pill
                    InkWell(
                      onTap: () => appSettings.toggleLanguage(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.getSurfaceLight(isDark),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          isBn ? '🇧🇩 বাংলা' : '🇬🇧 English',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),

                    // Theme Toggle Button
                    IconButton(
                      tooltip: isDark ? appSettings.tr('theme_light') : appSettings.tr('theme_dark'),
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? AppTheme.accent : AppTheme.violet,
                        size: 20,
                      ),
                      onPressed: () => appSettings.toggleTheme(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // App Logo and Branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.directions_car_filled_rounded, color: Colors.black, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EkRide',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          appSettings.tr('app_subtitle'),
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceLight(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    tabs: [
                      Tab(text: appSettings.tr('sign_in')),
                      Tab(text: appSettings.tr('register_account')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (auth.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  height: 330,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Sign In View
                      Column(
                        children: [
                          _buildTextField(_loginEmailController, appSettings.tr('email_hint'), Icons.email_outlined, isDark),
                          const SizedBox(height: 16),
                          _buildTextField(_loginPassController, appSettings.tr('password_hint'), Icons.lock_outline, isDark, isObscure: true),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      await auth.login(
                                        _loginEmailController.text.trim(),
                                        _loginPassController.text.trim(),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : Text(
                                      appSettings.tr('sign_in_btn'),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 1-Tap Quick Demo Sign In Button
                          InkWell(
                            onTap: () async {
                              _loginEmailController.text = 'teststudent@univ.edu';
                              _loginPassController.text = 'password123';
                              await auth.login('teststudent@univ.edu', 'password123');
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: AppTheme.getSurfaceLight(isDark),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    appSettings.tr('demo_login_btn'),
                                    style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Register View
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildTextField(_regNameController, appSettings.tr('fullname_hint'), Icons.person_outline, isDark),
                            const SizedBox(height: 12),
                            _buildTextField(_regEmailController, appSettings.tr('campus_email_hint'), Icons.email_outlined, isDark),
                            const SizedBox(height: 12),
                            _buildTextField(_regPassController, appSettings.tr('password_hint'), Icons.lock_outline, isDark, isObscure: true),
                            const SizedBox(height: 12),
                            _buildTextField(_regUnivController, appSettings.tr('university_hint'), Icons.school_outlined, isDark),
                            const SizedBox(height: 12),
                            _buildTextField(_regStudentIdController, appSettings.tr('student_id_hint'), Icons.badge_outlined, isDark),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        await auth.register(
                                          email: _regEmailController.text.trim(),
                                          password: _regPassController.text.trim(),
                                          fullName: _regNameController.text.trim(),
                                          phone: _regPhoneController.text.trim(),
                                          university: _regUnivController.text.trim(),
                                          studentId: _regStudentIdController.text.trim(),
                                          role: _selectedRole,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : Text(
                                        appSettings.tr('create_account_btn'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isDark, {bool isObscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLight(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorder(isDark)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: TextStyle(color: AppTheme.getTextPrimary(isDark), fontSize: 13.5),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.getTextSecondary(isDark), size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.getTextMuted(isDark), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
