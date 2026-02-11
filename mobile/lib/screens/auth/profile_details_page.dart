import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/profile_service.dart';
import '../../widgets/premium_dropdown.dart';

class ProfileDetailsPage extends StatefulWidget {
  final String? firstName;
  final String? lastName;

  const ProfileDetailsPage({super.key, this.firstName, this.lastName});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String _selectedGender = 'Male';
  String? _selectedEthnicityCountry;
  String? _selectedEthnicityState;
  String? _selectedTribe;
  String _selectedRelationshipStatus = 'Single';
  String _selectedReligion = 'Christianity';
  String _selectedGenotype = 'AA';
  String _selectedBloodGroup = 'O+';
  String? _calculatedZodiac;
  int? _calculatedAge;
  String? _selectedHeight;
  String _selectedBodyType = 'Average';
  bool _hasTattoos = false;
  bool _hasPiercings = false;
  bool _isLoadingLocation = false;

  final List<String> _countries = [
    'Nigeria',
    'Ghana',
    'Kenya',
    'South Africa',
    'USA',
    'UK',
    'Canada',
  ];
  final List<String> _nigerianStates = [
    'Abia',
    'Adamawa',
    'Akwa Ibom',
    'Anambra',
    'Bauchi',
    'Bayelsa',
    'Benue',
    'Borno',
    'Cross River',
    'Delta',
    'Ebonyi',
    'Edo',
    'Ekiti',
    'Enugu',
    'FCT',
    'Gombe',
    'Imo',
    'Jigawa',
    'Kaduna',
    'Kano',
    'Katsina',
    'Kebbi',
    'Kogi',
    'Kwara',
    'Lagos',
    'Nasarawa',
    'Niger',
    'Ogun',
    'Ondo',
    'Osun',
    'Oyo',
    'Plateau',
    'Rivers',
    'Sokoto',
    'Taraba',
    'Yobe',
    'Zamfara',
  ];
  final Map<String, List<String>> _stateTribes = {
    'Lagos': ['Yoruba', 'Awori', 'Egun'],
    'Oyo': ['Yoruba'],
    'Ogun': ['Yoruba', 'Egba', 'Ijebu'],
    'Kano': ['Hausa', 'Fulani'],
    'Kaduna': ['Hausa', 'Fulani', 'Gbagyi'],
    'Rivers': ['Ijaw', 'Ikwerre', 'Ogoni', 'Kalabari'],
    'Anambra': ['Igbo'],
    'Enugu': ['Igbo'],
    'Imo': ['Igbo'],
    'Abia': ['Igbo'],
    'Ebonyi': ['Igbo'],
    'Delta': ['Urhobo', 'Isoko', 'Itsekiri', 'Ijaw'],
    'Edo': ['Edo', 'Bini', 'Esan'],
    'Cross River': ['Efik', 'Ibibio', 'Ejagham'],
    'Akwa Ibom': ['Ibibio', 'Annang', 'Oron'],
  };
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _relationshipStatuses = [
    'Single',
    'Divorced',
    'Widowed',
    'Separated',
  ];
  final List<String> _religions = [
    'Christianity',
    'Islam',
    'Traditional',
    'Other',
    'Atheist',
  ];
  final List<String> _genotypes = ['AA', 'AS', 'SS', 'AC', 'SC'];
  final List<String> _bloodGroups = [
    'O+',
    'O-',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
  ];
  final List<String> _heights = [
    '4\'7" (140 cm)',
    '4\'8" (142 cm)',
    '4\'9" (145 cm)',
    '4\'10" (147 cm)',
    '4\'11" (150 cm)',
    '5\'0" (152 cm)',
    '5\'1" (155 cm)',
    '5\'2" (157 cm)',
    '5\'3" (160 cm)',
    '5\'4" (163 cm)',
    '5\'5" (165 cm)',
    '5\'6" (168 cm)',
    '5\'7" (170 cm)',
    '5\'8" (173 cm)',
    '5\'9" (175 cm)',
    '5\'10" (178 cm)',
    '5\'11" (180 cm)',
    '6\'0" (183 cm)',
    '6\'1" (185 cm)',
    '6\'2" (188 cm)',
    '6\'3" (190 cm)',
    '6\'4" (193 cm)',
    '6\'5" (196 cm)',
    '6\'6" (198 cm)',
    '6\'7" (201 cm)',
    '6\'8" (203 cm)',
  ];
  final List<String> _bodyTypes = [
    'Slim',
    'Average',
    'Athletic',
    'Curvy',
    'Plus Size',
    'Muscular',
  ];

  final List<String> _maleBodyTypes = [
    'Slim',
    'Average',
    'Athletic',
    'Muscular',
    'Stocky',
    'Heavyset',
  ];

  final List<String> _femaleBodyTypes = [
    'Slim',
    'Petite',
    'Average',
    'Athletic',
    'Curvy',
    'Full-figured',
  ];

  List<String> _getBodyTypesForGender() {
    if (_selectedGender == 'Male') return _maleBodyTypes;
    if (_selectedGender == 'Female') return _femaleBodyTypes;
    return _bodyTypes;
  }

  void _calculateZodiacAndAge(DateTime dob) {
    // Calculate Age
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    // Calculate Zodiac
    String zodiac;
    final month = dob.month;
    final day = dob.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      zodiac = 'Aries';
    } else if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      zodiac = 'Taurus';
    } else if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      zodiac = 'Gemini';
    } else if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      zodiac = 'Cancer';
    } else if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      zodiac = 'Leo';
    } else if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      zodiac = 'Virgo';
    } else if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      zodiac = 'Libra';
    } else if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      zodiac = 'Scorpio';
    } else if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      zodiac = 'Sagittarius';
    } else if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      zodiac = 'Capricorn';
    } else if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      zodiac = 'Aquarius';
    } else {
      zodiac = 'Pisces';
    }

    setState(() {
      _calculatedAge = age;
      _calculatedZodiac = zodiac;
    });
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B35),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
      });
      _calculateZodiacAndAge(picked);
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationString = [
          place.locality,
          place.administrativeArea,
          place.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _locationCtrl.text = locationString;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _continue() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Parse DOB to YYYY-MM-DD
        String? formattedDob;
        if (_dobCtrl.text.isNotEmpty) {
          final parts = _dobCtrl.text.split('/');
          if (parts.length == 3) {
            formattedDob = '${parts[2]}-${parts[1]}-${parts[0]}';
          }
        }

        final data = {
          'location': _locationCtrl.text,
          'ethnicityCountry': _selectedEthnicityCountry,
          'ethnicityState': _selectedEthnicityState,
          'tribe': _selectedTribe,
          'dateOfBirth': formattedDob,
          'gender': _selectedGender.toUpperCase(),
          'relationshipStatus': _selectedRelationshipStatus,
          'religion': _selectedReligion,
          'genotype': _selectedGenotype,
          'bloodGroup': _selectedBloodGroup,
          'height': _selectedHeight,
          'bodyType': _selectedBodyType,
          'hasTattoos': _hasTattoos,
          'hasPiercings': _hasPiercings,
          // Store raw age/zodiac if backend supports it, otherwise rely on DOB
          'age': _calculatedAge,
          'zodiac': _calculatedZodiac,
        };

        final profileService = ProfileService();
        await profileService.updateProfile(data);

        if (mounted) {
          // Close loader
          Navigator.pop(context);
          // Navigate to next step
          context.push('/image-upload');
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loader
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/register_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 0.9],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Details',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Step 2 of 5',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // WHERE DO YOU LIVE Section
                                  _buildSectionHeader('Where do you live?'),
                                  const SizedBox(height: 10),

                                  // Single Location Field with Geolocate Icon
                                  _buildLocationField(
                                    controller: _locationCtrl,
                                    label: 'Location',
                                    hint: 'City, State, Country',
                                    onGeolocate: _isLoadingLocation ? () {} : _fetchLocation,
                                  ),
                                  const SizedBox(height: 20),

                                  // ETHNICITY Section
                                  _buildSectionHeader('Ethnicity'),
                                  const SizedBox(height: 10),

                                  _buildDropdown(
                                    'Country of Origin',
                                    _selectedEthnicityCountry,
                                    _countries,
                                    (v) => setState(() {
                                      _selectedEthnicityCountry = v;
                                      _selectedEthnicityState = null;
                                      _selectedTribe = null;
                                    }),
                                  ),

                                  // Conditional State for Nigeria
                                  if (_selectedEthnicityCountry ==
                                      'Nigeria') ...[
                                    const SizedBox(height: 14),
                                    _buildDropdown(
                                      'State of Origin',
                                      _selectedEthnicityState,
                                      _nigerianStates,
                                      (v) => setState(() {
                                        _selectedEthnicityState = v;
                                        _selectedTribe = null;
                                      }),
                                    ),

                                    // Conditional Tribe for selected state
                                    if (_selectedEthnicityState != null &&
                                        _stateTribes[_selectedEthnicityState] !=
                                            null) ...[
                                      const SizedBox(height: 14),
                                      _buildDropdown(
                                        'Tribe',
                                        _selectedTribe,
                                        _stateTribes[_selectedEthnicityState]!,
                                        (v) =>
                                            setState(() => _selectedTribe = v),
                                      ),
                                    ],
                                  ],

                                  // For other countries, just show state
                                  if (_selectedEthnicityCountry != null &&
                                      _selectedEthnicityCountry !=
                                          'Nigeria') ...[
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      controller: TextEditingController(),
                                      label: 'State/Province',
                                      hint: 'Enter your state',
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Date of Birth
                                  _buildDateField(
                                    controller: _dobCtrl,
                                    label: 'Date of Birth',
                                    hint: 'DD/MM/YYYY',
                                    onTap: _selectDateOfBirth,
                                  ),

                                  // Calculated Age (readonly)
                                  if (_calculatedAge != null) ...[
                                    const SizedBox(height: 14),
                                    _buildReadOnlyField(
                                      'Age',
                                      '$_calculatedAge years',
                                    ),
                                  ],

                                  // Calculated Zodiac (readonly)
                                  if (_calculatedZodiac != null) ...[
                                    const SizedBox(height: 14),
                                    _buildReadOnlyField(
                                      'Zodiac Sign',
                                      _calculatedZodiac!,
                                    ),
                                  ],

                                  const SizedBox(height: 14),

                                  // Gender
                                  _buildDropdown(
                                    'Gender',
                                    _selectedGender,
                                    _genders,
                                    (v) => setState(() {
                                      _selectedGender = v!;
                                      // Reset body type if current selection is invalid for new gender
                                      final validTypes = _getBodyTypesForGender();
                                      if (!validTypes.contains(_selectedBodyType)) {
                                        _selectedBodyType = validTypes.first;
                                      }
                                    }),
                                  ),
                                  const SizedBox(height: 14),

                                  // Relationship Status
                                  _buildDropdown(
                                    'Relationship Status',
                                    _selectedRelationshipStatus,
                                    _relationshipStatuses,
                                    (v) => setState(
                                      () => _selectedRelationshipStatus = v!,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Religion
                                  _buildDropdown(
                                    'Religion',
                                    _selectedReligion,
                                    _religions,
                                    (v) =>
                                        setState(() => _selectedReligion = v!),
                                  ),
                                  const SizedBox(height: 14),

                                  // Genotype & Blood Group (Row)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdown(
                                          'Genotype',
                                          _selectedGenotype,
                                          _genotypes,
                                          (v) => setState(
                                            () => _selectedGenotype = v!,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildDropdown(
                                          'Blood Group',
                                          _selectedBloodGroup,
                                          _bloodGroups,
                                          (v) => setState(
                                            () => _selectedBloodGroup = v!,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Height
                                  PremiumDropdown(
                                    label: 'Height',
                                    value: _selectedHeight,
                                    hint: 'Select height',
                                    items: _heights,
                                    onChanged: (v) => setState(
                                      () => _selectedHeight = v,
                                    ),
                                    isDarkLabel: true,
                                  ),
                                  const SizedBox(height: 14),

                                  // Body Type
                                  _buildDropdown(
                                    'Body Type',
                                    _selectedBodyType,
                                    _getBodyTypesForGender(),
                                    (v) => setState(
                                      () => _selectedBodyType = v!,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Tattoos & Piercings
                                  _buildSwitchTile(
                                    'Tattoos',
                                    _hasTattoos,
                                    (v) => setState(() => _hasTattoos = v),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildSwitchTile(
                                    'Piercings',
                                    _hasPiercings,
                                    (v) => setState(() => _hasPiercings = v),
                                  ),

                                  const SizedBox(height: 24),

                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _continue,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFF6B35,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: Text(
                                        'Continue',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFF6B35),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Known location suggestions for autocomplete
  static const List<String> _locationSuggestions = [
    'Lagos, Lagos, Nigeria',
    'Ikeja, Lagos, Nigeria',
    'Lekki, Lagos, Nigeria',
    'Victoria Island, Lagos, Nigeria',
    'Abuja, FCT, Nigeria',
    'Port Harcourt, Rivers, Nigeria',
    'Ibadan, Oyo, Nigeria',
    'Kano, Kano, Nigeria',
    'Benin City, Edo, Nigeria',
    'Enugu, Enugu, Nigeria',
    'Owerri, Imo, Nigeria',
    'Calabar, Cross River, Nigeria',
    'Uyo, Akwa Ibom, Nigeria',
    'Abeokuta, Ogun, Nigeria',
    'Jos, Plateau, Nigeria',
    'Kaduna, Kaduna, Nigeria',
    'Warri, Delta, Nigeria',
    'Aba, Abia, Nigeria',
    'Accra, Greater Accra, Ghana',
    'Kumasi, Ashanti, Ghana',
    'Nairobi, Nairobi, Kenya',
    'Mombasa, Mombasa, Kenya',
    'Johannesburg, Gauteng, South Africa',
    'Cape Town, Western Cape, South Africa',
    'London, England, UK',
    'Manchester, England, UK',
    'New York, NY, USA',
    'Houston, TX, USA',
    'Atlanta, GA, USA',
    'Toronto, Ontario, Canada',
  ];

  List<String> _filteredLocations = [];

  void _onLocationChanged(String query) {
    if (query.length < 2) {
      setState(() => _filteredLocations = []);
      return;
    }
    setState(() {
      _filteredLocations = _locationSuggestions
          .where((loc) => loc.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onGeolocate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: controller.text.isNotEmpty
                  ? const Color(0xFFFF6B35).withOpacity(0.3)
                  : Colors.grey[300]!.withOpacity(0.5),
              width: controller.text.isNotEmpty ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: controller.text.isNotEmpty
                    ? const Color(0xFFFF6B35).withOpacity(0.06)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
            onChanged: _onLocationChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: controller.text.isNotEmpty
                    ? const Color(0xFFFF6B35)
                    : Colors.grey[400],
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF6B35),
                        ),
                      )
                    : const Icon(Icons.my_location, color: Color(0xFFFF6B35), size: 20),
                onPressed: onGeolocate,
                tooltip: 'Use current location',
              ),
            ),
          ),
        ),
        // Autocomplete suggestions
        if (_filteredLocations.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final loc = _filteredLocations[index];
                return InkWell(
                  onTap: () {
                    controller.text = loc;
                    setState(() => _filteredLocations = []);
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.place_outlined, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.text.isEmpty ? hint : controller.text,
                  style: GoogleFonts.poppins(
                    color: controller.text.isEmpty ? Colors.grey : Colors.black,
                    fontSize: 13,
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF6B35), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.lock, color: Color(0xFFFF6B35), size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return PremiumDropdown(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      isDarkLabel: true,
    );
  }

  Widget _buildSwitchTile(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
    );
  }
}
