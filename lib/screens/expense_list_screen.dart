import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Expense>> _expensesStream;

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _floatingController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _expensesStream = _firestoreService.getExpenses();
  }

  void _initializeAnimations() {
    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Floating elements animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _cardSlideAnimation = Tween<double>(
      begin: 50.0,
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
    super.dispose();
  }

  Widget _buildFloatingIcon(IconData icon, double top, double left, double delay, {double size = 30}) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Positioned(
          top: top + _floatingAnimation.value * (1 + delay * 0.5),
          left: left,
          child: Transform.rotate(
            angle: (_backgroundController.value + delay) * 2 * 3.14159 * 0.1,
            child: Opacity(
              opacity: 0.06 + (0.04 * delay),
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

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding, double? height}) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildExpenseItem(Expense expense, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(expense.category),
                          _getCategoryColor(expense.category).withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(expense.category).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Expense Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(expense.category).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getCategoryColor(expense.category).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            expense.category,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat.yMMMd().format(expense.date),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4facfe).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'PKR ${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Bills':
        return Icons.receipt;
      case 'Entertainment':
        return Icons.movie;
      case 'Health':
        return Icons.favorite;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Other':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  // Helper method to get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Bills':
        return Colors.red;
      case 'Entertainment':
        return Colors.purple;
      case 'Health':
        return Colors.pink;
      case 'Shopping':
        return Colors.green;
      case 'Other':
        return Colors.teal;
      default:
        return Colors.grey;
    }
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
                _buildFloatingIcon(Icons.receipt_long, 80, 50, 0.0),
                _buildFloatingIcon(Icons.list_alt, 150, 280, 0.2),
                _buildFloatingIcon(Icons.monetization_on, 250, 80, 0.4),
                _buildFloatingIcon(Icons.analytics, 350, 250, 0.6),
                _buildFloatingIcon(Icons.trending_up, 450, 120, 0.8),
                _buildFloatingIcon(Icons.account_balance_wallet, 200, 200, 0.3, size: 35),
                _buildFloatingIcon(Icons.payment, 120, 320, 0.5, size: 38),

                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Custom App Bar
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'All Expenses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main content area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: StreamBuilder<List<Expense>>(
                            stream: _expensesStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildGlassCard(
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return _buildGlassCard(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error, size: 60, color: Colors.white70),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Error: ${snapshot.error}',
                                          style: const TextStyle(color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final expenses = snapshot.data ?? [];

                              if (expenses.isEmpty) {
                                return AnimatedBuilder(
                                  animation: _cardController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _cardSlideAnimation.value),
                                      child: Opacity(
                                        opacity: _cardFadeAnimation.value,
                                        child: _buildGlassCard(
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.receipt_long, size: 80, color: Colors.white70),
                                              SizedBox(height: 24),
                                              Text(
                                                'No expenses found',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'Add an expense to get started with tracking your spending',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              // Calculate total amount
                              final totalAmount = expenses.fold(
                                  0.0,
                                      (sum, expense) => sum + expense.amount
                              );

                              return AnimatedBuilder(
                                animation: _cardController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _cardSlideAnimation.value),
                                    child: Opacity(
                                      opacity: _cardFadeAnimation.value,
                                      child: Column(
                                        children: [
                                          // Summary card
                                          TweenAnimationBuilder<double>(
                                            duration: const Duration(milliseconds: 1000),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            curve: Curves.easeOutBack,
                                            builder: (context, animValue, child) {
                                              return Transform.scale(
                                                scale: animValue,
                                                child: _buildGlassCard(
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                                          ),
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(0xFF667eea).withOpacity(0.3),
                                                              blurRadius: 10,
                                                              offset: const Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.account_balance_wallet,
                                                          color: Colors.white,
                                                          size: 28,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const Text(
                                                              'Total Expenses',
                                                              style: TextStyle(
                                                                color: Colors.white70,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              'PKR ${totalAmount.toStringAsFixed(2)}',
                                                              style: const TextStyle(
                                                                fontSize: 24,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Text(
                                                          '${expenses.length} items',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 20),

                                          // Expense list
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: expenses.length,
                                              itemBuilder: (context, index) {
                                                final expense = expenses[index];
                                                return _buildExpenseItem(expense, index);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1500),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, animValue, child) {
          return Transform.scale(
            scale: animValue,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
                tooltip: 'Add New Expense',
              ),
            ),
          );
        },
      ),
    );
  }
}