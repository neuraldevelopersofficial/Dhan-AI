# Quick Start Guide - Dhan-AI

## 🚀 Running the App

### Step 1: Navigate to Project Directory
```bash
cd C:\Users\adity\Desktop\dhan_ai
```

### Step 2: Clean and Rebuild (if seeing old app)
```bash
flutter clean
flutter pub get
```

### Step 3: Run on Your Device
```bash
flutter run -d RZCXA1SNX6H
```

## ✅ What You Should See

1. **Splash Screen** (1-2 seconds)
   - Blue background
   - White wallet icon in a circle
   - "Dhan-AI" title
   - "Your money co-pilot" subtitle

2. **Onboarding Screen** (3 pages)
   - Welcome carousel
   - Can swipe or click "Next"
   - Last page shows "Get Started" button

3. **Home Dashboard**
   - Stability Score card (circular progress)
   - 7-Day Forecast chart
   - Quick Actions (Income, Expense, Vault, Copilot)
   - Active Nudges carousel
   - Goals summary
   - Recent Transactions list

## 🐛 Troubleshooting

### If you see the old Flutter demo app:
1. **Stop the app completely** - Close it from recent apps
2. **Uninstall the old app** from your device
3. Run `flutter clean`
4. Run `flutter pub get`
5. Run `flutter run` again

### If navigation isn't working:
- Make sure you're in the `dhan_ai` directory, NOT `sms_upi_tracker`
- Check that you see "Dhan-AI" in the splash screen
- Try doing a hot restart (press 'R' in the terminal)

### If screens are missing:
- Check that all files exist in `lib/presentation/screens/`:
  - splash_screen.dart ✅
  - onboarding_screen.dart ✅
  - home_screen.dart ✅
  - add_transaction_screen.dart ✅
  - nudges_screen.dart ✅

## 📱 Available Screens

- ✅ Splash → `/splash`
- ✅ Onboarding → `/onboarding`
- ✅ Home Dashboard → `/home`
- ✅ Add Transaction → Bottom sheet from home
- ✅ Nudges → `/nudges` (from drawer or home)
- 🚧 Vaults → `/vaults` (placeholder)
- 🚧 Investment → `/invest` (placeholder)
- 🚧 Copilot → `/copilot` (placeholder)
- 🚧 Profile → `/profile` (placeholder)
- 🚧 Rewards → `/rewards` (placeholder)

## 🔍 Verify You're Running the Right App

The app should show:
- App name: "Dhan-AI" (check app drawer)
- Splash screen with wallet icon
- Blue color scheme (#0B6FFF)
- "Dhan-AI" title in the app bar

If you see something different, you're running the wrong app!

## 📞 Need Help?

Check the console output when running `flutter run` - it will show any errors.

