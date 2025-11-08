import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/route_constants.dart';
import '../../../core/routing/route_helper.dart';
import '../../../widgets/custom_textfield.dart';
import '../../../services/toast_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/validators/input_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0; // 0 = email, 1 = password

  // Simple animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

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

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _handleEmailNext() {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    _progressController.reset();
    _progressController.forward();

    // Just validation, ensure 1 complete cycle (800ms minimum)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _progressController.reset();
        setState(() {
          _isLoading = false;
          _currentStep = 1;
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    _progressController.reset();
    _progressController.repeat();

    // Track when we started
    final startTime = DateTime.now();
    final minimumDuration = const Duration(milliseconds: 800); // 1 complete cycle minimum

    // API call - show progress until response
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Ensure at least 1 complete cycle
      final elapsed = DateTime.now().difference(startTime);
      final remaining = minimumDuration - elapsed;

      if (!remaining.isNegative) {
        await Future.delayed(remaining);
      }

      if (mounted) {
        _progressController.stop();
        _progressController.reset();
        setState(() => _isLoading = false);

        if (success) {
          final userType = authProvider.user?.userType;
          AppToast.showSuccess(context, 'Welcome back!');
          RouteHelper.navigateToHome(context, userType);
        } else {
          AppToast.showError(context, 'Invalid email or password');
        }
      }
    } catch (e) {
      // For errors, also ensure minimum duration
      final elapsed = DateTime.now().difference(startTime);
      final remaining = minimumDuration - elapsed;

      if (!remaining.isNegative) {
        await Future.delayed(remaining);
      }

      if (mounted) {
        _progressController.stop();
        _progressController.reset();
        setState(() => _isLoading = false);
        AppToast.showError(context, 'Login failed: ${e.toString()}');
      }
    }
  }

  void _goBackToEmail() {
    setState(() {
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel - Branding
          Expanded(
            flex: 5,
            child: _buildLeftPanel(),
          ),
          // Right Panel - Login Form
          Expanded(
            flex: 5,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    // Replace the icon, title, subtitle, and add your logo/branding
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.theme['primaryColor'],
            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.85),
            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative geometric shapes
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Image.asset("assets/images/oneflow.png")
                      ),
                    ),
                    const SizedBox(height: 50),

                    const Text(
                      'ONEFLOW',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Plan. Execute. Bill. All in OneFlow',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.7,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Feature highlights (optional - can be customized)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeatureItem(Icons.integration_instructions_rounded, 'Unified'),
                        const SizedBox(width: 40),
                        _buildFeatureItem(Icons.timeline_rounded, 'Seamless'),
                        const SizedBox(width: 40),
                        _buildFeatureItem(Icons.trending_up_rounded, 'Efficient'),
                      ],
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProgressIndicator(),
                        const SizedBox(height: 40),
                        _currentStep == 0 ? _buildEmailStep() : _buildPasswordStep(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Blur overlay when loading
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const SizedBox(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (!_isLoading) {
      return const SizedBox(height: 4);
    }

    return SizedBox(
      height: 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final stripWidth = 500.0; // Google-style moving strip width

          return AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final progress = _progressAnimation.value;
              final stripStart = (totalWidth + stripWidth) * progress - stripWidth;

              return Stack(
                children: [
                  // Background
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: (AppColors.theme['secondaryColor'] as Color).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Moving strip
                  Positioned(
                    left: stripStart,
                    child: Container(
                      width: stripWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.0),
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormHeader('Sign in', 'to continue to your account'),
          const SizedBox(height: 32),
          _buildEmailField(),
          const SizedBox(height: 32),
          _buildNextButton(_handleEmailNext),
          const SizedBox(height: 28),
          _buildDivider(),
          const SizedBox(height: 28),
          _buildSignUpPrompt(),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: _goBackToEmail,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.theme['secondaryColor'],
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _emailController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.theme['secondaryColor'],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormHeader('Welcome', 'Enter your password'),
          const SizedBox(height: 32),
          _buildPasswordField(),
          const SizedBox(height: 32),
          _buildNextButton(_handleLogin, isLoading: _isLoading, title: 'Sign In'),
          const SizedBox(height: 28),
          _buildDivider(),
          const SizedBox(height: 28),
          _buildSignUpPrompt(),
        ],
      ),
    );
  }

  Widget _buildFormHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: AppColors.theme['textColor'],
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.theme['secondaryColor'],
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(VoidCallback onTap, {bool isLoading = false, String title = 'Next'}) {
    return MouseRegion(
      cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isLoading
                ? (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7)
                : AppColors.theme['primaryColor'],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
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
      onFieldSubmitted: (_) => _handleEmailNext(),
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
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      validator: InputValidators.validatePassword,
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: AppColors.theme['textColor'],
            fontSize: 15,
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => context.go(Routes.signup),
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: AppColors.theme['primaryColor'],
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
