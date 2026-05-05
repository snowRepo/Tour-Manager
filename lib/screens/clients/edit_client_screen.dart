import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/screen_background.dart';

class EditClientScreen extends StatefulWidget {
  final ClientModel client;
  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _otherNamesCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;
  late String _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _firstNameCtrl = TextEditingController(text: c.firstName);
    _lastNameCtrl = TextEditingController(text: c.lastName);
    _otherNamesCtrl = TextEditingController(text: c.otherNames);
    _phoneCtrl = TextEditingController(text: c.phone);
    _emailCtrl = TextEditingController(text: c.email);
    _notesCtrl = TextEditingController(text: c.notes);
    _selectedGender = c.gender;
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _otherNamesCtrl,
      _phoneCtrl,
      _emailCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final updated = widget.client.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      otherNames: _otherNamesCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      gender: _selectedGender,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await context.read<ClientProvider>().updateClient(updated);
    if (mounted) {
      showAppBanner(
        context,
        'Client updated',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.client.firstName}')),
      body: ScreenBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _firstNameCtrl,
                        'First Name *',
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _lastNameCtrl,
                        'Last Name *',
                        required: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_otherNamesCtrl, 'Other Names'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedGender = v);
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  _phoneCtrl,
                  'Phone',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _field(
                  _emailCtrl,
                  'Email',
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    IconData? icon,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}
