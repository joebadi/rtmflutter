import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/profile_details_page.dart';
import 'screens/auth/image_upload_page.dart';
import 'screens/auth/preferred_partner_page.dart';
import 'screens/auth/otp_verification_page.dart';
import 'screens/auth/video_verification_page.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile/profile_setup_page.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/complete_profile_page.dart';
import 'screens/profile/personal_information_page.dart';
import 'screens/profile/match_preferences_page.dart';
import 'screens/profile/options_page.dart';
import 'screens/premium/premium_page.dart';
import 'screens/wallet/wallet_page.dart';
import 'screens/explore_screen.dart';
import 'screens/live_dates_screen.dart';
import 'screens/likes_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/user_profile_page.dart';
import 'screens/main_shell.dart';
import 'providers/profile_provider.dart';
import 'providers/message_provider.dart';
import 'config/theme.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/splash', // Start with splash screen
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Navigation Error: ${state.error}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/splash'),
            child: const Text('Go to Splash'),
          ),
        ],
      ),
    ),
  ),
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/splash'),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login', // Explicit Login Route
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupPage(),
    ),
    GoRoute(
      path: '/profile-details',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ProfileDetailsPage(
          firstName: extra?['firstName'] as String?,
          lastName: extra?['lastName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/image-upload',
      builder: (context, state) => const ImageUploadPage(),
    ),
    GoRoute(
      path: '/preferred-partner',
      builder: (context, state) => const PreferredPartnerPage(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpVerificationPage(
          phoneNumber: extra?['phoneNumber'] as String? ?? '',
          email: extra?['email'] as String?,
          firstName: extra?['firstName'] as String?,
          lastName: extra?['lastName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/video-verification',
      builder: (context, state) => const VideoVerificationPage(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final isEditing = extra?['isEditing'] ?? false;
        return CompleteProfilePage(isEditing: isEditing);
      },
    ),
    GoRoute(
      path: '/personal-information',
      builder: (context, state) => const PersonalInformationPage(),
    ),
    GoRoute(
      path: '/match-preferences',
      builder: (context, state) => const MatchPreferencesPage(),
    ),
    GoRoute(path: '/options', builder: (context, state) => const OptionsPage()),
    GoRoute(path: '/premium', builder: (context, state) => const PremiumPage()),
    GoRoute(path: '/wallet', builder: (context, state) => const WalletPage()),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        
        return ChatScreen(
          conversationId: conversationId,
          receiverId: extra?['receiverId'] ?? '',
          receiverName: extra?['receiverName'] ?? 'User',
          receiverPhoto: extra?['receiverPhoto'],
        );
      },
    ),
    GoRoute(
      path: '/user-profile',
      builder: (context, state) {
        final userData = state.extra as Map<String, dynamic>?;
        if (userData == null) {
          // Fallback if no data provided
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No user data provided'),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        return UserProfilePage(userData: userData);
      },
    ),

    // Shell Route for Bottom Nav Tabs
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/live-dates',
          builder: (context, state) => const LiveDatesScreen(),
        ),
        GoRoute(
          path: '/likes',
          builder: (context, state) => const LikesScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()..init()),
        ChangeNotifierProvider(create: (_) => MessageProvider()..init()),
      ],
      child: MaterialApp.router(
        title: 'Ready to Marry',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}
