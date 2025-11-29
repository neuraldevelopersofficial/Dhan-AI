# 🎯 How to See All Screens in Dhan-AI

## ⚠️ Important: Make Sure You're Running the RIGHT App!

The app should show:
- **App Name**: "Dhan-AI" (not "sms_upi_tracker" or "Flutter Demo")
- **Splash Screen**: Blue background with wallet icon
- **Home Screen**: Shows "Stability Score", "7-Day Forecast", etc.

## 🚀 Step-by-Step Instructions

### 1. Navigate to Correct Directory
```powershell
cd C:\Users\adity\Desktop\dhan_ai
```
**Important**: Make sure you're in `dhan_ai` folder, NOT `sms_upi_tracker`!

### 2. Clean and Rebuild
```powershell
flutter clean
flutter pub get
```

### 3. Run the App
```powershell
flutter run -d RZCXA1SNX6H
```

### 4. Or Use the Script
```powershell
.\RUN_APP.ps1
```

## 📱 What You'll See (In Order)

1. **Splash Screen** (1-2 seconds)
   - Blue background
   - Wallet icon
   - "Dhan-AI" text

2. **Onboarding** (3 pages)
   - Swipe or click "Next"
   - Last page: "Get Started" button

3. **Home Dashboard** - THE MAIN SCREEN!
   - Stability Score (circular progress)
   - 7-Day Forecast (line chart)
   - Quick Actions (Income, Expense, Vault, Copilot)
   - Nudges carousel
   - Goals
   - Recent Transactions

## 🎮 How to Access ALL Screens

### From Home Dashboard:

#### Method 1: Drawer Menu (☰ icon top-left)
Tap the hamburger menu to see:
- ✅ Home
- ✅ Nudges (full screen)
- 🚧 Goals & Vaults (placeholder)
- 🚧 Investment Coach (placeholder)
- 🚧 AI Copilot (placeholder)
- 🚧 Rewards (placeholder)

#### Method 2: Quick Actions
Tap buttons on home:
- **Income** → Opens Add Transaction sheet
- **Expense** → Opens Add Transaction sheet
- **Vault** → Goes to Vaults screen
- **Copilot** → Goes to Copilot screen

#### Method 3: Floating Action Button
- Bottom-right FAB → Opens Add Transaction sheet

#### Method 4: Home Screen Sections
- Tap "See All" next to Nudges → Nudges screen
- Tap "See All" next to Goals → Vaults screen
- Tap on a transaction → Transaction details (to be implemented)

## ✅ Available Screens (Complete)

1. ✅ **Splash Screen** - Auto-navigates
2. ✅ **Onboarding** - 3 pages, then goes to home
3. ✅ **Home Dashboard** - Main screen with all widgets
4. ✅ **Add Transaction** - Bottom sheet (Income/Expense)
5. ✅ **Nudges Screen** - Full list of recommendations

## 🚧 Placeholder Screens (Show "Coming soon")

6. 🚧 Goals & Vaults
7. 🚧 Investment Coach
8. 🚧 AI Copilot
9. 🚧 Notifications
10. 🚧 Profile
11. 🚧 Rewards

## 🐛 Troubleshooting

### "I'm seeing the old Flutter counter app"
→ You're running the wrong project! Make sure you're in `dhan_ai` folder.

### "I'm seeing sms_upi_tracker app"
→ Wrong app! Navigate to `dhan_ai` folder.

### "Screens are blank/not loading"
→ Run `flutter clean` and rebuild.

### "Navigation not working"
→ Make sure you've completed onboarding first.

### "Can't see Nudges/Goals"
→ Pull down on home screen to refresh data.

## 🎨 Verify You're in the Right App

Look for these indicators:
- ✅ App name in drawer: "Dhan-AI"
- ✅ Blue color scheme (#0B6FFF)
- ✅ Wallet icon in splash
- ✅ Stability Score on home
- ✅ Forecast chart on home

If you DON'T see these, you're running the wrong app!

## 📞 Quick Test

After running the app:
1. Wait for splash → Onboarding
2. Complete onboarding (or skip)
3. You should see **Home Dashboard** with:
   - Circular stability score
   - Line chart for forecast
   - Transaction list
   - Quick action buttons

If you see this, everything is working! 🎉

## 🔄 Skip Onboarding (For Testing)

To skip onboarding and go straight to home, edit:
`lib/presentation/screens/splash_screen.dart`

Change line 25:
```dart
context.go('/home');  // Instead of '/onboarding'
```

