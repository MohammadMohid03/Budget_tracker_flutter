import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/firestore_service.dart';
import 'chart_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  late Stream<List<Expense>> _baseExpensesStream; // <<< ADD THIS LINE

  final List<String> _categories = ['All', 'Food', 'Transport', 'Bills', 'Entertainment', 'Other'];
  String _selectedCategory = 'All';
  bool _last7DaysOnly = false;
  String _selectedCategoryToAdd = 'Other';

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
    _refreshData();
    _initializeAnimations();
    _baseExpensesStream = _firestoreService.getExpenses();
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

  Future<void> _refreshData() async {
    setState(() {});
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

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
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

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required List<Color> gradientColors,
    double? width,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (title.hashCode % 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            width: width ?? 140,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(25),
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
                borderRadius: BorderRadius.circular(25),
                onTap: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

  void _addOrUpdateExpense({String? expenseId}) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final expense = Expense(
          id: expenseId ?? '',
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text),
          category: _selectedCategoryToAdd,
          date: DateTime.now(),
        );

        if (expenseId != null) {
          await _firestoreService.updateExpense(expenseId, expense);
          _showSuccessSnackBar('Expense updated successfully!');
        } else {
          await _firestoreService.addExpense(expense);
          _showSuccessSnackBar('Expense added successfully!');
        }

        _titleController.clear();
        _amountController.clear();
        setState(() {
          _selectedCategoryToAdd = 'Other';
          _isLoading = false;
        });

        _refreshData();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditDialog(Expense expense) {
    final _editFormKey = GlobalKey<FormState>(); // <<< ADD THIS LINE
    _titleController.text = expense.title;
    _amountController.text = expense.amount.toString();
    _selectedCategoryToAdd = expense.category;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text('Edit Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: _editFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) =>
                value!.isEmpty || double.tryParse(value) == null ? 'Enter valid number' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategoryToAdd,
                items: _categories
                    .where((c) => c != 'All')
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryToAdd = val!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
            onPressed: () {
    // First, validate the dialog's form using its own key
    if (_editFormKey.currentState!.validate()) {
      // Only if the form is valid, proceed with the update
      _addOrUpdateExpense(expenseId: expense.id);
      Navigator.of(context).pop();
    }
            },
          ),
        ],
      ),
    );
  }

  void _deleteExpense(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(child: const Text('No'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteExpense(id);
        _showSuccessSnackBar('Expense deleted successfully');
        _refreshData();
      } catch (e) {
        _showErrorSnackBar('Error deleting expense: $e');
      }
    }
  }

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
      default:
        return Icons.category;
    }
  }

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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    Stream<List<Expense>> expensesStream = _baseExpensesStream;

    if (_selectedCategory != 'All' || _last7DaysOnly) {
      expensesStream = expensesStream.map((expenses) {
        return expenses.where((expense) {
          bool matchesCategory = _selectedCategory == 'All' || expense.category == _selectedCategory;
          bool matchesDate = !_last7DaysOnly ||
              expense.date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
          return matchesCategory && matchesDate;
        }).toList();
      });
    }

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
                _buildFloatingIcon(Icons.monetization_on, 150, 280, 0.2),
                _buildFloatingIcon(Icons.pie_chart, 250, 80, 0.4),
                _buildFloatingIcon(Icons.trending_up, 350, 250, 0.6),
                _buildFloatingIcon(Icons.analytics, 450, 120, 0.8),

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
                              'Manage Expenses',
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: AnimatedBuilder(
                            animation: _cardController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _cardSlideAnimation.value),
                                child: Opacity(
                                  opacity: _cardFadeAnimation.value,
                                  child: Column(
                                    children: [
                                      // Add Expense Form
                                      _buildGlassCard(
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.add_circle, color: Colors.white, size: 24),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Add New Expense',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              TextFormField(
                                                controller: _titleController,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  labelText: 'Title',
                                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: const BorderSide(color: Colors.white),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.1),
                                                ),
                                                validator: (value) =>
                                                value == null || value.isEmpty ? 'Enter a title' : null,
                                              ),
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller: _amountController,
                                                keyboardType: TextInputType.number,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  labelText: 'Amount (PKR)',
                                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: const BorderSide(color: Colors.white),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.1),
                                                ),
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) return 'Enter amount';
                                                  if (double.tryParse(value) == null) return 'Enter valid number';
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 16),
                                              DropdownButtonFormField<String>(
                                                value: _selectedCategoryToAdd,
                                                dropdownColor: const Color(0xFF667eea),
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  labelText: 'Category',
                                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: const BorderSide(color: Colors.white),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.1),
                                                ),
                                                items: _categories
                                                    .where((c) => c != 'All')
                                                    .map((cat) => DropdownMenuItem(
                                                  value: cat,
                                                  child: Text(cat, style: const TextStyle(color: Colors.white)),
                                                ))
                                                    .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedCategoryToAdd = value!;
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _isLoading
                                                        ? const Center(child: CircularProgressIndicator())
                                                        : _buildActionButton(
                                                      title: 'Add Expense',
                                                      icon: Icons.add,
                                                      onTap: () => _addOrUpdateExpense(),
                                                      gradientColors: [
                                                        const Color(0xFF667eea),
                                                        const Color(0xFF764ba2)
                                                      ],
                                                      width: double.infinity,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  _buildActionButton(
                                                    title: 'Charts',
                                                    icon: Icons.pie_chart,
                                                    onTap: () {
                                                      Navigator.of(context).push(
                                                        PageRouteBuilder(
                                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                                          const ChartScreen(),
                                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                            return SlideTransition(
                                                              position: Tween<Offset>(
                                                                begin: const Offset(1.0, 0.0),
                                                                end: Offset.zero,
                                                              ).animate(CurvedAnimation(
                                                                parent: animation,
                                                                curve: Curves.easeInOutCubic,
                                                              )),
                                                              child: FadeTransition(opacity: animation, child: child),
                                                            );
                                                          },
                                                          transitionDuration: const Duration(milliseconds: 500),
                                                        ),
                                                      );
                                                    },
                                                    gradientColors: [
                                                      const Color(0xFF4facfe),
                                                      const Color(0xFF00f2fe)
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Filters
                                      _buildGlassCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.filter_list, color: Colors.white, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Filters',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: DropdownButton<String>(
                                                    value: _selectedCategory,
                                                    isExpanded: true,
                                                    dropdownColor: const Color(0xFF667eea),
                                                    style: const TextStyle(color: Colors.white),
                                                    items: _categories
                                                        .map((cat) => DropdownMenuItem(
                                                      value: cat,
                                                      child: Text(cat),
                                                    ))
                                                        .toList(),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _selectedCategory = value!;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Row(
                                                  children: [
                                                    Checkbox(
                                                      value: _last7DaysOnly,
                                                      activeColor: Colors.white,
                                                      checkColor: const Color(0xFF667eea),
                                                      onChanged: (val) {
                                                        setState(() {
                                                          _last7DaysOnly = val!;
                                                        });
                                                      },
                                                    ),
                                                    const Text(
                                                      'Last 7 Days',
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Expenses List
                                      StreamBuilder<List<Expense>>(
                                        stream: expensesStream,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                            return _buildGlassCard(
                                              child: const Center(
                                                child: CircularProgressIndicator(color: Colors.white),
                                              ),
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return _buildGlassCard(
                                              child: Center(
                                                child: Text(
                                                  'Error: ${snapshot.error}',
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            );
                                          }

                                          final expenses = snapshot.data ?? [];

                                          if (expenses.isEmpty) {
                                            return _buildGlassCard(
                                              child: const Column(
                                                children: [
                                                  Icon(Icons.receipt_long, size: 60, color: Colors.white70),
                                                  SizedBox(height: 16),
                                                  Text(
                                                    'No expenses found',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Add your first expense above',
                                                    style: TextStyle(color: Colors.white70),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }

                                          return _buildGlassCard(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Row(
                                                      children: [
                                                        Icon(Icons.list_alt, color: Colors.white, size: 20),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Recent Expenses',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      'Total: PKR ${_calculateTotal(expenses).toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                ...expenses.map((expense) => Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: Colors.white.withOpacity(0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: _getCategoryColor(expense.category).withOpacity(0.2),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          _getCategoryIcon(expense.category),
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
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
                                                            Text(
                                                              DateFormat.yMMMd().format(expense.date),
                                                              style: TextStyle(
                                                                color: Colors.white.withOpacity(0.7),
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: _getCategoryColor(expense.category).withOpacity(0.3),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: Text(
                                                                expense.category,
                                                                style: const TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(
                                                            'PKR ${expense.amount.toStringAsFixed(2)}',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                  color: Colors.orange.withOpacity(0.2),
                                                                  borderRadius: BorderRadius.circular(6),
                                                                ),
                                                                child: IconButton(
                                                                  icon: const Icon(Icons.edit, size: 16),
                                                                  color: Colors.white,
                                                                  constraints: const BoxConstraints(
                                                                    minWidth: 32,
                                                                    minHeight: 32,
                                                                  ),
                                                                  padding: EdgeInsets.zero,
                                                                  onPressed: () => _showEditDialog(expense),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                  color: Colors.red.withOpacity(0.2),
                                                                  borderRadius: BorderRadius.circular(6),
                                                                ),
                                                                child: IconButton(
                                                                  icon: const Icon(Icons.delete, size: 16),
                                                                  color: Colors.white,
                                                                  constraints: const BoxConstraints(
                                                                    minWidth: 32,
                                                                    minHeight: 32,
                                                                  ),
                                                                  padding: EdgeInsets.zero,
                                                                  onPressed: () => _deleteExpense(expense.id),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                )).toList(),
                                              ],
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _calculateTotal(List<Expense> expenses) {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }
}