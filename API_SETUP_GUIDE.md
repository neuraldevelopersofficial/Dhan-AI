# API Setup Guide

This guide explains how to configure API keys to replace the n8n webhook with direct AI insights.

## Quick Start

1. **Open the Advanced tab** in the app
2. **Tap the Settings icon** (⚙️) in the top-right corner
3. **Select your API provider** (OpenAI, Anthropic, or Custom)
4. **Enter your API key**
5. **Save settings**
6. **Tap the cloud upload icon** (☁️) to get AI insights!

## Supported API Providers

### 1. OpenAI (GPT-4)

**Best for:** General financial insights and recommendations

**Setup:**
1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (starts with `sk-`)
6. Paste it in the app settings

**Cost:** ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
**Model Used:** GPT-4o-mini (cost-effective)

### 2. Anthropic (Claude)

**Best for:** Detailed financial analysis and recommendations

**Setup:**
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (starts with `sk-ant-`)
6. Paste it in the app settings

**Cost:** ~$0.25 per 1M input tokens, ~$1.25 per 1M output tokens
**Model Used:** Claude 3 Haiku (cost-effective)

### 3. Custom API

**Best for:** Using your own backend or API

**Setup:**
1. Enter your API endpoint URL (e.g., `https://api.example.com/insights`)
2. Enter your API key (if required)
3. Your API should accept POST requests with the financial data payload
4. Your API should return JSON with an `insights` field

**Expected Request Format:**
```json
{
  "user_id": "phone_number",
  "timestamp": "ISO8601 timestamp",
  "income": [...],
  "expenses": [...],
  "metadata": {...},
  "user_profile": {...}
}
```

**Expected Response Format:**
```json
{
  "insights": "AI-generated insights",
  "recommendations": ["..."],
  "warnings": ["..."],
  "next_steps": ["..."]
}
```

## How It Works

1. **Data Collection**: The app collects all your financial data:
   - Income transactions (from SMS + manual)
   - Expense transactions (from SMS + manual)
   - Forecast calculations
   - Stability score
   - User profile information

2. **Data Formatting**: The data is formatted into a structured JSON payload

3. **AI Processing**: The payload is sent to your selected API provider

4. **Insights Generation**: The AI analyzes your data and generates:
   - Key insights about spending patterns
   - Recommendations for better financial management
   - Warnings (if any)
   - Actionable next steps

5. **Display**: Insights are shown in the app after successful processing

## Security Notes

- **API keys are stored locally** on your device using `SharedPreferences`
- **Keys are encrypted** by the system
- **Keys never leave your device** (except when making API calls)
- **You can clear keys** anytime by deleting them from settings

## Troubleshooting

### "API key not configured" Error

**Solution:** Go to Settings and add your API key for the selected provider.

### "API error: 401" Error

**Solution:** Your API key is invalid. Check:
- Key is copied correctly (no extra spaces)
- Key hasn't expired
- Key has proper permissions

### "API error: 429" Error

**Solution:** You've hit the rate limit. Wait a few minutes and try again.

### "API error: 500" Error

**Solution:** The API service is having issues. Try again later.

### No Insights Returned

**Solution:** 
- Check if you have transaction data
- Try a different API provider
- Check the console logs for detailed errors

## Cost Estimation

For a typical user with 50-100 transactions:

- **OpenAI**: ~$0.01-0.02 per request
- **Anthropic**: ~$0.02-0.03 per request
- **Custom API**: Depends on your backend

**Tip:** Use GPT-4o-mini or Claude Haiku for cost-effective insights.

## Switching Between Providers

You can switch providers anytime:
1. Go to Settings
2. Select a different provider
3. Make sure the API key is configured
4. Save settings

The app will use the selected provider for all future requests.

## Disabling AI Insights

If you want to use the webhook instead:
- The webhook service will automatically fallback if AI fails
- Or you can modify the code to disable AI insights

## Need Help?

- Check the console logs for detailed error messages
- Verify your API key is correct
- Test your API key manually (curl/Postman)
- Make sure you have internet connectivity

