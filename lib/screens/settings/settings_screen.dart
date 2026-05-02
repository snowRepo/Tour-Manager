import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../database/db_helper.dart';
import '../../services/pdf_service.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/screen_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pdf = PdfService();
  final _imagePicker = ImagePicker();

  late final TextEditingController _bizNameCtrl;
  late final TextEditingController _bizPhoneCtrl;
  late final TextEditingController _bizEmailCtrl;
  late final TextEditingController _tncCtrl;

  String? _logoPath;
  bool _isSavingBiz = false;
  bool _isSavingTnc = false;
  bool _isPrinting = false;
  final _db = DbHelper();
  final _deletePasswordCtrl = TextEditingController();
  final _deletePinCtrl = TextEditingController();
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _bizNameCtrl = TextEditingController(text: settings.businessName);
    _bizPhoneCtrl = TextEditingController(text: settings.businessPhone);
    _bizEmailCtrl = TextEditingController(text: settings.businessEmail);
    _tncCtrl = TextEditingController(text: settings.termsAndConditions);
    _logoPath = settings.businessLogo.isNotEmpty ? settings.businessLogo : null;
  }

  Future<void> _pickLogo() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      final base64 = base64Encode(bytes);
      setState(() => _logoPath = base64);
      await context.read<SettingsProvider>().updateBusinessLogo(base64);
      if (mounted) {
        showAppBanner(
          context,
          'Logo saved',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      }
    }
  }

  Future<void> _removeLogo() async {
    setState(() => _logoPath = null);
    await context.read<SettingsProvider>().updateBusinessLogo('');
    if (mounted) {
      showAppBanner(
        context,
        'Logo removed',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );
    }
  }

  @override
  void dispose() {
    _bizNameCtrl.dispose();
    _bizPhoneCtrl.dispose();
    _bizEmailCtrl.dispose();
    _tncCtrl.dispose();
    _deletePasswordCtrl.dispose();
    _deletePinCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBusinessInfo() async {
    setState(() => _isSavingBiz = true);
    final prov = context.read<SettingsProvider>();
    await prov.updateBusinessName(_bizNameCtrl.text.trim());
    await prov.updateBusinessPhone(_bizPhoneCtrl.text.trim());
    await prov.updateBusinessEmail(_bizEmailCtrl.text.trim());
    if (mounted) {
      setState(() => _isSavingBiz = false);
      showAppBanner(
        context,
        'Business info saved',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );
    }
  }

  Future<void> _saveTerms() async {
    setState(() => _isSavingTnc = true);
    await context.read<SettingsProvider>().updateTermsAndConditions(
      _tncCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _isSavingTnc = false);
      showAppBanner(
        context,
        'Terms & Conditions saved',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );
    }
  }

  Future<void> _printTerms() async {
    setState(() => _isPrinting = true);
    try {
      final settings = context.read<SettingsProvider>().settings;
      await _pdf.printTermsOnly(settings: Map<String, String>.from(settings));
    } catch (e) {
      if (mounted) {
        showAppBanner(
          context,
          'Print error: $e',
          backgroundColor: AppColors.error,
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<String?> _promptCredential({
    required String title,
    required String label,
    required TextEditingController controller,
  }) async {
    controller.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return confirmed == true ? controller.text.trim() : null;
  }

  Future<void> _deleteAccount() async {
    final authProv = context.read<AuthProvider>();
    final username = authProv.currentUser?.username;
    if (username == null) return;

    final password = await _promptCredential(
      title: 'Confirm Password',
      label: 'Account password',
      controller: _deletePasswordCtrl,
    );
    if (password == null) return;

    final passwordValid = await authProv.verifyPassword(username, password);
    if (!passwordValid) {
      showAppBanner(
        context,
        'Password incorrect',
        backgroundColor: AppColors.error,
        icon: Icons.lock_outline,
      );
      return;
    }

    final pin = await _promptCredential(
      title: 'Confirm PIN',
      label: 'Account PIN',
      controller: _deletePinCtrl,
    );
    if (pin == null) return;

    final pinValid = await authProv.verifyPin(username, pin);
    if (!pinValid) {
      showAppBanner(
        context,
        'PIN incorrect',
        backgroundColor: AppColors.error,
        icon: Icons.pin,
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Account',
      message:
          'This will permanently delete your account and all stored data. This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;

    setState(() => _isDeletingAccount = true);
    try {
      await _db.deleteAllData();
      await authProv.clearSetupComplete();
      authProv.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppBanner(
          context,
          'Delete failed: $e',
          backgroundColor: AppColors.error,
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: ScreenBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Business Info ──────────────────────────────────────────
                _sectionHeader(
                  icon: Icons.business_rounded,
                  title: 'Business Information',
                  subtitle: 'This appears on printed documents',
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    children: [
                      // Logo picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: _logoPath != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          base64Decode(_logoPath!),
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: _removeLogo,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 32,
                                        color: AppColors.textSecondary,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Add Logo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to add logo (appears on prints)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _bizNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bizPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Business Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bizEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Business Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSavingBiz ? null : _saveBusinessInfo,
                        child: _isSavingBiz
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Business Info'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Terms & Conditions ─────────────────────────────────────
                _sectionHeader(
                  icon: Icons.gavel_rounded,
                  title: 'Terms & Conditions',
                  subtitle:
                      'Included in trip agreements and standalone T&C prints',
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _tncCtrl,
                        maxLines: 10,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          hintText: 'Enter your terms and conditions here...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: _isSavingTnc ? null : _saveTerms,
                              child: _isSavingTnc
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save T&C'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isPrinting ? null : _printTerms,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                              ),
                              child: _isPrinting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.print_rounded, size: 16),
                                        SizedBox(width: 6),
                                        Text('Print T&C'),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Account Management ─────────────────────────────────────
                _sectionHeader(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Account',
                  subtitle: 'This removes your account and all data',
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deleting your account will remove all clients, trips, payments, and settings from this device.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: _isDeletingAccount ? null : _deleteAccount,
                        child: _isDeletingAccount
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Delete Account'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── App Info ───────────────────────────────────────────────
                _sectionHeader(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    children: [
                      _aboutRow('App', AppStrings.appName),
                      _aboutRow('Version', '1.0.0'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
