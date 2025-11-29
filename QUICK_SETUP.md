# Quick Setup Guide - API Keys

## Your Provided API Keys

You've provided the following API keys:

### Gemini Keys:
1. `YOUR_GEMINI_API_KEY_1`
2. `YOUR_GEMINI_API_KEY_2`

### Groq Keys:
1. `YOUR_GROQ_API_KEY_1`
2. `YOUR_GROQ_API_KEY_2`

## How to Add Keys to the App

### Method 1: Using the Settings Screen (Recommended)

1. **Open the app**
2. **Go to Advanced tab** (bottom navigation)
3. **Tap the Settings icon** (⚙️) in the top-right
4. **Select your preferred provider:**
   - **Gemini**: Fast, free tier available
   - **Groq**: Ultra-fast inference with Llama 3.1
5. **Paste your API key** in the corresponding field
6. **Tap "Save Settings"**

### Method 2: Quick Setup (For Development)

If you want to quickly set up the keys programmatically, you can add this to `main.dart`:

```dart
import 'data/services/ai_insights_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Quick setup with your keys (optional)
  await AiInsightsService.setupDefaultKeys(
    geminiKey1: 'YOUR_GEMINI_API_KEY_1',
    geminiKey2: 'YOUR_GEMINI_API_KEY_2',
    groqKey1: 'YOUR_GROQ_API_KEY_1',
    groqKey2: 'YOUR_GROQ_API_KEY_2',
  );
  
  // ... rest of your initialization
}
```

**Note:** For production, it's better to let users enter keys manually for security.

## Recommended Provider

**Groq** is recommended because:
- ✅ Ultra-fast inference (often < 1 second)
- ✅ Free tier available
- ✅ Uses powerful Llama 3.1 70B model
- ✅ Great for real-time financial insights

**Gemini** is also great because:
- ✅ Free tier with generous limits
- ✅ Fast responses
- ✅ Good for cost-effective insights

## Testing

After adding keys:

1. Go to **Advanced tab**
2. Tap the **cloud upload icon** (☁️)
3. Wait for AI insights
4. You should see financial insights based on your transaction data

## Troubleshooting

- **"API key not configured"**: Make sure you selected the provider and entered the key
- **"API error: 401"**: Check if the key is correct (no extra spaces)
- **"API error: 429"**: Rate limit hit, wait a few minutes
- **Slow responses**: Try Groq for faster responses

## Security Note

⚠️ **Never commit API keys to version control!**
- Keys are stored locally on your device
- They're encrypted by the system
- Remove keys from code before pushing to Git

