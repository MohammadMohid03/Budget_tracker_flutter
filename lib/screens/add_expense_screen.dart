import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import 'expense_list_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  bool _isSubmitting = false;

  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _floatingController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _floatingAnimation;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Other'
  ];

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Health': Icons.favorite,
    'Other': Icons.category,
  };

  final Map<String, List<Color>> _categoryColors = {
    'Food': [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
    'Transport': [Color(0xFF3742FA), Color(0xFF2F3542)],
    'Shopping': [Color(0xFF5F27CD), Color(0xFF341F97)],
    'Entertainment': [Color(0xFFFF9FF3), Color(0xFFF368E0)],
    'Health': [Color(0xFF26DE81), Color(0xFF20BF6B)],
    'Other': [Color(0xFF667eea), Color(0xFF764ba2)],
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
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

    _cardController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Widget _buildFloatingIcon(IconData icon, double top, double left, double delay) {
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
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassContainer({required Widget child, double? height}) {
    return Container(
      height: height,
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
      child: child,
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildGlassContainer(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              final colors = _categoryColors[category]!;

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, animValue, child) {
                  return Transform.scale(
                    scale: animValue,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: colors.first.withOpacity(0.3),
                              blurRadius: isSelected ? 15 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView( // <<<< WRAP WITH THIS
                          physics: const NeverScrollableScrollPhysics(), // Prevents accidental
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _categoryIcons[category],
                              color: Colors.white,
                              size: isSelected ? 38 : 32,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSelected ? 14 : 12,
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
            },
          ),
        ),
      ],
    );
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) {
      _showSnackBar('Please enter valid title and amount.', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final expense = Expense(
      id: '',
      title: title,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
    );

    try {
      await FirestoreService().addExpense(expense);

      if (mounted) {
        _showSnackBar('Expense added successfully!', Colors.green);

        _titleController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedCategory = 'Food';
          _isSubmitting = false;
        });

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _showSnackBar('Failed to add expense: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
                _buildFloatingIcon(Icons.add_circle, 80, 50, 0.0),
                _buildFloatingIcon(Icons.receipt, 150, 300, 0.2),
                _buildFloatingIcon(Icons.credit_card, 250, 80, 0.4),
                _buildFloatingIcon(Icons.savings, 350, 280, 0.6),
                _buildFloatingIcon(Icons.account_balance, 450, 120, 0.8),

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
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Custom App Bar
                                    Row(
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
                                            onPressed: () => Navigator.of(context).pop(),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text(
                                          'Add New Expense',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 40),

                                    // Title Field
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 800),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(-30 * (1 - value), 0),
                                            child: _buildStyledTextField(
                                              controller: _titleController,
                                              label: 'Expense Title',
                                              hint: 'Enter expense title',
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return 'Please enter a title';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    // Amount Field
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1000),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(30 * (1 - value), 0),
                                            child: _buildStyledTextField(
                                              controller: _amountController,
                                              label: 'Amount',
                                              hint: 'Enter amount',
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return 'Please enter an amount';
                                                }
                                                final amount = double.tryParse(value);
                                                if (amount == null || amount <= 0) {
                                                  return 'Please enter a valid positive amount';
                                                }
                                                return null;
                                              },
                                              suffixIcon: Icon(
                                                Icons.attach_money,
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    // Date Picker
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1200),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(-30 * (1 - value), 0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Date',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                _buildGlassContainer(
                                                  child: ListTile(
                                                    leading: const Icon(
                                                      Icons.calendar_today,
                                                      color: Colors.white,
                                                    ),
                                                    title: Text(
                                                      DateFormat.yMMMd().format(_selectedDate),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    trailing: const Icon(
                                                      Icons.keyboard_arrow_down,
                                                      color: Colors.white,
                                                    ),
                                                    onTap: _presentDatePicker,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    // Category Selector
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1400),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(30 * (1 - value), 0),
                                            child: _buildCategorySelector(),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 40),

                                    // Submit Button
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1600),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Center(
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
                                                  onTap: _isSubmitting ? null : _submitData,
                                                  child: Center(
                                                    child: _isSubmitting
                                                        ? const CircularProgressIndicator(
                                                      color: Colors.white,
                                                    )
                                                        : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withOpacity(0.2),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.add,
                                                            color: Colors.white,
                                                            size: 24,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        const Text(
                                                          'Add Expense',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 0.5,
                                                          ),
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

                                    const SizedBox(height: 24),

                                    // Show All Expenses Button
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1800),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 30 * (1 - value)),
                                            child: Center(
                                              child: _buildGlassContainer(
                                                height: 60,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(20),
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => const ExpenseListScreen(),
                                                      ),
                                                    );
                                                  },
                                                  child: const Center(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.list_alt,
                                                          color: Colors.white,
                                                          size: 24,
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text(
                                                          'View All Expenses',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
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
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}