import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/budget.dart'; // You will need to create this file for the budget feature

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Use a getter to always get the current user's UID.
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // =======================================================================
  // Expense Methods
  // =======================================================================

  Future<void> addExpense(Expense expense) async {
    if (uid.isEmpty) throw Exception('User not logged in');

    await _db.collection('expenses').add({
      'title': expense.title,
      'amount': expense.amount,
      'date': Timestamp.fromDate(expense.date),
      'category': expense.category,
      'userId': uid, // Ensure the userId is always stored
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Expense>> getExpenses() {
    if (uid.isEmpty) return Stream.value([]); // Handle unauthenticated state

    // Query for the user's expenses and sort them by date.
    // NOTE: For this to be most efficient, you should create a composite index in your
    // Firebase console for the 'expenses' collection on 'userId' (ascending) and 'date' (descending).
    return _db
        .collection('expenses')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
      } catch (e) {
        print('Error parsing expenses: $e');
        return <Expense>[];
      }
    }).handleError((e) {
      print('Error loading expenses: $e');
      return <Expense>[];
    });
  }

  Future<void> updateExpense(String id, Expense expense) async {
    if (uid.isEmpty) throw Exception('User not logged in');

    await _db.collection('expenses').doc(id).update({
      'title': expense.title,
      'amount': expense.amount,
      'date': Timestamp.fromDate(expense.date),
      'category': expense.category,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String id) async {
    if (uid.isEmpty) throw Exception('User not logged in');

    await _db.collection('expenses').doc(id).delete();
  }

  // =======================================================================
  // Home Screen & Chart Methods
  // =======================================================================

  /// Calculates statistics for the home screen.
  Future<Map<String, double>> getHomeScreenStats() async {
    if (uid.isEmpty) {
      return {'monthTotal': 0.0, 'grandTotal': 0.0};
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Query all expenses for the current user once
    final querySnapshot =
    await _db.collection('expenses').where('userId', isEqualTo: uid).get();

    double monthTotal = 0.0;
    double grandTotal = 0.0;

    for (var doc in querySnapshot.docs) {
      final expense = Expense.fromFirestore(doc);
      grandTotal += expense.amount;

      // Check if the expense is within the current month
      if (expense.date.isAfter(startOfMonth) || expense.date.isAtSameMomentAs(startOfMonth)) {
        monthTotal += expense.amount;
      }
    }

    return {'monthTotal': monthTotal, 'grandTotal': grandTotal};
  }

  Stream<Map<String, double>> getExpenseTotalsByCategory() {
    if (uid.isEmpty) return Stream.value({});

    return _db
        .collection('expenses')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final Map<String, double> categoryTotals = {};
      for (final doc in snapshot.docs) {
        final expense = Expense.fromFirestore(doc);
        categoryTotals.update(
          expense.category,
              (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
      return categoryTotals;
    });
  }

  // =======================================================================
  // Budget Methods (For the new Budget Feature)
  // =======================================================================

  /// Adds a new budget or updates an existing one for a specific category and month.
  Future<void> addOrUpdateBudget(Budget budget) async {
    if (uid.isEmpty) throw Exception('User not logged in');

    // Create a predictable document ID to prevent duplicates
    final docId = '${uid}_${budget.year}_${budget.month}_${budget.category}';

    await _db.collection('budgets').doc(docId).set({
      'userId': uid,
      'category': budget.category,
      'amount': budget.amount,
      'month': budget.month,
      'year': budget.year,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Gets a stream of all budgets for a specific month and year.
  Stream<List<Budget>> getBudgetsForMonth(int month, int year) {
    if (uid.isEmpty) return Stream.value([]);

    return _db
        .collection('budgets')
        .where('userId', isEqualTo: uid)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList();
      } catch (e) {
        print('Error parsing budgets: $e');
        return [];
      }
    });
  }

  /// Deletes a specific budget document.
  Future<void> deleteBudget(String budgetId) async {
    if (uid.isEmpty) throw Exception('User not logged in');

    await _db.collection('budgets').doc(budgetId).delete();
  }

  Future<void> clearBudgetsForMonth(int month, int year) async {
    if (uid.isEmpty) throw Exception('User not logged in');

    // 1. Query for all the budget documents that match the criteria.
    final querySnapshot = await _db
        .collection('budgets')
        .where('userId', isEqualTo: uid)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    if (querySnapshot.docs.isEmpty) {
      // No budgets to clear, so we can just return.
      return;
    }

    // 2. Create a batched write to delete all found documents in a single operation.
    final batch = _db.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Commit the batch. This is an atomic operation.
    await batch.commit();
  }
}