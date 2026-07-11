import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

enum _Stage { loading, noQuestionConfigured, answerQuestion, resetPassword, done }

/// Offline password recovery via a security question set up in Account
/// Settings — no internet connection is ever needed.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _answerFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _Stage _stage = _Stage.loading;
  UserModel? _user;
  String? _answerError;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final authProvider = context.read<AuthProvider>();
    final user = await authProvider.getUserForRecovery();
    if (!mounted) return;
    setState(() {
      _user = user;
      _stage = (user?.securityQuestion == null)
          ? _Stage.noQuestionConfigured
          : _Stage.answerQuestion;
    });
  }

  void _verifyAnswer() {
    if (!_answerFormKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final correct = authProvider.verifySecurityAnswer(_user!, _answerController.text);
    if (!correct) {
      setState(() => _answerError = 'auth.security_answer_incorrect'.tr());
      return;
    }
    setState(() {
      _answerError = null;
      _stage = _Stage.resetPassword;
    });
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.resetPasswordViaRecovery(_user!.id!, _newPasswordController.text);
    if (!mounted) return;
    setState(() => _stage = _Stage.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auth.reset_password_title'.tr())),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildStageContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _Stage.loading:
        return const CircularProgressIndicator();

      case _Stage.noQuestionConfigured:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 56),
            const SizedBox(height: 16),
            Text(
              'auth.no_security_question_configured'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('auth.back_to_login'.tr()),
            ),
          ],
        );

      case _Stage.answerQuestion:
        return Form(
          key: _answerFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _user!.securityQuestion!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _answerController,
                decoration: InputDecoration(
                  labelText: 'auth.security_answer_label'.tr(),
                  errorText: _answerError,
                ),
                validator: (value) =>
                    Validators.required(value, 'common.required_field'.tr()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _verifyAnswer,
                  child: Text('auth.answer_question_button'.tr()),
                ),
              ),
            ],
          ),
        );

      case _Stage.resetPassword:
        return Form(
          key: _resetFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'auth.confirm_password'.tr()),
                validator: (value) => Validators.matches(
                  value,
                  _newPasswordController.text,
                  'auth.password_mismatch'.tr(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _resetPassword,
                  child: Text('auth.reset_password_button'.tr()),
                ),
              ),
            ],
          ),
        );

      case _Stage.done:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'auth.password_reset_success'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('auth.back_to_login'.tr()),
            ),
          ],
        );
    }
  }
}
