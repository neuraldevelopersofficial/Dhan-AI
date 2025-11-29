import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/webhook_service.dart';
import 'user_profile_provider.dart';

// Provider to send data and get AI insights
final webhookProvider = FutureProvider.family<Map<String, dynamic>?, String?>((
  ref,
  userId,
) async {
  try {
    return await WebhookService.sendDataToWebhook(userId: userId);
  } catch (e) {
    // Re-throw to preserve original error message
    rethrow;
  }
});

// Provider to send current user's data and get AI insights
final sendCurrentUserDataProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final phone = ref.watch(currentUserPhoneProvider);
  if (phone == null) {
    throw Exception('No user logged in');
  }

  try {
    // Uses AI service directly (Groq, Gemini, OpenAI, etc.)
    return await WebhookService.sendDataToWebhook(userId: phone);
  } catch (e) {
    // Re-throw to preserve the original error message from AI service
    rethrow;
  }
});
