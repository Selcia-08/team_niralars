import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

/// Phone Login Screen - Enter phone number and select role
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Add +91 prefix if not present
    if (digits.length == 10) {
      return '+91$digits';
    }
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    return '+91$digits';
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final phone = _formatPhoneNumber(_phoneController.text.trim());

    final success = await authProvider.sendOTP(phone);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtpScreen(phoneNumber: phone)),
      );
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Logo/Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            size: 48,
                            color: AppColors.background,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('EcoLogiq', style: AppTextStyles.heading1),
                        const SizedBox(height: 8),
                        Text(
                          'Smart Logistics Platform',
                          style: AppTextStyles.subtitle,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Phone Input
                  Text(
                    'Enter your phone number',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll send you a verification code',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇮🇳', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              '+91',
                              style: AppTextStyles.body.copyWith(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 24,
                              color: AppColors.cardLight,
                            ),
                          ],
                        ),
                      ),
                      hintText: '9876543210',
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.length != 10) {
                        return 'Please enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Role Selection
                  Text('I am a', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),

                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => Row(
                      children: [
                        _RoleButton(
                          label: 'Driver',
                          icon: Icons.drive_eta_rounded,
                          isSelected: auth.selectedRole == 'DRIVER',
                          onTap: () => auth.setSelectedRole('DRIVER'),
                        ),
                        const SizedBox(width: 16),
                        _RoleButton(
                          label: 'Shipper',
                          icon: Icons.inventory_2_rounded,
                          isSelected: auth.selectedRole == 'SHIPPER',
                          onTap: () => auth.setSelectedRole('SHIPPER'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _sendOTP,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background,
                                ),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Terms text
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms of Service',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Role selection button widget
class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
