import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/route_constants.dart';
import '../../../core/routing/route_helper.dart';
import '../../../widgets/custom_textfield.dart';
import '../../../widgets/custom_button.dart';
import '../../../services/toast_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/validators/input_validators.dart';

class SignupMobile extends StatefulWidget {
  const SignupMobile({super.key});

  @override
  State<SignupMobile> createState() => _SignupMobileState();
}

class _SignupMobileState extends State<SignupMobile> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedUserType = 'type1';
  bool _isLoading = false;

  // Simple animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        userType: _selectedUserType,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          final userType = authProvider.user?.userType;
          AppToast.showSuccess(context, 'Account created successfully!');

          if (userType != null) {
            RouteHelper.navigateToHome(context, userType);
          }
        } else {
          AppToast.showError(context, 'Failed to create account');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, 'Signup failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.theme['backgroundColor'],
              (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildWelcomeText(),
                              const SizedBox(height: 32),
                              _buildNameField(),
                              const SizedBox(height: 20),
                              _buildEmailField(),
                              const SizedBox(height: 20),
                              _buildPasswordField(),
                              const SizedBox(height: 20),
                              _buildPhoneField(),
                              const SizedBox(height: 20),
                              _buildUserTypeDropdown(),
                              const SizedBox(height: 28),
                              _buildSignupButton(),
                              const SizedBox(height: 24),
                              _buildDivider(),
                              const SizedBox(height: 24),
                              _buildLoginPrompt(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.theme['primaryColor'],
            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_add_rounded,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.theme['textColor'],
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Join us and start your journey',
          style: TextStyle(
            fontSize: 15,
            color: (AppColors.theme['secondaryColor'] as Color).withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return CustomTextField(
      controller: _nameController,
      hintText: 'Enter your full name',
      labelText: 'Full Name',
      prefixIcon: Icons.person_rounded,
      textInputAction: TextInputAction.next,
      validator: InputValidators.validateName,
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      controller: _emailController,
      hintText: 'Enter your email',
      labelText: 'Email',
      prefixIcon: Icons.email_rounded,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: InputValidators.validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return CustomTextField(
      controller: _passwordController,
      hintText: 'Enter your password',
      labelText: 'Password',
      prefixIcon: Icons.lock_rounded,
      obscureText: true,
      textInputAction: TextInputAction.next,
      validator: InputValidators.validatePassword,
    );
  }

  Widget _buildPhoneField() {
    return CustomTextField(
      controller: _phoneController,
      hintText: 'Enter your phone number',
      labelText: 'Phone Number',
      prefixIcon: Icons.phone_rounded,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleSignup(),
      validator: InputValidators.validatePhone,
    );
  }

  Widget _buildUserTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (AppColors.theme['secondaryColor'] as Color).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_rounded,
            color: (AppColors.theme['secondaryColor'] as Color).withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUserType,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.theme['primaryColor']),
                style: TextStyle(
                  color: AppColors.theme['textColor'],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: 'type1',
                    child: Text('Type 1 User'),
                  ),
                  DropdownMenuItem(
                    value: 'type2',
                    child: Text('Type 2 User'),
                  ),
                  DropdownMenuItem(
                    value: 'type3',
                    child: Text('Type 3 User (Admin)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupButton() {
    return CustomButton(
      title: 'Create Account',
      onTap: _handleSignup,
      isLoading: _isLoading,
      icon: Icons.login_rounded,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.theme['secondaryColor'].withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.theme['secondaryColor'],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.theme['secondaryColor'].withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: AppColors.theme['textColor'],
            fontSize: 14,
          ),
        ),
        InkWell(
          onTap: () => context.go(Routes.login),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: AppColors.theme['primaryColor'],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
