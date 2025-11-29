import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/nudge_model.dart';

class MockApi {
  static const bool useRealBackend = false; // Feature flag
  static String currentPersona = 'ravi'; // Default persona
  
  // In-memory storage for dynamically added transactions
  static final List<Transaction> _addedTransactions = [];

  // Simulate network latency
  static Future<T> _simulateDelay<T>(T data, {int minMs = 200, int maxMs = 800}) async {
    final delay = minMs + (maxMs - minMs) * (DateTime.now().millisecond % 100) / 100;
    await Future.delayed(Duration(milliseconds: delay.toInt()));
    return data;
  }

  static Future<Map<String, dynamic>> _loadPersonaData(String persona) async {
    final jsonString = await rootBundle.loadString('assets/mocks/$persona.json');
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  // User methods
  static Future<User> getUser(String userId) async {
    final data = await _loadPersonaData(currentPersona);
    final userData = data['user'] as Map<String, dynamic>;
    return _simulateDelay(User.fromJson(userData));
  }

  // Dashboard data
  static Future<Map<String, dynamic>> getDashboard(String userId) async {
    final data = await _loadPersonaData(currentPersona);
    return _simulateDelay({
      'stability': data['stability'] as Map<String, dynamic>,
      'forecast': data['forecast'] as Map<String, dynamic>,
      'transactions': (data['transactions'] as List)
          .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList(),
      'goals': (data['goals'] as List)
          .map((g) => Goal.fromJson(g as Map<String, dynamic>))
          .toList(),
    });
  }

  // Transactions
  static Future<List<Transaction>> getTransactions(String userId) async {
    final data = await _loadPersonaData(currentPersona);
    final baseTransactions = (data['transactions'] as List)
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();
    
    // Combine base transactions with added ones, sort by date (newest first)
    final allTransactions = [...baseTransactions, ..._addedTransactions];
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    
    return _simulateDelay(allTransactions);
  }

  static Future<Transaction> addTransaction(String userId, Transaction transaction) async {
    // Add to in-memory list
    _addedTransactions.add(transaction);
    return _simulateDelay(transaction);
  }

  // Goals/Vaults
  static Future<List<Goal>> getGoals(String userId) async {
    final data = await _loadPersonaData(currentPersona);
    final goals = (data['goals'] as List)
        .map((g) => Goal.fromJson(g as Map<String, dynamic>))
        .toList();
    return _simulateDelay(goals);
  }

  // Nudges
  static Future<List<Nudge>> getNudges(String userId) async {
    final data = await _loadPersonaData(currentPersona);
    final nudges = (data['nudges'] as List)
        .map((n) => Nudge.fromJson(n as Map<String, dynamic>))
        .toList();
    return _simulateDelay(nudges);
  }

  // Investment instruments
  static Future<Map<String, dynamic>> getInstruments() async {
    final jsonString = await rootBundle.loadString('assets/mocks/instruments.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return _simulateDelay(data);
  }

  // Subscription
  static Future<bool> subscribe(String userId, String plan) async {
    // Mock subscription - always succeeds
    return _simulateDelay(true);
  }
}

