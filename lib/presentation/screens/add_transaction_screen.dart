import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/ai_copilot_service.dart';
import '../../data/services/database_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/user_profile_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String initialType;

  const AddTransactionScreen({super.key, this.initialType = 'income'});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String _type = 'income';
  double _amount = 0.0;
  String _category = '';
  DateTime _date = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isCategorizing = false;

  final List<String> _incomeCategories = [
    'Salary',
    'Delivery',
    'Vendor',
    'Other',
  ];

  final List<String> _expenseCategories = [
    'Food',
    'Fuel',
    'Rent',
    'Transport',
    'Other',
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == 'income'
        ? _incomeCategories[0]
        : _expenseCategories[0];
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmount(String value) {
    final parsed = double.tryParse(value) ?? 0.0;
    setState(() {
      _amount = parsed;
    });
  }

  void _quickAddAmount(double amount) {
    final newAmount = _amount + amount;
    setState(() {
      _amount = newAmount;
      _amountController.text = newAmount.toStringAsFixed(0);
    });
  }

  Future<void> _saveTransaction() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        type: _type,
        amount: _amount,
        category: _category,
        date: _date,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      // Save to repository
      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);

      // Invalidate providers to refresh
      ref.invalidate(transactionsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(stabilityProvider);
      ref.invalidate(forecastProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_type == 'income' ? 'Income' : 'Expense'} added successfully',
            ),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // TODO: Implement undo
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(Responsive.cardPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(
                      bottom: Responsive.spacing(context, 24),
                      top: Responsive.spacing(context, 8),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Title
                Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 24),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 24)),

                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        'income',
                        'Income',
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildTypeButton(
                        'expense',
                        'Expense',
                        AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Amount input
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹',
                    hintText: '0',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _amountController.clear();
                        setState(() {
                          _amount = 0;
                        });
                      },
                    ),
                  ),
                  onChanged: _updateAmount,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Quick amount buttons
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    _buildQuickAmountButton(100),
                    _buildQuickAmountButton(500),
                    _buildQuickAmountButton(1000),
                    _buildQuickAmountButton(5000),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      (_type == 'income'
                              ? _incomeCategories
                              : _expenseCategories)
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _date = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('MMM dd, yyyy').format(_date)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Note with AI categorization
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    suffixIcon: _isCategorizing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.auto_awesome),
                            tooltip: 'Auto-categorize with AI',
                            onPressed:
                                _amount > 0 && _noteController.text.isNotEmpty
                                ? _autoCategorize
                                : null,
                          ),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    // Auto-categorize when user types
                    if (value.length > 10 && _amount > 0) {
                      _autoCategorize();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _saveTransaction,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Transaction'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, Color color) {
    final isSelected = _type == type;
    return InkWell(
      onTap: () {
        setState(() {
          _type = type;
          _category = type == 'income'
              ? _incomeCategories[0]
              : _expenseCategories[0];
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    return OutlinedButton(
      onPressed: () => _quickAddAmount(amount),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        '+₹${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _autoCategorize() async {
    if (_noteController.text.isEmpty || _amount <= 0 || _isCategorizing) {
      return;
    }

    setState(() {
      _isCategorizing = true;
    });

    try {
      // Get user profile for better categorization
      final phone = ref.read(currentUserPhoneProvider);
      final databaseService = DatabaseService();
      final userProfile = phone != null
          ? await databaseService.getUserByPhone(phone)
          : null;

      final category = await AiCopilotService.categorizeTransaction(
        description: _noteController.text,
        amount: _amount,
        type: _type,
        userProfile: userProfile,
      );

      if (mounted) {
        setState(() {
          _category = category;
          _isCategorizing = false;
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-categorized as: $category'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCategorizing = false;
        });
        // Silently fail - user can still select category manually
        print('AI categorization failed: $e');
      }
    }
  }
}
