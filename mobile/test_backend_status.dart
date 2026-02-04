import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final email = 'josephekukinam@gmail.com';
  final password =
      'password123'; // Assuming you used a simple password for testing, or update this
  // note: cannot know actual password, so this might fail login if not matching.
  // Instead, let's just test the health endpoint and maybe a generic OTP send if available without auth?
  // No, send-otp usually requires auth or phone number.

  try {
    print('Testing login for $email...');
    // We can't easily login without the password you used.
    // But we can check if the user exists by trying to register again (which you confirmed works/fails correctly).

    print('Checking if user exists via register...');
    try {
      await dio.post(
        'https://rtmadmin.e-clicks.net/api/auth/register',
        data: {
          'firstName': 'Joseph',
          'lastName': 'Ekukinam',
          'email': email,
          'password': 'Password123!',
          'phoneNumber': '+2348012345678', // Just testing existence
        },
      );
    } on DioException catch (e) {
      print('Register Result: ${e.response?.data}');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}
