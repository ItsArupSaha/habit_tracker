# Habit Tracker App

A Flutter application for tracking daily habits, managing progress, and staying motivated with inspirational quotes.

## Features

### 🔐 User Authentication
- User registration with email/password
- Login/logout functionality
- Profile management with editable fields
- Session persistence using SharedPreferences

### 📊 Habit Management
- Create, edit, and delete habits
- Categorize habits (Health, Study, Fitness, Productivity, Mental Health, Others)
- Set frequency (Daily/Weekly)
- Add notes and start dates
- Track completion status

### 🔥 Streak Tracking
- Automatic streak calculation
- Visual streak indicators
- Reset streaks on missed days/weeks

### 💬 Motivational Quotes
- Fetch quotes from Quotable API
- Save favorite quotes
- Copy quotes to clipboard
- Fallback quotes when API is unavailable

### 🎨 Theme Support
- Light and Dark mode
- Theme persistence
- Material 3 design

### ☁️ Data Sync
- Firebase Authentication
- Firestore database
- Real-time updates
- Offline support with local caching

## Tech Stack

- **Frontend**: Flutter
- **State Management**: Provider
- **Backend**: Firebase (Auth + Firestore)
- **Local Storage**: SharedPreferences
- **HTTP Client**: http package
- **Charts**: fl_chart (for future progress visualization)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── habit.dart           # Habit model
│   └── quote.dart           # Quote model
├── services/                 # Business logic
│   ├── auth_service.dart    # Authentication
│   ├── habit_service.dart   # Habit CRUD operations
│   ├── quotes_service.dart  # Quotes API integration
│   └── theme_service.dart   # Theme management
├── screens/                  # UI screens
│   ├── splash_screen.dart   # Loading screen
│   ├── auth/                # Authentication screens
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── home/                # Main app screens
│       ├── home_screen.dart # Main navigation
│       └── tabs/            # Tab screens
│           ├── habits_tab.dart
│           ├── quotes_tab.dart
│           └── profile_tab.dart
└── widgets/                  # Reusable components
    ├── custom_button.dart
    ├── custom_text_field.dart
    ├── habit_card.dart
    ├── quote_card.dart
    └── add_habit_fab.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.1.0 or higher)
- Dart SDK
- Firebase project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd habit_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate platform directories

4. **Run the app**
   ```bash
   flutter run
   ```

## Firebase Configuration

### Authentication Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Users can access their own habits
      match /habits/{habitId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Users can access their own favorite quotes
      match /favorites/quotes/{quoteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Usage

1. **Registration**: Create an account with email and password
2. **Login**: Sign in to access your habits
3. **Create Habits**: Use the + button to add new habits
4. **Track Progress**: Mark habits as complete daily/weekly
5. **View Streaks**: See your current streak for each habit
6. **Get Inspired**: Browse motivational quotes and save favorites
7. **Customize**: Switch between light and dark themes

## Future Enhancements

- [ ] Progress visualization with charts
- [ ] Habit statistics and analytics
- [ ] Reminder notifications
- [ ] Social features (share progress)
- [ ] Export data functionality
- [ ] Multiple habit templates
- [ ] Achievement badges

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository or contact the development team.
