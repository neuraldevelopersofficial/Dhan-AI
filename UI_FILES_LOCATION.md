# 📁 All UI Files Location Guide

## 🎨 Complete File Structure

```
C:\Users\adity\Desktop\dhan_ai\
└── lib/
    ├── main.dart                          ← App entry point
    │
    ├── core/                              ← Core configuration
    │   ├── constants/
    │   │   ├── app_colors.dart           ← Color definitions
    │   │   └── app_spacing.dart          ← Spacing tokens
    │   ├── router/
    │   │   └── app_router.dart           ← Navigation setup
    │   └── theme/
    │       └── app_theme.dart            ← Theme configuration
    │
    ├── data/                              ← Data layer
    │   ├── models/
    │   │   ├── transaction_model.dart
    │   │   ├── goal_model.dart
    │   │   ├── nudge_model.dart
    │   │   └── user_model.dart
    │   └── mock/
    │       └── mock_api.dart             ← Mock API service
    │
    └── presentation/                      ← 🎨 ALL UI FILES ARE HERE!
        ├── screens/                       ← 📱 SCREEN FILES
        │   ├── splash_screen.dart        ✅ Splash screen
        │   ├── onboarding_screen.dart    ✅ Onboarding (3 pages)
        │   ├── home_screen.dart          ✅ Main dashboard
        │   ├── add_transaction_screen.dart ✅ Add income/expense
        │   └── nudges_screen.dart        ✅ Nudges & recommendations
        │
        ├── widgets/                       ← 🧩 REUSABLE WIDGETS
        │   ├── stability_score_card.dart ✅ Circular progress card
        │   ├── forecast_chart.dart       ✅ 7-day forecast chart
        │   └── transaction_list_item.dart ✅ Transaction row widget
        │
        └── providers/                     ← State management
            └── dashboard_provider.dart
```

## 📱 Screen Files (Main UI)

All screen files are in: **`lib/presentation/screens/`**

1. **`splash_screen.dart`**
   - Location: `lib/presentation/screens/splash_screen.dart`
   - What it does: Shows app logo, then navigates to onboarding
   - Route: `/splash`

2. **`onboarding_screen.dart`**
   - Location: `lib/presentation/screens/onboarding_screen.dart`
   - What it does: 3-page carousel (Welcome, Forecasting, Insights)
   - Route: `/onboarding`

3. **`home_screen.dart`**
   - Location: `lib/presentation/screens/home_screen.dart`
   - What it does: Main dashboard with all widgets
   - Route: `/home`
   - Contains:
     - Stability Score
     - Forecast Chart
     - Quick Actions
     - Nudges
     - Goals
     - Transactions

4. **`add_transaction_screen.dart`**
   - Location: `lib/presentation/screens/add_transaction_screen.dart`
   - What it does: Bottom sheet for adding income/expense
   - Route: Opened as modal from home

5. **`nudges_screen.dart`**
   - Location: `lib/presentation/screens/nudges_screen.dart`
   - What it does: Full screen list of recommendations
   - Route: `/nudges`

## 🧩 Widget Files (Reusable Components)

All widget files are in: **`lib/presentation/widgets/`**

1. **`stability_score_card.dart`**
   - Location: `lib/presentation/widgets/stability_score_card.dart`
   - What it does: Circular progress card showing stability score
   - Used in: Home screen

2. **`forecast_chart.dart`**
   - Location: `lib/presentation/widgets/forecast_chart.dart`
   - What it does: Line chart showing 7-day forecast
   - Used in: Home screen

3. **`transaction_list_item.dart`**
   - Location: `lib/presentation/widgets/transaction_list_item.dart`
   - What it does: Individual transaction row widget
   - Used in: Home screen, transaction lists

## 🎨 Design System Files

1. **`app_colors.dart`**
   - Location: `lib/core/constants/app_colors.dart`
   - Contains: All color definitions (primary, secondary, etc.)

2. **`app_spacing.dart`**
   - Location: `lib/core/constants/app_spacing.dart`
   - Contains: Spacing tokens (padding, margins)

3. **`app_theme.dart`**
   - Location: `lib/core/theme/app_theme.dart`
   - Contains: Material theme configuration

## 🗺️ Navigation File

**`app_router.dart`**
- Location: `lib/core/router/app_router.dart`
- Contains: All route definitions using go_router

## 📊 Data Files

**Models:**
- `lib/data/models/transaction_model.dart`
- `lib/data/models/goal_model.dart`
- `lib/data/models/nudge_model.dart`
- `lib/data/models/user_model.dart`

**Mock API:**
- `lib/data/mock/mock_api.dart` - Simulates backend API calls

## 🔍 Quick Access Commands

### View all screen files:
```powershell
Get-ChildItem lib\presentation\screens\
```

### View all widget files:
```powershell
Get-ChildItem lib\presentation\widgets\
```

### View all UI files:
```powershell
Get-ChildItem lib\presentation\ -Recurse -Filter *.dart
```

## 📝 Summary

**All UI files are in:**
- Screens: `lib/presentation/screens/` (5 files)
- Widgets: `lib/presentation/widgets/` (3 files)
- Theme/Design: `lib/core/` (3 files)

**Total UI-related files: 11 files**

## 🎯 To Edit a Screen

1. Open the file from `lib/presentation/screens/`
2. Make your changes
3. Hot reload (press 'r' in terminal) or hot restart (press 'R')

## 🎯 To Create a New Screen

1. Create file in `lib/presentation/screens/your_screen.dart`
2. Add route in `lib/core/router/app_router.dart`
3. Import and use in navigation

