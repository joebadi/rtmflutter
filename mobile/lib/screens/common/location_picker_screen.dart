import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../services/location_search_service.dart';
import '../../widgets/premium_loader.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchCtrl = TextEditingController();
  final _locationService = LocationSearchService();
  
  List<LocationSearchResult> _results = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;
  
  // Suggested locations for quick selection
  final List<String> _suggestedCities = [
    'Lagos, Nigeria',
    'Abuja, Nigeria',
    'Accra, Ghana',
    'Nairobi, Kenya',
    'Johannesburg, South Africa',
    'London, UK',
    'New York, USA',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.length < 3) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final results = await _locationService.searchPlaces(query);
        if (mounted) {
          setState(() {
            _results = results;
            if (results.isEmpty) {
              _error = 'No locations found';
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _error = 'Failed to search nearby locations');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _locationService.getCurrentLocation();
      if (mounted) {
        if (result != null) {
          Navigator.pop(context, result);
        } else {
          setState(() => _error = 'Could not determine location');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectLocation(LocationSearchResult result) {
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search city, state, or country',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: _searchCtrl.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                         _searchCtrl.clear();
                         _onSearchChanged('');
                      },
                    )
                  : null,
              ),
            ),
          ),

          // Use Current Location
          InkWell(
            onTap: _useCurrentLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFFFF5722),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Current Location',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                      Text(
                        'Using GPS',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading, Error, or Results
          if (_isLoading)
            const Expanded(
              child: Center(
                child: PremiumLoader(),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else 
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Search Results
                  if (_results.isNotEmpty) ...[
                    Padding(
                       padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                       child: Text(
                         'SEARCH RESULTS',
                         style: GoogleFonts.poppins(
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
                           color: Colors.grey[500],
                           letterSpacing: 1,
                         ),
                       ),
                    ),
                    ..._results.map((result) => ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                      title: Text(
                        result.displayName,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${result.city}${result.city.isNotEmpty ? ', ' : ''}${result.country}',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                      onTap: () => _selectLocation(result),
                    )),
                  ] else if (_searchCtrl.text.isEmpty) ...[
                    // Suggestions
                    Padding(
                       padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                       child: Text(
                         'SUGGESTED',
                         style: GoogleFonts.poppins(
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
                           color: Colors.grey[500],
                           letterSpacing: 1,
                         ),
                       ),
                    ),
                    ..._suggestedCities.map((city) => ListTile(
                      leading: const Icon(Icons.location_city, color: Colors.grey),
                      title: Text(
                        city,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      onTap: () {
                        // Quick populate search
                        _searchCtrl.text = city;
                        _onSearchChanged(city);
                      },
                    )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
