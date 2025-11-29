# Webhook Troubleshooting Guide

## Common Errors

### 404 Error (Webhook Not Found)

**Error Message:** `Webhook request failed with status: 404`

**Possible Causes:**
1. The webhook URL is incorrect or doesn't exist
2. The n8n workflow is not active
3. The webhook path has changed

**Solutions:**

1. **Verify the webhook URL:**
   - Check `lib/data/services/webhook_service.dart` line 10
   - Current URL: `https://neuraldev.app.n8n.cloud/webhook-test/9cb411f8-508a-45f5-b6a3-4581d503d5d5`
   - Make sure the URL is correct in your n8n instance

2. **Test the webhook manually:**
   ```bash
   curl -X POST https://neuraldev.app.n8n.cloud/webhook-test/9cb411f8-508a-45f5-b6a3-4581d503d5d5 \
     -H "Content-Type: application/json" \
     -d '{"test": "data"}'
   ```

3. **Check n8n workflow:**
   - Ensure the workflow is active
   - Verify the webhook node is configured correctly
   - Check if the webhook path matches exactly

4. **Update the webhook URL:**
   Edit `lib/data/services/webhook_service.dart`:
   ```dart
   static const String webhookUrl = 'YOUR_NEW_WEBHOOK_URL_HERE';
   ```

### Network Errors

**Error Message:** `Error sending data to webhook: SocketException` or `TimeoutException`

**Solutions:**
- Check internet connection
- Verify the webhook server is accessible
- Check firewall/network restrictions

### No User Logged In

**Error Message:** `No user logged in`

**Solution:**
- Make sure you're logged in before sending data
- The app needs a user profile to send data

## Debugging

### Enable Debug Logging

The webhook service now prints debug information:
- Webhook URL being called
- Payload being sent
- Response status and body

Check your console/logs for:
```
Sending to webhook: https://...
Payload: {...}
Response status: 200
Response body: {...}
```

### Check Payload Format

The webhook expects this format:
```json
{
  "user_id": "phone_number",
  "timestamp": "ISO8601 timestamp",
  "income": [...],
  "expenses": [...],
  "metadata": {...}
}
```

### Test with Sample Data

You can test the webhook with a simple curl command:
```bash
curl -X POST YOUR_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test123",
    "timestamp": "2025-01-15T10:30:00.000Z",
    "income": [{"amount": 100, "source": "Test", "date": "2025-01-15", "type": "UPI"}],
    "expenses": [{"amount": 50, "category": "Food", "date": "2025-01-15", "payment_method": "UPI", "description": "Test"}],
    "metadata": {
      "previous_forecast": {"week": {"predicted_expenses": 100, "actual_expenses": 50}},
      "risk_profile": "moderate",
      "monthly_goal": {"emergency_fund": 0, "savings": 0}
    }
  }'
```

## Updating Webhook URL

To change the webhook URL:

1. Open `lib/data/services/webhook_service.dart`
2. Find line 10:
   ```dart
   static const String webhookUrl = 'YOUR_URL_HERE';
   ```
3. Replace with your new webhook URL
4. Save and rebuild the app

## Getting Help

If you continue to have issues:
1. Check the console logs for detailed error messages
2. Verify the webhook URL is correct
3. Test the webhook manually with curl
4. Check n8n workflow status
5. Verify network connectivity


