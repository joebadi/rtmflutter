import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSearchResult {
  final String displayName;
  final double lat;
  final double lon;
  final String city;
  final String state;
  final String country;

  LocationSearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.city,
    required this.state,
    required this.country,
  });

  factory LocationSearchResult.fromNominatim(Map<String, dynamic> json) {
    final address = json['address'] ?? {};
    return LocationSearchResult(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat'] ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon'] ?? '0') ?? 0.0,
      city: address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? '',
      state: address['state'] ?? address['region'] ?? '',
      country: address['country'] ?? '',
    );
  }
}

class LocationSearchService {
  final Dio _dio = Dio();
  
  // Nominatim requires a User-Agent identifying the application
  final String _userAgent = 'ReadyToMarryApp/1.0';

  Future<List<LocationSearchResult>> searchPlaces(String query) async {
    if (query.length < 3) return [];

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
          'accept-language': 'en', // Prefer English results
        },
        options: Options(
          headers: {'User-Agent': _userAgent},
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((item) => LocationSearchResult.fromNominatim(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching location: $e');
      return [];
    }
  }

  Future<LocationSearchResult?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check availability
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    // Get position
    final position = await Geolocator.getCurrentPosition();

    // Reverse Geocode
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Construct display name
        final parts = [
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        return LocationSearchResult(
          displayName: parts,
          lat: position.latitude,
          lon: position.longitude,
          city: place.locality ?? place.subAdministrativeArea ?? '',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
        );
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
  }
}
