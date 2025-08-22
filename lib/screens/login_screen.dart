import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
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
        case 'user-not-found':
        case 'invalid-credential':
          return 'No account found with this email. Please register first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    (_backgroundController.value * 0.5 + 0.5),
                  )!,
                  Color.lerp(
                    const Color(0xFF764ba2),
                    const Color(0xFFf093fb),
                    (_backgroundController.value * 0.3 + 0.7),
                  )!,
                  Color.lerp(
                    const Color(0xFFf093fb),
                    const Color(0xFF4facfe),
                    (_backgroundController.value * 0.4 + 0.6),
                  )!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Floating background elements
                _buildFloatingIcon(Icons.attach_money, 100, 50, 0.0),
                _buildFloatingIcon(Icons.trending_up, 200, 300, 0.3),
                _buildFloatingIcon(Icons.savings, 350, 80, 0.7),
                _buildFloatingIcon(Icons.account_balance_wallet, 500, 250, 0.5),
                _buildFloatingIcon(Icons.monetization_on, 150, 200, 0.9),
                _buildFloatingIcon(Icons.show_chart, 450, 320, 0.2),

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
                                                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF667eea).withOpacity(0.3),
                                                      blurRadius: 20,
                                                      spreadRadius: 5,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.account_balance_wallet,
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
                                                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                                      ).createShader(bounds),
                                                      child: const Text(
                                                        'Budget Tracker',
                                                        style: TextStyle(
                                                          fontSize: 28,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Welcome back! Sign in to continue',
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
                                                        color: Color(0xFF667eea),
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
                                                        color: Color(0xFF667eea),
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

                                        // Login button with animation
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
                                                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF667eea).withOpacity(0.4),
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
                                                        await authService.signIn(emailCtrl.text, passCtrl.text);
                                                      } on FirebaseAuthException catch (e) {
                                                        print('FIREBASE ERROR: ${e.code} - ${e.message}');
                                                        setState(() => error = _getUserFriendlyError(e));
                                                      } catch (e) {
                                                        print('GENERIC ERROR: $e');
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
                                                        'Sign In',
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

                                        // Register button with animation
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
                                                      color: const Color(0xFF667eea),
                                                      width: 2,
                                                    ),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(16),
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          PageRouteBuilder(
                                                            pageBuilder: (context, animation, secondaryAnimation) =>
                                                            const RegisterScreen(),
                                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                              return SlideTransition(
                                                                position: Tween<Offset>(
                                                                  begin: const Offset(1.0, 0.0),
                                                                  end: Offset.zero,
                                                                ).animate(CurvedAnimation(
                                                                  parent: animation,
                                                                  curve: Curves.easeInOut,
                                                                )),
                                                                child: child,
                                                              );
                                                            },
                                                            transitionDuration: const Duration(milliseconds: 300),
                                                          ),
                                                        );
                                                      },
                                                      child: Center(
                                                        child: RichText(
                                                          text: TextSpan(
                                                            style: const TextStyle(fontSize: 16),
                                                            children: [
                                                              TextSpan(
                                                                text: "Don't have an account? ",
                                                                style: TextStyle(color: Colors.grey.shade600),
                                                              ),
                                                              const TextSpan(
                                                                text: "Create one",
                                                                style: TextStyle(
                                                                  color: Color(0xFF667eea),
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

                                        // Forgot password link
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 1600),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          curve: Curves.easeOut,
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: TextButton(
                                                onPressed: () {
                                                  // TODO: Implement forgot password
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Forgot password feature coming soon!'),
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Forgot Password?',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
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

                // Floating money particles
                ...List.generate(15, (index) {
                  return AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      final delay = index * 0.1;
                      final animValue = (_floatingController.value + delay) % 1.0;
                      return Positioned(
                        top: MediaQuery.of(context).size.height * animValue,
                        left: 50.0 + (index * 25) % (MediaQuery.of(context).size.width - 100),
                        child: Transform.rotate(
                          angle: animValue * 2 * 3.14159,
                          child: Icon(
                            [Icons.monetization_on, Icons.trending_up, Icons.savings][index % 3],
                            color: Colors.white.withOpacity(0.05),
                            size: 24,
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