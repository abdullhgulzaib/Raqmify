import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/split_expense_model.dart';
import '../models/user_model.dart';

/// Development and debugging mock data (S1).
/// Only loaded when kDebugMode is true; tree-shaken from release builds.
class DemoData {
  static UserModel get demoUser {
    assert(kDebugMode, 'Demo data must only be accessed in debug mode');
    return UserModel(
      id: 'demo_user_101',
      name: 'Rana Abdullah',
      email: 'rana.abdullah@hostel.edu.pk',
      easypaisa: '03001234567',
      jazzcash: '03001234567',
    );
  }

  static List<ExpenseModel> getSampleExpenses() {
    if (!kDebugMode) return [];
    final now = DateTime.now();
    return [
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
  }

  static ({List<GroupModel> groups, List<SplitExpenseModel> expenses}) getSampleSplitData() {
    if (!kDebugMode) return (groups: [], expenses: []);
    final now = DateTime.now();

    final groups = [
      GroupModel(
        id: 'grp_hostel_304',
        name: 'Hostel Room 304 (Lahore)',
        description: 'Roommate shared expenses, mess & utilities',
        category: 'Hostel',
        icon: 'home',
        createdBy: 'demo_user_101',
        inviteCode: 'HOSTEL26',
        createdAt: now.subtract(const Duration(days: 15)),
        members: [
          GroupMember(userId: 'demo_user_101', name: 'Rana Abdullah', email: 'rana@hostel.edu.pk', role: 'Admin'),
          GroupMember(userId: 'user_ali', name: 'Ali (Flatmate)', email: 'ali@tech.pk', role: 'Member'),
          GroupMember(userId: 'user_abdul', name: 'Abdul Rehman', email: 'abdul@hostel.edu.pk', role: 'Member'),
        ],
      ),
      GroupModel(
        id: 'grp_trip_north',
        name: 'Northern Areas Roadtrip',
        description: 'Fuel, hotel stays & snacks',
        category: 'Trip',
        icon: 'compass',
        createdBy: 'user_ali',
        inviteCode: 'TRIP2026',
        createdAt: now.subtract(const Duration(days: 20)),
        members: [
          GroupMember(userId: 'demo_user_101', name: 'Rana Abdullah', email: 'rana@hostel.edu.pk'),
          GroupMember(userId: 'user_ali', name: 'Ali', email: 'ali@tech.pk'),
        ],
      ),
    ];

    final expenses = [
      SplitExpenseModel(
        id: 'split_1',
        title: 'Weekly Grocery & Mess Ration',
        totalAmount: 2540.0,
        category: 'Groceries',
        paidByUserId: 'demo_user_101',
        paidByName: 'Rana Abdullah',
        groupId: 'grp_hostel_304',
        groupName: 'Hostel Room 304 (Lahore)',
        splitType: 'Equal',
        date: now.subtract(const Duration(days: 4)),
        splits: [
          SplitMemberShare(userId: 'demo_user_101', name: 'Rana Abdullah', amount: 846.66, status: 'Settled'),
          SplitMemberShare(
            userId: 'user_ali',
            name: 'Ali (Flatmate)',
            amount: 846.67,
            status: 'Verified',
            proofTid: 'EP-9831772',
            paymentMethod: 'Easypaisa',
          ),
          SplitMemberShare(userId: 'user_abdul', name: 'Abdul Rehman', amount: 846.67, status: 'Unpaid'),
        ],
      ),
      SplitExpenseModel(
        id: 'split_2',
        title: 'Generator Fuel & Utility Bill',
        totalAmount: 1800.0,
        category: 'Utilities',
        paidByUserId: 'demo_user_101',
        paidByName: 'Rana Abdullah',
        groupId: 'grp_hostel_304',
        groupName: 'Hostel Room 304 (Lahore)',
        splitType: 'Equal',
        date: now.subtract(const Duration(days: 2)),
        splits: [
          SplitMemberShare(userId: 'demo_user_101', name: 'Rana Abdullah', amount: 600.0, status: 'Settled'),
          SplitMemberShare(userId: 'user_ali', name: 'Ali (Flatmate)', amount: 600.0, status: 'Unpaid'),
          SplitMemberShare(userId: 'user_abdul', name: 'Abdul Rehman', amount: 600.0, status: 'Unpaid'),
        ],
      ),
      SplitExpenseModel(
        id: 'split_3',
        title: 'Late Night Biryani & Chai',
        totalAmount: 1500.0,
        category: 'Food',
        paidByUserId: 'user_ali',
        paidByName: 'Ali (Flatmate)',
        groupId: 'grp_hostel_304',
        groupName: 'Hostel Room 304 (Lahore)',
        splitType: 'Equal',
        date: now.subtract(const Duration(days: 1)),
        splits: [
          SplitMemberShare(userId: 'user_ali', name: 'Ali (Flatmate)', amount: 500.0, status: 'Settled'),
          SplitMemberShare(userId: 'demo_user_101', name: 'Rana Abdullah', amount: 500.0, status: 'Unpaid'),
          SplitMemberShare(userId: 'user_abdul', name: 'Abdul Rehman', amount: 500.0, status: 'Unpaid'),
        ],
      ),
    ];

    return (groups: groups, expenses: expenses);
  }
}
