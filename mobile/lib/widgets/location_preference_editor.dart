import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../data/location_preferences.dart';
import '../data/nigeria_locations.dart';

/// Shared editor for coupled location/origin preference blocks. Used by both the
/// registration "Preferred Partner" step and the Options "Match Preferences"
/// page so they stay in lockstep. Theme-aware (AppTheme tokens).
///
/// Each block = a residence rule (country + optional states) paired with optional
/// origin/nationality rules (Nigeria drills into state-of-origin -> tribe). Blocks
/// are OR'd together — "match anyone who fits ANY of these".
class LocationPreferenceEditor extends StatefulWidget {
  const LocationPreferenceEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
  });

  final List<LocationBlock> blocks;
  final ValueChanged<List<LocationBlock>> onChanged;

  @override
  State<LocationPreferenceEditor> createState() =>
      _LocationPreferenceEditorState();
}

class _LocationPreferenceEditorState extends State<LocationPreferenceEditor> {
  List<LocationBlock> get _blocks => widget.blocks;

  void _emit() {
    // Pass a *copy* of the list. The parent holds the same list instance as
    // `widget.blocks`, and its onChanged typically does `..clear()..addAll(b)`.
    // If we passed `_blocks` directly, `clear()` would empty the very list we
    // then read from, wiping every block (tribe selections would vanish).
    widget.onChanged(List<LocationBlock>.from(_blocks));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add one or more location rules. A partner matches if they fit ANY '
          'rule. Pick where they live, and optionally where they’re from.',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: AppTheme.fg(context, 0.6),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _blocks.length; i++) ...[
          _blockCard(i),
          const SizedBox(height: 10),
        ],
        _addBlockButton(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────── block card

  Widget _blockCard(int index) {
    final block = _blocks[index];
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Location ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _blocks.removeAt(index);
                  _emit();
                },
                child: Icon(Icons.delete_outline_rounded,
                    size: 19, color: AppTheme.fg(context, 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Residence ----------------------------------------------------------
          Row(
            children: [
              Icon(Icons.home_outlined,
                  size: 15, color: AppTheme.fg(context, 0.7)),
              const SizedBox(width: 6),
              Text('Where they live', style: _label()),
            ],
          ),
          const SizedBox(height: 8),
          _countryDropdown(
            block.residenceCountry,
            (v) {
              block.residenceCountry = v;
              if (!countryHasStates(v)) block.residenceStates.clear();
              _emit();
            },
          ),
          if (countryHasStates(block.residenceCountry)) ...[
            const SizedBox(height: 8),
            _multiField(
              block.residenceStates,
              statesForCountry(block.residenceCountry),
              'States of residence',
              emptyLabel: 'Anywhere in ${block.residenceCountry}',
            ),
          ],

          const SizedBox(height: 12),
          Divider(color: AppTheme.hairline(context), height: 1),
          const SizedBox(height: 12),

          // Origin / nationality ----------------------------------------------
          Row(
            children: [
              Icon(Icons.public_rounded,
                  size: 15, color: AppTheme.fg(context, 0.7)),
              const SizedBox(width: 6),
              Expanded(child: Text('Where they’re from', style: _label())),
              Text('optional',
                  style: GoogleFonts.poppins(
                      fontSize: 10.5, color: AppTheme.textFaint(context))),
            ],
          ),
          const SizedBox(height: 8),
          _nationalityField(block),
          for (final origin in block.origins)
            if (countryHasTribes(origin.country)) _originTribePicker(origin),
        ],
      ),
    );
  }

  Widget _addBlockButton() {
    return GestureDetector(
      onTap: () {
        _blocks.add(LocationBlock(residenceCountry: 'Nigeria'));
        _emit();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.accent.withOpacity(0.4), width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_location_alt_outlined,
                color: AppTheme.accent, size: 18),
            const SizedBox(width: 6),
            Text(
              _blocks.isEmpty
                  ? 'Add a location preference'
                  : 'Add another location',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────── nationality sync

  Widget _nationalityField(LocationBlock block) {
    final selected = block.origins.map((o) => o.country).toList();
    final summary = selected.isEmpty ? 'Any origin' : selected.join(', ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await _openMultiSelect(
              'Nationality / heritage', kCountries, selected.toList());
          _syncOrigins(block, picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
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

  /// Reconcile a block's [LocationBlock.origins] with the picked nationality
  /// list, preserving the state-tribe data of countries that remain selected.
  void _syncOrigins(LocationBlock block, List<String> picked) {
    final existing = {for (final o in block.origins) o.country: o};
    block.origins
      ..clear()
      ..addAll(picked.map((c) => existing[c] ?? OriginRule(country: c)));
    _emit();
  }

  // ───────────────────────────────────────── origin state-of-origin picker

  Widget _originTribePicker(OriginRule origin) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${origin.country} origin — state & tribe',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.fg(context, 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            origin.stateTribes.isEmpty
                ? 'Any state of origin. Add one to narrow by tribe.'
                : 'Matches any tribe listed below.',
            style: GoogleFonts.poppins(
                fontSize: 10.5, color: AppTheme.textFaint(context)),
          ),
          const SizedBox(height: 10),
          ...origin.stateTribes.keys.toList().map((s) => _stateCard(origin, s)),
          _addStateButton(origin),
        ],
      ),
    );
  }

  Widget _stateCard(OriginRule origin, String state) {
    final selected = origin.stateTribes[state] ?? [];
    final isAll = selected.contains('All');
    final tribes = tribesForState(state);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppTheme.accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                state,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  origin.stateTribes.remove(state);
                  _emit();
                },
                child: Icon(Icons.close_rounded,
                    size: 16, color: AppTheme.fg(context, 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('All', isAll, () {
                origin.stateTribes[state] = isAll ? [] : ['All'];
                _emit();
              }),
              ...tribes.map((t) {
                final on = selected.contains(t);
                return _chip(t, on, () {
                  final list = List<String>.from(origin.stateTribes[state] ?? [])
                    ..remove('All');
                  if (on) {
                    list.remove(t);
                  } else {
                    list.add(t);
                  }
                  origin.stateTribes[state] = list;
                  _emit();
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addStateButton(OriginRule origin) {
    return GestureDetector(
      onTap: () => _showAddStateSheet(origin),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, color: AppTheme.accent, size: 16),
            const SizedBox(width: 4),
            Text('Add state of origin',
                style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent)),
          ],
        ),
      ),
    );
  }

  void _showAddStateSheet(OriginRule origin) {
    final remaining = kNigerianStates
        .where((s) => !origin.stateTribes.containsKey(s))
        .toList();
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
                  color: AppTheme.textFaint(context),
                  borderRadius: BorderRadius.circular(2)),
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
                            color: AppTheme.textPrimary(context),
                            fontSize: 13.5)),
                    trailing: const Icon(Icons.add_rounded,
                        color: AppTheme.accent, size: 18),
                    onTap: () {
                      origin.stateTribes[s] = ['All'];
                      _emit();
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

  // ─────────────────────────────────────────────────────────────── atoms

  TextStyle _label() => GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppTheme.fg(context, 0.85));

  Widget _countryDropdown(String value, ValueChanged<String> onPick) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: kCountries.contains(value) ? value : null,
          dropdownColor: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textFaint(context)),
          style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context)),
          items: kCountries
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onPick(v);
          },
        ),
      ),
    );
  }

  Widget _multiField(
    List<String> selected,
    List<String> options,
    String sheetTitle, {
    String emptyLabel = 'Any',
  }) {
    final summary = selected.isEmpty ? emptyLabel : selected.join(', ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked =
              await _openMultiSelect(sheetTitle, options, selected.toList());
          selected
            ..clear()
            ..addAll(picked);
          _emit();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
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

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: selected ? AppTheme.accent : AppTheme.hairline(context)),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : AppTheme.fg(context, 0.7),
          ),
        ),
      ),
    );
  }

  /// Theme-aware checkbox sheet. Returns the chosen list (does not mutate input).
  Future<List<String>> _openMultiSelect(
      String title, List<String> options, List<String> initial) async {
    final selected = List<String>.from(initial);
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
    return selected;
  }
}
