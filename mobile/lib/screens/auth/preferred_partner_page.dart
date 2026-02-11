import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/profile_service.dart';
import '../../widgets/premium_dropdown.dart';
import '../../widgets/premium_multi_select.dart';
import '../../widgets/premium_loader.dart';

class PreferredPartnerPage extends StatefulWidget {
  const PreferredPartnerPage({super.key});

  @override
  State<PreferredPartnerPage> createState() => _PreferredPartnerPageState();
}

class _PreferredPartnerPageState extends State<PreferredPartnerPage> {
  final _formKey = GlobalKey<FormState>();

  RangeValues _ageRange = const RangeValues(25, 35);
  final List<String> _selectedRelationshipStatuses = [];
  String _selectedCountry = 'Nigeria';
  final List<String> _selectedStates = [];
  final List<String> _selectedTribes = [];
  final List<String> _selectedReligions = [];
  final List<String> _selectedZodiacs = [];
  final List<String> _selectedGenotypes = [];
  final List<String> _selectedBloodGroups = [];
  RangeValues _heightRange = const RangeValues(4, 19); // 5'0" to 6'0" default
  final List<String> _selectedBodyTypes = [];
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
  final List<String> _tribes = [
    'Annang',
    'Awori',
    'Bachama',
    'Berom',
    'Bini',
    'Chamba',
    'Ebira',
    'Edo',
    'Efik',
    'Egba',
    'Egun',
    'Ejagham',
    'Esan',
    'Fulani',
    'Gbagyi',
    'Hausa',
    'Ibibio',
    'Idoma',
    'Igala',
    'Igbo',
    'Ijaw',
    'Ijebu',
    'Ikwerre',
    'Isoko',
    'Itsekiri',
    'Jukun',
    'Kalabari',
    'Kanuri',
    'Kilba',
    'Margi',
    'Mumuye',
    'Nupe',
    'Ogoni',
    'Oron',
    'Tiv',
    'Urhobo',
    'Yoruba',
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
    'Petite',
    'Average',
    'Athletic',
    'Muscular',
    'Curvy',
    'Stocky',
    'Full-figured',
    'Heavyset',
  ];

  final ProfileService _profileService = ProfileService();
  bool _isSaving = false;

  String _heightLabel(int index) {
    if (index < 0 || index >= _heights.length) return '';
    return _heights[index].split(' (').first;
  }

  int _heightToCm(int index) {
    if (index < 0 || index >= _heights.length) return 0;
    final match = RegExp(r'\((\d+) cm\)').firstMatch(_heights[index]);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<void> _continue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final preferencesData = {
          'ageMin': _ageRange.start.round(),
          'ageMax': _ageRange.end.round(),
          'ageIsDealBreaker': false,
          'relationshipStatus': _selectedRelationshipStatuses,
          'relationshipIsDealBreaker':
              _dealBreakers['relationshipStatus'] ?? false,
          'locationCountry': _selectedCountry,
          'locationStates': _selectedStates,
          'locationTribes': _selectedTribes,
          'locationIsDealBreaker': _dealBreakers['location'] ?? false,
          'religion': _selectedReligions,
          'religionIsDealBreaker': _dealBreakers['religion'] ?? false,
          'zodiac': _selectedZodiacs,
          'zodiacIsDealBreaker': _dealBreakers['zodiac'] ?? false,
          'genotype': _selectedGenotypes,
          'genotypeIsDealBreaker': _dealBreakers['genotype'] ?? false,
          'bloodGroup': _selectedBloodGroups,
          'bloodGroupIsDealBreaker': _dealBreakers['bloodGroup'] ?? false,
          'heightMin': _heightToCm(_heightRange.start.round()),
          'heightMax': _heightToCm(_heightRange.end.round()),
          'heightIsDealBreaker': _dealBreakers['height'] ?? false,
          'bodyType': _selectedBodyTypes,
          'bodyTypeIsDealBreaker': _dealBreakers['bodyType'] ?? false,
          if (_preferredTattoos != null) 'tattoosAcceptable': _preferredTattoos,
          'tattoosIsDealBreaker': _dealBreakers['tattoos'] ?? false,
          if (_preferredPiercings != null)
            'piercingsAcceptable': _preferredPiercings,
          'piercingsIsDealBreaker': _dealBreakers['piercings'] ?? false,
        };

        await _profileService.savePreferences(preferencesData);

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
                                  _buildSectionTitle('Preferred Age Range'),
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

                                  // Relationship Status - multiselect
                                  _buildMultiSelectWithDealBreaker(
                                    'Relationship Status',
                                    _selectedRelationshipStatuses,
                                    _relationshipStatuses,
                                    'relationshipStatus',
                                  ),
                                  const SizedBox(height: 14),

                                  // Location
                                  _buildDropdownWithDealBreaker(
                                    'Preferred Partner Location',
                                    _selectedCountry,
                                    _countries,
                                    (v) => setState(
                                        () => _selectedCountry = v!),
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
                                      'Preferred Tribe(s)',
                                      _selectedTribes,
                                      _tribes,
                                    ),
                                  ],

                                  const SizedBox(height: 14),

                                  // Religion - multiselect
                                  _buildMultiSelectWithDealBreaker(
                                    'Preferred Religion',
                                    _selectedReligions,
                                    _religions,
                                    'religion',
                                  ),
                                  const SizedBox(height: 14),

                                  // Zodiac - multiselect
                                  _buildMultiSelectWithDealBreaker(
                                    'Preferred Zodiac',
                                    _selectedZodiacs,
                                    _zodiacs,
                                    'zodiac',
                                  ),
                                  const SizedBox(height: 14),

                                  // Genotype - multiselect
                                  _buildMultiSelectWithDealBreaker(
                                    'Preferred Genotype',
                                    _selectedGenotypes,
                                    _genotypes,
                                    'genotype',
                                  ),
                                  const SizedBox(height: 14),

                                  // Blood Group - multiselect
                                  _buildMultiSelectWithDealBreaker(
                                    'Preferred Blood Group',
                                    _selectedBloodGroups,
                                    _bloodGroups,
                                    'bloodGroup',
                                  ),
                                  const SizedBox(height: 14),

                                  // Height - range slider
                                  _buildHeightRangeWithDealBreaker(),
                                  const SizedBox(height: 14),

                                  // Body Type - multiselect
                                  _buildMultiSelectWithDealBreaker(
                                    'Preferred Body Type',
                                    _selectedBodyTypes,
                                    _bodyTypes,
                                    'bodyType',
                                  ),
                                  const SizedBox(height: 14),

                                  // Tattoos
                                  _buildBooleanWithDealBreaker(
                                    'Tattoos',
                                    _preferredTattoos,
                                    (v) => setState(
                                        () => _preferredTattoos = v),
                                    'tattoos',
                                  ),
                                  const SizedBox(height: 14),

                                  // Piercings
                                  _buildBooleanWithDealBreaker(
                                    'Piercings',
                                    _preferredPiercings,
                                    (v) => setState(
                                        () => _preferredPiercings = v),
                                    'piercings',
                                  ),

                                  const SizedBox(height: 24),

                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isSaving ? null : _continue,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFF6B35,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child:
                                                  PremiumLoader(
                                                strokeWidth: 2,
                                                color: Colors.white,
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
          hint: 'Any',
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
        PremiumMultiSelect(
          label: label,
          selectedValues: selectedValues,
          items: items,
          hint: 'Any',
          onChanged: (values) => setState(() {
            selectedValues.clear();
            selectedValues.addAll(values);
          }),
          isDarkLabel: true,
        ),
      ],
    );
  }

  Widget _buildMultiSelectField(
    String label,
    List<String> selectedValues,
    List<String> items,
  ) {
    return PremiumMultiSelect(
      label: label,
      selectedValues: selectedValues,
      items: items,
      hint: 'Any',
      onChanged: (values) => setState(() {
        selectedValues.clear();
        selectedValues.addAll(values);
      }),
      isDarkLabel: true,
    );
  }

  Widget _buildHeightRangeWithDealBreaker() {
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
                color: _dealBreakers['height']!
                    ? const Color(0xFFFF6B35)
                    : Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: _dealBreakers['height']!,
                onChanged: (v) =>
                    setState(() => _dealBreakers['height'] = v),
                activeColor: const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        Text(
          'Preferred Height',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFF5722).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _heightLabel(_heightRange.start.round()),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF5722),
                    ),
                  ),
                  Text(
                    'to',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    _heightLabel(_heightRange.end.round()),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF5722),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFFF6B35),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: const Color(0xFFFF6B35),
                  overlayColor: const Color(0xFFFF6B35).withOpacity(0.2),
                  trackHeight: 4,
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                ),
                child: RangeSlider(
                  values: _heightRange,
                  min: 0,
                  max: (_heights.length - 1).toDouble(),
                  divisions: _heights.length - 1,
                  onChanged: (values) =>
                      setState(() => _heightRange = values),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _heights.first.split(' (').first,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    _heights.last.split(' (').first,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
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
