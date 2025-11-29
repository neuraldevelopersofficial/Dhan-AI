# Webhook Usage Guide

## How to Send Data to Webhook

### Method 1: Using the UI (Easiest)
1. Open the app and login
2. Navigate to the **"Advanced"** tab (bottom navigation bar)
3. Click the **cloud upload icon** (☁️) in the top-right corner of the app bar
4. Wait for the loading indicator
5. You'll see a success message with AI insights (if returned from webhook)

### Method 2: Programmatically (From Code)

#### Option A: Using the Provider (Recommended)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/webhook_provider.dart';

// In a ConsumerWidget or ConsumerStatefulWidget
final result = await ref.read(sendCurrentUserDataProvider.future);
print('Webhook response: $result');
```

#### Option B: Direct Service Call
```dart
import 'data/services/webhook_service.dart';

// Send current user's data (automatically gets phone from SharedPreferences)
final result = await WebhookService.sendDataToWebhook();

// Or send specific user's data
final result = await WebhookService.sendDataToWebhook(userId: '1234567890');
```

#### Option C: From Any Screen
```dart
// In any widget with access to WidgetRef
Future<void> sendData() async {
  try {
    final result = await ref.read(sendCurrentUserDataProvider.future);
    // Handle success
    print('Data sent! Insights: ${result?['insights']}');
  } catch (e) {
    // Handle error
    print('Error: $e');
  }
}
```

### What Data Gets Sent?

The webhook receives a JSON payload with:

```json
{
  "user_id": "phone_number",
  "timestamp": "2025-01-15T10:30:00.000Z",
  "income": [
    {
      "amount": 500,
      "source": "Swiggy Delivery",
      "date": "2025-01-15",
      "type": "UPI"
    }
  ],
  "expenses": [
    {
      "amount": 120,
      "category": "Food",
      "date": "2025-01-15",
      "payment_method": "UPI",
      "description": "Lunch at cafe"
    }
  ],
  "metadata": {
    "previous_forecast": {
      "week": {
        "predicted_expenses": 3000.0,
        "actual_expenses": 2800.0
      }
    },
    "risk_profile": "moderate",
    "monthly_goal": {
      "emergency_fund": 0,
      "savings": 0
    }
  }
}
```

### Data Sources

- **Income Transactions**: All income transactions from SMS + manually added
- **Expense Transactions**: All expense transactions from SMS + manually added
- **Forecast Data**: Calculated from transaction history
- **Stability Score**: Risk profile (low/moderate/high)
- **User Profile**: Phone number as user_id

### Webhook URL

Current webhook URL: `https://neuraldev.app.n8n.cloud/webhook-test/9cb411f8-508a-45f5-b6a3-4581d503d5d5`

To change the URL, edit `lib/data/services/webhook_service.dart`:
```dart
static const String webhookUrl = 'YOUR_NEW_URL_HERE';
```

### Error Handling

The service throws exceptions if:
- No user is logged in
- Network request fails
- Webhook returns non-200 status code

Always wrap calls in try-catch:
```dart
try {
  final result = await WebhookService.sendDataToWebhook();
  // Success
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

### Response Format

If successful, the webhook should return:
```json
{
  "insights": "AI-generated insights about user's financial data"
}
```

The response is parsed and can be accessed via `result['insights']`.

