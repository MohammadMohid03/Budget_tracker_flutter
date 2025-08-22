import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single budget entry set by the user for a specific category and month.
class Budget {
  final String id; // The document ID from Firestore
  final String category;
  final double amount;
  final int month; // e.g., 8 for August
  final int year;  // e.g., 2025

  const Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
  });

  /// Factory constructor to create a Budget instance from a Firestore document.
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    // Cast the data to a Map<String, dynamic> to access its fields.
    final data = doc.data() as Map<String, dynamic>;

    return Budget(
      // The document ID is retrieved from the snapshot itself, not the data map.
      id: doc.id,
      // Use null-aware operators to provide default values if a field is missing.
      category: data['category'] ?? 'Unknown',
      // Safely cast 'amount' from num to double, handling both int and double types.
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      month: data['month'] ?? 0,
      year: data['year'] ?? 0,
    );
  }
}