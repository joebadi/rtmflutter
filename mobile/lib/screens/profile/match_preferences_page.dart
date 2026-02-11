import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/match_service.dart';
import '../../widgets/premium_dropdown.dart';
import '../../widgets/premium_multi_select.dart';
import '../../widgets/premium_loader.dart';

class MatchPreferencesPage extends StatefulWidget {
  const MatchPreferencesPage({super.key});

  @override
  State<MatchPreferencesPage> createState() => _MatchPreferencesPageState();
}

class _MatchPreferencesPageState extends State<MatchPreferencesPage> {
  final _formKey = GlobalKey<FormState>();
  final _matchService = MatchService();
  bool _isLoading = false;

  RangeValues _ageRange = const RangeValues(18, 50);
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  String _heightLabel(int index) {
    if (index < 0 || index >= _heights.length) return '';
    return _heights[index].split(' (').first;
  }

  int _heightToCm(int index) {
    if (index < 0 || index >= _heights.length) return 0;
    final match = RegExp(r'\((\d+) cm\)').firstMatch(_heights[index]);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  int _cmToHeightIndex(int? cm) {
    if (cm == null || cm <= 0) return -1;
    for (int i = 0; i < _heights.length; i++) {
      final match = RegExp(r'\((\d+) cm\)').firstMatch(_heights[i]);
      if (match != null && int.parse(match.group(1)!) == cm) return i;
    }
    int closest = 0;
    int minDiff = 999;
    for (int i = 0; i < _heights.length; i++) {
      final match = RegExp(r'\((\d+) cm\)').firstMatch(_heights[i]);
      if (match != null) {
        final diff = (int.parse(match.group(1)!) - cm).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = i;
        }
      }
    }
    return closest;
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final data = await _matchService.getPreferences();
      if (data.isNotEmpty) {
        setState(() {
          if (data['ageMin'] != null && data['ageMax'] != null) {
            _ageRange = RangeValues(
              (data['ageMin'] as num).toDouble(),
              (data['ageMax'] as num).toDouble(),
            );
          }
          if (data['locationCountry'] != null) {
            _selectedCountry = data['locationCountry'];
          }

          void loadList(String key, List<String> target) {
            if (data[key] != null && data[key] is List) {
              target.clear();
              target.addAll((data[key] as List).map((e) => e.toString()));
            }
          }

          loadList('relationshipStatus', _selectedRelationshipStatuses);
          loadList('locationStates', _selectedStates);
          loadList('locationTribes', _selectedTribes);
          loadList('religion', _selectedReligions);
          loadList('zodiac', _selectedZodiacs);
          loadList('genotype', _selectedGenotypes);
          loadList('bloodGroup', _selectedBloodGroups);
          loadList('bodyType', _selectedBodyTypes);

          // Height range (stored as cm integers)
          final minIdx = _cmToHeightIndex(
            data['heightMin'] is num ? (data['heightMin'] as num).toInt() : null,
          );
          final maxIdx = _cmToHeightIndex(
            data['heightMax'] is num ? (data['heightMax'] as num).toInt() : null,
          );
          if (minIdx >= 0 && maxIdx >= 0 && maxIdx >= minIdx) {
            _heightRange = RangeValues(minIdx.toDouble(), maxIdx.toDouble());
          }

          // Tattoos/Piercings
          if (data['tattoosAcceptable'] != null) {
            _preferredTattoos = data['tattoosAcceptable'] as bool;
          }
          if (data['piercingsAcceptable'] != null) {
            _preferredPiercings = data['piercingsAcceptable'] as bool;
          }

          // Deal breakers
          _dealBreakers['relationshipStatus'] =
              data['relationshipIsDealBreaker'] ?? false;
          _dealBreakers['location'] =
              data['locationIsDealBreaker'] ?? false;
          _dealBreakers['religion'] =
              data['religionIsDealBreaker'] ?? false;
          _dealBreakers['zodiac'] =
              data['zodiacIsDealBreaker'] ?? false;
          _dealBreakers['genotype'] =
              data['genotypeIsDealBreaker'] ?? false;
          _dealBreakers['bloodGroup'] =
              data['bloodGroupIsDealBreaker'] ?? false;
          _dealBreakers['height'] =
              data['heightIsDealBreaker'] ?? false;
          _dealBreakers['bodyType'] =
              data['bodyTypeIsDealBreaker'] ?? false;
          _dealBreakers['tattoos'] =
              data['tattoosIsDealBreaker'] ?? false;
          _dealBreakers['piercings'] =
              data['piercingsIsDealBreaker'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'ageMin': _ageRange.start.round(),
        'ageMax': _ageRange.end.round(),
        'ageIsDealBreaker': false,
        'locationCountry': _selectedCountry,
        'locationStates': _selectedStates,
        'locationTribes': _selectedTribes,
        'locationIsDealBreaker': _dealBreakers['location'] ?? false,
        'relationshipStatus': _selectedRelationshipStatuses,
        'relationshipIsDealBreaker':
            _dealBreakers['relationshipStatus'] ?? false,
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

      final success = await _matchService.updatePreferences(data);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match preferences updated successfully!'),
            backgroundColor: Color(0xFFFF6B35),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update preferences'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: PremiumLoader(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Match Preferences',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFF6B35),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Toggle "Deal Breaker" for must-have preferences',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AGE RANGE
                _buildSectionCard('Preferred Age Range', Icons.calendar_today, [
                  Text(
                    '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF6B35),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 70,
                    divisions: 52,
                    activeColor: const Color(0xFFFF6B35),
                    inactiveColor: Colors.grey[300],
                    labels: RangeLabels(
                      _ageRange.start.round().toString(),
                      _ageRange.end.round().toString(),
                    ),
                    onChanged: (values) => setState(() => _ageRange = values),
                  ),
                ]),

                const SizedBox(height: 16),

                // RELATIONSHIP & LOCATION
                _buildSectionCard('Relationship & Location', Icons.favorite, [
                  _buildMultiSelectWithDealBreaker(
                    'Relationship Status',
                    _selectedRelationshipStatuses,
                    _relationshipStatuses,
                    'relationshipStatus',
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownWithDealBreaker(
                    'Preferred Partner Location',
                    _selectedCountry,
                    _countries,
                    (v) => setState(() => _selectedCountry = v!),
                    'location',
                  ),
                  if (_selectedCountry == 'Nigeria') ...[
                    const SizedBox(height: 16),
                    _buildMultiSelectField(
                      'Preferred States',
                      _selectedStates,
                      _nigerianStates,
                    ),
                    const SizedBox(height: 16),
                    _buildMultiSelectField(
                      'Preferred Tribe(s)',
                      _selectedTribes,
                      _tribes,
                    ),
                  ],
                ]),

                const SizedBox(height: 16),

                // RELIGION & ZODIAC
                _buildSectionCard('Religion & Zodiac', Icons.auto_awesome, [
                  _buildMultiSelectWithDealBreaker(
                    'Preferred Religion',
                    _selectedReligions,
                    _religions,
                    'religion',
                  ),
                  const SizedBox(height: 16),
                  _buildMultiSelectWithDealBreaker(
                    'Preferred Zodiac',
                    _selectedZodiacs,
                    _zodiacs,
                    'zodiac',
                  ),
                ]),

                const SizedBox(height: 16),

                // MEDICAL
                _buildSectionCard(
                  'Medical Preferences',
                  Icons.medical_services,
                  [
                    _buildMultiSelectWithDealBreaker(
                      'Preferred Genotype',
                      _selectedGenotypes,
                      _genotypes,
                      'genotype',
                    ),
                    const SizedBox(height: 16),
                    _buildMultiSelectWithDealBreaker(
                      'Preferred Blood Group',
                      _selectedBloodGroups,
                      _bloodGroups,
                      'bloodGroup',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PHYSICAL
                _buildSectionCard('Physical Preferences', Icons.face, [
                  _buildHeightRangeWithDealBreaker(),
                  const SizedBox(height: 16),
                  _buildMultiSelectWithDealBreaker(
                    'Preferred Body Type',
                    _selectedBodyTypes,
                    _bodyTypes,
                    'bodyType',
                  ),
                  const SizedBox(height: 16),
                  _buildBooleanWithDealBreaker(
                    'Tattoos',
                    _preferredTattoos,
                    (v) => setState(() => _preferredTattoos = v),
                    'tattoos',
                  ),
                  const SizedBox(height: 16),
                  _buildBooleanWithDealBreaker(
                    'Piercings',
                    _preferredPiercings,
                    (v) => setState(() => _preferredPiercings = v),
                    'piercings',
                  ),
                ]),

                const SizedBox(height: 48),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFFFF6B35).withOpacity(0.4),
                    ),
                    child: Text(
                      'Save Preferences',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFFF6B35), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
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
                    : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.75,
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
                    : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.75,
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
                    : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.75,
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
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Row(
              children: [
                Text(
                  'Deal Breaker',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _dealBreakers[dealBreakerKey]!,
                    onChanged: (v) =>
                        setState(() => _dealBreakers[dealBreakerKey] = v),
                    activeColor: const Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _dealBreakers[dealBreakerKey]!
                  ? const Color(0xFFFF6B35)
                  : Colors.grey[300]!,
              width: _dealBreakers[dealBreakerKey]! ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: value == true
                          ? const Color(0xFFFF6B35)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Yes',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value == true ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: value == false
                          ? const Color(0xFFFF6B35)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'No',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              value == false ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: value == null
                          ? const Color(0xFFFF6B35)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Any',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value == null ? Colors.white : Colors.black87,
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
