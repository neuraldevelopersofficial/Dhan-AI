# Dhan-AI - Personal Financial Co-pilot

Dhan-AI is an intelligent financial co-pilot designed for gig workers, freelancers, and low-salaried individuals in India who face irregular or unpredictable income streams. Millions of people working in delivery, ride-hailing, and contract-based jobs struggle with conventional financial tools that assume steady salaries.
Dhan-AI continuously learns from a user’s real-time income patterns, spending habits, and upcoming financial obligations. It uses this data to forecast cash-flow gaps and deliver personalized, proactive financial guidance.
By turning uncertain earnings into structured, goal-driven financial journeys, Dhan-AI empowers individuals to avoid cash crunches, plan for emergencies, and build long-term financial resilience — all through intuitive, human-like AI interactions.

## Core Features

Onboarding & Personalization – quick setup, goals, language, persona

Income & Expense Tracking – manual + AI-categorized transactions

Dashboard – wallet balance, financial stability score, spending limits, charts

AI Copilot / Chat – personalized advice, proactive nudges, “what-if” simulations, voice option

Smart Nudges & Alerts – shortfall warnings, bill reminders, goal progress

Goals & Micro-Savings – emergency fund, purchase goals, Safety Vault

Investment Coach (Premium) – simulated investments, real stock tracking, risk & growth visualization

Rewards & Gamification – streaks, badges, points for good financial habits

Settings & Security – profile, notifications, backup, data privacy

Tech & Monetization

Tech: Flutter + Firebase Realtime DB + LLM API + FCM notifications

Free Tier: Dashboard + basic nudges + goal tracking

Premium Tier: AI voice coach, advanced forecasts, investment coach, priority support

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


## License

Private project - not for distribution.
