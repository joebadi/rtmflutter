# RTM App

A modern Flutter-based dating and social connection application with real-time messaging, profile management, and premium features.

## Features

- 🔐 **Authentication System**
  - User registration with phone verification
  - OTP-based login
  - Profile setup and image upload
  - Video verification

- 👤 **Profile Management**
  - Personal information editing
  - Match preferences customization
  - Profile completion tracking
  - Image gallery management

- 💬 **Social Features**
  - Real-time messaging
  - User discovery and exploration
  - Likes and matches
  - Live dates scheduling

- 💎 **Premium Features**
  - Subscription management
  - Wallet integration
  - Enhanced profile visibility

## Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Backend Integration**: REST API
- **Platforms**: iOS, Android, Web, Windows, macOS, Linux

## Project Structure

```
rtm_app/
├── mobile/                 # Flutter application
│   ├── lib/
│   │   ├── config/        # App configuration
│   │   ├── providers/     # State management
│   │   ├── screens/       # UI screens
│   │   └── services/      # API services
│   ├── android/           # Android platform files
│   ├── ios/               # iOS platform files
│   └── web/               # Web platform files
└── docs/                  # Documentation
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio

### Installation

1. Clone the repository:

```bash
git clone <your-repo-url>
cd rtm_app
```

2. Navigate to the mobile directory:

```bash
cd mobile
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Configuration

Update the API configuration in `mobile/lib/config/api_config.dart` to point to your backend server.

## Development

- See `FLUTTER_INTEGRATION.md` for backend integration details
- See `FLUTTER_QUICKSTART.md` for quick start guide
- See `RTM_DEVELOPMENT_TASKS.md` for development roadmap

## Contributing

This is a private project. For collaboration inquiries, contact the development team.

## License

Proprietary - All rights reserved

## Contact

- Email: internet@e-clicks.net
- Developer: Joeey

---

Built with ❤️ using Flutter
