import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class CategoryAnalytics {
  final String category;
  final double totalAmount;
  final double percentage;
  final Color color;

  CategoryAnalytics({
    required this.category,
    required this.totalAmount,
    required this.percentage,
    required this.color,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  // Official fixed 10-color palette for Raqmify Expense Analytics
  static const Map<String, Color> _categoryColorMap = {
    'food': Color(0xFF0B3D34),
    'housing': Color(0xFF1A6553),
    'rent': Color(0xFF1A6553),
    'transport': Color(0xFF16C79A),
    'transportation': Color(0xFF16C79A),
    'travel': Color(0xFF16C79A),
    'groceries': Color(0xFF83C5AD),
    'grocery': Color(0xFF83C5AD),
    'bill': Color(0xFFD4AF6B),
    'bills': Color(0xFFD4AF6B),
    'utilities': Color(0xFFD4AF6B),
    'education': Color(0xFFA8844F),
    'health': Color(0xFF4D9A80),
    'medical': Color(0xFF4D9A80),
    'shopping': Color(0xFFB7DCCF),
    'entertainment': Color(0xFF2C8175),
    'other': Color(0xFF8C9D95),
  };

  /// Returns the deterministic category color adhering to the 10-color Raqmify palette
  static Color getCategoryColor(String category) {
    final key = category.trim().toLowerCase();
    if (_categoryColorMap.containsKey(key)) {
      return _categoryColorMap[key]!;
    }
    // Substring match for compound category names (e.g. "Food & Dining", "Bills/Utilities")
    for (final entry in _categoryColorMap.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }
    return const Color(0xFF8C9D95); // Default to Other: #8C9D95
  }

  List<CategoryAnalytics> getCategoryBreakdown(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return [];

    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    if (total == 0) return [];

    final Map<String, double> categorySums = {};
    for (final exp in expenses) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
    }

    final sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<CategoryAnalytics> list = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final pct = (entry.value / total) * 100;
      final color = getCategoryColor(entry.key);

      list.add(CategoryAnalytics(
        category: entry.key,
        totalAmount: entry.value,
        percentage: pct,
        color: color,
      ));
    }

    return list;
  }
}
