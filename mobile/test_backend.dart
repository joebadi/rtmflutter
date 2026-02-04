import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();

  try {
    print('Testing backend connectivity...');
    print('URL: https://rtmadmin.e-clicks.net/api/health');

    final response = await dio.get('https://rtmadmin.e-clicks.net/api/health');
    print('Health check successful!');
    print('Response: ${response.data}');

    // Test registration endpoint
    print('\nTesting registration endpoint...');
    final regResponse = await dio.post(
      'https://rtmadmin.e-clicks.net/api/auth/register',
      data: {
        'firstName': 'Test',
        'lastName': 'User',
        'email': 'test@example.com',
        'password': 'Test123456',
        'phoneNumber': '+2348012345678',
      },
    );
    print('Registration response: ${regResponse.data}');
  } on DioException catch (e) {
    print('Error occurred:');
    print('Message: ${e.message}');
    print('Type: ${e.type}');
    print('Response: ${e.response?.data}');
    print('Status code: ${e.response?.statusCode}');
  } catch (e) {
    print('Unexpected error: $e');
  }
}
