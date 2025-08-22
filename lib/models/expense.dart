import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? userId;  // Make userId part of the model

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.userId,
  });

  // Create from Firestore document
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle potential null or missing values
    final date = data['date'] is Timestamp 
        ? (data['date'] as Timestamp).toDate() 
        : DateTime.now();
        
    final amount = data['amount'] is double 
        ? data['amount'] as double
        : data['amount'] is int 
            ? (data['amount'] as int).toDouble()
            : 0.0;
    
    return Expense(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      amount: amount,
      date: date,
      category: data['category'] ?? 'Other',
      userId: data['userId'],
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'userId': userId,
    };
  }
}