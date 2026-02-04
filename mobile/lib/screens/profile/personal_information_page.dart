import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _aboutMeCtrl = TextEditingController(text: 'I love traveling and meeting new people...');
  final _hobbiesCtrl = TextEditingController(text: 'Reading, Hiking, Cooking');
  final _locationCtrl = TextEditingController(text: 'Lagos, Lagos State, Nigeria');
  final _dobCtrl = TextEditingController(text: '15/03/1995');
  
  // Dropdowns
  String _gender = 'Male';
  String _relationshipStatus = 'Single';
  String _preferredLanguage = 'English';
  String _workStatus = 'Employed';
  String _educationLevel = 'Bachelor\'s Degree';
  String _religion = 'Christianity';
  String _genotype = 'AA';
  String _bloodGroup = 'O+';
  String _height = '5\'6"';
  String _bodyType = 'Athletic';
  String _skinColor = 'Brown';
  String _eyeColor = 'Brown';
  String _personalityType = 'Extrovert';
  
  // Ethnicity fields
  String? _ethnicityCountry;
  String? _ethnicityState;
  String? _tribe;
  
  // Calculated fields
  int? _calculatedAge;
  String? _calculatedZodiac;
  
  // Booleans
  bool _hasTattoos = false;
  bool _hasPiercings = false;
  bool _isHairy = false;
  bool _hasTribalMarks = false;
  
  // Lists
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _relationshipStatuses = ['Single', 'Separated', 'Divorced', 'Widowed'];
  final List<String> _languages = ['English', 'Yoruba', 'Igbo', 'Hausa', 'French'];
  final List<String> _workStatuses = ['Employed', 'Self-employed', 'Student', 'Unemployed'];
  final List<String> _educationLevels = ['High School', 'Bachelor\'s Degree', 'Master\'s Degree', 'PhD'];
  final List<String> _religions = ['Christianity', 'Islam', 'Traditional', 'Other'];
  final List<String> _genotypes = ['AA', 'AS', 'SS', 'AC'];
  final List<String> _bloodGroups = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  final List<String> _heights = ['4\'0"', '5\'0"', '5\'6"', '6\'0"', '6\'6"'];
  final List<String> _bodyTypes = ['Slim', 'Average', 'Athletic', 'Curvy', 'Plus Size'];
  final List<String> _skinColors = ['Fair', 'Light Brown', 'Brown', 'Dark Brown', 'Dark'];
  final List<String> _eyeColors = ['Brown', 'Black', 'Blue', 'Green', 'Hazel'];
  final List<String> _personalityTypes = ['Extrovert', 'Introvert', 'Ambivert'];
  
  // Ethnicity lists
  final List<String> _countries = ['Nigeria', 'Ghana', 'Kenya', 'South Africa', 'USA', 'UK', 'Canada'];
  final List<String> _nigerianStates = [
    'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno',
    'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'FCT', 'Gombe', 'Imo',
    'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa',
    'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto', 'Taraba',
    'Yobe', 'Zamfara'
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

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal information updated successfully!'),
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
          'Personal Information',
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
                // PHOTO GALLERY SECTION
                _buildSectionCard(
                  'Profile Photos',
                  Icons.photo_library,
                  [
                    Text(
                      'Add up to 6 photos to your profile',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        // Placeholder for photo slots
                        final hasPhoto = index == 0; // First slot has photo (placeholder)
                        return GestureDetector(
                          onTap: () {
                            // TODO: Implement photo picker
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Photo picker coming soon!')),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasPhoto ? AppTheme.primary : Colors.grey[300]!,
                                width: hasPhoto ? 2 : 1,
                              ),
                              image: hasPhoto
                                  ? const DecorationImage(
                                      image: NetworkImage(
                                        'https://randomuser.me/api/portraits/men/32.jpg',
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: hasPhoto
                                ? Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          // TODO: Remove photo
                                        },
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        color: Colors.grey[400],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add Photo',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // BASIC INFO
                _buildSectionCard(
                  'Basic Information',
                  Icons.person,
                  [
                    _buildTextArea(
                      controller: _aboutMeCtrl,
                      label: 'About Me',
                      hint: 'Tell us about yourself...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildTextArea(
                      controller: _hobbiesCtrl,
                      label: 'Hobbies & Interests',
                      hint: 'What do you enjoy doing?',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationCtrl,
                      label: 'Location',
                      hint: 'City, State, Country',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _dobCtrl,
                            label: 'Date of Birth',
                            hint: 'DD/MM/YYYY',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Gender',
                            _gender,
                            _genders,
                            (v) => setState(() => _gender = v!),
                          ),
                        ),
                      ],
                    ),
                    // Age and Zodiac (readonly, calculated from DOB)
                    if (_calculatedAge != null) ...[ 
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildReadOnlyField('Age', '$_calculatedAge years'),
                          ),
                          if (_calculatedZodiac != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReadOnlyField('Zodiac Sign', _calculatedZodiac!),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // ETHNICITY SECTION
                _buildSectionCard(
                  'Ethnicity',
                  Icons.public,
                  [
                    _buildDropdown(
                      'Country of Origin',
                      _ethnicityCountry ?? 'Select Country',
                      _countries,
                      (v) => setState(() {
                        _ethnicityCountry = v;
                        _ethnicityState = null;
                        _tribe = null;
                      }),
                    ),
                    
                    // Conditional State for Nigeria
                    if (_ethnicityCountry == 'Nigeria') ...[
                      const SizedBox(height: 16),
                      _buildDropdown(
                        'State of Origin',
                        _ethnicityState ?? 'Select State',
                        _nigerianStates,
                        (v) => setState(() {
                          _ethnicityState = v;
                          _tribe = null;
                        }),
                      ),
                      
                      // Conditional Tribe for selected state
                      if (_ethnicityState != null && _stateTribes[_ethnicityState] != null) ...[
                        const SizedBox(height: 16),
                        _buildDropdown(
                          'Tribe',
                          _tribe ?? 'Select Tribe',
                          _stateTribes[_ethnicityState]!,
                          (v) => setState(() => _tribe = v),
                        ),
                      ],
                    ],
                    
                    // For other countries, just show state text field
                    if (_ethnicityCountry != null && _ethnicityCountry != 'Nigeria') ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: TextEditingController(),
                        label: 'State/Province',
                        hint: 'Enter your state',
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // PERSONAL DETAILS
                _buildSectionCard(
                  'Personal Details',
                  Icons.info,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Relationship Status',
                            _relationshipStatus,
                            _relationshipStatuses,
                            (v) => setState(() => _relationshipStatus = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Language',
                            _preferredLanguage,
                            _languages,
                            (v) => setState(() => _preferredLanguage = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Work Status',
                            _workStatus,
                            _workStatuses,
                            (v) => setState(() => _workStatus = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Education',
                            _educationLevel,
                            _educationLevels,
                            (v) => setState(() => _educationLevel = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Religion',
                      _religion,
                      _religions,
                      (v) => setState(() => _religion = v!),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Personality Type',
                      _personalityType,
                      _personalityTypes,
                      (v) => setState(() => _personalityType = v!),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PHYSICAL ATTRIBUTES
                _buildSectionCard(
                  'Physical Attributes',
                  Icons.face,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Height',
                            _height,
                            _heights,
                            (v) => setState(() => _height = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Body Type',
                            _bodyType,
                            _bodyTypes,
                            (v) => setState(() => _bodyType = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Skin Color',
                            _skinColor,
                            _skinColors,
                            (v) => setState(() => _skinColor = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Eye Color',
                            _eyeColor,
                            _eyeColors,
                            (v) => setState(() => _eyeColor = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile('Tattoos', _hasTattoos, (v) => setState(() => _hasTattoos = v)),
                    const SizedBox(height: 8),
                    _buildSwitchTile('Piercings', _hasPiercings, (v) => setState(() => _hasPiercings = v)),
                    const SizedBox(height: 8),
                    _buildSwitchTile('Hairy', _isHairy, (v) => setState(() => _isHairy = v)),
                    const SizedBox(height: 8),
                    _buildSwitchTile('Tribal Marks', _hasTribalMarks, (v) => setState(() => _hasTribalMarks = v)),
                  ],
                ),

                const SizedBox(height: 16),

                // MEDICAL INFO
                _buildSectionCard(
                  'Medical Information',
                  Icons.medical_services,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Genotype',
                            _genotype,
                            _genotypes,
                            (v) => setState(() => _genotype = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Blood Group',
                            _bloodGroup,
                            _bloodGroups,
                            (v) => setState(() => _bloodGroup = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
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
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
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
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
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
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 22),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
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
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
