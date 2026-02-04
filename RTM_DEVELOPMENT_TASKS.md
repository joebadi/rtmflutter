# Ready to Marry (RTM) Flutter Development Tasks

## Project Overview
This document outlines the comprehensive development tasks for converting the demo_orange Flutter app into the Ready to Marry (RTM) dating application. The project involves repurposing an existing dating app codebase to match RTM specifications with MongoDB backend integration.

## Project Structure
```
/mnt/c/Users/Joeey/Documents/rtm/
├── apps/
│   ├── demo_orange/           # Original source app
│   └── rtm_flutter/           # New RTM app (copied from demo_orange)
├── flutter_dating_app_spec.md # RTM specification document
└── RTM_DEVELOPMENT_TASKS.md   # This file
```

## Development Phases

### Phase 1: Project Setup & Backend Integration (Week 1)

#### 1.1 Firebase to MongoDB Migration
**Priority: HIGH**
- [ ] **Remove Firebase Dependencies**
  - Remove from pubspec.yaml: firebase_core, firebase_auth, cloud_firestore, firebase_messaging
  - Clean up Firebase initialization code in main.dart
  - Remove google-services.json (Android) and GoogleService-Info.plist (iOS)
  - Remove Firebase configuration files

- [ ] **Add MongoDB/REST API Dependencies**
  ```yaml
  dependencies:
    dio: ^5.3.2                    # HTTP client
    provider: ^6.0.5               # State management (replace GetX)
    shared_preferences: ^2.2.2     # Local storage
    hive: ^2.2.3                   # Local database
    hive_flutter: ^1.1.0           # Hive Flutter integration
    socket_io_client: ^2.0.3+1     # Real-time communication
    go_router: ^12.0.0             # Navigation (replace GetX)
    flutter_secure_storage: ^9.0.0 # Secure token storage
  ```

#### 1.2 Authentication System Overhaul
**Priority: HIGH**
- [ ] **Create JWT Authentication Service**
  - Implement JWTAuthService class
  - Add token storage/retrieval methods
  - Create auto-refresh token mechanism
  - Implement logout functionality

- [ ] **Update Login/Registration Screens**
  - Replace Firebase auth calls with HTTP requests
  - Update registration form to match RTM spec
  - Implement OTP verification via SMS (backend integration)
  - Add phone number validation

- [ ] **Create API Service Layer**
  ```dart
  lib/services/
  ├── api_service.dart           # Base HTTP service
  ├── auth_service.dart          # Authentication
  ├── user_service.dart          # User management
  ├── match_service.dart         # Matching logic
  ├── message_service.dart       # Messaging
  └── upload_service.dart        # File uploads
  ```

#### 1.3 Data Models Implementation
**Priority: HIGH**
- [ ] **Create RTM Data Models**
  - User model with comprehensive profile fields
  - Location model for geographical data
  - UserProfile model with detailed attributes
  - MatchPreferences model for filtering criteria
  - Message/Conversation models
  - API response wrapper models

- [ ] **Implement Model Serialization**
  - Add toJson() and fromJson() methods
  - Create model factories
  - Add validation logic

### Phase 2: UI/UX Transformation (Week 2)

#### 2.1 Design System Implementation
**Priority: HIGH**
- [ ] **Update Color Scheme**
  - Replace orange theme with RTM purple theme
  - Update ColorRes class with RTM colors:
    ```dart
    static const Color primary = Color(0xFF7B68EE);
    static const Color primaryLight = Color(0xFF9B8AFF);
    static const Color primaryDark = Color(0xFF5D4CDB);
    ```

- [ ] **Typography Updates**
  - Replace Gilroy fonts with Poppins
  - Update FontRes class
  - Implement RTM text styles

- [ ] **Component Updates**
  - Update all UI components to use new colors
  - Redesign buttons, cards, form fields
  - Update loading animations and spinners

#### 2.2 Screen Flow Restructuring
**Priority: MEDIUM**
- [ ] **Authentication Flow**
  - Update SplashScreen with RTM branding
  - Redesign OnboardingScreen (3 screens)
  - Update RegistrationScreen with RTM fields
  - Create OTPVerificationScreen
  - Build IdealMatchScreen (preferences)
  - Create LocationInputScreen

- [ ] **Main App Navigation**
  - Update bottom navigation icons/labels
  - Implement RTM navigation structure:
    - HomeScreen (match feeds)
    - ExploreScreen (map/card view)
    - LiveDatesScreen (coming soon)
    - LikesScreen (saved/liked profiles)
    - MessagesScreen (chat list)
    - ProfileScreen (user profile)

#### 2.3 Screen-Specific Updates
**Priority: MEDIUM**
- [ ] **HomeScreen Redesign**
  - Implement 3-section layout:
    - Closest Matches
    - New Users
    - Nearest by Distance
  - Update card designs with RTM styling

- [ ] **ExploreScreen Enhancement**
  - Add map/card view toggle
  - Implement advanced filtering
  - Update user markers design
  - Add distance radius controls

- [ ] **Profile Screens**
  - Redesign ProfileScreen with RTM sections
  - Update ProfileDetailScreen for other users
  - Add compatibility score display
  - Implement photo carousel

### Phase 3: Core Functionality Implementation (Week 3)

#### 3.1 Matching System
**Priority: HIGH**
- [ ] **Match Algorithm Integration**
  - Replace existing match logic with RTM API calls
  - Implement GET /api/matches/home-feed
  - Add GET /api/matches/explore
  - Create filter functionality
  - Implement compatibility scoring

- [ ] **Location Services**
  - Update location detection
  - Implement distance calculations
  - Add location privacy controls
  - Create location-based filtering

#### 3.2 User Profile Management
**Priority: HIGH**
- [ ] **Comprehensive Profile Fields**
  - Add all RTM profile fields:
    - Basic info, ethnicity, lifestyle
    - Religion, personality, physical attributes
    - Medical information, preferences
  - Implement multi-step profile creation
  - Add profile completion indicators

- [ ] **Photo Management**
  - Update photo upload functionality
  - Implement photo reordering
  - Add photo verification process
  - Create photo gallery views

#### 3.3 Preferences & Filtering
**Priority: MEDIUM**
- [ ] **Match Preferences**
  - Implement comprehensive preference system
  - Add deal-breaker toggles
  - Create preference validation
  - Update preference storage

- [ ] **Advanced Filtering**
  - Add all RTM filter criteria
  - Implement filter persistence
  - Create filter reset functionality
  - Add filter result counts

### Phase 4: Communication & Interaction (Week 4)

#### 4.1 Real-time Messaging
**Priority: HIGH**
- [ ] **Socket.io Integration**
  - Replace Firebase messaging with Socket.io
  - Implement real-time message delivery
  - Add typing indicators
  - Create online status tracking

- [ ] **Chat Functionality**
  - Update ChatScreen with new API
  - Implement message types (text, image, emoji)
  - Add message status indicators
  - Create conversation management

#### 4.2 Likes & Interactions
**Priority: MEDIUM**
- [ ] **Like System**
  - Implement like/unlike functionality
  - Create LikesScreen with tabs
  - Add mutual match detection
  - Implement poke functionality

- [ ] **Premium Features Integration**
  - Add premium messaging restrictions
  - Implement worldwide search for premium users
  - Create premium badge indicators
  - Add premium upgrade prompts

### Phase 5: Advanced Features (Week 5)

#### 5.1 Live Dating Features
**Priority: LOW (Coming Soon)**
- [ ] **Live Dates Preparation**
  - Create "Coming Soon" screen
  - Design notification signup
  - Plan video call room architecture
  - Research queuing system requirements

#### 5.2 Maps Integration
**Priority: MEDIUM**
- [ ] **Google Maps Enhancement**
  - Update map integration with new data
  - Implement custom user markers
  - Add map clustering for dense areas
  - Create location privacy controls

#### 5.3 Push Notifications
**Priority: MEDIUM**
- [ ] **Local Notifications**
  - Replace Firebase messaging with local notifications
  - Implement notification scheduling
  - Add notification preferences
  - Create notification action handlers

### Phase 6: Backend API Integration (Week 6)

#### 6.1 API Endpoints Implementation
**Priority: HIGH**
- [ ] **Authentication APIs**
  ```
  POST /api/auth/register
  POST /api/auth/verify-otp
  POST /api/auth/login
  POST /api/auth/refresh-token
  ```

- [ ] **User Management APIs**
  ```
  GET /api/user/profile
  PUT /api/user/profile
  PUT /api/user/match-preferences
  PUT /api/user/location
  POST /api/user/upload-photo
  ```

- [ ] **Matching APIs**
  ```
  GET /api/matches/home-feed
  GET /api/matches/explore
  POST /api/matches/filter
  GET /api/matches/compatibility/:userId
  ```

- [ ] **Messaging APIs**
  ```
  GET /api/messages/conversations
  GET /api/messages/:conversationId
  POST /api/messages
  PUT /api/messages/:messageId/read
  ```

#### 6.2 Error Handling & Validation
**Priority: HIGH**
- [ ] **API Error Handling**
  - Implement comprehensive error handling
  - Add retry mechanisms
  - Create user-friendly error messages
  - Add offline mode indicators

- [ ] **Form Validation**
  - Update all form validations
  - Add real-time validation feedback
  - Implement server-side validation integration
  - Create validation error displays

### Phase 7: State Management Migration (Week 7)

#### 7.1 GetX to Provider Migration
**Priority: MEDIUM**
- [ ] **Provider Implementation**
  - Create AuthProvider
  - Implement MatchProvider
  - Add MessageProvider
  - Create ProfileProvider
  - Add PremiumProvider

- [ ] **Navigation Updates**
  - Replace GetX navigation with GoRouter
  - Update route definitions
  - Implement navigation guards
  - Add deep linking support

#### 7.2 Data Persistence
**Priority: MEDIUM**
- [ ] **Local Storage**
  - Implement Hive for local data storage
  - Add user session management
  - Create data synchronization
  - Implement offline mode support

### Phase 8: Testing & Quality Assurance (Week 8)

#### 8.1 Testing Implementation
**Priority: HIGH**
- [ ] **Unit Tests**
  - Test data models
  - Test API services
  - Test utility functions
  - Test validation logic

- [ ] **Widget Tests**
  - Test UI components
  - Test form interactions
  - Test navigation flows
  - Test state changes

- [ ] **Integration Tests**
  - Test complete user flows
  - Test API integrations
  - Test real-time features
  - Test offline scenarios

#### 8.2 Performance Optimization
**Priority: MEDIUM**
- [ ] **Image Optimization**
  - Implement image caching
  - Add image compression
  - Optimize image loading
  - Add lazy loading for lists

- [ ] **Memory Management**
  - Profile memory usage
  - Fix memory leaks
  - Optimize large lists
  - Implement proper disposal

### Phase 9: Production Preparation (Week 9)

#### 9.1 App Configuration
**Priority: HIGH**
- [ ] **App Identity**
  - Update app name to "Ready to Marry"
  - Change package name to com.readytomarry.app
  - Update app icons and splash screens
  - Add proper app descriptions

- [ ] **Environment Configuration**
  - Set up development/staging/production environments
  - Configure API endpoints
  - Add environment-specific settings
  - Implement feature flags

#### 9.2 Security Implementation
**Priority: HIGH**
- [ ] **Security Measures**
  - Implement certificate pinning
  - Add API key protection
  - Secure local storage
  - Add biometric authentication option

- [ ] **Privacy Controls**
  - Implement location privacy settings
  - Add profile visibility controls
  - Create data deletion functionality
  - Add privacy policy integration

### Phase 10: Deployment & Launch (Week 10)

#### 10.1 Build Configuration
**Priority: HIGH**
- [ ] **Android Build**
  - Configure release build
  - Set up app signing
  - Optimize APK size
  - Test on multiple devices

- [ ] **iOS Build**
  - Configure Xcode project
  - Set up provisioning profiles
  - Build for App Store
  - Test on multiple iOS devices

#### 10.2 Store Preparation
**Priority: MEDIUM**
- [ ] **App Store Assets**
  - Create app screenshots
  - Write app descriptions
  - Prepare app preview videos
  - Design app store graphics

- [ ] **Store Submissions**
  - Submit to Google Play Console
  - Submit to Apple App Store
  - Configure in-app purchases
  - Set up app analytics

## Technical Specifications

### Dependencies to Remove
```yaml
# Firebase dependencies to remove
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
firebase_messaging: ^15.1.3
google_mobile_ads: ^5.2.0

# State management to replace
get: ^4.6.6
stacked: ^3.4.3
```

### Dependencies to Add
```yaml
# HTTP & API
dio: ^5.3.2
retry: ^3.1.2

# State Management
provider: ^6.0.5
go_router: ^12.0.0

# Local Storage
shared_preferences: ^2.2.2
hive: ^2.2.3
hive_flutter: ^1.1.0
flutter_secure_storage: ^9.0.0

# Real-time Communication
socket_io_client: ^2.0.3+1

# Form Validation
form_field_validator: ^1.1.0

# Utilities
connectivity_plus: ^5.0.1
device_info_plus: ^9.1.0
package_info_plus: ^4.2.0
```

### File Structure Changes
```
lib/
├── main.dart                      # Updated without Firebase
├── app.dart                       # New app configuration
├── constants/
│   ├── app_colors.dart           # RTM purple theme
│   ├── app_text_styles.dart      # Poppins font styles
│   ├── app_constants.dart        # App-wide constants
│   └── api_endpoints.dart        # API endpoint definitions
├── models/
│   ├── user.dart                 # Enhanced user model
│   ├── location.dart             # Location model
│   ├── user_profile.dart         # Detailed profile model
│   ├── match_preferences.dart    # Preference model
│   ├── message.dart              # Message model
│   ├── conversation.dart         # Conversation model
│   └── api_response.dart         # API response wrapper
├── providers/
│   ├── auth_provider.dart        # Authentication state
│   ├── match_provider.dart       # Matching logic
│   ├── message_provider.dart     # Messaging state
│   ├── profile_provider.dart     # Profile management
│   └── premium_provider.dart     # Premium features
├── services/
│   ├── api_service.dart          # Base HTTP service
│   ├── auth_service.dart         # JWT authentication
│   ├── socket_service.dart       # Real-time communication
│   ├── location_service.dart     # Location services
│   ├── storage_service.dart      # Local storage
│   └── notification_service.dart # Local notifications
├── screens/                      # Updated screen implementations
├── widgets/                      # Reusable UI components
├── utils/                        # Utility functions
└── config/
    ├── routes.dart               # GoRouter configuration
    ├── themes.dart               # App themes
    └── environment.dart          # Environment configuration
```

## Testing Strategy

### Test Categories
1. **Unit Tests (40%)**
   - Data models
   - API services
   - Utility functions
   - Business logic

2. **Widget Tests (35%)**
   - UI components
   - Screen layouts
   - User interactions
   - Form validations

3. **Integration Tests (25%)**
   - Complete user flows
   - API integrations
   - Navigation flows
   - Real-time features

### Test Coverage Goals
- Minimum 80% code coverage
- 100% coverage for critical paths
- All API services must be tested
- All data models must be tested

## Risk Assessment & Mitigation

### High-Risk Areas
1. **Real-time Messaging Migration**
   - Risk: Complex Firebase to Socket.io migration
   - Mitigation: Thorough testing, gradual rollout

2. **State Management Changes**
   - Risk: GetX to Provider migration complexity
   - Mitigation: Screen-by-screen migration, extensive testing

3. **Authentication System**
   - Risk: JWT implementation security
   - Mitigation: Security audit, penetration testing

### Medium-Risk Areas
1. **Performance Impact**
   - Risk: HTTP calls may be slower than Firebase
   - Mitigation: Implement caching, optimize API calls

2. **Offline Functionality**
   - Risk: Loss of Firebase offline capabilities
   - Mitigation: Implement local storage, sync mechanisms

## Success Criteria

### Functional Requirements
- [ ] All authentication flows working
- [ ] User profiles completely functional
- [ ] Matching system operational
- [ ] Real-time messaging working
- [ ] Location services functional
- [ ] Premium features implemented

### Performance Requirements
- [ ] App launches in under 3 seconds
- [ ] API calls complete within 5 seconds
- [ ] Smooth scrolling on all screens
- [ ] Memory usage under 200MB
- [ ] No memory leaks detected

### Quality Requirements
- [ ] Zero crash rate on launch
- [ ] 95%+ successful API call rate
- [ ] All forms validate correctly
- [ ] Consistent UI/UX across screens
- [ ] Responsive design on all devices

## Timeline Summary

| Week | Focus Area | Key Deliverables |
|------|------------|------------------|
| 1 | Backend Integration | Firebase removal, API setup, authentication |
| 2 | UI/UX Transformation | Design system, screen updates, navigation |
| 3 | Core Functionality | Matching system, profiles, preferences |
| 4 | Communication | Real-time messaging, likes, interactions |
| 5 | Advanced Features | Live dating prep, maps, notifications |
| 6 | API Integration | All endpoints, error handling, validation |
| 7 | State Management | Provider migration, navigation updates |
| 8 | Testing & QA | Unit tests, widget tests, integration tests |
| 9 | Production Prep | App config, security, privacy controls |
| 10 | Deployment | Build configuration, store submission |

## Contact & Resources

### Development Team
- **Project Lead**: [Name]
- **Backend Developer**: [Name]
- **Mobile Developer**: [Name]
- **UI/UX Designer**: [Name]

### Key Resources
- RTM Specification: `/mnt/c/Users/Joeey/Documents/rtm/flutter_dating_app_spec.md`
- Source Code: `/mnt/c/Users/Joeey/Documents/rtm/apps/demo_orange/`
- Target Code: `/mnt/c/Users/Joeey/Documents/rtm/apps/rtm_flutter/`
- Documentation: `/mnt/c/Users/Joeey/Documents/rtm/RTM_DEVELOPMENT_TASKS.md`

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-12  
**Next Review**: Weekly during development phases

This document serves as the master reference for all RTM Flutter development activities. Update this document as tasks are completed and new requirements emerge.