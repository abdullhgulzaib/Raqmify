import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/group_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/split_provider.dart';

class ParticipantSplitItem {
  final String userId;
  final String name;
  final String email;
  final bool isCurrentUser;
  bool selected;
  double amount;
  double percentage;
  TextEditingController amountController;
  TextEditingController pctController;

  ParticipantSplitItem({
    required this.userId,
    required this.name,
    this.email = '',
    required this.isCurrentUser,
    this.selected = true,
    this.amount = 0.0,
    this.percentage = 0.0,
  })  : amountController = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(0) : ''),
        pctController = TextEditingController(text: percentage > 0 ? percentage.toStringAsFixed(1) : '');

  void dispose() {
    amountController.dispose();
    pctController.dispose();
  }
}

class CreateSplitExpenseBottomSheet extends StatefulWidget {
  final String? preselectedGroupId;

  const CreateSplitExpenseBottomSheet({
    super.key,
    this.preselectedGroupId,
  });

  static Future<void> show(BuildContext context, {String? preselectedGroupId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateSplitExpenseBottomSheet(preselectedGroupId: preselectedGroupId),
    );
  }

  @override
  State<CreateSplitExpenseBottomSheet> createState() => _CreateSplitExpenseBottomSheetState();
}

class _CreateSplitExpenseBottomSheetState extends State<CreateSplitExpenseBottomSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _categories = [
    'Food',
    'Groceries',
    'Utilities',
    'Housing',
    'Transport',
    'Entertainment',
    'Other',
  ];
  String _selectedCategory = 'Food';
  String _splitType = 'Equal'; // 'Equal' | 'Custom' | 'Percentage'

  String? _selectedGroupId;
  List<ParticipantSplitItem> _participants = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final groups = splitProvider.groups;
    if (widget.preselectedGroupId != null && groups.any((g) => g.id == widget.preselectedGroupId)) {
      _selectedGroupId = widget.preselectedGroupId;
    } else if (groups.isNotEmpty) {
      _selectedGroupId = groups.first.id;
    }

    _initParticipantsForGroup(_selectedGroupId, authProvider);
  }

  void _initParticipantsForGroup(String? groupId, AuthProvider auth) {
    for (final p in _participants) {
      p.dispose();
    }
    _participants = [];

    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final currentUserId = auth.currentUser?.id ?? 'demo_user_101';
    final currentUserName = auth.currentUser?.name ?? 'You';

    // Payer (Current User)
    _participants.add(
      ParticipantSplitItem(
        userId: currentUserId,
        name: '$currentUserName (You)',
        email: auth.currentUser?.email ?? '',
        isCurrentUser: true,
        selected: true,
        amount: 0.0,
        percentage: 100.0,
      ),
    );

    // Group Members
    if (groupId != null) {
      final grp = splitProvider.groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => GroupModel(
          id: '',
          name: '',
          createdBy: '',
          inviteCode: '',
          members: [],
          createdAt: DateTime.now(),
        ),
      );

      for (final m in grp.members) {
        if (m.userId != currentUserId && m.name.isNotEmpty) {
          _participants.add(
            ParticipantSplitItem(
              userId: m.userId,
              name: m.name,
              email: m.email,
              isCurrentUser: false,
              selected: true,
              amount: 0.0,
              percentage: 0.0,
            ),
          );
        }
      }
    }

    _recalculateSplits();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final p in _participants) {
      p.dispose();
    }
    super.dispose();
  }

  void _recalculateSplits() {
    final total = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final selectedCount = _participants.where((p) => p.selected).length;

    if (_splitType == 'Equal') {
      if (selectedCount == 0 || total <= 0) {
        for (final p in _participants) {
          p.amount = 0.0;
          p.percentage = 0.0;
          p.amountController.text = '0';
        }
        return;
      }

      final splitAmount = (total / selectedCount).floorToDouble();
      final remainder = total - (splitAmount * selectedCount);
      final splitPct = (100.0 / selectedCount);

      bool remainderAssigned = false;
      for (final p in _participants) {
        if (!p.selected) {
          p.amount = 0.0;
          p.percentage = 0.0;
          p.amountController.text = '0';
        } else {
          double amt = splitAmount;
          if (!remainderAssigned && remainder > 0) {
            amt += remainder;
            remainderAssigned = true;
          }
          p.amount = amt;
          p.percentage = splitPct;
          p.amountController.text = amt.toStringAsFixed(0);
        }
      }
    } else if (_splitType == 'Percentage') {
      final splitPct = selectedCount > 0 ? (100.0 / selectedCount) : 0.0;
      for (final p in _participants) {
        if (!p.selected) {
          p.amount = 0.0;
          p.percentage = 0.0;
          p.pctController.text = '0';
          p.amountController.text = '0';
        } else {
          if (p.percentage <= 0) {
            p.percentage = splitPct;
            p.pctController.text = splitPct.toStringAsFixed(1);
          }
          p.amount = (total * p.percentage) / 100.0;
          p.amountController.text = p.amount.toStringAsFixed(0);
        }
      }
    } else if (_splitType == 'Custom') {
      // Custom Amount Mode
      final payerIdx = _participants.indexWhere((p) => p.isCurrentUser);
      if (payerIdx != -1 && total > 0) {
        double othersSum = 0.0;
        for (int i = 0; i < _participants.length; i++) {
          if (i != payerIdx && _participants[i].selected) {
            othersSum += _participants[i].amount;
          }
        }
        final payerRemaining = (total - othersSum) > 0 ? (total - othersSum) : 0.0;
        _participants[payerIdx].amount = payerRemaining;
        _participants[payerIdx].amountController.text = payerRemaining.toStringAsFixed(0);
      }
    }
  }

  void _onTotalAmountChanged(String val) {
    setState(() {
      _errorMessage = null;
      _recalculateSplits();
    });
  }

  void _onSplitTypeChanged(String type) {
    setState(() {
      _splitType = type;
      _errorMessage = null;
      _recalculateSplits();
    });
  }

  void _toggleParticipant(int index) {
    setState(() {
      _participants[index].selected = !_participants[index].selected;
      _errorMessage = null;
      _recalculateSplits();
    });
  }

  void _showAddRoommateDialog() {
    final nameCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Roommate to Split',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nameCtl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Usman, Hamza',
            prefixIcon: Icon(Icons.person_add_rounded, color: AppColors.deepEmerald),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _participants.add(
                    ParticipantSplitItem(
                      userId: 'roommate_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      isCurrentUser: false,
                      selected: true,
                    ),
                  );
                  _recalculateSplits();
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSplit() async {
    final title = _titleController.text.trim();
    final total = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter an expense title.');
      return;
    }
    if (total <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }

    final activeParticipants = _participants.where((p) => p.selected).toList();
    if (activeParticipants.length < 2) {
      setState(() => _errorMessage = 'Shared expenses require at least 2 participants (e.g. you + 1 roommate).');
      return;
    }

    final allocatedSum = activeParticipants.fold<double>(0.0, (sum, p) => sum + p.amount);
    if ((allocatedSum - total).abs() > 2.0) {
      setState(() => _errorMessage =
          'Allocated sum (Rs ${allocatedSum.toStringAsFixed(0)}) must match total (Rs ${total.toStringAsFixed(0)}).');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id ?? 'demo_user_101';
    final currentUserName = authProvider.currentUser?.name ?? 'You';

    String groupName = 'Split Group';
    if (_selectedGroupId != null) {
      final grp = splitProvider.groups.where((g) => g.id == _selectedGroupId).firstOrNull;
      if (grp != null) groupName = grp.name;
    }

    final payload = activeParticipants.map((p) {
      return {
        'userId': p.userId,
        'name': p.name.replaceAll(' (You)', ''),
        'amount': p.amount,
        'percentage': p.percentage,
      };
    }).toList();

    final success = await splitProvider.createSplitExpense(
      title: title,
      totalAmount: total,
      category: _selectedCategory,
      groupId: _selectedGroupId ?? '',
      groupName: groupName,
      splitType: _splitType,
      paidByUserId: currentUserId,
      paidByName: currentUserName,
      notes: _notesController.text.trim(),
      participants: payload,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Split expense "$title" created successfully!'),
            backgroundColor: AppColors.deepEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _errorMessage = 'Failed to create split expense. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitProvider = Provider.of<SplitProvider>(context);
    final groups = splitProvider.groups;
    final total = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final activeParticipants = _participants.where((p) => p.selected).toList();
    final allocatedSum = activeParticipants.fold<double>(0.0, (sum, p) => sum + p.amount);
    final isMatched = total > 0 && (allocatedSum - total).abs() <= 2.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.call_split_rounded, color: AppColors.deepEmerald, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Create Split Expense',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkInk,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Group selector if groups exist
                if (groups.isNotEmpty) ...[
                  Text(
                    'Select Group',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGroupId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceSubtle,
                      prefixIcon: const Icon(Icons.group_rounded, color: AppColors.deepEmerald, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: groups.map((g) {
                      return DropdownMenuItem(
                        value: g.id,
                        child: Text(
                          g.name,
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedGroupId = val;
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          _initParticipantsForGroup(val, auth);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Expense Title
                Text(
                  'Expense Title',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkInk,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Weekly Ration, Biryani, Electricity Bill',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.deepEmerald, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Total Amount (PKR)
                Text(
                  'Total Amount (PKR)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkInk,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _onTotalAmountChanged,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEmerald,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'Rs  ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEmerald,
                    ),
                    hintText: '0',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 18),
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Chips
                Text(
                  'Category',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkInk,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((c) {
                      final isSel = c == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          labelStyle: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : AppColors.darkInk,
                          ),
                          selected: isSel,
                          selectedColor: AppColors.deepEmerald,
                          backgroundColor: AppColors.surfaceSubtle,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = c);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Split Type Segmented Selector
                Text(
                  'Split Mode',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkInk,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildSplitTypeTab('Equal', 'Equal Split', Icons.balance_rounded),
                      _buildSplitTypeTab('Custom', 'Exact Amount', Icons.tune_rounded),
                      _buildSplitTypeTab('Percentage', 'Percentage %', Icons.percent_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Participants Header & Add Roommate Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Participants (${activeParticipants.length}/${_participants.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkInk,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddRoommateDialog,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.deepEmerald),
                      label: Text(
                        '+ Add Roommate',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Participants List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _participants.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final p = _participants[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: p.selected ? Colors.white : AppColors.surfaceSubtle.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: p.selected ? AppColors.borderLight : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          Checkbox(
                            value: p.selected,
                            activeColor: AppColors.deepEmerald,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            onChanged: (_) => _toggleParticipant(idx),
                          ),

                          // Initial Circle
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: p.isCurrentUser
                                ? AppColors.deepEmerald
                                : AppColors.deepEmerald.withValues(alpha: 0.12),
                            child: Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.isCurrentUser ? Colors.white : AppColors.deepEmerald,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name & Payer badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: p.isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                                    color: p.selected ? AppColors.darkInk : AppColors.textMuted,
                                  ),
                                ),
                                if (p.isCurrentUser)
                                  Text(
                                    'Payer (You paid)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Input or Share preview based on mode
                          if (_splitType == 'Equal')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: p.selected ? AppColors.lightEmerald : AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p.selected ? 'Rs ${p.amount.toStringAsFixed(0)}' : 'Excluded',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.selected ? AppColors.deepEmerald : AppColors.textMuted,
                                ),
                              ),
                            )
                          else if (_splitType == 'Custom')
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: p.amountController,
                                enabled: p.selected,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepEmerald,
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'Rs ',
                                  prefixStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  filled: true,
                                  fillColor: p.selected ? AppColors.surfaceSubtle : Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    p.amount = double.tryParse(val.trim()) ?? 0.0;
                                    final payerIdx = _participants.indexWhere((item) => item.isCurrentUser);
                                    if (payerIdx != -1 && idx != payerIdx && total > 0) {
                                      double others = 0.0;
                                      for (int i = 0; i < _participants.length; i++) {
                                        if (i != payerIdx && _participants[i].selected) {
                                          others += _participants[i].amount;
                                        }
                                      }
                                      final remaining = (total - others) > 0 ? (total - others) : 0.0;
                                      _participants[payerIdx].amount = remaining;
                                      _participants[payerIdx].amountController.text = remaining.toStringAsFixed(0);
                                    }
                                  });
                                },
                              ),
                            )
                          else if (_splitType == 'Percentage')
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: p.pctController,
                                enabled: p.selected,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepEmerald,
                                ),
                                decoration: InputDecoration(
                                  suffixText: '%',
                                  suffixStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  filled: true,
                                  fillColor: p.selected ? AppColors.surfaceSubtle : Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    final pct = double.tryParse(val.trim()) ?? 0.0;
                                    p.percentage = pct;
                                    p.amount = (total * pct) / 100.0;
                                    p.amountController.text = p.amount.toStringAsFixed(0);
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Live Reconciliation Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMatched
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.pendingOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMatched
                          ? AppColors.successGreen.withValues(alpha: 0.3)
                          : AppColors.pendingOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMatched ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 18,
                        color: isMatched ? AppColors.successGreen : AppColors.pendingOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMatched
                              ? 'Allocated: Rs ${allocatedSum.toStringAsFixed(0)} (100% matched)'
                              : 'Allocated: Rs ${allocatedSum.toStringAsFixed(0)} of Rs ${total.toStringAsFixed(0)} (Rs ${(total - allocatedSum).abs().toStringAsFixed(0)} ${(total > allocatedSum) ? 'remaining' : 'over-allocated'})',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMatched ? AppColors.successGreen : AppColors.pendingOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Error message if any
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Notes / Remarks (Optional)
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Add an optional note (e.g. Paid via Easypaisa)',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textMuted, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 18),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitSplit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepEmerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Split Expense Now',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
  }

  Widget _buildSplitTypeTab(String type, String label, IconData icon) {
    final isSel = _splitType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onSplitTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSel ? AppColors.deepEmerald : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? AppColors.deepEmerald : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
