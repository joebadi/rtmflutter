import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../data/location_preferences.dart';
import '../../data/nigeria_locations.dart';
import '../../services/match_service.dart';
import '../../widgets/location_preference_editor.dart';
import '../../widgets/premium_loader.dart';
import '../../widgets/premium_message.dart';

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
  // Coupled location/origin blocks (OR'd) — see LocationPreferenceEditor.
  final List<LocationBlock> _locationBlocks = [];
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
        void loadList(String key, List<String> target) {
          if (data[key] != null && data[key] is List) {
            target
              ..clear()
              ..addAll((data[key] as List).map((e) => e.toString()));
          }
        }

        loadList('relationshipStatus', _selectedRelationshipStatuses);
        loadList('religion', _selectedReligions);
        loadList('zodiac', _selectedZodiacs);
        loadList('genotype', _selectedGenotypes);
        loadList('bloodGroup', _selectedBloodGroups);
        loadList('bodyType', _selectedBodyTypes);

        // Location/origin blocks. Prefer the new model; otherwise reconstruct a
        // single block from the legacy locationCountry/locationStates/tribePreferences.
        _locationBlocks
          ..clear()
          ..addAll(parseLocationBlocks(data['locationPreferences']));
        if (_locationBlocks.isEmpty && data['locationCountry'] != null) {
          final legacyTribes = parseTribePreferences(data['tribePreferences']);
          _locationBlocks.add(LocationBlock(
            residenceCountry: data['locationCountry'].toString(),
            residenceStates: data['locationStates'] is List
                ? (data['locationStates'] as List).map((e) => e.toString()).toList()
                : [],
            origins: legacyTribes.isEmpty
                ? []
                : [OriginRule(country: 'Nigeria', stateTribes: legacyTribes)],
          ));
        }

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

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final data = {
        'ageMin': _ageRange.start.round(),
        'ageMax': _ageRange.end.round(),
        'ageIsDealBreaker': false,
        // New coupled-block model + derived legacy fields for back-compat.
        'locationPreferences': locationBlocksToJson(_locationBlocks),
        'locationCountry': deriveLegacyCountry(_locationBlocks),
        'locationStates': deriveLegacyStates(_locationBlocks),
        'locationTribes': deriveLegacyFlatTribes(_locationBlocks),
        'tribePreferences': deriveLegacyTribePrefs(_locationBlocks),
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

      if (success) {
        await showPremiumAlert(
          context,
          title: 'Preferences saved',
          message: 'We’ll use these to find your best matches.',
          kind: MessageKind.success,
          autoDismiss: const Duration(milliseconds: 1300),
        );
        if (mounted) context.pop();
      } else {
        await showPremiumAlert(
          context,
          title: 'Couldn’t save',
          message: 'We couldn’t update your preferences. Please try again.',
          kind: MessageKind.error,
          buttonText: 'Try again',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showPremiumAlert(
        context,
        title: 'Something went wrong',
        message: 'Please check your connection and try again.',
        kind: MessageKind.error,
        buttonText: 'Dismiss',
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
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      children: [
                        _introHeader(),
                        _sliderField(
                          'Age',
                          Icons.cake_outlined,
                          '${_ageRange.start.round()}–${_ageRange.end.round()} yrs',
                          RangeSlider(
                            values: _ageRange,
                            min: 18,
                            max: 70,
                            divisions: 52,
                            activeColor: AppTheme.accent,
                            inactiveColor: AppTheme.fg(context, 0.12),
                            labels: RangeLabels('${_ageRange.start.round()}',
                                '${_ageRange.end.round()}'),
                            onChanged: (v) => setState(() => _ageRange = v),
                          ),
                        ),
                        _multiField('Relationship status',
                            Icons.favorite_border_rounded,
                            _selectedRelationshipStatuses, _relationshipStatuses,
                            dbKey: 'relationshipStatus'),
                        _locationField(),
                        _multiField('Religion', Icons.church_outlined,
                            _selectedReligions, _religions, dbKey: 'religion'),
                        _multiField('Zodiac', Icons.star_outline_rounded,
                            _selectedZodiacs, _zodiacs, dbKey: 'zodiac'),
                        _multiField('Genotype', Icons.biotech_outlined,
                            _selectedGenotypes, _genotypes, dbKey: 'genotype'),
                        _multiField('Blood group', Icons.bloodtype_outlined,
                            _selectedBloodGroups, _bloodGroups,
                            dbKey: 'bloodGroup'),
                        _sliderField(
                          'Height',
                          Icons.height_rounded,
                          '${_heightLabel(_heightRange.start.round())} – ${_heightLabel(_heightRange.end.round())}',
                          RangeSlider(
                            values: _heightRange,
                            min: 0,
                            max: (_heights.length - 1).toDouble(),
                            divisions: _heights.length - 1,
                            activeColor: AppTheme.accent,
                            inactiveColor: AppTheme.fg(context, 0.12),
                            onChanged: (v) => setState(() => _heightRange = v),
                          ),
                          dbKey: 'height',
                        ),
                        _multiField('Body type',
                            Icons.accessibility_new_rounded, _selectedBodyTypes,
                            _bodyTypes, dbKey: 'bodyType'),
                        _tristateField('Tattoos', Icons.brush_outlined,
                            _preferredTattoos,
                            (v) => setState(() => _preferredTattoos = v),
                            'tattoos'),
                        _tristateField('Piercings', Icons.diamond_outlined,
                            _preferredPiercings,
                            (v) => setState(() => _preferredPiercings = v),
                            'piercings'),
                        const SizedBox(height: 8),
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

  Widget _introHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find your kind of person',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context))),
          const SizedBox(height: 3),
          Text(
            'Dial in the details — tap the flame to mark a must-have. We only '
            'score the preferences you set.',
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary(context),
                height: 1.35),
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

  // --------------------------------------------------------- filter-style fields

  TextStyle _fieldLabel() => GoogleFonts.poppins(
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      color: AppTheme.textSecondary(context));

  Widget _slim(Widget slider) => SliderTheme(
        data: SliderThemeData(
          trackHeight: 3,
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          rangeThumbShape:
              const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
        ),
        child: slider,
      );

  /// Compact "deal breaker" toggle — a small flame chip, accent when on.
  Widget _dbToggle(String key) {
    final on = _dealBreakers[key] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _dealBreakers[key] = !on),
      child: Tooltip(
        message: on ? 'Deal breaker — must match' : 'Tap to mark a must-have',
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? AppTheme.accent.withOpacity(0.16) : Colors.transparent,
            border: Border.all(
                color: on ? AppTheme.accent : AppTheme.hairline(context)),
          ),
          child: Icon(Icons.local_fire_department_rounded,
              size: 14, color: on ? AppTheme.accent : AppTheme.textFaint(context)),
        ),
      ),
    );
  }

  /// Filter-style multi-select field: icon + label/value, count badge, optional
  /// deal-breaker flame, opens a checkbox sheet.
  Widget _multiField(String label, IconData icon, List<String> selected,
      List<String> options,
      {String? dbKey}) {
    final summary = selected.isEmpty ? 'Any' : selected.join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await _openMultiSelect(label, options, selected);
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: _fieldLabel()),
                      const SizedBox(height: 1),
                      Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: selected.isEmpty
                              ? FontWeight.w500
                              : FontWeight.w600,
                          color: selected.isEmpty
                              ? AppTheme.textFaint(context)
                              : AppTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (dbKey != null) _dbToggle(dbKey),
                if (selected.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 6, right: 2),
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
      ),
    );
  }

  /// Filter-style slider field: icon + label, value text and slim slider.
  Widget _sliderField(String label, IconData icon, String valueText,
      Widget slider,
      {String? dbKey}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.accent),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(context))),
              const Spacer(),
              if (dbKey != null) _dbToggle(dbKey),
              const SizedBox(width: 8),
              Text(valueText,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent)),
            ],
          ),
          _slim(slider),
        ],
      ),
    );
  }

  /// Location/origin editor wrapped as a filter-style field.
  Widget _locationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Preferred location & origin',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(context))),
              ),
              _dbToggle('location'),
            ],
          ),
          const SizedBox(height: 10),
          LocationPreferenceEditor(
            blocks: _locationBlocks,
            onChanged: (b) => setState(() {
              _locationBlocks
                ..clear()
                ..addAll(b);
            }),
          ),
          if (_locationBlocks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.travel_explore_rounded,
                      color: AppTheme.accent, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatLocationBlocks(_locationBlocks),
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppTheme.fg(context, 0.85),
                          fontWeight: FontWeight.w500,
                          height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  /// Filter-style tri-state field (Yes / No / Any) with a deal-breaker flame.
  Widget _tristateField(
    String label,
    IconData icon,
    bool? value,
    ValueChanged<bool?> onChanged,
    String dealBreakerKey,
  ) {
    Widget seg(String text, bool active, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(text,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : AppTheme.textSecondary(context))),
              ),
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(context))),
              ),
              _dbToggle(dealBreakerKey),
            ],
          ),
          const SizedBox(height: 8),
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
      ),
    );
  }
}
