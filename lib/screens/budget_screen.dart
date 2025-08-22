import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  // State for holding our data streams
  late Stream<List<Budget>> _budgetsStream;
  late Stream<List<Expense>> _expensesStream;

  // To ensure we are always looking at the current month
  final int _currentMonth = DateTime.now().month;
  final int _currentYear = DateTime.now().year;

  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _floatingController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
    _initializeAnimations();
  }

  void _initializeStreams() {
    // Initialize the streams ONCE to avoid issues with StreamBuilder
    _budgetsStream = _firestoreService.getBudgetsForMonth(_currentMonth, _currentYear);
    _expensesStream = _firestoreService.getExpenses(); // We'll filter this stream for the current month later
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _floatingController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    _cardSlideAnimation = Tween<double>(begin: 50.0, end: 0.0)
        .animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack));
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cardController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _floatingAnimation = Tween<double>(begin: -20.0, end: 20.0)
        .animate(CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut));

    _cardController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  // =======================================================================
  // UI Helper Widgets (to keep the build method clean)
  // =======================================================================

  Widget _buildFloatingIcon(IconData icon, double top, double left, double delay) {
    // Re-using the floating icon animation from your other screens for consistency
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
              child: Icon(icon, size: 40, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    // Re-using the glassmorphism card style from your other screens
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  Widget _buildSummaryCard(double totalBudget, double totalSpent) {
    final remaining = totalBudget - totalSpent;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) => Transform.scale(
        scale: animValue,
        child: _buildGlassCard(
          child: Column(
            children: [
              Row(
                // No need for spaceAround when using Expanded
                children: [
                  // Wrap each item in an Expanded widget
                  Expanded(
                    child: _buildSummaryItem('Total Budget', totalBudget, Colors.blue),
                  ),
                  Expanded(
                    child: _buildSummaryItem('Total Spent', totalSpent, Colors.orange),
                  ),
                  Expanded(
                    child: _buildSummaryItem('Remaining', remaining, remaining >= 0 ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    // Helper for the items inside the summary card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          'PKR ${amount.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center, // <<< ADD THIS LINE
        ),
      ],
    );
  }

  Widget _buildBudgetListItem(Budget budget, double spentAmount) {
    // The main widget for each category's budget progress
    final double progress = budget.amount > 0 ? (spentAmount / budget.amount).clamp(0.0, 1.0) : 0.0;
    final Color progressColor = progress > 0.9 ? Colors.red : (progress > 0.7 ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _buildGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getCategoryIcon(budget.category), color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(budget.category, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Three-dot menu for edit/delete options
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddOrEditBudgetDialog(budget: budget);
                    } else if (value == 'delete') {
                      _deleteBudget(budget.id);
                    }
                  },
                  icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.8)),
                  color: const Color(0xFF667eea),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem<String>(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.white))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PKR ${spentAmount.toStringAsFixed(0)} / ${budget.amount.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600),
                ),
                Text('${(progress * 100).toStringAsFixed(1)}%', style: TextStyle(color: progressColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // Main Build Method
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          // Re-using the animated background from your other screens
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF667eea), const Color(0xFF764ba2), (_backgroundController.value * 0.3 + 0.7))!,
                  Color.lerp(const Color(0xFF764ba2), const Color(0xFFf093fb), (_backgroundController.value * 0.4 + 0.6))!,
                  Color.lerp(const Color(0xFFf093fb), const Color(0xFF4facfe), (_backgroundController.value * 0.2 + 0.8))!,
                  Color.lerp(const Color(0xFF4facfe), const Color(0xFF00f2fe), (_backgroundController.value * 0.5 + 0.5))!,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Floating background elements for decoration
                _buildFloatingIcon(Icons.savings, 80, 50, 0.0),
                _buildFloatingIcon(Icons.calculate, 150, 280, 0.2),
                _buildFloatingIcon(Icons.flag, 250, 80, 0.4),
                _buildFloatingIcon(Icons.assessment, 350, 250, 0.6),

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
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Monthly Budgets',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(), // <<< ADD THIS SPACER
                            // --- ADD THIS RESET BUTTON ---
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                                onPressed: () {
                                  // We will show a confirmation dialog before deleting
                                  _showClearAllBudgetsConfirmationDialog();
                                },
                                tooltip: 'Reset All Budgets',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // We need data from both streams (budgets and expenses) to build the UI
                      // So we use nested StreamBuilders.
                      Expanded(
                        child: StreamBuilder<List<Budget>>(
                          stream: _budgetsStream,
                          builder: (context, budgetSnapshot) {
                            if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                            }
                            if (budgetSnapshot.hasError) {
                              return Center(child: Text('Error: ${budgetSnapshot.error}', style: const TextStyle(color: Colors.white)));
                            }

                            final budgets = budgetSnapshot.data ?? [];
                            final totalBudget = budgets.fold(0.0, (sum, item) => sum + item.amount);

                            return StreamBuilder<List<Expense>>(
                              stream: _expensesStream,
                              builder: (context, expenseSnapshot) {
                                if (expenseSnapshot.connectionState == ConnectionState.waiting && !expenseSnapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                                }

                                final allExpenses = expenseSnapshot.data ?? [];
                                final expensesThisMonth = allExpenses.where((e) => e.date.month == _currentMonth && e.date.year == _currentYear).toList();
                                final totalSpent = expensesThisMonth.fold(0.0, (sum, item) => sum + item.amount);

                                // Group expenses by category for easy lookup
                                final Map<String, double> spendingByCategory = {};
                                for (var expense in expensesThisMonth) {
                                  spendingByCategory.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
                                }

                                return AnimatedBuilder(
                                  animation: _cardController,
                                  builder: (context, child) => Transform.translate(
                                    offset: Offset(0, _cardSlideAnimation.value),
                                    child: Opacity(
                                      opacity: _cardFadeAnimation.value,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Column(
                                          children: [
                                            // The summary card at the top
                                            _buildSummaryCard(totalBudget, totalSpent),
                                            const SizedBox(height: 24),

                                            // The list of budgets
                                            Expanded(
                                              child: budgets.isEmpty
                                                  ? _buildEmptyState()
                                                  : ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: budgets.length,
                                                itemBuilder: (context, index) {
                                                  final budget = budgets[index];
                                                  final spentAmount = spendingByCategory[budget.category] ?? 0.0;
                                                  return _buildBudgetListItem(budget, spentAmount);
                                                },
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
                          },
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
      // Floating Action Button to add new budgets
      floatingActionButton: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1500),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, animValue, child) => Transform.scale(
          scale: animValue,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF667eea).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: FloatingActionButton(
              onPressed: () => _showAddOrEditBudgetDialog(),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
              tooltip: 'Add New Budget',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // A nice message to show when there are no budgets yet.
    return Center(
      child: _buildGlassCard(
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.savings_outlined, size: 80, color: Colors.white70),
            SizedBox(height: 24),
            Text('No Budgets Yet', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
              'Tap the + button to create a spending plan for this month.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // Logic & Dialogs
  // =======================================================================

  void _showAddOrEditBudgetDialog({Budget? budget}) {
    // Remember our GlobalKey lesson? Create a new, local key for this dialog's form.
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();

    // Available categories to budget for (you can customize this list)
    final categories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Health', 'Other'];
    String _selectedCategory = categories.first;

    // If we are editing, pre-fill the form fields
    if (budget != null) {
      _selectedCategory = budget.category;
      _amountController.text = budget.amount.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.9),
        title: Text(budget == null ? 'Add New Budget' : 'Edit Budget', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown for category selection
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _selectedCategory = value;
                  }
                },
                decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              // Text field for budget amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Budget Amount (PKR)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Please enter a valid positive number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final newBudget = Budget(
                  // ID will be auto-generated by Firestore logic if new, otherwise we use existing id
                  id: budget?.id ?? '',
                  category: _selectedCategory,
                  amount: double.parse(_amountController.text),
                  month: _currentMonth,
                  year: _currentYear,
                );
                _firestoreService.addOrUpdateBudget(newBudget);
                Navigator.of(context).pop();
              }
            },
            child: Text(budget == null ? 'Save' : 'Update', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _showClearAllBudgetsConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset All Budgets?'),
        content: const Text(
            'This will delete all budgets set for the current month. Your expenses will not be affected.\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Call the firestore service to clear the data
              _firestoreService.clearBudgetsForMonth(_currentMonth, _currentYear);
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteBudget(String budgetId) {
    // Show a confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this budget? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _firestoreService.deleteBudget(budgetId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper to get icons for categories
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Shopping': return Icons.shopping_bag;
      case 'Entertainment': return Icons.movie;
      case 'Health': return Icons.favorite;
      default: return Icons.category;
    }
  }
}