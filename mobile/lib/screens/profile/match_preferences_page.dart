import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class MatchPreferencesPage extends StatefulWidget {
  const MatchPreferencesPage({super.key});

  @override
  State<MatchPreferencesPage> createState() => _MatchPreferencesPageState();
}

class _MatchPreferencesPageState extends State<MatchPreferencesPage> {
  final _formKey = GlobalKey<FormState>();

  RangeValues _ageRange = const RangeValues(25, 35);
  final List<String> _selectedRelationshipStatuses = ['Single'];
  String _selectedCountry = 'Nigeria';
  final List<String> _selectedStates = ['Lagos', 'Abuja'];
  final List<String> _selectedTribes = ['Yoruba'];
  String? _selectedReligion = 'Christianity';
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
    'religion': true,
    'zodiac': false,
    'genotype': true,
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

  void _savePreferences() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match preferences updated successfully!'),
          backgroundColor: AppTheme.primary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Match Preferences',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Toggle "Deal Breaker" for must-have preferences',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AGE RANGE
                _buildSectionCard('Age Range', Icons.calendar_today, [
                  Text(
                    '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primary,
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
                    activeColor: AppTheme.primary,
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
                    'Partner\'s Location',
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
                      'Preferred Tribes',
                      _selectedTribes,
                      _tribes,
                    ),
                  ],
                ]),

                const SizedBox(height: 16),

                // RELIGION & ZODIAC
                _buildSectionCard('Religion & Zodiac', Icons.auto_awesome, [
                  _buildDropdownWithDealBreaker(
                    'Preferred Religion',
                    _selectedReligion,
                    _religions,
                    (v) => setState(() => _selectedReligion = v),
                    'religion',
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownWithDealBreaker(
                    'Preferred Zodiac',
                    _selectedZodiac,
                    _zodiacs,
                    (v) => setState(() => _selectedZodiac = v),
                    'zodiac',
                  ),
                ]),

                const SizedBox(height: 16),

                // MEDICAL
                _buildSectionCard(
                  'Medical Preferences',
                  Icons.medical_services,
                  [
                    _buildDropdownWithDealBreaker(
                      'Preferred Genotype',
                      _selectedGenotype,
                      _genotypes,
                      (v) => setState(() => _selectedGenotype = v),
                      'genotype',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownWithDealBreaker(
                      'Preferred Blood Group',
                      _selectedBloodGroup,
                      _bloodGroups,
                      (v) => setState(() => _selectedBloodGroup = v),
                      'bloodGroup',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PHYSICAL
                _buildSectionCard('Physical Preferences', Icons.face, [
                  _buildDropdownWithDealBreaker(
                    'Preferred Height',
                    _selectedHeight,
                    _heights,
                    (v) => setState(() => _selectedHeight = v),
                    'height',
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownWithDealBreaker(
                    'Preferred Body Type',
                    _selectedBodyType,
                    _bodyTypes,
                    (v) => setState(() => _selectedBodyType = v),
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

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Preferences',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
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
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 22),
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
                    activeColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _dealBreakers[dealBreakerKey]!
                  ? Colors.red
                  : Colors.grey[300]!,
              width: _dealBreakers[dealBreakerKey]! ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Select',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 22,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
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
                    activeColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _dealBreakers[dealBreakerKey]!
                  ? Colors.red
                  : Colors.grey[300]!,
              width: _dealBreakers[dealBreakerKey]! ? 2 : 1,
            ),
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
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.black87,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
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
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.black87,
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
                    activeColor: Colors.red,
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
                  ? Colors.red
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
                          ? AppTheme.primary
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
                          ? AppTheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'No',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value == false ? Colors.white : Colors.black87,
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
                          ? AppTheme.primary
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
