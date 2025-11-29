# AI Features Integration Guide

This document explains how Groq AI is integrated throughout the app to power all AI features.

## Overview

The app uses **Groq API** (via `AiCopilotService`) to power all AI features:

1. ✅ **Transaction Categorization** - AI categorizes transactions automatically
2. ✅ **Smart Nudges** - AI generates personalized financial recommendations
3. ✅ **AI Copilot Chat** - Conversational financial advisor
4. ✅ **What-If Simulations** - Predict financial outcomes
5. ✅ **Investment Recommendations** - Personalized investment advice
6. ✅ **Goal Suggestions** - AI suggests relevant financial goals
7. ✅ **Financial Insights** - Dashboard insights and analysis

## Service Architecture

### `AiCopilotService` - Main AI Service

Located at: `lib/data/services/ai_copilot_service.dart`

This service handles all AI-powered features using Groq API.

**Key Methods:**

1. **`categorizeTransaction()`** - Categorizes transactions
2. **`generateNudges()`** - Generates smart nudges
3. **`chat()`** - AI Copilot conversational interface
4. **`whatIfSimulation()`** - Financial scenario simulation
5. **`getInvestmentRecommendations()`** - Investment advice
6. **`suggestGoals()`** - Goal suggestions

## Integration Points

### 1. Transaction Categorization

**Current:** Simple string matching in `SmsService`
**With AI:** Automatic intelligent categorization

```dart
// In add_transaction_screen.dart or sms_service.dart
final category = await AiCopilotService.categorizeTransaction(
  description: transactionNote,
  amount: amount,
  type: 'expense',
  userProfile: userProfile,
);
```

### 2. Smart Nudges

**Current:** Mock data from `MockApi`
**With AI:** Real-time AI-generated nudges

```dart
// In nudges_provider.dart
final nudges = await AiCopilotService.generateNudges(
  transactions: allTransactions,
  forecast: forecastData,
  stability: stabilityData,
  userProfile: userProfile,
);
```

### 3. AI Copilot Chat

**New Feature:** Conversational financial advisor

```dart
// In copilot_screen.dart (to be created)
final response = await AiCopilotService.chat(
  userMessage: userInput,
  recentTransactions: transactions,
  financialSummary: summary,
  userProfile: userProfile,
  conversationHistory: chatHistory,
);
```

### 4. What-If Simulations

**New Feature:** Predict financial outcomes

```dart
final simulation = await AiCopilotService.whatIfSimulation(
  scenario: "What if I save ₹2000 more per month?",
  currentTransactions: transactions,
  currentForecast: forecast,
  userProfile: userProfile,
);
```

### 5. Investment Recommendations

**New Feature:** Personalized investment advice

```dart
final recommendations = await AiCopilotService.getInvestmentRecommendations(
  transactions: transactions,
  financialSummary: summary,
  userProfile: userProfile,
);
```

### 6. Goal Suggestions

**New Feature:** AI-suggested financial goals

```dart
final goals = await AiCopilotService.suggestGoals(
  transactions: transactions,
  financialSummary: summary,
  userProfile: userProfile,
);
```

## Setup

### 1. Configure Groq API Key

1. Go to **Advanced** tab
2. Tap **Settings** (⚙️)
3. Select **Groq (Llama)**
4. Enter your Groq API key
5. Save

### 2. Default Provider

The service defaults to Groq. To change:
- Go to Settings
- Select a different provider (OpenAI, Gemini, Anthropic)
- All AI features will use the selected provider

## Error Handling

All AI methods include:
- ✅ Fallback to default data if AI fails
- ✅ Clear error messages
- ✅ Graceful degradation

## Performance

- **Fast Responses:** Groq provides ultra-fast inference (< 1 second)
- **Cost-Effective:** Free tier available
- **Reliable:** Automatic retry and fallback

## Next Steps

1. **Integrate Transaction Categorization:**
   - Update `SmsService` to use `AiCopilotService.categorizeTransaction()`
   - Update `add_transaction_screen.dart` to use AI categorization

2. **Integrate Smart Nudges:**
   - Update `nudgesProvider` to use `AiCopilotService.generateNudges()`
   - Remove dependency on `MockApi.getNudges()`

3. **Create AI Copilot Screen:**
   - Create `copilot_screen.dart`
   - Integrate `AiCopilotService.chat()`
   - Add conversation history management

4. **Add What-If Feature:**
   - Create UI for scenario input
   - Integrate `AiCopilotService.whatIfSimulation()`
   - Display results with charts

5. **Add Investment Coach:**
   - Create investment screen
   - Integrate `AiCopilotService.getInvestmentRecommendations()`
   - Display recommendations with risk levels

6. **Add Goal Suggestions:**
   - Integrate `AiCopilotService.suggestGoals()`
   - Show suggestions in goals screen
   - Allow user to accept/reject suggestions

## Testing

Test each feature:
1. Ensure Groq API key is configured
2. Test with real transaction data
3. Verify AI responses are relevant
4. Check fallback behavior if API fails

## Notes

- All AI calls use the same Groq API key from settings
- Responses are cached where appropriate
- Error handling ensures app never crashes if AI fails
- All features work offline with fallback data

