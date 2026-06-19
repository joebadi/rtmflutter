import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../data/nigeria_locations.dart';
import '../../services/match_service.dart';
import '../../widgets/premium_loader.dart';

/// Match Preferences — dark premium redesign matching the Live Dates / Wallet
/// aesthetic. Collects who the user wants to match with, including a
/// state-of-origin → tribes picker, and deal-breaker toggles.
class MatchPreferencesPage extends StatefulWidget {
  const MatchPreferencesPage({super.key});

  @override
  State<MatchPreferencesPage> createState() => _MatchPreferencesPageState();
}

class _MatchPreferencesPageState extends State<MatchPreferencesPage> {
  final _matchService = MatchService();
  bool _isLoading = false;
  bool _isSaving = false;

  RangeValues _ageRange = const RangeValues(18, 50);
  final List<String> _selectedRelationshipStatuses = [];
  String _selectedCountry = 'Nigeria';
  final List<String> _selectedStates = [];
  // Preferred state-of-origin -> tribes (e.g. {"Edo":["Esan"],"Delta":["All"]}).
  final Map<String, List<String>> _tribePrefs = {};
  final List<String> _selectedReligions = [];
  final List<String> _selectedZodiacs = [];
  final List<String> _selectedGenotypes = [];
  final List<String> _selectedBloodGroups = [];
  RangeValues _heightRange = const RangeValues(4, 19);
  final List<String> _selectedBodyTypes = [];
  bool? _preferredTattoos;
  bool? _preferredPiercings;

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
  final List<String> _religions = ['Christianity', 'Islam', 'Traditional', 'Other'];
  final List<String> _zodiacs = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];
  final List<String> _genotypes = ['AA', 'AS', 'SS', 'AC', 'SC'];
  final List<String> _bloodGroups = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  final List<String> _bodyTypes = [
    'Slim', 'Petite', 'Average', 'Athletic', 'Muscular',
    'Curvy', 'Stocky', 'Full-figured', 'Heavyset',
  ];
  final List<String> _heights = [
    '4\'7" (140 cm)', '4\'8" (142 cm)', '4\'9" (145 cm)', '4\'10" (147 cm)',
    '4\'11" (150 cm)', '5\'0" (152 cm)', '5\'1" (155 cm)', '5\'2" (157 cm)',
    '5\'3" (160 cm)', '5\'4" (163 cm)', '5\'5" (165 cm)', '5\'6" (168 cm)',
    '5\'7" (170 cm)', '5\'8" (173 cm)', '5\'9" (175 cm)', '5\'10" (178 cm)',
    '5\'11" (180 cm)', '6\'0" (183 cm)', '6\'1" (185 cm)', '6\'2" (188 cm)',
    '6\'3" (190 cm)', '6\'4" (193 cm)', '6\'5" (196 cm)', '6\'6" (198 cm)',
    '6\'7" (201 cm)', '6\'8" (203 cm)',
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
    int closest = 0;
    int minDiff = 9999;
    for (int i = 0; i < _heights.length; i++) {
      final match = RegExp(r'\((\d+) cm\)').firstMatch(_heights[i]);
      if (match != null) {
        final v = int.parse(match.group(1)!);
        if (v == cm) return i;
        final diff = (v - cm).abs();
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
            target
              ..clear()
              ..addAll((data[key] as List).map((e) => e.toString()));
          }
        }

        loadList('relationshipStatus', _selectedRelationshipStatuses);
        loadList('locationStates', _selectedStates);
        loadList('religion', _selectedReligions);
        loadList('zodiac', _selectedZodiacs);
        loadList('genotype', _selectedGenotypes);
        loadList('bloodGroup', _selectedBloodGroups);
        loadList('bodyType', _selectedBodyTypes);

        // Tribe preferences (state -> tribes map). Fall back to the legacy flat
        // list if the new field is absent.
        _tribePrefs
          ..clear()
          ..addAll(parseTribePreferences(data['tribePreferences']));

        final minIdx = _cmToHeightIndex(
            data['heightMin'] is num ? (data['heightMin'] as num).toInt() : null);
        final maxIdx = _cmToHeightIndex(
            data['heightMax'] is num ? (data['heightMax'] as num).toInt() : null);
        if (minIdx >= 0 && maxIdx >= 0 && maxIdx >= minIdx) {
          _heightRange = RangeValues(minIdx.toDouble(), maxIdx.toDouble());
        }

        if (data['tattoosAcceptable'] != null) {
          _preferredTattoos = data['tattoosAcceptable'] as bool;
        }
        if (data['piercingsAcceptable'] != null) {
          _preferredPiercings = data['piercingsAcceptable'] as bool;
        }

        _dealBreakers['relationshipStatus'] = data['relationshipIsDealBreaker'] ?? false;
        _dealBreakers['location'] = data['locationIsDealBreaker'] ?? false;
        _dealBreakers['religion'] = data['religionIsDealBreaker'] ?? false;
        _dealBreakers['zodiac'] = data['zodiacIsDealBreaker'] ?? false;
        _dealBreakers['genotype'] = data['genotypeIsDealBreaker'] ?? false;
        _dealBreakers['bloodGroup'] = data['bloodGroupIsDealBreaker'] ?? false;
        _dealBreakers['height'] = data['heightIsDealBreaker'] ?? false;
        _dealBreakers['bodyType'] = data['bodyTypeIsDealBreaker'] ?? false;
        _dealBreakers['tattoos'] = data['tattoosIsDealBreaker'] ?? false;
        _dealBreakers['piercings'] = data['piercingsIsDealBreaker'] ?? false;
      }
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Flatten the state -> tribes map into a legacy flat list of tribe names
  /// (excluding the "All" sentinel) for backward compatibility.
  List<String> _flatTribes() {
    final set = <String>{};
    _tribePrefs.forEach((_, tribes) {
      for (final t in tribes) {
        if (t != 'All') set.add(t);
      }
    });
    return set.toList();
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final data = {
        'ageMin': _ageRange.start.round(),
        'ageMax': _ageRange.end.round(),
        'ageIsDealBreaker': false,
        'locationCountry': _selectedCountry,
        'locationStates': _selectedStates,
        'locationTribes': _flatTribes(),
        'tribePreferences': _tribePrefs,
        'locationIsDealBreaker': _dealBreakers['location'] ?? false,
        'relationshipStatus': _selectedRelationshipStatuses,
        'relationshipIsDealBreaker': _dealBreakers['relationshipStatus'] ?? false,
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
        if (_preferredPiercings != null) 'piercingsAcceptable': _preferredPiercings,
        'piercingsIsDealBreaker': _dealBreakers['piercings'] ?? false,
      };

      final success = await _matchService.updatePreferences(data);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Match preferences updated'
              : 'Failed to update preferences'),
          backgroundColor: success ? AppTheme.accent : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: PremiumLoader())
            : Column(
                children: [
                  _header(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        _infoBanner(),
                        const SizedBox(height: 16),
                        _ageSection(),
                        const SizedBox(height: 14),
                        _relationshipSection(),
                        const SizedBox(height: 14),
                        _locationSection(),
                        const SizedBox(height: 14),
                        _tribeSection(),
                        const SizedBox(height: 14),
                        _beliefsSection(),
                        const SizedBox(height: 14),
                        _medicalSection(),
                        const SizedBox(height: 14),
                        _physicalSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  _saveBar(),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------- chrome

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary(context)),
            onPressed: () => context.pop(),
          ),
          Text(
            'Match Preferences',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Toggle "Deal breaker" for must-haves. We only score the preferences you set.',
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: AppTheme.fg(context, 0.75), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        border: Border(top: BorderSide(color: AppTheme.hairline(context))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.accent.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isSaving ? null : _savePreferences,
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(
                        'Save Preferences',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- sections

  Widget _card(String title, IconData icon, List<Widget> children, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context)),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _ageSection() {
    return _card('Age Range', Icons.cake_outlined, [
      Text(
        '${_ageRange.start.round()} – ${_ageRange.end.round()} years',
        style: GoogleFonts.poppins(
            color: AppTheme.accent, fontSize: 15, fontWeight: FontWeight.w700),
      ),
      RangeSlider(
        values: _ageRange,
        min: 18,
        max: 70,
        divisions: 52,
        activeColor: AppTheme.accent,
        inactiveColor: AppTheme.textFaint(context),
        labels: RangeLabels(
            _ageRange.start.round().toString(), _ageRange.end.round().toString()),
        onChanged: (v) => setState(() => _ageRange = v),
      ),
    ]);
  }

  Widget _relationshipSection() {
    return _card(
      'Relationship Status',
      Icons.favorite_outline_rounded,
      [
        _multiField(_selectedRelationshipStatuses, _relationshipStatuses,
            'Relationship status'),
      ],
      trailing: _dealBreakerSwitch('relationshipStatus'),
    );
  }

  Widget _locationSection() {
    return _card(
      'Preferred Location',
      Icons.place_outlined,
      [
        Text('Country', style: _labelStyle()),
        const SizedBox(height: 8),
        _singleField(_selectedCountry, _countries,
            (v) => setState(() => _selectedCountry = v)),
        if (_selectedCountry == 'Nigeria') ...[
          const SizedBox(height: 14),
          Text('States they can reside in', style: _labelStyle()),
          const SizedBox(height: 8),
          _multiField(_selectedStates, kNigerianStates, 'Preferred states'),
          if (_selectedStates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '$_selectedCountry (${_selectedStates.join(', ')})',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.fg(context, 0.6),
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ],
      trailing: _dealBreakerSwitch('location'),
    );
  }

  Widget _tribeSection() {
    return _card(
      'Preferred Tribe',
      Icons.diversity_3_outlined,
      [
        Text(
          'Pick a state of origin, then the tribe(s) you prefer — or "All".',
          style: GoogleFonts.poppins(
              fontSize: 11.5, color: AppTheme.fg(context, 0.6), height: 1.35),
        ),
        const SizedBox(height: 12),
        ..._tribePrefs.keys.map(_tribeStateCard),
        const SizedBox(height: 4),
        _addStateButton(),
        if (_tribePrefs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded,
                    color: AppTheme.accent, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tribe(s): ${formatTribePreferences(_tribePrefs)}',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.fg(context, 0.85),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tribeStateCard(String state) {
    final selected = _tribePrefs[state] ?? [];
    final isAll = selected.contains('All');
    final tribes = tribesForState(state);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                state,
                style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _tribePrefs.remove(state)),
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppTheme.fg(context, 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _smallChip('All', isAll, () {
                setState(() => _tribePrefs[state] = isAll ? [] : ['All']);
              }),
              ...tribes.map((t) {
                final on = selected.contains(t);
                return _smallChip(t, on, () {
                  setState(() {
                    final list = List<String>.from(_tribePrefs[state] ?? []);
                    list.remove('All');
                    if (on) {
                      list.remove(t);
                    } else {
                      list.add(t);
                    }
                    _tribePrefs[state] = list;
                  });
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addStateButton() {
    return GestureDetector(
      onTap: _showAddStateSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.accent.withOpacity(0.4),
              width: 1.3,
              style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: AppTheme.accent, size: 18),
            const SizedBox(width: 6),
            Text('Add state of origin',
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent)),
          ],
        ),
      ),
    );
  }

  void _showAddStateSheet() {
    final remaining =
        kNigerianStates.where((s) => !_tribePrefs.containsKey(s)).toList();
    if (remaining.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.textFaint(context), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select state of origin',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context))),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: remaining.length,
                itemBuilder: (_, i) {
                  final s = remaining[i];
                  return ListTile(
                    title: Text(s,
                        style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary(context), fontSize: 13.5)),
                    trailing: const Icon(Icons.add_rounded,
                        color: AppTheme.accent, size: 18),
                    onTap: () {
                      setState(() => _tribePrefs[s] = ['All']);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _beliefsSection() {
    return _card('Beliefs', Icons.auto_awesome_outlined, [
      Row(
        children: [
          Text('Religion', style: _labelStyle()),
          const Spacer(),
          _dealBreakerSwitch('religion'),
        ],
      ),
      const SizedBox(height: 8),
      _multiField(_selectedReligions, _religions, 'Religion'),
      const SizedBox(height: 14),
      Row(
        children: [
          Text('Zodiac', style: _labelStyle()),
          const Spacer(),
          _dealBreakerSwitch('zodiac'),
        ],
      ),
      const SizedBox(height: 8),
      _multiField(_selectedZodiacs, _zodiacs, 'Zodiac'),
    ]);
  }

  Widget _medicalSection() {
    return _card('Medical', Icons.medical_services_outlined, [
      Row(
        children: [
          Text('Genotype', style: _labelStyle()),
          const Spacer(),
          _dealBreakerSwitch('genotype'),
        ],
      ),
      const SizedBox(height: 8),
      _multiField(_selectedGenotypes, _genotypes, 'Genotype'),
      const SizedBox(height: 14),
      Row(
        children: [
          Text('Blood Group', style: _labelStyle()),
          const Spacer(),
          _dealBreakerSwitch('bloodGroup'),
        ],
      ),
      const SizedBox(height: 8),
      _multiField(_selectedBloodGroups, _bloodGroups, 'Blood group'),
    ]);
  }

  Widget _physicalSection() {
    return _card('Physical', Icons.accessibility_new_rounded, [
      _heightRangeField(),
      const SizedBox(height: 14),
      Row(
        children: [
          Text('Body Type', style: _labelStyle()),
          const Spacer(),
          _dealBreakerSwitch('bodyType'),
        ],
      ),
      const SizedBox(height: 8),
      _multiField(_selectedBodyTypes, _bodyTypes, 'Body type'),
      const SizedBox(height: 14),
      _tristate('Tattoos', _preferredTattoos,
          (v) => setState(() => _preferredTattoos = v), 'tattoos'),
      const SizedBox(height: 12),
      _tristate('Piercings', _preferredPiercings,
          (v) => setState(() => _preferredPiercings = v), 'piercings'),
    ]);
  }

  Widget _heightRangeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Height', style: _labelStyle()),
            const Spacer(),
            _dealBreakerSwitch('height'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_heightLabel(_heightRange.start.round()),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent)),
            Text('to',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textFaint(context))),
            Text(_heightLabel(_heightRange.end.round()),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent)),
          ],
        ),
        RangeSlider(
          values: _heightRange,
          min: 0,
          max: (_heights.length - 1).toDouble(),
          divisions: _heights.length - 1,
          activeColor: AppTheme.accent,
          inactiveColor: AppTheme.textFaint(context),
          onChanged: (v) => setState(() => _heightRange = v),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- atoms

  TextStyle _labelStyle() => GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppTheme.fg(context, 0.85));


  /// Filter-style multi-select field: a tappable surface field that shows the
  /// selection summary + count and opens a checkbox sheet.
  Widget _multiField(
      List<String> selected, List<String> options, String sheetTitle) {
    final summary = selected.isEmpty ? 'Any' : selected.join(', ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await _openMultiSelect(sheetTitle, options, selected);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppTheme.surface2(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.hairline(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight:
                        selected.isEmpty ? FontWeight.w500 : FontWeight.w600,
                    color: selected.isEmpty
                        ? AppTheme.textFaint(context)
                        : AppTheme.textPrimary(context),
                  ),
                ),
              ),
              if (selected.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${selected.length}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textFaint(context)),
            ],
          ),
        ),
      ),
    );
  }

  /// Single-select field (e.g. country) using a styled dropdown.
  Widget _singleField(
      String value, List<String> options, ValueChanged<String> onPick) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: options.contains(value) ? value : null,
          dropdownColor: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textFaint(context)),
          style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context)),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onPick(v);
          },
        ),
      ),
    );
  }

  /// Theme-aware checkbox bottom sheet; mutates [selected] in place.
  Future<void> _openMultiSelect(
      String title, List<String> options, List<String> selected) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Container(
          height: MediaQuery.of(sheetCtx).size.height * 0.65,
          decoration: BoxDecoration(
            color: AppTheme.bg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textFaint(context),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 6),
                child: Row(
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context))),
                    const Spacer(),
                    if (selected.isNotEmpty)
                      TextButton(
                        onPressed: () => setSheet(() => selected.clear()),
                        child: Text('Clear',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  children: options.map((o) {
                    final on = selected.contains(o);
                    return GestureDetector(
                      onTap: () => setSheet(
                          () => on ? selected.remove(o) : selected.add(o)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: on
                              ? AppTheme.accent.withOpacity(0.16)
                              : AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: on
                                  ? AppTheme.accent
                                  : AppTheme.hairline(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              on
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: on
                                  ? AppTheme.accent
                                  : AppTheme.textFaint(context),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(o,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: on
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: AppTheme.textPrimary(context))),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(sheetCtx),
                        child: Center(
                          child: Text(
                            selected.isEmpty
                                ? 'Done'
                                : 'Done · ${selected.length} selected',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
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
      ),
    );
  }

  Widget _smallChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.hairline(context),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : AppTheme.fg(context, 0.7),
          ),
        ),
      ),
    );
  }

  Widget _dealBreakerSwitch(String key) {
    final on = _dealBreakers[key] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _dealBreakers[key] = !on),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Deal breaker',
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: on ? AppTheme.accent : AppTheme.textFaint(context))),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: on,
              onChanged: (v) => setState(() => _dealBreakers[key] = v),
              activeColor: AppTheme.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tristate(
    String label,
    bool? value,
    ValueChanged<bool?> onChanged,
    String dealBreakerKey,
  ) {
    Widget seg(String text, bool active, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(text,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppTheme.textSecondary(context))),
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: _labelStyle()),
            const Spacer(),
            _dealBreakerSwitch(dealBreakerKey),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surface2(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.hairline(context)),
          ),
          child: Row(
            children: [
              seg('Yes', value == true, () => onChanged(true)),
              seg('No', value == false, () => onChanged(false)),
              seg('Any', value == null, () => onChanged(null)),
            ],
          ),
        ),
      ],
    );
  }
}
