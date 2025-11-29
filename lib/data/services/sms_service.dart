import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';

const String _smsBoxName = 'sms_transactions';
const String _autoFetchKey = 'sms_auto_fetch_enabled';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Telephony _telephony = Telephony.instance;
  bool _isListening = false;
  bool _autoFetchEnabled = false;

  /// Initialize SMS service and load settings
  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_smsBoxName);
    _loadAutoFetchSetting();
  }

  void _loadAutoFetchSetting() {
    final box = Hive.box(_smsBoxName);
    _autoFetchEnabled = box.get(_autoFetchKey, defaultValue: false) as bool;
  }

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Request SMS permission
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Enable/disable auto-fetch
  Future<void> setAutoFetch(bool enabled) async {
    _autoFetchEnabled = enabled;
    final box = Hive.box(_smsBoxName);
    await box.put(_autoFetchKey, enabled);

    if (enabled) {
      await _setupSmsListener();
    }
  }

  bool get autoFetchEnabled => _autoFetchEnabled;

  /// Get count of stored transactions (for debugging)
  Future<int> getStoredTransactionCount() async {
    try {
      final box = await Hive.openBox(_smsBoxName);
      int count = 0;
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map &&
            value.containsKey('source') &&
            value['source'] == 'sms') {
          count++;
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Setup SMS listener for real-time transaction detection
  Future<void> _setupSmsListener() async {
    if (!await hasPermission() || _isListening) return;

    try {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          _processSmsMessage(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
      );
      _isListening = true;
    } catch (e) {
      // Handle error setting up listener
      _isListening = false;
    }
  }

  /// Process incoming SMS message
  Future<void> _processSmsMessage(SmsMessage message) async {
    final body = (message.body ?? '').trim();
    final sender = (message.address ?? '').trim();
    final dateMillis = message.date ?? DateTime.now().millisecondsSinceEpoch;

    if (body.isEmpty) return;

    // Parse amount
    final amount = _parseAmount(body);
    if (amount == null || amount <= 0) return;

    // Check if it looks like a transaction
    if (!_looksLikeTransaction(body)) return;

    // Determine transaction type (income/expense)
    final type = _determineTransactionType(body);

    // Check for duplicates
    if (await _isDuplicate(sender, amount, dateMillis)) return;

    // Save transaction
    await _saveTransaction(
      sender: sender,
      body: body,
      amount: amount,
      dateMillis: dateMillis,
      type: type,
    );
  }

  /// Fetch SMS from inbox and process them
  Future<List<Transaction>> fetchSmsTransactions({int daysBack = 14}) async {
    if (!await hasPermission()) {
      throw Exception('SMS permission not granted');
    }

    final twoWeeksAgo = DateTime.now()
        .subtract(Duration(days: daysBack))
        .millisecondsSinceEpoch;

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final List<Transaction> newTransactions = [];

    for (final sms in messages) {
      final body = (sms.body ?? '').trim();
      if (body.isEmpty) continue;

      final sender = (sms.address ?? '').trim();
      final smsDate = sms.date ?? DateTime.now().millisecondsSinceEpoch;

      // Skip old SMS
      if (smsDate < twoWeeksAgo) break;

      // Parse amount
      final amount = _parseAmount(body);
      if (amount == null || amount <= 0) continue;

      // Check if it looks like a transaction
      if (!_looksLikeTransaction(body)) continue;

      // Check for duplicates
      if (await _isDuplicate(sender, amount, smsDate)) continue;

      // Determine transaction type
      final type = _determineTransactionType(body);

      // Save transaction
      final transaction = await _saveTransaction(
        sender: sender,
        body: body,
        amount: amount,
        dateMillis: smsDate,
        type: type,
      );

      if (transaction != null) {
        newTransactions.add(transaction);
      }
    }

    return newTransactions;
  }

  /// Get all SMS-based transactions from storage
  Future<List<Transaction>> getStoredTransactions() async {
    try {
      // Ensure box is open
      final box = await Hive.openBox(_smsBoxName);
      final transactions = <Transaction>[];

      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map &&
            value.containsKey('source') &&
            value['source'] == 'sms') {
          try {
            final transaction = Transaction(
              id: value['id'] as String? ?? key.toString(),
              type: value['type'] as String? ?? 'expense',
              amount: (value['amount'] as num?)?.toDouble() ?? 0.0,
              category: _extractCategory(value['body'] as String? ?? ''),
              date: DateTime.fromMillisecondsSinceEpoch(
                value['date'] as int? ?? 0,
              ),
              note: value['body'] as String?,
            );
            transactions.add(transaction);
          } catch (e) {
            // Skip invalid entries
            continue;
          }
        }
      }

      // Sort by date (newest first)
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    } catch (e) {
      // If box doesn't exist or error, return empty list
      return [];
    }
  }

  /// Save transaction to Hive storage
  Future<Transaction?> _saveTransaction({
    required String sender,
    required double amount,
    required int dateMillis,
    required String type,
    required String body,
  }) async {
    try {
      // Ensure box is open
      final box = await Hive.openBox(_smsBoxName);
      final id = 'sms_${dateMillis}_${amount.toStringAsFixed(2)}';

      final transactionData = {
        'id': id,
        'address': sender,
        'body': body,
        'amount': amount,
        'date': dateMillis,
        'type': type,
        'source': 'sms',
      };

      await box.put(id, transactionData);

      // Force Hive to persist immediately
      await box.flush();

      return Transaction(
        id: id,
        type: type,
        amount: amount,
        category: _extractCategory(body),
        date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
        note: body,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if transaction is duplicate
  Future<bool> _isDuplicate(
    String sender,
    double amount,
    int dateMillis,
  ) async {
    try {
      final box = await Hive.openBox(_smsBoxName);
      final senderLc = sender.toLowerCase();

      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map && value.containsKey('source')) {
          final savedSender = (value['address'] ?? '').toString().toLowerCase();
          final savedAmount = (value['amount'] as num?)?.toDouble();
          final savedDate = value['date'] as int? ?? 0;

          final timeDiff = (savedDate - dateMillis).abs();
          if (savedAmount == amount &&
              savedSender == senderLc &&
              timeDiff < 300000) {
            // 5 minutes window
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Parse amount from SMS body
  double? _parseAmount(String body) {
    final patterns = [
      RegExp(
        r'(?:rs|inr|₹|rupees?|amount|amt)\s*:?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:rs|inr|₹|rupees?)',
        caseSensitive: false,
      ),
      RegExp(r'\b([0-9]{1,2}(?:,[0-9]{2})*(?:\.[0-9]{1,2})?)\b'),
      RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:rs|inr|₹)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final numeric = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(numeric);
        if (amount != null && amount > 0 && amount < 100000000) {
          return amount;
        }
      }
    }
    return null;
  }

  /// Check if SMS looks like a transaction
  bool _looksLikeTransaction(String body) {
    final lower = body.toLowerCase();
    return lower.contains('upi') ||
        lower.contains('credited') ||
        lower.contains('debited') ||
        lower.contains('payment') ||
        lower.contains('paid') ||
        lower.contains('txn') ||
        lower.contains('transaction') ||
        lower.contains('transfer') ||
        lower.contains('received') ||
        lower.contains('sent') ||
        lower.contains('successful') ||
        lower.contains('failed') ||
        lower.contains('refund') ||
        lower.contains('refunded') ||
        lower.contains('account') ||
        lower.contains('balance') ||
        lower.contains('a/c') ||
        lower.contains('bank') ||
        lower.contains('wallet') ||
        (lower.contains('rs') &&
            (lower.contains('credited') || lower.contains('debited'))) ||
        (lower.contains('₹') &&
            (lower.contains('credited') || lower.contains('debited')));
  }

  /// Determine if transaction is income or expense
  String _determineTransactionType(String body) {
    final lower = body.toLowerCase();
    if (lower.contains('credited') ||
        lower.contains('received') ||
        lower.contains('deposit')) {
      return 'income';
    } else if (lower.contains('debited') ||
        lower.contains('paid') ||
        lower.contains('sent') ||
        lower.contains('payment')) {
      return 'expense';
    }
    // Default to expense if unclear
    return 'expense';
  }

  /// Extract category from SMS body
  String _extractCategory(String body) {
    final lower = body.toLowerCase();

    // Check for common categories
    if (lower.contains('food') ||
        lower.contains('restaurant') ||
        lower.contains('zomato') ||
        lower.contains('swiggy')) {
      return 'Food';
    } else if (lower.contains('fuel') ||
        lower.contains('petrol') ||
        lower.contains('diesel')) {
      return 'Fuel';
    } else if (lower.contains('rent') || lower.contains('house')) {
      return 'Rent';
    } else if (lower.contains('transport') ||
        lower.contains('uber') ||
        lower.contains('ola')) {
      return 'Transport';
    } else if (lower.contains('salary') || lower.contains('income')) {
      return 'Salary';
    } else if (lower.contains('delivery')) {
      return 'Delivery';
    } else if (lower.contains('vendor')) {
      return 'Vendor';
    }

    return 'Other';
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  // Background processing can be added here if needed
  // For now, we rely on foreground listener
}
