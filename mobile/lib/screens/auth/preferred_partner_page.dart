import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/profile_service.dart';
import '../../widgets/premium_dropdown.dart';

class PreferredPartnerPage extends StatefulWidget {
  const PreferredPartnerPage({super.key});

  @override
  State<PreferredPartnerPage> createState() => _PreferredPartnerPageState();
}

class _PreferredPartnerPageState extends State<PreferredPartnerPage> {
  final _formKey = GlobalKey<FormState>();

  RangeValues _ageRange = const RangeValues(25, 35);
  final List<String> _selectedRelationshipStatuses = ['Single'];
  String _selectedCountry = 'Nigeria';
  final List<String> _selectedStates = [];
  final List<String> _selectedTribes = [];
  String? _selectedReligion;
  String? _selectedZodiac;
  String? _selectedGenotype;
  String? _selectedBloodGroup;
  String? _selectedHeight;
  String? _selectedBodyType;
  bool? _preferredTattoos;
  bool? _preferredPiercings;

  // Deal breakers
  final Map<String, bool> _dealBreakers = {
    'relationshipStatus': false,
    'location': false,
    'religion': false,
    'zodiac': false,
    'genotype': false,
    'bloodGroup': false,
    'height': false,
    'bodyType': false,
    'tattoos': false,
    'piercings': false,
  };

  final List<String> _relationshipStatuses = [
    'Single',
    'Divorced',
    'Widowed',
    'Separated',
  ];
  final List<String> _countries = [
    'Nigeria',
    'Ghana',
    'Kenya',
    'South Africa',
    'USA',
    'UK',
  ];
  final List<String> _nigerianStates = [
    'Lagos',
    'Abuja',
    'Kano',
    'Rivers',
    'Oyo',
    'Ogun',
    'Edo',
    'Anambra',
    'Enugu',
  ];
  final List<String> _tribes = [
    'Yoruba',
    'Igbo',
    'Hausa',
    'Ijaw',
    'Fulani',
    'Edo',
  ];
  final List<String> _religions = [
    'Christianity',
    'Islam',
    'Traditional',
    'Other',
  ];
  final List<String> _zodiacs = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];
  final List<String> _genotypes = ['AA', 'AS', 'SS', 'AC'];
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
  final List<String> _heights = ['4\'0"', '5\'0"', '5\'6"', '6\'0"', '6\'6"'];
  final List<String> _bodyTypes = [
    'Slim',
    'Average',
    'Athletic',
    'Curvy',
    'Plus Size',
  ];

  final ProfileService _profileService = ProfileService();
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        // Prepare preferences data
        final preferencesData = {
          'ageMin': _ageRange.start.round(),
          'ageMax': _ageRange.end.round(),
          'ageIsDealBreaker': false, // Age is not typically a deal breaker
          'relationshipStatus': _selectedRelationshipStatuses,
          'relationshipIsDealBreaker': _dealBreakers['relationshipStatus'] ?? false,
          'locationCountry': _selectedCountry,
          'locationStates': _selectedStates,
          'locationTribes': _selectedTribes,
          'locationIsDealBreaker': _dealBreakers['location'] ?? false,
          if (_selectedReligion != null) 'religion': [_selectedReligion],
          'religionIsDealBreaker': _dealBreakers['religion'] ?? false,
          if (_selectedZodiac != null) 'zodiac': [_selectedZodiac],
          'zodiacIsDealBreaker': _dealBreakers['zodiac'] ?? false,
          if (_selectedGenotype != null) 'genotype': [_selectedGenotype],
          'genotypeIsDealBreaker': _dealBreakers['genotype'] ?? false,
          if (_selectedBloodGroup != null) 'bloodGroup': [_selectedBloodGroup],
          'bloodGroupIsDealBreaker': _dealBreakers['bloodGroup'] ?? false,
          if (_selectedBodyType != null) 'bodyType': [_selectedBodyType],
          'bodyTypeIsDealBreaker': _dealBreakers['bodyType'] ?? false,
          if (_preferredTattoos != null) 'tattoosAcceptable': _preferredTattoos,
          'tattoosIsDealBreaker': _dealBreakers['tattoos'] ?? false,
          if (_preferredPiercings != null) 'piercingsAcceptable': _preferredPiercings,
          'piercingsIsDealBreaker': _dealBreakers['piercings'] ?? false,
        };

        // Save preferences to backend
        await _profileService.savePreferences(preferencesData);

        // Navigate to home/dashboard
        if (mounted) {
          context.go('/video-verification');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save preferences: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/register_bg.png',
              fit: BoxFit.cover,
            ),
          ),
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
                            'Preferred Partner',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Step 4 of 5',
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
                                  // Age Range
                                  _buildSectionTitle('Age Range'),
                                  Text(
                                    '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFFF6B35),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  RangeSlider(
                                    values: _ageRange,
                                    min: 18,
                                    max: 70,
                                    divisions: 52,
                                    activeColor: const Color(0xFFFF6B35),
                                    inactiveColor: Colors.white.withOpacity(
                                      0.3,
                                    ),
                                    onChanged: (values) =>
                                        setState(() => _ageRange = values),
                                  ),
                                  const SizedBox(height: 20),

                                  // Relationship Status with Deal Breaker
                                  _buildMultiSelectWithDealBreaker(
                                    'Relationship Status',
                                    _selectedRelationshipStatuses,
                                    _relationshipStatuses,
                                    'relationshipStatus',
                                  ),
                                  const SizedBox(height: 14),

                                  // Location with Deal Breaker
                                  _buildDropdownWithDealBreaker(
                                    'Partner\'s Location',
                                    _selectedCountry,
                                    _countries,
                                    (v) =>
                                        setState(() => _selectedCountry = v!),
                                    'location',
                                  ),

                                  if (_selectedCountry == 'Nigeria') ...[
                                    const SizedBox(height: 14),
                                    _buildMultiSelectField(
                                      'Preferred States',
                                      _selectedStates,
                                      _nigerianStates,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildMultiSelectField(
                                      'Preferred Tribes',
                                      _selectedTribes,
                                      _tribes,
                                    ),
                                  ],

                                  const SizedBox(height: 14),

                                  // Religion with Deal Breaker
                                  _buildDropdownWithDealBreaker(
                                    'Preferred Religion',
                                    _selectedReligion,
                                    _religions,
                                    (v) =>
                                        setState(() => _selectedReligion = v),
                                    'religion',
                                  ),
                                  const SizedBox(height: 14),

                                  // Zodiac with Deal Breaker
                                  _buildDropdownWithDealBreaker(
                                    'Preferred Zodiac',
                                    _selectedZodiac,
                                    _zodiacs,
                                    (v) => setState(() => _selectedZodiac = v),
                                    'zodiac',
                                  ),
                                  const SizedBox(height: 14),

                                  // Genotype with Deal Breaker
                                  _buildDropdownWithDealBreaker(
                                    'Preferred Genotype',
                                    _selectedGenotype,
                                    _genotypes,
                                    (v) =>
                                        setState(() => _selectedGenotype = v),
                                    'genotype',
                                  ),
                                  const SizedBox(height: 14),

                                  // Blood Group with Deal Breaker
                                  _buildDropdownWithDealBreaker(
                                    'Preferred Blood Group',
                                    _selectedBloodGroup,
                                    _bloodGroups,
                                    (v) =>
                                        setState(() => _selectedBloodGroup = v),
                                    'bloodGroup',
                                  ),
                                  const SizedBox(height: 14),

                                  // Height with Deal Breaker
                                  _buildDropdownWithDealBreaker(
                                    'Preferred Height',
                                    _selectedHeight,
                                    _heights,
                                    (v) => setState(() => _selectedHeight = v),
                                    'height',
                                  ),
                                  const SizedBox(height: 14),

                                  // Body Type with Deal Breaker
                                  _buildDropdownWithDealBreaker(
                                    'Preferred Body Type',
                                    _selectedBodyType,
                                    _bodyTypes,
                                    (v) =>
                                        setState(() => _selectedBodyType = v),
                                    'bodyType',
                                  ),
                                  const SizedBox(height: 14),

                                  // Tattoos with Deal Breaker
                                  _buildBooleanWithDealBreaker(
                                    'Tattoos',
                                    _preferredTattoos,
                                    (v) =>
                                        setState(() => _preferredTattoos = v),
                                    'tattoos',
                                  ),
                                  const SizedBox(height: 14),

                                  // Piercings with Deal Breaker
                                  _buildBooleanWithDealBreaker(
                                    'Piercings',
                                    _preferredPiercings,
                                    (v) =>
                                        setState(() => _preferredPiercings = v),
                                    'piercings',
                                  ),

                                  const SizedBox(height: 24),

                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _continue,
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
                                      child: _isSaving
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : Text(
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildDropdownWithDealBreaker(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
    String dealBreakerKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Deal Breaker',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _dealBreakers[dealBreakerKey]!
                    ? const Color(0xFFFF6B35)
                    : Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: _dealBreakers[dealBreakerKey]!,
                onChanged: (v) =>
                    setState(() => _dealBreakers[dealBreakerKey] = v),
                activeColor: const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        PremiumDropdown(
          label: label,
          value: value,
          hint: 'Select',
          items: items,
          onChanged: onChanged,
          isDarkLabel: true,
        ),
      ],
    );
  }

  Widget _buildMultiSelectWithDealBreaker(
    String label,
    List<String> selectedValues,
    List<String> items,
    String dealBreakerKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Row(
              children: [
                Text(
                  'Deal Breaker',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _dealBreakers[dealBreakerKey]!,
                    onChanged: (v) =>
                        setState(() => _dealBreakers[dealBreakerKey] = v),
                    activeColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            border: _dealBreakers[dealBreakerKey]!
                ? Border.all(color: Colors.red, width: 2)
                : null,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = selectedValues.contains(item);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedValues.remove(item);
                    } else {
                      selectedValues.add(item);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6B35)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectField(
    String label,
    List<String> selectedValues,
    List<String> items,
  ) {
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = selectedValues.contains(item);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedValues.remove(item);
                    } else {
                      selectedValues.add(item);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6B35)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBooleanWithDealBreaker(
    String label,
    bool? value,
    ValueChanged<bool?> onChanged,
    String dealBreakerKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Row(
              children: [
                Text(
                  'Deal Breaker',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _dealBreakers[dealBreakerKey]!,
                    onChanged: (v) =>
                        setState(() => _dealBreakers[dealBreakerKey] = v),
                    activeColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            border: _dealBreakers[dealBreakerKey]!
                ? Border.all(color: Colors.red, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: value == true
                          ? const Color(0xFFFF6B35)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Yes',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: value == true ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: value == false
                          ? const Color(0xFFFF6B35)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'No',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: value == false ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: value == null
                          ? const Color(0xFFFF6B35)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Any',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: value == null ? Colors.white : Colors.black,
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
    );
  }
}
