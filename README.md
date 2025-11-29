# Dhan-AI - Personal Financial Co-pilot

A Flutter mobile app for users with irregular incomes, providing financial forecasting, nudges, and savings management.

## Project Status

This is a frontend prototype with mock data and stubbed APIs. The app demonstrates the full user experience with local mock data that simulates backend responses.

## Features

- ✅ **Splash & Onboarding** - 3-step carousel onboarding flow
- ✅ **Home Dashboard** - Stability score, quick actions, recent transactions
- 🚧 **Add Transaction** - Manual income/expense entry (in progress)
- 🚧 **Nudges & Recommendations** - Actionable financial insights (in progress)
- 🚧 **Goals & Vaults** - Savings goals and progress tracking (in progress)
- 🚧 **Investment Coach** - Premium investment recommendations (in progress)
- 🚧 **AI Copilot Chat** - Conversational financial assistant (in progress)
- 🚧 **Notifications** - Alert history and management (in progress)
- 🚧 **Profile & Settings** - User preferences and subscription (in progress)
- 🚧 **Rewards & Gamification** - Streaks and badges (in progress)

## Project Structure

```
lib/
├── core/
│   ├── constants/        # App colors, spacing, constants
│   ├── theme/            # Theme configuration
│   └── router/           # Navigation setup (go_router)
├── data/
│   ├── models/           # Data models (Transaction, Goal, Nudge, User)
│   ├── mock/             # Mock API service
│   └── repositories/     # Repository pattern (for future backend integration)
└── presentation/
    ├── screens/          # All screen widgets
    ├── widgets/          # Reusable UI components
    └── providers/        # Riverpod state providers
```

## Getting Started

### Prerequisites

- Flutter SDK (3.8.1+)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Mock Data

The app uses local JSON files in `assets/mocks/`:
- `ravi.json` - Delivery driver persona
- `meena.json` - Vendor persona
- `arjun.json` - Student persona
- `instruments.json` - Investment instruments data

To switch personas, modify `MockApi.currentPersona` in `lib/data/mock/mock_api.dart`.

### Feature Flag

Toggle between mock and real backend:
```dart
// In lib/data/mock/mock_api.dart
static const bool useRealBackend = false; // Set to true when backend is ready
```

## Design System

- **Primary Color**: #0B6FFF (Dhan Blue)
- **Typography**: Inter font family
- **Spacing**: 4px base unit (xs, sm, md, lg, xl, xxl)
- **Radius**: 8px (small), 12px (medium), 16px (large)

## State Management

Using **Riverpod** for state management. Providers will be added in `lib/presentation/providers/` as features are built.

## Navigation

Using **go_router** for declarative navigation. Routes are defined in `lib/core/router/app_router.dart`.

## Adding New Screens

1. Create screen widget in `lib/presentation/screens/`
2. Add route in `lib/core/router/app_router.dart`
3. Create provider (if needed) in `lib/presentation/providers/`
4. Update navigation calls throughout the app

## Next Steps

1. Implement remaining screens (see Features list above)
2. Connect Riverpod providers for state management
3. Add more mock data scenarios
4. Implement analytics events (currently console logging)
5. Add widget tests and integration tests
6. Prepare API contracts for backend team

## Backend Integration

When ready to connect to real backend:
1. Set `useRealBackend = true` in `MockApi`
2. Create repository implementations in `lib/data/repositories/`
3. Update providers to use repositories instead of MockApi
4. Add authentication handling
5. Update API contracts (see `assets/mocks/` for expected JSON structure)

## License

Private project - not for distribution.
