import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isFirstLoad = true; // Track if this is the first time loading

  // Photos
  List<dynamic> _photos = [];
  final ImagePicker _picker = ImagePicker();

  // Quick Introduction
  final _aboutMeCtrl = TextEditingController();
  final _hobbiesCtrl = TextEditingController();
  
  // ... (keeping other fields) ...
  String _relationshipStatus = 'Single';
  String _preferredLanguage = 'English';
  String _workStatus = 'Employed';
  String _educationLevel = 'Bachelor\'s Degree';

  // Lifestyle
  String _drinkStatus = 'Socially';
  String _smokeStatus = 'No';
  String _childrenStatus = 'No';
  String _livingConditions = 'Alone';

  // Personality
  String _personalityType = 'Extrovert';
  String _hivPartnerView = 'Open to discussion';
  String _divorceView = 'Acceptable';

  // Looks
  String _skinColor = 'Brown';
  String _eyeColor = 'Brown';
  String _hairyStatus = 'No';
  String _tribalMarks = 'No';
  String _bestFeature = 'Eyes';

  // Bio

  // Location
  final _locationCtrl = TextEditingController();

  // Medical Info
  String _genotype = 'AA';
  String _bloodGroup = 'O+';

  // Lists
  final List<String> _relationshipStatuses = [
    'Single',
    'Separated',
    'Divorced',
    'Widowed',
  ];
  final List<String> _languages = [
    'English',
    'Yoruba',
    'Igbo',
    'Hausa',
    'French',
    'Other',
  ];
  final List<String> _workStatuses = [
    'Employed',
    'Self-employed',
    'Student',
    'Unemployed',
    'Retired',
  ];
  final List<String> _educationLevels = [
    'High School',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Other',
  ];
  final List<String> _drinkOptions = ['Yes', 'No', 'Socially', 'Occasionally'];
  final List<String> _smokeOptions = ['Yes', 'No', 'Occasionally'];
  final List<String> _childrenOptions = ['Yes', 'No', 'Want children'];
  final List<String> _livingOptions = [
    'Alone',
    'With parents',
    'With roommate',
    'With partner',
  ];
  final List<String> _personalityTypes = ['Extrovert', 'Introvert', 'Ambivert'];
  final List<String> _hivViews = ['Yes', 'No', 'Open to discussion'];
  final List<String> _divorceViews = [
    'Acceptable',
    'Not acceptable',
    'Depends',
  ];
  final List<String> _skinColors = [
    'Fair',
    'Light Brown',
    'Brown',
    'Dark Brown',
    'Dark',
  ];
  final List<String> _eyeColors = ['Brown', 'Black', 'Blue', 'Green', 'Hazel'];
  final List<String> _yesNoOptions = ['Yes', 'No'];
  final List<String> _bestFeatures = [
    'Eyes',
    'Smile',
    'Hair',
    'Body',
    'Legs',
    'Arms',
    'Face',
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

  // Ethnicity fields
  String? _ethnicityCountry;
  String? _ethnicityState;
  String? _tribe;

  // Calculated fields

  // Ethnicity lists
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

  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _profileService.getMyProfile();
      if (response != null && response['data'] != null) {
        final data = response['data'];
        final profile = data['profile'];

        if (profile != null) {
          setState(() {
             // Photos
             _photos = (profile['photos'] as List?) ?? [];
             
             // Text Controllers
             _aboutMeCtrl.text = profile['aboutMe'] ?? '';
             _hobbiesCtrl.text = profile['hobbies'] ?? '';
             
             // Location Reconstruction
             // Map backend city/state/country to location string
             String loc = '';
             if (profile['city'] != null && profile['city'].toString().isNotEmpty) {
               loc += profile['city'];
             }
             if (profile['state'] != null && profile['state'].toString().isNotEmpty) {
               loc += (loc.isEmpty ? '' : ', ') + profile['state'];
             }
             if (profile['country'] != null && profile['country'].toString().isNotEmpty) {
               loc += (loc.isEmpty ? '' : ', ') + profile['country'];
             }
             // If constructed location is empty, checking if 'location' field exists just in case
             if (loc.isEmpty && profile['location'] != null && profile['location'] is String) {
               loc = profile['location'];
             }
             _locationCtrl.text = loc;

            // Dropdowns
            // Use ?? to provide default only if null, but if value exists ensure it matches list
            if (profile['relationshipStatus'] != null) _relationshipStatus = profile['relationshipStatus'];
            if (profile['language'] != null) _preferredLanguage = profile['language'];
            if (profile['workStatus'] != null) _workStatus = profile['workStatus'];
            if (profile['education'] != null) _educationLevel = profile['education'];
            
            // Ethnicity
            // Map backend 'stateOfOrigin' back to frontend '_ethnicityState'
            _ethnicityCountry = profile['ethnicityCountry'];
            _ethnicityState = profile['stateOfOrigin']; 
            _tribe = profile['tribe'];

            // Lifestyle
            if (profile['drinkingStatus'] != null) _drinkStatus = profile['drinkingStatus'];
            if (profile['smokingStatus'] != null) _smokeStatus = profile['smokingStatus'];
            if (profile['hasChildren'] != null) _childrenStatus = profile['hasChildren'];
            if (profile['livingConditions'] != null) _livingConditions = profile['livingConditions'];

            // Personality
            if (profile['personalityType'] != null) _personalityType = profile['personalityType'];
            if (profile['divorceView'] != null) _divorceView = profile['divorceView'];
            if (profile['hivPartnerView'] != null) _hivPartnerView = profile['hivPartnerView'];

            // Looks
            if (profile['skinColor'] != null) _skinColor = profile['skinColor'];
            if (profile['eyeColor'] != null) _eyeColor = profile['eyeColor'];
            if (profile['isHairy'] != null) _hairyStatus = profile['isHairy'] == true ? 'Yes' : 'No';
            if (profile['hasTribalMarks'] != null) _tribalMarks = profile['hasTribalMarks'] == true ? 'Yes' : 'No';
             if (profile['bestFeature'] != null) _bestFeature = profile['bestFeature'];

            // Medical
            if (profile['genotype'] != null) _genotype = profile['genotype'];
            if (profile['bloodGroup'] != null) _bloodGroup = profile['bloodGroup'];
            
            // If we have data, it's not strictly first load logic for routing, 
            // but we still want to redirect to home on save if they came from login.
            // For now, keep _isFirstLoad logic as is or adjust if needed.
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await _profileService.uploadPhoto(image.path);
      // Backend returns the created photo object
      // Assuming response['data'] is the photo object or response IS the photo object
      // API response structure: { message: "...", data: { ...photo... } } usually? 
      // Checking uploadPhoto implementation: returns response.data directly.
      // Need to refresh profile to get updated list OR just append to list if I know the structure.
      // Safest is to refresh profile photos or append.
      
      await _fetchProfileData(); // Refresh data to get updated photos
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Photo uploaded successfully')),
         );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePhoto(String photoId) async {
     setState(() => _isLoading = true);
    try {
      await _profileService.deletePhoto(photoId);
      await _fetchProfileData(); // Refresh list
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Photo deleted')),
         );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Map fields to backend schema
        final profileData = {
          'aboutMe': _aboutMeCtrl.text,
          'hobbies': _hobbiesCtrl.text,
          'relationshipStatus': _relationshipStatus,
          'language': _preferredLanguage,
          'workStatus': _workStatus,
          'education': _educationLevel,
          
          // Location (if set)
          if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text,
          
          // Ethnicity
          if (_ethnicityCountry != null) 'ethnicityCountry': _ethnicityCountry,
          if (_ethnicityState != null) 'ethnicityState': _ethnicityState,
          if (_tribe != null) 'tribe': _tribe,

          // Lifestyle
          'drinkingStatus': _drinkStatus,
          'smokingStatus': _smokeStatus,
          'hasChildren': _childrenStatus, // BE schema expects string for hasChildren? No, usually boolean or string. Checking validator... it says z.string().optional()
          'livingConditions': _livingConditions,

          // Personality
          'personalityType': _personalityType,
          'divorceView': _divorceView,

          // Looks
          'skinColor': _skinColor,
          'eyeColor': _eyeColor,
          'isHairy': _hairyStatus == 'Yes',
          'hasTribalMarks': _tribalMarks == 'Yes',
          'bestFeature': _bestFeature,

          // Medical
          'genotype': _genotype,
          'bloodGroup': _bloodGroup,
          'hivPartnerView': _hivPartnerView,
        };

        // Call backend
        await _profileService.updateProfile(profileData);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile saved successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFFFF5722),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Navigate based on first load status
          if (_isFirstLoad) {
            setState(() {
              _isFirstLoad = false;
            });

            // Navigate to home/explore page on first save
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go('/home');
            });
          }
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save profile: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'EDIT PROFILE',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PHOTO GALLERY SECTION
                _buildSectionCard('Profile Photos', Icons.photo_library, [
                  Text(
                    'Add up to 6 photos to your profile',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final hasPhoto = index < _photos.length;
                      final isNextSlot = index == _photos.length;
                      final photo = hasPhoto ? _photos[index] : null;

                      return GestureDetector(
                        onTap: () {
                          if (isNextSlot) {
                            _uploadPhoto();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (hasPhoto && photo['isPrimary'] == true)
                                  ? const Color(0xFFFF5722)
                                  : Colors.grey[300]!,
                              width: (hasPhoto && photo['isPrimary'] == true) ? 2 : 1,
                            ),
                            image: (hasPhoto && photo != null && photo['url'] != null)
                                ? DecorationImage(
                                    image: NetworkImage(photo['url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: hasPhoto
                              ? Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        if (photo != null && photo['id'] != null) {
                                           _deletePhoto(photo['id']);
                                        }
                                      },
                                    ),
                                  ),
                                )
                              : isNextSlot 
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          color: Colors.grey[400],
                                          size: 28,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Add Photo',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    )
                                  : null, // Empty container for future slots
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 12),

                // QUICK INTRODUCTION
                _buildSectionCard('Quick Introduction', Icons.person, [
                  _buildTextArea(
                    controller: _aboutMeCtrl,
                    label: 'About Me *',
                    hint: 'Tell us about yourself...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextArea(
                    controller: _hobbiesCtrl,
                    label: 'Hobbies & Interests *',
                    hint: 'What do you enjoy doing?',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Relationship Status *',
                          _relationshipStatus,
                          _relationshipStatuses,
                          (v) => setState(() => _relationshipStatus = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Work Status *',
                          _workStatus,
                          _workStatuses,
                          (v) => setState(() => _workStatus = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          'Education *',
                          _educationLevel,
                          _educationLevels,
                          (v) => setState(() => _educationLevel = v!),
                        ),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 12),

                // WHERE DO YOU LIVE SECTION
                _buildSectionCard('Where do you live?', Icons.location_on, [
                  _buildLocationField(
                    controller: _locationCtrl,
                    label: 'Location',
                    hint: 'City, State, Country',
                    onGeolocate: () {
                      // TODO: Implement geolocation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Fetching your location...',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: const Color(0xFFFF5722),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      // Simulate location fetch
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _locationCtrl.text = 'Lagos, Lagos State, Nigeria';
                          });
                        }
                      });
                    },
                  ),
                ]),

                const SizedBox(height: 12),

                // ETHNICITY SECTION
                _buildSectionCard('Ethnicity', Icons.public, [
                  // Country dropdown - show button to add if null
                  if (_ethnicityCountry == null)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _ethnicityCountry = 'Nigeria'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFF5722),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add,
                              color: Color(0xFFFF5722),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add Country of Origin',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _buildDropdown(
                      'Country of Origin',
                      _ethnicityCountry!,
                      _countries,
                      (v) => setState(() {
                        _ethnicityCountry = v;
                        _ethnicityState = null;
                        _tribe = null;
                      }),
                    ),

                    // Conditional State for Nigeria
                    if (_ethnicityCountry == 'Nigeria') ...[
                      const SizedBox(height: 12),
                      if (_ethnicityState == null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _ethnicityState = 'Lagos'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.grey[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Add State of Origin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        _buildDropdown(
                          'State of Origin',
                          _ethnicityState!,
                          _nigerianStates,
                          (v) => setState(() {
                            _ethnicityState = v;
                            _tribe = null;
                          }),
                        ),

                        // Conditional Tribe for selected state
                        if (_stateTribes[_ethnicityState] != null) ...[
                          const SizedBox(height: 12),
                          if (_tribe == null)
                            GestureDetector(
                              onTap: () => setState(
                                () => _tribe =
                                    _stateTribes[_ethnicityState]!.first,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Colors.grey[600],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Add Tribe',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            _buildDropdown(
                              'Tribe',
                              _tribe!,
                              _stateTribes[_ethnicityState]!,
                              (v) => setState(() => _tribe = v),
                            ),
                        ],
                      ],
                    ],
                  ],
                ]),

                const SizedBox(height: 12),

                // LIFESTYLE
                _buildSectionCard('Lifestyle', Icons.local_cafe, [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Do you drink? *',
                          _drinkStatus,
                          _drinkOptions,
                          (v) => setState(() => _drinkStatus = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          'Do you smoke? *',
                          _smokeStatus,
                          _smokeOptions,
                          (v) => setState(() => _smokeStatus = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Children? *',
                          _childrenStatus,
                          _childrenOptions,
                          (v) => setState(() => _childrenStatus = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          'Living Conditions',
                          _livingConditions,
                          _livingOptions,
                          (v) => setState(() => _livingConditions = v!),
                        ),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 12),

                // PERSONALITY
                _buildSectionCard('Personality', Icons.psychology, [
                  _buildDropdown(
                    'Personality Type *',
                    _personalityType,
                    _personalityTypes,
                    (v) => setState(() => _personalityType = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Views on Divorce',
                    _divorceView,
                    _divorceViews,
                    (v) => setState(() => _divorceView = v!),
                  ),
                ]),

                const SizedBox(height: 12),

                // LOOKS
                _buildSectionCard('Physical Appearance', Icons.face, [
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
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Hairy?',
                          _hairyStatus,
                          _yesNoOptions,
                          (v) => setState(() => _hairyStatus = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          'Tribal Marks?',
                          _tribalMarks,
                          _yesNoOptions,
                          (v) => setState(() => _tribalMarks = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Best Body Feature',
                    _bestFeature,
                    _bestFeatures,
                    (v) => setState(() => _bestFeature = v!),
                  ),
                ]),

                const SizedBox(height: 12),

                // MEDICAL INFORMATION
                _buildSectionCard(
                  'Medical Information',
                  Icons.medical_services,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Genotype *',
                            _genotype,
                            _genotypes,
                            (v) => setState(() => _genotype = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown(
                            'Blood Group *',
                            _bloodGroup,
                            _bloodGroups,
                            (v) => setState(() => _bloodGroup = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      'Would you marry an HIV+ partner? *',
                      _hivPartnerView,
                      _hivViews,
                      (v) => setState(() => _hivPartnerView = v!),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _isFirstLoad
                          ? 'Complete Profile & Start Exploring'
                          : 'Save Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFFF5722), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
            validator: required
                ? (value) => value == null || value.isEmpty ? 'Required' : null
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 20,
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location, color: Color(0xFFFF5722)),
                onPressed: onGeolocate,
                tooltip: 'Use current location',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
