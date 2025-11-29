# Dhan-AI Development Guide

## Quick Start

1. **Run the app**: `flutter run`
2. **Check structure**: All core files are in place
3. **Switch personas**: Edit `MockApi.currentPersona` in `lib/data/mock/mock_api.dart`

## Architecture Overview

### State Management Pattern
```
UI Widget → Riverpod Provider → Repository → MockApi (or Real API)
```

### Current Implementation Status

#### ✅ Completed
- Project structure and dependencies
- Design system (colors, theme, spacing)
- Mock data (3 personas + instruments)
- Data models (Transaction, Goal, Nudge, User)
- Mock API service
- Navigation setup (go_router)
- Splash screen
- Onboarding flow (3-step carousel)
- Home dashboard (basic layout)

#### 🚧 To Implement

1. **Riverpod Providers** (`lib/presentation/providers/`)
   - `dashboard_provider.dart` - Dashboard state
   - `transaction_provider.dart` - Transaction list and CRUD
   - `goal_provider.dart` - Goals/vaults management
   - `nudge_provider.dart` - Nudges and recommendations

2. **Core Screens** (`lib/presentation/screens/`)
   - `add_transaction_screen.dart` - Bottom sheet for adding income/expense
   - `nudges_screen.dart` - List of actionable recommendations
   - `vaults_screen.dart` - Goals and savings vaults
   - `investment_screen.dart` - Premium investment coach
   - `copilot_screen.dart` - AI chat interface (UI only)
   - `notifications_screen.dart` - Notification history
   - `profile_screen.dart` - User profile and settings
   - `rewards_screen.dart` - Gamification and badges

3. **Reusable Widgets** (`lib/presentation/widgets/`)
   - `stability_score_card.dart` - Circular progress stability indicator
   - `forecast_chart.dart` - 7-day forecast sparkline (using fl_chart)
   - `transaction_list_item.dart` - Transaction row widget
   - `goal_card.dart` - Goal progress card
   - `nudge_card.dart` - Nudge/recommendation card
   - `quick_action_button.dart` - Quick action button widget

## Example: Adding a New Feature

### Step 1: Create the Model
```dart
// lib/data/models/new_model.dart
class NewModel {
  final String id;
  final String name;
  // ... fields
}
```

### Step 2: Add to Mock API
```dart
// lib/data/mock/mock_api.dart
static Future<List<NewModel>> getNewModels(String userId) async {
  // Load from JSON or generate mock data
}
```

### Step 3: Create Provider
```dart
// lib/presentation/providers/new_model_provider.dart
final newModelProvider = FutureProvider<List<NewModel>>((ref) {
  return MockApi.getNewModels('user_id');
});
```

### Step 4: Create Screen/Widget
```dart
// lib/presentation/screens/new_screen.dart
class NewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(newModelProvider);
    // Build UI
  }
}
```

### Step 5: Add Route
```dart
// lib/core/router/app_router.dart
GoRoute(
  path: '/new-feature',
  builder: (context, state) => const NewScreen(),
),
```

## Mock Data Structure

### User Data (`assets/mocks/[persona].json`)
```json
{
  "user": { "id", "name", "occupation", "language", "phone" },
  "stability": { "score", "safeDays", "trend" },
  "forecast": { "next7Days", "predictedEndBalance" },
  "transactions": [...],
  "goals": [...],
  "nudges": [...]
}
```

## Design Tokens

### Colors
- Primary: `AppColors.primary` (#0B6FFF)
- Success: `AppColors.success` (#16A34A)
- Warning: `AppColors.warning` (#F59E0B)
- Danger: `AppColors.danger` (#EF4444)

### Spacing
- Use `AppSpacing.xs` through `AppSpacing.xxl`

### Typography
- Access via `Theme.of(context).textTheme.*`

## Testing

### Run Tests
```bash
flutter test
```

### Widget Tests
Create tests in `test/widget_test.dart` or separate files.

## Next Priority Features

1. **Connect Dashboard to Mock Data** - Use Riverpod providers to fetch and display real mock data
2. **Add Transaction Sheet** - Implement bottom sheet with form validation
3. **Forecast Chart** - Use fl_chart to render 7-day forecast
4. **Nudges Screen** - Display and handle nudge actions
5. **Vaults** - Create, deposit, track progress

## Backend Integration Checklist

When ready to connect to real backend:
- [ ] Update `MockApi.useRealBackend = true`
- [ ] Create repository interfaces
- [ ] Implement HTTP client (dio or http package)
- [ ] Add authentication handling
- [ ] Update error handling
- [ ] Add network error states
- [ ] Update API contracts based on backend spec

