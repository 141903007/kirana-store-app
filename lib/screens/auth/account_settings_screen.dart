import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _usernameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityQuestionController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _securityQuestionController.text = user?.securityQuestion ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _securityQuestionController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveUsername() async {
    if (!_usernameFormKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.changeUsername(_usernameController.text.trim());
    if (!mounted) return;
    _showMessage('common.success'.tr());
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );
    if (!mounted) return;
    if (!success) {
      _showMessage(authProvider.errorMessage!.tr());
      return;
    }
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _showMessage('common.success'.tr());
  }

  Future<void> _saveSecurityQuestion() async {
    if (!_securityFormKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.setSecurityQuestion(
      _securityQuestionController.text.trim(),
      _securityAnswerController.text,
    );
    if (!mounted) return;
    _securityAnswerController.clear();
    _showMessage('auth.security_question_saved'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auth.account_settings_title'.tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _usernameFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('auth.change_username'.tr(),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(labelText: 'auth.username'.tr()),
                        validator: (value) =>
                            Validators.required(value, 'common.required_field'.tr()),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _saveUsername,
                          child: Text('common.save'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('auth.change_password'.tr(),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'auth.current_password'.tr()),
                        validator: (value) =>
                            Validators.required(value, 'common.required_field'.tr()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'auth.new_password'.tr()),
                        validator: (value) => Validators.minLength(
                          value,
                          4,
                          'common.required_field'.tr(),
                          'auth.password_mismatch'.tr(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: 'auth.confirm_password'.tr()),
                        validator: (value) => Validators.matches(
                          value,
                          _newPasswordController.text,
                          'auth.password_mismatch'.tr(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _savePassword,
                          child: Text('common.save'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _securityFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('auth.security_question_title'.tr(),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'auth.no_security_question_configured'.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _securityQuestionController,
                        decoration: InputDecoration(
                          labelText: 'auth.security_question_label'.tr(),
                          hintText: 'auth.security_question_hint'.tr(),
                        ),
                        validator: (value) =>
                            Validators.required(value, 'common.required_field'.tr()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _securityAnswerController,
                        decoration: InputDecoration(
                          labelText: 'auth.security_answer_label'.tr(),
                          hintText: 'auth.security_answer_hint'.tr(),
                        ),
                        validator: (value) =>
                            Validators.required(value, 'common.required_field'.tr()),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _saveSecurityQuestion,
                          child: Text('common.save'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
