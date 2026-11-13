import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/app_failure.dart';
import '../core/network/result.dart';
import '../dev/demo_data.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Pagination (Q3)
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  // Filter States
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedPaymentMethod = 'All';

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedPaymentMethod => _selectedPaymentMethod;

  ExpenseProvider() {
    _expenses = [];
  }

  void clearData() {
    _expenses = [];
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
  }

  void loadDemoData() {
    if (!kDebugMode) return;
    _expenses = DemoData.getSampleExpenses();
    notifyListeners();
  }

  // --- Analytical Calculations (As defined in Proposal) ---
  double get todaySpend {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get currentMonthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get dynamicDailyAverage {
    final now = DateTime.now();
    final daysElapsed = now.day > 0 ? now.day : 1;
    final total = currentMonthTotal;
    return total / daysElapsed;
  }

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

  // Fetch with Pagination (Q3)
  Future<void> fetchExpenses({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        ApiConstants.expenses,
        queryParameters: {'page': _currentPage, 'limit': _pageSize},
      );

      if (response.data != null) {
        final dynamic raw = response.data;
        final List<dynamic> list = raw is List
            ? raw
            : (raw['expenses'] ?? raw['data'] ?? []);

        final fetched = list
            .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh || _currentPage == 1) {
          _expenses = fetched;
        } else {
          _expenses.addAll(fetched);
        }

        _hasMore = fetched.length >= _pageSize;
      } else {
        if (refresh || _currentPage == 1) _expenses = [];
        _hasMore = false;
      }
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreExpenses() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiClient.get(
        ApiConstants.expenses,
        queryParameters: {'page': nextPage, 'limit': _pageSize},
      );

      if (response.data != null) {
        final dynamic raw = response.data;
        final List<dynamic> list = raw is List
            ? raw
            : (raw['expenses'] ?? raw['data'] ?? []);

        final fetched = list
            .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
            .toList();

        _expenses.addAll(fetched);
        _currentPage = nextPage;
        _hasMore = fetched.length >= _pageSize;
      } else {
        _hasMore = false;
      }
    } catch (_) {
      // Background page load failure doesn't wipe existing items
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Add Expense with Explicit Result and Sync State (S5)
  Future<Result<ExpenseModel>> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required String paymentMethod,
    String notes = '',
  }) async {
    final tempId = 'exp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ExpenseModel(
      id: tempId,
      title: title,
      amount: amount,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
      notes: notes,
      syncStatus: 'pending',
    );

    // Optimistic insert
    _expenses.insert(0, optimistic);
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.expenses,
        data: optimistic.toJson(),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final created = ExpenseModel.fromJson(response.data as Map<String, dynamic>).copyWith(
          syncStatus: 'synced',
        );
        final idx = _expenses.indexWhere((e) => e.id == tempId);
        if (idx != -1) {
          _expenses[idx] = created;
          notifyListeners();
        }
        return Success(created);
      }

      // Synced successfully
      final synced = optimistic.copyWith(syncStatus: 'synced');
      final idx = _expenses.indexWhere((e) => e.id == tempId);
      if (idx != -1) {
        _expenses[idx] = synced;
        notifyListeners();
      }
      return Success(synced);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      // Mark as pending or failed
      final idx = _expenses.indexWhere((e) => e.id == tempId);
      if (idx != -1) {
        // If 4xx client rejection (e.g. invalid payload), roll back
        if (failure.statusCode != null && failure.statusCode! >= 400 && failure.statusCode! < 500 && failure.statusCode != 408) {
          _expenses.removeAt(idx);
          _errorMessage = failure.message;
          notifyListeners();
          return Failure(failure);
        } else {
          // Network issue: keep in queue with 'failed' or 'pending' badge
          _expenses[idx] = optimistic.copyWith(syncStatus: 'failed');
          _errorMessage = 'Expense saved locally. Pending sync: ${failure.message}';
          notifyListeners();
          return Failure(failure);
        }
      }
      return Failure(failure);
    }
  }

  Future<Result<ExpenseModel>> addExpenseModel(ExpenseModel expense) async {
    return addExpense(
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      paymentMethod: expense.paymentMethod,
      notes: expense.notes,
    );
  }

  // Update Expense with explicit Result (S5)
  Future<Result<ExpenseModel>> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required String paymentMethod,
    String notes = '',
  }) async {
    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx == -1) {
      return Failure.fromMessage('Expense not found');
    }

    final previous = _expenses[idx];
    final updated = previous.copyWith(
      title: title,
      amount: amount,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
      notes: notes,
      syncStatus: 'pending',
    );

    _expenses[idx] = updated;
    notifyListeners();

    try {
      await _apiClient.put(
        '${ApiConstants.expenses}/$id',
        data: updated.toJson(),
      );

      final synced = updated.copyWith(syncStatus: 'synced');
      final currentIdx = _expenses.indexWhere((e) => e.id == id);
      if (currentIdx != -1) {
        _expenses[currentIdx] = synced;
        notifyListeners();
      }
      return Success(synced);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      final currentIdx = _expenses.indexWhere((e) => e.id == id);
      if (currentIdx != -1) {
        if (failure.statusCode != null && failure.statusCode! >= 400 && failure.statusCode! < 500) {
          // Roll back on permanent error
          _expenses[currentIdx] = previous;
          _errorMessage = failure.message;
          notifyListeners();
          return Failure(failure);
        } else {
          _expenses[currentIdx] = updated.copyWith(syncStatus: 'failed');
          notifyListeners();
        }
      }
      return Failure(failure);
    }
  }

  // Delete Expense with Rollback (S5)
  Future<Result<void>> deleteExpense(String id) async {
    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx == -1) return const Success(null);

    final deletedItem = _expenses[idx];
    _expenses.removeAt(idx);
    notifyListeners();

    try {
      await _apiClient.delete('${ApiConstants.expenses}/$id');
      return const Success(null);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      // Roll back
      _expenses.insert(idx, deletedItem);
      _errorMessage = 'Could not delete expense: ${failure.message}';
      notifyListeners();
      return Failure(failure);
    }
  }

  // Retry sync for an unsynced expense (S5)
  Future<void> retrySync(String id) async {
    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final item = _expenses[idx];
    _expenses[idx] = item.copyWith(syncStatus: 'pending');
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.expenses,
        data: item.toJson(),
      );
      final currentIdx = _expenses.indexWhere((e) => e.id == id);
      if (currentIdx != -1) {
        _expenses[currentIdx] = item.copyWith(syncStatus: 'synced');
        notifyListeners();
      }
    } catch (e) {
      final currentIdx = _expenses.indexWhere((e) => e.id == id);
      if (currentIdx != -1) {
        _expenses[currentIdx] = item.copyWith(syncStatus: 'failed');
        notifyListeners();
      }
    }
  }

  // Restore expense for Undo action (U5)
  void restoreExpense(ExpenseModel expense) {
    if (!_expenses.any((e) => e.id == expense.id)) {
      _expenses.insert(0, expense);
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
