import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter States
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedPaymentMethod = 'All';

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedPaymentMethod => _selectedPaymentMethod;

  ExpenseProvider() {
    // Empty by default — real database data will be fetched on login
    _expenses = [];
  }

  void clearData() {
    _expenses = [];
    notifyListeners();
  }

  void loadDemoData() {
    final now = DateTime.now();
    _expenses = [
      ExpenseModel(
        id: 'exp_1',
        title: 'Hostel Room Rent & WiFi',
        amount: 8500.0,
        category: 'Housing',
        date: now.subtract(const Duration(days: 1)),
        paymentMethod: 'Bank Transfer',
        notes: 'Monthly hostel dues',
      ),
      ExpenseModel(
        id: 'exp_2',
        title: 'Dinner at Monal with Roommates',
        amount: 2540.0,
        category: 'Food',
        date: now,
        paymentMethod: 'Easypaisa',
        notes: 'Split between Rana, Ali and Abdul',
      ),
      ExpenseModel(
        id: 'exp_3',
        title: 'Metro Bus Card Recharge',
        amount: 1000.0,
        category: 'Transportation',
        date: now.subtract(const Duration(days: 3)),
        paymentMethod: 'Card',
      ),
      ExpenseModel(
        id: 'exp_4',
        title: 'Semester Textbooks & Printing',
        amount: 1850.0,
        category: 'Education',
        date: now.subtract(const Duration(days: 5)),
        paymentMethod: 'Cash',
      ),
      ExpenseModel(
        id: 'exp_5',
        title: 'Grocery (Milk, Eggs & Fruits)',
        amount: 980.0,
        category: 'Groceries',
        date: now,
        paymentMethod: 'Cash',
      ),
    ];
    notifyListeners();
  }

  // --- Analytical Calculations (As defined in Proposal) ---

  // Today's Total Spend
  double get todaySpend {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Current Month Total
  double get currentMonthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Dynamic Daily Average = Current Month Total / Days Elapsed
  double get dynamicDailyAverage {
    final now = DateTime.now();
    final daysElapsed = now.day > 0 ? now.day : 1;
    final total = currentMonthTotal;
    return total / daysElapsed;
  }

  // Filtered Expenses List
  List<ExpenseModel> get filteredExpenses {
    return _expenses.where((expense) {
      final matchesSearch = _searchQuery.isEmpty ||
          expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          expense.notes.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          expense.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesPayment = _selectedPaymentMethod == 'All' ||
          expense.paymentMethod.toLowerCase() == _selectedPaymentMethod.toLowerCase();

      return matchesSearch && matchesCategory && matchesPayment;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Filter Setters
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  // Fetch from MongoDB Atlas API
  Future<void> fetchExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.expenses);
      if (response.data != null) {
        final dynamic raw = response.data;
        final List<dynamic> list = raw is List
            ? raw
            : (raw['expenses'] ?? raw['data'] ?? []);
        _expenses = list
            .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _expenses = [];
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'] ?? e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add Expense
  Future<bool> addExpenseModel(ExpenseModel expense) async {
    _expenses.insert(0, expense);
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.expenses,
        data: expense.toJson(),
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        final created = ExpenseModel.fromJson(response.data as Map<String, dynamic>);
        final idx = _expenses.indexWhere((e) => e.id == expense.id);
        if (idx != -1) {
          _expenses[idx] = created;
          notifyListeners();
        }
      }
    } catch (_) {}
    return true;
  }

  Future<bool> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required String paymentMethod,
    String notes = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    final newExpense = ExpenseModel(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    // Optimistic UI update
    _expenses.insert(0, newExpense);

    try {
      final response = await _apiClient.post(
        ApiConstants.expenses,
        data: newExpense.toJson(),
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        final created = ExpenseModel.fromJson(response.data as Map<String, dynamic>);
        final idx = _expenses.indexWhere((e) => e.id == newExpense.id);
        if (idx != -1) {
          _expenses[idx] = created;
          notifyListeners();
        }
      }
    } catch (_) {
      // Local addition remains accessible even if offline
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Update Expense Model directly
  Future<bool> updateExpenseModel(ExpenseModel updated) async {
    final idx = _expenses.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _expenses[idx] = updated;
      notifyListeners();

      try {
        await _apiClient.put(
          '${ApiConstants.expenses}/${updated.id}',
          data: updated.toJson(),
        );
      } catch (_) {
        // Keep optimistic update
      }
      return true;
    }
    return false;
  }

  // Update Expense by fields
  Future<bool> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required String paymentMethod,
    String notes = '',
  }) async {
    final idx = _expenses.indexWhere((e) => e.id == id);
    final userId = idx != -1 ? _expenses[idx].userId : '';
    final status = idx != -1 ? _expenses[idx].status : 'Active';
    final updated = ExpenseModel(
      id: id,
      title: title,
      amount: amount,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
      notes: notes,
      userId: userId,
      status: status,
    );
    return updateExpenseModel(updated);
  }

  // Delete Expense
  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();

    try {
      await _apiClient.delete('${ApiConstants.expenses}/$id');
    } catch (_) {}
  }
}
