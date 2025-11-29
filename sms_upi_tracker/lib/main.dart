import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

const _boxName = 'txns';
const _autoFetchKey = 'auto_fetch_enabled';

const _knownSenders = [
  'hdfc',
  'icici',
  'sbi',
  'axis',
  'kotak',
  'yesbank',
  'paytm',
  'phonepe',
  'gpay',
  'googlepay',
  'google pay',
  'upi',
  'npci',
  'bank',
  'imps',
  'neft',
  'rtgs',
];

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(_boxName);

  // Request notification permission for Android 13+
  await Permission.notification.request();

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'upi_transactions',
    'UPI Transactions',
    description: 'Notifications for new UPI transactions',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  runApp(const MyApp());
}

bool _looksLikeUpiStatic(String body) {
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
      (lower.contains('rs') &&
          (lower.contains('credited') || lower.contains('debited'))) ||
      (lower.contains('₹') &&
          (lower.contains('credited') || lower.contains('debited')));
}

bool _isDuplicateStatic(
  Iterable<dynamic> existing,
  String sender,
  double amount,
  int dateMillis,
) {
  final senderLc = sender.toLowerCase();
  return existing.whereType<Map>().any((txn) {
    final savedSender = (txn['address'] ?? '').toString().toLowerCase();
    final savedAmount = (txn['amount'] as num?)?.toDouble();
    final savedDate = txn['date'] as int? ?? 0;
    // Check if same amount, same sender, and within 5 minutes (in case of multiple notifications for same transaction)
    final timeDiff = (savedDate - dateMillis).abs();
    return savedAmount == amount &&
        savedSender == senderLc &&
        timeDiff < 300000; // 5 minutes window instead of 30 seconds
  });
}

Future<void> _showNotificationStatic(String title, String body) async {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications in background context
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await notifications.initialize(initializationSettings);

  // Create notification channel in background context with high importance
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'upi_transactions',
    'UPI Transactions',
    description: 'Notifications for new UPI transactions',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );
  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'upi_transactions',
        'UPI Transactions',
        channelDescription: 'Notifications for new UPI transactions',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  try {
    await notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
    );
  } catch (e) {
    // Notification failed in background
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  // This is required for background isolates
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  try {
    final body = (message.body ?? '').trim();
    final senderRaw = (message.address ?? '').trim();
    final dateMillis = message.date ?? DateTime.now().millisecondsSinceEpoch;

    if (body.isEmpty) return;

    // Parse amount FIRST (without Hive dependency)
    // Very lenient amount parsing - try multiple patterns
    double? amount;
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
        final parsedAmount = double.tryParse(numeric);
        if (parsedAmount != null &&
            parsedAmount > 0 &&
            parsedAmount < 100000000) {
          amount = parsedAmount;
          break;
        }
      }
    }

    if (amount == null || amount <= 0) return;

    // Check if it looks like a transaction
    final looksLikeTransaction =
        _looksLikeUpiStatic(body) ||
        body.toLowerCase().contains('bank') ||
        body.toLowerCase().contains('wallet') ||
        (amount > 0 &&
            (body.toLowerCase().contains('to') ||
                body.toLowerCase().contains('from')));

    if (!looksLikeTransaction) return;

    // Show notification IMMEDIATELY - before any Hive operations
    // This ensures user gets notified even if app is closed or processing fails
    try {
      await _showNotificationStatic(
        'New UPI Transaction',
        '₹${amount.toStringAsFixed(2)} from ${senderRaw.length > 20 ? senderRaw.substring(0, 20) + "..." : senderRaw}',
      );
    } catch (e) {
      // Notification error - try again with simpler message
      try {
        await _showNotificationStatic(
          'UPI Payment Received',
          '₹${amount.toStringAsFixed(2)}',
        );
      } catch (_) {}
    }

    // Now try to save to database (but notification already shown)
    try {
      // Initialize Hive in background isolate
      await Hive.initFlutter();
      final box = await Hive.openBox(_boxName);

      // Check auto-fetch setting
      final autoFetchEnabled =
          box.get(_autoFetchKey, defaultValue: false) as bool;

      // Check for duplicates before adding
      final isDuplicate = _isDuplicateStatic(
        box.values,
        senderRaw,
        amount,
        dateMillis,
      );

      // Only add if not duplicate and auto-fetch is enabled
      if (!isDuplicate && autoFetchEnabled) {
        await box.add({
          'address': senderRaw,
          'body': body,
          'amount': amount,
          'date': dateMillis,
          'source': 'sms',
        });
      }
    } catch (e) {
      // Database error - notification already shown, so continue
    }
  } catch (e) {
    // Overall error - still try to show notification
    try {
      await _showNotificationStatic(
        'UPI Transaction Detected',
        'Check your SMS',
      );
    } catch (_) {}
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final Telephony _telephony = Telephony.instance;
  final NumberFormat _currencyFmt = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );

  bool _isFetching = false;
  String? _statusMessage;
  bool _autoFetchEnabled = false;
  Timer? _periodicTimer;

  final RegExp _amountRegex = RegExp(
    r'(?:rs|inr|₹|rupees?|amount|amt)\s*:?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAutoFetchSetting();
    _setupSmsListener();
    // Check for recent SMS when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRecentSms();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check for new SMS
      if (_autoFetchEnabled && !_isFetching) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _autoFetchEnabled && !_isFetching) {
            _fetchSms();
          }
        });
      }
      // Re-setup SMS listener when app resumes
      _setupSmsListener();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background - ensure listener is still active
      _setupSmsListener();
    }
  }

  Future<void> _checkRecentSms() async {
    if (!_autoFetchEnabled) return;
    final hasPermission = await Permission.sms.isGranted;
    if (!hasPermission) return;

    // Wait a bit for app to fully initialize
    await Future.delayed(const Duration(seconds: 2));
    if (_autoFetchEnabled && !_isFetching) {
      _fetchSms();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAutoFetchSetting() async {
    final box = Hive.box(_boxName);
    setState(() {
      _autoFetchEnabled = box.get(_autoFetchKey, defaultValue: false) as bool;
    });
    if (_autoFetchEnabled) {
      _startPeriodicCheck();
    }
  }

  void _setupSmsListener() async {
    final hasPermission = await Permission.sms.isGranted;
    if (!hasPermission) return;

    // Register SMS listener with background handler
    // IMPORTANT: Always process in background handler for notifications
    // onNewMessage is for foreground/background when app is running
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        // Process immediately when app is running (foreground or background)
        _processSmsMessage(message);
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  Future<void> _processSmsMessage(SmsMessage message) async {
    final body = (message.body ?? '').trim();
    final senderRaw = (message.address ?? '').trim();
    final dateMillis = message.date ?? DateTime.now().millisecondsSinceEpoch;

    if (body.isEmpty) return;

    // Very lenient - check for amount first, then transaction context
    final amount = _parseAmount(body);
    if (amount == null || amount <= 0) return;

    // Check if it looks like a transaction (either has UPI keywords OR has amount with transaction context)
    final looksLikeTransaction =
        _looksLikeUpi(body) ||
        body.toLowerCase().contains('bank') ||
        body.toLowerCase().contains('wallet') ||
        (amount > 0 &&
            (body.toLowerCase().contains('to') ||
                body.toLowerCase().contains('from')));

    if (!looksLikeTransaction) return;

    // Show notification FIRST - before any database operations
    // This ensures user gets notified even if processing fails
    try {
      await _showNotification(
        'New UPI Transaction',
        '₹${amount.toStringAsFixed(2)} from $senderRaw',
      );
    } catch (e) {
      // Notification error - continue anyway
    }

    // Now check for duplicates and save
    final box = Hive.box(_boxName);
    if (_isDuplicate(box.values, senderRaw, amount, dateMillis)) {
      return; // Already exists, notification already shown
    }

    // Only save if auto-fetch is enabled
    final autoFetchEnabled =
        box.get(_autoFetchKey, defaultValue: false) as bool;
    if (autoFetchEnabled) {
      await box.add({
        'address': senderRaw,
        'body': body,
        'amount': amount,
        'date': dateMillis,
        'source': 'sms',
      });
    }
  }

  Future<void> _showNotification(String title, String body) async {
    // Check and request notification permission
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await Permission.notification.request();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'upi_transactions',
          'UPI Transactions',
          channelDescription: 'Notifications for new UPI transactions',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      // Notification failed, but continue processing
      print('Failed to show notification: $e');
    }
  }

  void _startPeriodicCheck() {
    _periodicTimer?.cancel();
    // Check every 2 minutes for new transactions
    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_autoFetchEnabled && !_isFetching) {
        _fetchSms();
      }
    });
  }

  void _stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void _toggleAutoFetch(bool value) async {
    setState(() {
      _autoFetchEnabled = value;
    });
    final box = Hive.box(_boxName);
    await box.put(_autoFetchKey, value);

    if (value) {
      final hasPermission = await Permission.sms.isGranted;
      if (hasPermission) {
        _startPeriodicCheck();
        _setupSmsListener();
        // Also fetch immediately when enabled to catch any missed SMS
        await Future.delayed(const Duration(milliseconds: 500));
        _fetchSms();
        setState(
          () => _statusMessage = 'Auto-fetch enabled. Monitoring SMS...',
        );
      } else {
        setState(() {
          _autoFetchEnabled = false;
          _statusMessage = 'Grant SMS permission first to enable auto-fetch.';
        });
        await box.put(_autoFetchKey, false);
      }
    } else {
      _stopPeriodicCheck();
      setState(() => _statusMessage = 'Auto-fetch disabled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(_boxName);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SMS UPI Tracker'),
          actions: [
            IconButton(
              tooltip: 'Grant SMS permission',
              onPressed: _askPermission,
              icon: const Icon(Icons.verified_user),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _askPermission,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Grant Permissions'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isFetching ? null : _fetchSms,
                      icon: _isFetching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sms_rounded),
                      label: Text(_isFetching ? 'Reading...' : 'Fetch SMS'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    title: const Text('Auto-fetch SMS'),
                    subtitle: Text(
                      _autoFetchEnabled
                          ? 'Monitoring SMS. For notifications when app is closed, disable battery optimization in Settings → Apps → SMS UPI Tracker → Battery'
                          : 'Notifications will still work, but transactions won\'t be saved automatically',
                    ),
                    value: _autoFetchEnabled,
                    onChanged: _toggleAutoFetch,
                    secondary: Icon(
                      _autoFetchEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: _autoFetchEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_statusMessage != null)
                  Text(
                    _statusMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: ValueListenableBuilder<Box>(
                    valueListenable: box.listenable(),
                    builder: (_, box, __) {
                      // Filter out non-map values (like the auto_fetch_enabled bool)
                      final txns =
                          box.values
                              .whereType<Map<dynamic, dynamic>>()
                              .where(
                                (txn) => txn.containsKey('source'),
                              ) // Only transaction entries
                              .toList()
                            ..sort((a, b) {
                              final dateA = (a['date'] as int?) ?? 0;
                              final dateB = (b['date'] as int?) ?? 0;
                              return dateB.compareTo(
                                dateA,
                              ); // Latest first (descending)
                            });
                      if (txns.isEmpty) {
                        return const Center(
                          child: Text(
                            'No transactions yet.\nGrant SMS access then tap Fetch SMS.',
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: txns.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final txn = txns[index];
                          final address = (txn['address'] ?? 'Unknown')
                              .toString();
                          final body = (txn['body'] ?? '').toString();
                          final amount =
                              (txn['amount'] as num?)?.toDouble() ?? 0;
                          final dateMillis = txn['date'] as int?;
                          return Card(
                            child: ListTile(
                              title: Text(address),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _truncate(body),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(dateMillis),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                _currencyFmt.format(amount),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _askPermission() async {
    final smsStatus = await Permission.sms.request();
    final notificationStatus = await Permission.notification.request();

    if (!mounted) return;

    String message = '';
    if (smsStatus.isGranted && notificationStatus.isGranted) {
      message = 'SMS and Notification permissions granted.';
      // Re-setup listener after permission granted
      _setupSmsListener();
    } else if (smsStatus.isGranted) {
      message = 'SMS granted. Please grant notification permission for alerts.';
    } else if (notificationStatus.isGranted) {
      message = 'Notification granted. Please grant SMS permission.';
    } else {
      message = 'Please grant SMS and Notification permissions from settings.';
    }

    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _fetchSms() async {
    final hasPermission = await Permission.sms.isGranted;
    if (!hasPermission) {
      setState(() => _statusMessage = 'Grant SMS permission first.');
      return;
    }

    setState(() {
      _isFetching = true;
      _statusMessage = 'Reading SMS inbox...';
    });

    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      final box = Hive.box(_boxName);
      int stored = 0;

      // Check SMS from last 2 weeks
      final twoWeeksAgo = DateTime.now()
          .subtract(const Duration(days: 14))
          .millisecondsSinceEpoch;

      for (final sms in messages) {
        final body = (sms.body ?? '').trim();
        if (body.isEmpty) continue;

        final senderRaw = (sms.address ?? '').trim();
        final smsDate = sms.date;

        // Handle date - use SMS date if available, otherwise use current time
        final dateMillis = smsDate ?? DateTime.now().millisecondsSinceEpoch;

        // Skip SMS older than 2 weeks (only if date is valid)
        if (smsDate != null && smsDate < twoWeeksAgo) {
          // Since messages are sorted DESC, we can break once we hit old ones
          break;
        }

        // Very lenient filtering - if it has an amount, check if it looks like a transaction
        final amount = _parseAmount(body);
        if (amount == null || amount <= 0) continue;

        // Check if it looks like a transaction (either has UPI keywords OR has amount with transaction context)
        final looksLikeTransaction =
            _looksLikeUpi(body) ||
            body.toLowerCase().contains('bank') ||
            body.toLowerCase().contains('wallet') ||
            (amount > 0 &&
                (body.toLowerCase().contains('to') ||
                    body.toLowerCase().contains('from')));

        if (!looksLikeTransaction) continue;

        // If it has amount and looks like transaction, accept it

        if (_isDuplicate(box.values, senderRaw, amount, dateMillis)) {
          continue;
        }

        await box.add({
          'address': senderRaw,
          'body': body,
          'amount': amount,
          'date': dateMillis,
          'source': 'sms',
        });
        stored++;

        // Show notification for each new transaction
        if (_autoFetchEnabled) {
          await _showNotification(
            'New UPI Transaction',
            '₹${amount.toStringAsFixed(2)} from ${senderRaw.length > 25 ? senderRaw.substring(0, 25) + "..." : senderRaw}',
          );
        }
      }

      setState(
        () => _statusMessage = stored == 0
            ? 'No new UPI SMS found. Scanned ${messages.length} SMS from last 2 weeks.'
            : 'Stored $stored new transaction(s) from ${messages.length} SMS scanned.',
      );
    } catch (err) {
      setState(() => _statusMessage = 'Failed to fetch SMS: $err');
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  bool _looksLikeUpi(String body) {
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
        (lower.contains('rs') &&
            (lower.contains('credited') || lower.contains('debited'))) ||
        (lower.contains('₹') &&
            (lower.contains('credited') || lower.contains('debited')));
  }

  double? _parseAmount(String body) {
    // Try multiple regex patterns to catch different amount formats
    final patterns = [
      // Standard: Rs/INR/₹ followed by amount
      RegExp(
        r'(?:rs|inr|₹|rupees?|amount|amt)\s*:?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      // Amount at start or end with currency
      RegExp(
        r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:rs|inr|₹|rupees?)',
        caseSensitive: false,
      ),
      // Just numbers with commas (common in UPI SMS)
      RegExp(r'\b([0-9]{1,2}(?:,[0-9]{2})*(?:\.[0-9]{1,2})?)\b'),
      // Amount with decimal
      RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:rs|inr|₹)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final numeric = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(numeric);
        if (amount != null && amount > 0 && amount < 100000000) {
          // Reasonable range
          return amount;
        }
      }
    }
    return null;
  }

  bool _isDuplicate(
    Iterable<dynamic> existing,
    String sender,
    double amount,
    int dateMillis,
  ) {
    final senderLc = sender.toLowerCase();
    return existing.whereType<Map>().any((txn) {
      final savedSender = (txn['address'] ?? '').toString().toLowerCase();
      final savedAmount = (txn['amount'] as num?)?.toDouble();
      final savedDate = txn['date'] as int? ?? 0;
      // Check if same amount, same sender, and within 5 minutes (in case of multiple notifications for same transaction)
      final timeDiff = (savedDate - dateMillis).abs();
      return savedAmount == amount &&
          savedSender == senderLc &&
          timeDiff < 300000; // 5 minutes window instead of 30 seconds
    });
  }

  String _formatDate(int? millis) {
    if (millis == null) return 'Unknown date';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
  }

  String _truncate(String value, {int max = 200}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}...';
  }
}
