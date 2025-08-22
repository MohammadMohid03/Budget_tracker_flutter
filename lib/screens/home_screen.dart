import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'expense_screen.dart';
import 'add_expense_screen.dart'; // Added
import 'chart_screen.dart';
import '../services/firestore_service.dart';
import 'budget_screen.dart'; // <<< ADD THIS LINE

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  final FirestoreService _firestoreService = FirestoreService();
  double _thisMonthTotal = 0.0;
  double _totalSpending = 0.0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();

    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Floating elements animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Pulse animation for main button
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _cardSlideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _floatingAnimation = Tween<double>(
      begin: -30.0,
      end: 30.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start entrance animation
    _cardController.forward();
    _loadStats();
  }
  // ADD THIS NEW METHOD
  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _isLoadingStats = true;
      });
    }

    final stats = await _firestoreService.getHomeScreenStats();

    if (mounted) {
      setState(() {
        _thisMonthTotal = stats['monthTotal'] ?? 0.0;
        _totalSpending = stats['grandTotal'] ?? 0.0;
        _isLoadingStats = false;
      });
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildFloatingIcon(IconData icon, double top, double left, double delay, {double size = 40}) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Positioned(
          top: top + _floatingAnimation.value * (1 + delay * 0.5),
          left: left,
          child: Transform.rotate(
            angle: (_backgroundController.value + delay) * 2 * 3.14159 * 0.1,
            child: Opacity(
              opacity: 0.08 + (0.04 * delay),
              child: Icon(
                icon,
                size: size,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (title.hashCode % 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onTap, List<Color> gradientColors) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1000 + (title.hashCode % 500)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'User';

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
                    (_backgroundController.value * 0.3 + 0.7),
                  )!,
                  Color.lerp(
                    const Color(0xFF764ba2),
                    const Color(0xFFf093fb),
                    (_backgroundController.value * 0.4 + 0.6),
                  )!,
                  Color.lerp(
                    const Color(0xFFf093fb),
                    const Color(0xFF4facfe),
                    (_backgroundController.value * 0.2 + 0.8),
                  )!,
                  Color.lerp(
                    const Color(0xFF4facfe),
                    const Color(0xFF00f2fe),
                    (_backgroundController.value * 0.5 + 0.5),
                  )!,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Floating background elements
                _buildFloatingIcon(Icons.trending_up, 80, 50, 0.0),
                _buildFloatingIcon(Icons.monetization_on, 150, 300, 0.2),
                _buildFloatingIcon(Icons.savings, 250, 80, 0.4),
                _buildFloatingIcon(Icons.account_balance_wallet, 350, 280, 0.6),
                _buildFloatingIcon(Icons.show_chart, 450, 120, 0.8),
                _buildFloatingIcon(Icons.attach_money, 200, 200, 0.3, size: 35),
                _buildFloatingIcon(Icons.analytics, 400, 50, 0.7, size: 45),
                _buildFloatingIcon(Icons.payment, 120, 320, 0.5, size: 38),

                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AnimatedBuilder(
                        animation: _cardController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _cardSlideAnimation.value),
                            child: Opacity(
                              opacity: _cardFadeAnimation.value,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Custom App Bar
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Profile section
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(milliseconds: 800),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(-30 * (1 - value), 0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Colors.white, Color(0xFFF8F9FA)],
                                                      ),
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.1),
                                                          blurRadius: 10,
                                                          offset: const Offset(0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.grey.shade700,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Welcome back!',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Text(
                                                        userName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Logout button
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(milliseconds: 1000),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(30 * (1 - value), 0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.logout, color: Colors.white),
                                                  onPressed: () async {
                                                    // Add confirmation dialog
                                                    final shouldLogout = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                        title: const Text('Logout'),
                                                        content: const Text('Are you sure you want to logout?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context, false),
                                                            child: const Text('Cancel'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () => Navigator.pop(context, true),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFF667eea),
                                                            ),
                                                            child: const Text('Logout', style: TextStyle(color: Colors.white)),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (shouldLogout == true) {
                                                      await FirebaseAuth.instance.signOut();
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  // Stats Cards
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 1200),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 30 * (1 - value)),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _buildStatsCard(
                                                  'This Month',
                                                  _isLoadingStats
                                                      ? '...'
                                                      : 'PKR ${_thisMonthTotal.toStringAsFixed(2)}',
                                                  Icons.trending_up,
                                                  [const Color(0xFF667eea), const Color(0xFF764ba2)],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildStatsCard(
                                                  'Total Saved',
                                                  _isLoadingStats
                                                      ? '...'
                                                      : 'PKR ${_totalSpending.toStringAsFixed(2)}',
                                                  Icons.savings,
                                                  [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 40),

                                  // Quick Actions Title
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 1400),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(-20 * (1 - value), 0),
                                          child: const Text(
                                            'Quick Actions',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Quick Action Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // UPDATED 'Add' BUTTON
                                      _buildQuickActionButton(
                                        'Add',
                                        Icons.add,
                                            () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) =>
                                              const AddExpenseScreen(), // Navigate to AddExpenseScreen
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0.0, 1.0), // Slide from bottom
                                                    end: Offset.zero,
                                                  ).animate(CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeInOutCubic,
                                                  )),
                                                  child: FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              transitionDuration: const Duration(milliseconds: 500),
                                            ),
                                          );
                                        },
                                        [const Color(0xFF667eea), const Color(0xFF764ba2)],
                                      ),

                                      // UPDATED 'Stats' BUTTON
                                      _buildQuickActionButton(
                                        'Stats',
                                        Icons.bar_chart,
                                            () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) =>
                                              const ChartScreen(), // Navigate to ChartScreen
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0.0, 1.0), // Slide from bottom
                                                    end: Offset.zero,
                                                  ).animate(CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeInOutCubic,
                                                  )),
                                                  child: FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              transitionDuration: const Duration(milliseconds: 500),
                                            ),
                                          );
                                        },
                                        [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                                      ),

                                      // Budget button remains unchanged
                                      _buildQuickActionButton(
                                        'Budget',
                                        Icons.account_balance_wallet,
                                            () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) =>
                                              const BudgetScreen(), // Navigate to BudgetScreen
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0.0, 1.0), // Slide from bottom
                                                    end: Offset.zero,
                                                  ).animate(CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeInOutCubic,
                                                  )),
                                                  child: FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              transitionDuration: const Duration(milliseconds: 500),
                                            ),
                                          );
                                        },
                                        [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 60),

                                  // Main Action Button (Expenses)
                                  Center(
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: TweenAnimationBuilder<double>(
                                            duration: const Duration(milliseconds: 1600),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            curve: Curves.elasticOut,
                                            builder: (context, value, child) {
                                              return Transform.scale(
                                                scale: value,
                                                child: Container(
                                                  width: 280,
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(35),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF667eea).withOpacity(0.5),
                                                        blurRadius: 25,
                                                        offset: const Offset(0, 15),
                                                        spreadRadius: 5,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(35),
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          PageRouteBuilder(
                                                            pageBuilder: (context, animation, secondaryAnimation) =>
                                                            const ExpenseScreen(),
                                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                              return SlideTransition(
                                                                position: Tween<Offset>(
                                                                  begin: const Offset(1.0, 0.0),
                                                                  end: Offset.zero,
                                                                ).animate(CurvedAnimation(
                                                                  parent: animation,
                                                                  curve: Curves.easeInOutCubic,
                                                                )),
                                                                child: FadeTransition(
                                                                  opacity: animation,
                                                                  child: child,
                                                                ),
                                                              );
                                                            },
                                                            transitionDuration: const Duration(milliseconds: 500),
                                                          ),
                                                        );
                                                      },
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withOpacity(0.2),
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: const Icon(
                                                              Icons.list_alt,
                                                              color: Colors.white,
                                                              size: 24,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          const Text(
                                                            'View My Expenses',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 0.5,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          const Icon(
                                                            Icons.arrow_forward_ios,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Recent Activity Card
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 1800),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 50 * (1 - value)),
                                          child: Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.2),
                                                  Colors.white.withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.2),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.history,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Text(
                                                      'Recent Activity',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Track your latest expenses and budget progress here. Your financial journey starts with small steps!',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontSize: 14,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Animated particles
                ...List.generate(20, (index) {
                  return AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      final delay = index * 0.1;
                      final animValue = (_floatingController.value + delay) % 1.0;
                      final screenHeight = MediaQuery.of(context).size.height;
                      final screenWidth = MediaQuery.of(context).size.width;

                      return Positioned(
                        top: screenHeight * animValue,
                        left: 30.0 + (index * 35) % (screenWidth - 60),
                        child: Transform.rotate(
                          angle: animValue * 2 * 3.14159,
                          child: Icon(
                            [
                              Icons.monetization_on_outlined,
                              Icons.trending_up_outlined,
                              Icons.savings_outlined,
                              Icons.analytics_outlined
                            ][index % 4],
                            color: Colors.white.withOpacity(0.03),
                            size: 16 + (index % 3) * 4,
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