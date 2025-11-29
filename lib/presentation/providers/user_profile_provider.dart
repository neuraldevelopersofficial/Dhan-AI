import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/database_service.dart';
import '../../data/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _currentUserPhoneKey = 'current_user_phone';

// Provider for current logged-in user phone number
final currentUserPhoneProvider = StateProvider<String?>((ref) => null);

// Provider for current user profile
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final phone = ref.watch(currentUserPhoneProvider);
  if (phone == null) return null;
  
  final databaseService = DatabaseService();
  return await databaseService.getUserByPhone(phone);
});

// Helper function to save current user phone
Future<void> saveCurrentUserPhone(String phone) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_currentUserPhoneKey, phone);
}

// Helper function to get current user phone
Future<String?> getCurrentUserPhone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_currentUserPhoneKey);
}

// Helper function to clear current user
Future<void> clearCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_currentUserPhoneKey);
}

