# 🔧 How to See All Screens - Fix Instructions

## The Problem
If you're seeing the old Flutter demo app or missing screens, follow these steps:

## ✅ Solution Steps

### Step 1: Stop Any Running App
- Close the app completely from your device (swipe it away)
- Or press 'q' in the terminal to quit

### Step 2: Uninstall Old App (if exists)
On your Android device:
- Go to Settings → Apps
- Find "dhan_ai" or "Dhan-AI" 
- Uninstall it completely

### Step 3: Clean and Rebuild
Open a NEW terminal/PowerShell window and run:

```powershell
cd C:\Users\adity\Desktop\dhan_ai
flutter clean
flutter pub get
flutter run -d RZCXA1SNX6H
```

### Step 4: Verify You're in the Right Project
Make sure you're in: `C:\Users\adity\Desktop\dhan_ai`
NOT in: `C:\Users\adity\Desktop\sms_upi_tracker`

## 🎯 What You Should See

When the app starts correctly:

1. **Splash Screen** (1-2 seconds)
   - Blue background (#0B6FFF)
   - White circular container with wallet icon
   - "Dhan-AI" in white text
   - "Your money co-pilot" subtitle

2. **Onboarding** (3 pages, swipe or click Next)
   - Page 1: Welcome to Dhan-AI
   - Page 2: Smart Forecasting  
   - Page 3: Actionable Insights

3. **Home Dashboard** with:
   - Stability Score card (72% with circular progress)
   - 7-Day Forecast chart (line chart)
   - Quick Actions row (Income, Expense, Vault, Copilot)
   - Active Nudges (if available)
   - Goals summary
   - Recent Transactions list

4. **Available Screens:**
   - ✅ Home Dashboard
   - ✅ Add Transaction (bottom sheet from FAB)
   - ✅ Nudges (from drawer or home)
   - 🚧 Other screens show "Coming soon" placeholders

## 🚪 How to Access All Screens

From Home Dashboard:

1. **Drawer Menu** (hamburger icon top-left):
   - Nudges
   - Goals & Vaults  
   - Investment Coach
   - AI Copilot
   - Rewards

2. **Quick Actions** on home:
   - Income button → Add Transaction sheet
   - Expense button → Add Transaction sheet
   - Vault button → Vaults screen
   - Copilot button → AI Copilot screen

3. **Floating Action Button** (bottom-right):
   - Opens Add Transaction sheet

## 🐛 Still Not Working?

If you're STILL seeing the old app:

1. **Check the app name** in your app drawer - it should say "Dhan-AI"
2. **Check terminal output** - does it say "dhan_ai" project?
3. **Force stop**: 
   ```powershell
   flutter run -d RZCXA1SNX6H --release
   ```

4. **Verify files exist**:
   ```powershell
   ls lib/presentation/screens/
   ```
   Should show: splash_screen.dart, onboarding_screen.dart, home_screen.dart, etc.

## 📱 Screens Status

- ✅ Splash Screen
- ✅ Onboarding (3 pages)
- ✅ Home Dashboard (full implementation)
- ✅ Add Transaction (bottom sheet)
- ✅ Nudges Screen (full implementation)
- 🚧 Goals & Vaults (placeholder)
- 🚧 Investment Coach (placeholder)
- 🚧 AI Copilot (placeholder)
- 🚧 Notifications (placeholder)
- 🚧 Profile (placeholder)
- 🚧 Rewards (placeholder)

The placeholder screens show "Coming soon" but are accessible via navigation!

