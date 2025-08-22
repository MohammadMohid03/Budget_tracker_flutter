import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<Expense> _expenses = [];
  bool _isLoading = true;

  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _floatingController;
  late TabController _tabController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _tabController = TabController(length: 3, vsync: this);
    _loadExpenses();
  }

  void _initAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )
      ..repeat();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )
      ..repeat();

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
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildFloatingIcon(IconData icon, double top, double left,
      double delay) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Positioned(
          top: top + _floatingAnimation.value * (1 + delay * 0.5),
          left: left,
          child: Transform.rotate(
            angle: (_backgroundController.value + delay) * 2 * 3.14159 * 0.1,
            child: Opacity(
              opacity: 0.06 + (0.03 * delay),
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

  Widget _buildGlassContainer(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
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

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await _firestoreService
          .getExpenses()
          .first;

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expenses: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
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
                _buildFloatingIcon(Icons.bar_chart, 80, 50, 0.0),
                _buildFloatingIcon(Icons.pie_chart, 150, 300, 0.2),
                _buildFloatingIcon(Icons.show_chart, 250, 80, 0.4),
                _buildFloatingIcon(Icons.analytics, 350, 280, 0.6),
                _buildFloatingIcon(Icons.trending_up, 450, 120, 0.8),

                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Custom App Bar
                      AnimatedBuilder(
                        animation: _cardController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _cardSlideAnimation.value),
                            child: Opacity(
                              opacity: _cardFadeAnimation.value,
                              child: Padding(
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
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.white),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Budget Charts',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
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
                                        icon: const Icon(
                                            Icons.refresh, color: Colors.white),
                                        onPressed: _loadExpenses,
                                        tooltip: 'Refresh Data',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Tab Bar
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicator: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white
                                      .withOpacity(0.7),
                                  tabs: const [
                                    Tab(
                                      icon: Icon(Icons.bar_chart, size: 20),
                                      text: 'Categories',
                                    ),
                                    Tab(
                                      icon: Icon(Icons.pie_chart, size: 20),
                                      text: 'Distribution',
                                    ),
                                    Tab(
                                      icon: Icon(Icons.show_chart, size: 20),
                                      text: 'Trend',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Tab Views
                      Expanded(
                        child: _isLoading
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading charts...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                            : _expenses.isEmpty
                            ? Center(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.scale(
                                  scale: value,
                                  child: _buildGlassContainer(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.bar_chart,
                                          size: 80,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No expense data available',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white.withOpacity(
                                                0.9),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add some expenses to see charts',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                                0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                            : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCategoryBarChart(),
                            _buildPieChart(),
                            _buildLineChart(),
                          ],
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

  Widget _buildCategoryBarChart() {
    final Map<String, double> categoryTotals = {};

    for (final expense in _expenses) {
      categoryTotals.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final barGroups = <BarChartGroupData>[];
    final categoryList = categoryTotals.keys.toList();
    final colors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
    ];

    for (int i = 0; i < categoryList.length; i++) {
      final category = categoryList[i];
      final amount = categoryTotals[category]!;
      final gradient = colors[i % colors.length];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              width: 25,
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildGlassContainer(
                child: Column(
                  children: [
                    Text(
                      'Spending by Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: PKR ${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: categoryList.isEmpty
                          ? const Center(child: Text(
                          'No categories to display'))
                          : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(categoryTotals.values),
                          barGroups: barGroups,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 &&
                                      index < categoryList.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        categoryList[index],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                reservedSize: 30,
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.black87,
                              getTooltipItem: (group, groupIndex, rod,
                                  rodIndex) {
                                final category = categoryList[group.x.toInt()];
                                final amount = rod.toY;
                                final percentage = (amount / total * 100)
                                    .toStringAsFixed(1);
                                return BarTooltipItem(
                                  '$category\nPKR ${amount.toStringAsFixed(
                                      2)}\n$percentage%',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          gridData: FlGridData(
                            drawHorizontalLine: true,
                            drawVerticalLine: false,
                            horizontalInterval: _getMaxY(
                                categoryTotals.values) / 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white.withOpacity(0.2),
                                strokeWidth: 1,
                              );
                            },
                          ),
                        ),
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

  Widget _buildPieChart() {
    final Map<String, double> categoryTotals = {};
    for (final expense in _expenses) {
      categoryTotals.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);

    final sections = <PieChartSectionData>[];
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFFf093fb),
      const Color(0xFF4facfe),
      const Color(0xFF43e97b),
      const Color(0xFFfa709a),
      const Color(0xFFa8edea),
      const Color(0xFF764ba2),
      const Color(0xFFf5576c),
    ];

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final percentage = (entry.value / total) * 100;

      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          color: colors[i % colors.length],
          radius: 120,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildGlassContainer(
                child: Column(
                  children: [
                    Text(
                      'Expense Distribution',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: PKR ${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                  Expanded(
                      child: sections.isEmpty
                          ? const Center(child: Text('No data to display'))
                          : LayoutBuilder(
                          builder: (context, constraints) {
                            // Check if the screen is wide enough for a side-by-side layout
                            bool isWideScreen = constraints.maxWidth > 500;

                            if (isWideScreen) {
                              // --- WIDE SCREEN LAYOUT (side-by-side) ---
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: PieChart(
                                      PieChartData(
                                        sections: sections,
                                        centerSpaceRadius: 40,
                                        sectionsSpace: 2,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildPieChartLegend(
                                        sortedCategories, colors),
                                  ),
                                ],
                              );
                            } else {
                              // --- NARROW SCREEN LAYOUT (stacked) ---
                              return Column(
                                children: [
                                  Expanded(
                                    flex: 3, // Give more space to the chart
                                    child: PieChart(
                                      PieChartData(
                                        sections: sections,
                                        centerSpaceRadius: 40,
                                        sectionsSpace: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    flex: 2, // Give space for the legend below
                                    child: _buildPieChartLegend(
                                        sortedCategories, colors),
                                  ),
                                ],
                              );
                            }
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
  }

  Widget _buildLineChart() {
    final Map<DateTime, double> dailyTotals = {};

    final today = DateTime.now();
    final oneMonthAgo = today.subtract(const Duration(days: 30));

    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateWithoutTime = DateTime(date.year, date.month, date.day);
      dailyTotals[dateWithoutTime] = 0;
    }

    for (final expense in _expenses) {
      final dateWithoutTime = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day
      );

      if (dateWithoutTime.isAfter(oneMonthAgo) ||
          dateWithoutTime.isAtSameMomentAs(oneMonthAgo)) {
        dailyTotals.update(
            dateWithoutTime,
                (value) => value + expense.amount,
            ifAbsent: () => expense.amount
        );
      }
    }

    final sortedDates = dailyTotals.keys.toList()
      ..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final amount = dailyTotals[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), amount));
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildGlassContainer(
                child: Column(
                  children: [
                    Text(
                      'Daily Spending (Last 30 Days)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: spots.isEmpty
                          ? const Center(child: Text(
                          'No daily data to display'))
                          : LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 3,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: const Color(0xFF667eea),
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF667eea).withOpacity(0.3),
                                    const Color(0xFF764ba2).withOpacity(0.1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index % 5 == 0 &&
                                      index < sortedDates.length) {
                                    final date = sortedDates[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        '${date.month}/${date.day}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            drawHorizontalLine: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white.withOpacity(0.2),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.black87,
                              getTooltipItems: (
                                  List<LineBarSpot> touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final index = spot.x.toInt();
                                  if (index >= 0 &&
                                      index < sortedDates.length) {
                                    final date = sortedDates[index];
                                    final dateStr = '${date.month}/${date.day}';

                                    return LineTooltipItem(
                                      '$dateStr\nPKR ${spot.y.toStringAsFixed(
                                          2)}',
                                      const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    );
                                  }
                                  return null;
                                }).toList();
                              },
                            ),
                          ),
                        ),
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

  double _getMaxY(Iterable<double> values) {
    if (values.isEmpty) return 100;
    final max = values.reduce((curr, next) => curr > next ? curr : next);
    return max * 1.1;
  }

  Widget _buildPieChartLegend(List<MapEntry<String, double>> sortedCategories,
      List<Color> colors) {
    final total = sortedCategories.fold(0.0, (sum, entry) => sum + entry.value);

    return Container(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final percentage = (entry.value / total * 100).toStringAsFixed(
                    1);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
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
          ),
        ],
      ),
    );
  }
}