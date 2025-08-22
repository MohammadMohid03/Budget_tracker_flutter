import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final authService = AuthService();
  String error = '';
  bool isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _floatingController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Floating elements animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _cardSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _floatingAnimation = Tween<double>(
      begin: -20.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start entrance animation
    _cardController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _floatingController.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  String _getUserFriendlyError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please log in or use another email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Registration is currently disabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Error code: ${error.code}\nMessage: ${error.message}';
      }
    }
    return 'An error occurred. Please try again.';
  }

  Widget _buildFloatingIcon(IconData icon, double top, double left, double delay) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Positioned(
          top: top + _floatingAnimation.value * (1 + delay),
          left: left,
          child: Opacity(
            opacity: 0.1,
            child: Transform.rotate(
              angle: _backgroundController.value * 2 * 3.14159 * 0.1,
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color.lerp(
                    const Color(0xFF4facfe),
                    const Color(0xFF00f2fe),
                    (_backgroundController.value * 0.5 + 0.5),
                  )!,
                  Color.lerp(
                    const Color(0xFF00f2fe),
                    const Color(0xFF667eea),
                    (_backgroundController.value * 0.3 + 0.7),
                  )!,
                  Color.lerp(
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    (_backgroundController.value * 0.4 + 0.6),
                  )!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Floating background elements
                _buildFloatingIcon(Icons.person_add, 80, 60, 0.0),
                _buildFloatingIcon(Icons.security, 180, 280, 0.4),
                _buildFloatingIcon(Icons.verified_user, 320, 70, 0.8),
                _buildFloatingIcon(Icons.shield, 480, 240, 0.2),
                _buildFloatingIcon(Icons.lock_open, 120, 180, 0.6),
                _buildFloatingIcon(Icons.account_circle, 420, 300, 0.1),

                // Main content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedBuilder(
                      animation: _cardController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _cardSlideAnimation.value),
                          child: Opacity(
                            opacity: _cardFadeAnimation.value,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Card(
                                elevation: 25,
                                shadowColor: Colors.black.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.9),
                                        Colors.white.withOpacity(0.7),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Back button with animation
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 800),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: IconButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  icon: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.arrow_back_ios_new,
                                                      size: 20,
                                                      color: Color(0xFF667eea),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        // App logo/icon with animation
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 1500),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF4facfe).withOpacity(0.3),
                                                      blurRadius: 20,
                                                      spreadRadius: 5,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.person_add,
                                                  size: 48,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 24),

                                        // Welcome text with stagger animation
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 800),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          curve: Curves.easeOut,
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(0, 20 * (1 - value)),
                                                child: Column(
                                                  children: [
                                                    ShaderMask(
                                                      shaderCallback: (bounds) => const LinearGradient(
                                                        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                                                      ).createShader(bounds),
                                                      child: const Text(
                                                        'Create Account',
                                                        style: TextStyle(
                                                          fontSize: 28,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Join us to start tracking your budget',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 32),

                                        // Email field with animation
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 600),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          curve: Curves.easeOut,
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(30 * (1 - value), 0),
                                                child: TextField(
                                                  controller: emailCtrl,
                                                  decoration: InputDecoration(
                                                    labelText: 'Email',
                                                    prefixIcon: Icon(
                                                      Icons.email_outlined,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.grey.shade100,
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                      borderSide: const BorderSide(
                                                        color: Color(0xFF4facfe),
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                  keyboardType: TextInputType.emailAddress,
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 20),

                                        // Password field with animation
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 800),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          curve: Curves.easeOut,
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(30 * (1 - value), 0),
                                                child: TextField(
                                                  controller: passCtrl,
                                                  decoration: InputDecoration(
                                                    labelText: 'Password',
                                                    prefixIcon: Icon(
                                                      Icons.lock_outline,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(
                                                        _obscurePassword
                                                            ? Icons.visibility_outlined
                                                            : Icons.visibility_off_outlined,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _obscurePassword = !_obscurePassword;
                                                        });
                                                      },
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.grey.shade100,
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                      borderSide: const BorderSide(
                                                        color: Color(0xFF4facfe),
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                  obscureText: _obscurePassword,
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Password requirements hint
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 1000),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          curve: Curves.easeOut,
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFF4facfe).withOpacity(0.1),
                                                      const Color(0xFF00f2fe).withOpacity(0.1),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: const Color(0xFF4facfe).withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      color: const Color(0xFF4facfe),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Password should be at least 6 characters long',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Error display with animation
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: error.isNotEmpty
                                              ? Container(
                                            key: const ValueKey('error'),
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.red.shade50,
                                                  Colors.red.shade100,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.red.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red.shade700,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    error,
                                                    style: TextStyle(
                                                      color: Colors.red.shade700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                              : const SizedBox.shrink(),
                                        ),

                                        const SizedBox(height: 8),

                                        // Register button with animation
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 1000),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          curve: Curves.elasticOut,
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Container(
                                                width: double.infinity,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF4facfe).withOpacity(0.4),
                                                      blurRadius: 15,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(16),
                                                    onTap: isLoading ? null : () async {
                                                      if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                                                        setState(() => error = 'Please fill in all fields');
                                                        return;
                                                      }

                                                      setState(() {
                                                        isLoading = true;
                                                        error = '';
                                                      });

                                                      try {
                                                        await authService.register(emailCtrl.text, passCtrl.text);
                                                        Navigator.pop(context); // Go back to login screen
                                                      } on FirebaseAuthException catch (e) {
                                                        setState(() => error = _getUserFriendlyError(e));
                                                      } catch (e) {
                                                        setState(() => error = 'An unexpected error occurred. Please try again.');
                                                      } finally {
                                                        setState(() => isLoading = false);
                                                      }
                                                    },
                                                    child: Center(
                                                      child: isLoading
                                                          ? const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                          : const Text(
                                                        'Create Account',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 24),

                                        // Divider with animation
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 1200),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      height: 1,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.grey.shade300,
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                    child: Text(
                                                      'OR',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade500,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      height: 1,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.grey.shade300,
                                                            Colors.transparent,
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 24),

                                        // Login link with animation
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 1400),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          curve: Curves.easeOut,
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(0, 20 * (1 - value)),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: const Color(0xFF4facfe),
                                                      width: 2,
                                                    ),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(16),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Center(
                                                        child: RichText(
                                                          text: TextSpan(
                                                            style: const TextStyle(fontSize: 16),
                                                            children: [
                                                              TextSpan(
                                                                text: "Already have an account? ",
                                                                style: TextStyle(color: Colors.grey.shade600),
                                                              ),
                                                              const TextSpan(
                                                                text: "Sign in",
                                                                style: TextStyle(
                                                                  color: Color(0xFF4facfe),
                                                                  fontWeight: FontWeight.w600,
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
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Terms and conditions
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 1600),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          curve: Curves.easeOut,
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Text(
                                                'By creating an account, you agree to our Terms of Service and Privacy Policy',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Floating security particles
                ...List.generate(12, (index) {
                  return AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      final delay = index * 0.15;
                      final animValue = (_floatingController.value + delay) % 1.0;
                      return Positioned(
                        top: MediaQuery.of(context).size.height * animValue,
                        left: 40.0 + (index * 30) % (MediaQuery.of(context).size.width - 80),
                        child: Transform.rotate(
                          angle: animValue * 2 * 3.14159,
                          child: Icon(
                            [Icons.security, Icons.verified_user, Icons.shield, Icons.lock_open][index % 4],
                            color: Colors.white.withOpacity(0.05),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}