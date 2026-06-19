/// Coupled location/origin preference model + country reference data.
///
/// A user's location preference is an OR'd list of [LocationBlock]s. Each block
/// pairs a *residence* rule (where the partner lives) with optional *origin*
/// rules (where the partner is from / their nationality). For countries we have
/// rich data for (currently only Nigeria) the block reveals residence-states and
/// each origin reveals a state-of-origin -> tribe picker; other countries are
/// nationality-only.
///
/// Matching (server-side, mirrored here for reference): a profile satisfies the
/// preference if it falls into ANY block —
///   profile.country == block.residenceCountry
///   AND (block.residenceStates empty OR profile.state in it)
///   AND (block.origins empty OR profile matches one origin)
/// where an origin matches when profile.ethnicityCountry == origin.country AND
/// (origin.stateTribes empty OR stateTribes[profile.stateOfOrigin] contains
/// "All" or profile.tribe).
library;

import 'nigeria_locations.dart';

/// Countries offered for residence + nationality selection.
const List<String> kCountries = [
  'Nigeria',
  'Ghana',
  'Kenya',
  'South Africa',
  'Cameroon',
  "Côte d'Ivoire",
  'Senegal',
  'Tanzania',
  'Uganda',
  'Egypt',
  'Ethiopia',
  'United Kingdom',
  'England',
  'Scotland',
  'Ireland',
  'United States',
  'Canada',
  'Germany',
  'France',
  'Netherlands',
  'United Arab Emirates',
  'Other',
];

/// Whether a residence country exposes a state-of-residence picker.
bool countryHasStates(String country) => country == 'Nigeria';

/// Whether a nationality exposes a state-of-origin -> tribe drill-down.
bool countryHasTribes(String country) => country == 'Nigeria';

/// Residence states available for a country (empty = "anywhere").
List<String> statesForCountry(String country) =>
    country == 'Nigeria' ? kNigerianStates : const [];

// ─────────────────────────────────────────────────────────── models

/// One nationality/heritage rule within a [LocationBlock]. For Nigeria the
/// [stateTribes] map drills into state-of-origin -> tribes (or "All"); other
/// countries leave it empty (nationality-only).
class OriginRule {
  String country;
  Map<String, List<String>> stateTribes;

  OriginRule({required this.country, Map<String, List<String>>? stateTribes})
      : stateTribes = stateTribes ?? {};

  OriginRule clone() => OriginRule(
        country: country,
        stateTribes: {
          for (final e in stateTribes.entries) e.key: List<String>.from(e.value),
        },
      );

  Map<String, dynamic> toJson() => {
        'country': country,
        'stateTribes': stateTribes,
      };

  factory OriginRule.fromJson(Map raw) => OriginRule(
        country: (raw['country'] ?? '').toString(),
        stateTribes: parseTribePreferences(raw['stateTribes']),
      );
}

/// One coupled residence+origin block. Blocks are OR'd together.
class LocationBlock {
  String residenceCountry;
  List<String> residenceStates;
  List<OriginRule> origins;

  LocationBlock({
    required this.residenceCountry,
    List<String>? residenceStates,
    List<OriginRule>? origins,
  })  : residenceStates = residenceStates ?? [],
        origins = origins ?? [];

  Map<String, dynamic> toJson() => {
        'residenceCountry': residenceCountry,
        'residenceStates': residenceStates,
        'origins': origins.map((o) => o.toJson()).toList(),
      };

  factory LocationBlock.fromJson(Map raw) => LocationBlock(
        residenceCountry: (raw['residenceCountry'] ?? '').toString(),
        residenceStates: raw['residenceStates'] is List
            ? (raw['residenceStates'] as List).map((e) => e.toString()).toList()
            : [],
        origins: raw['origins'] is List
            ? (raw['origins'] as List)
                .whereType<Map>()
                .map(OriginRule.fromJson)
                .toList()
            : [],
      );
}

/// Parse a loosely-typed JSON array (from the API) into location blocks.
List<LocationBlock> parseLocationBlocks(dynamic raw) {
  if (raw is List) {
    return raw.whereType<Map>().map(LocationBlock.fromJson).toList();
  }
  return [];
}

/// Serialize blocks for the API.
List<Map<String, dynamic>> locationBlocksToJson(List<LocationBlock> blocks) =>
    blocks.map((b) => b.toJson()).toList();

// ───────────────────────────────────────────── back-compat derivation

/// Legacy `locationCountry` derived from the first block (or null).
String? deriveLegacyCountry(List<LocationBlock> blocks) =>
    blocks.isEmpty ? null : blocks.first.residenceCountry;

/// Legacy `locationStates` derived from the first block.
List<String> deriveLegacyStates(List<LocationBlock> blocks) =>
    blocks.isEmpty ? const [] : blocks.first.residenceStates;

/// Legacy `tribePreferences` (state -> tribes) merged from the first block's
/// Nigerian origin(s), so older readers keep working.
Map<String, List<String>> deriveLegacyTribePrefs(List<LocationBlock> blocks) {
  final out = <String, List<String>>{};
  if (blocks.isEmpty) return out;
  for (final o in blocks.first.origins) {
    if (o.country == 'Nigeria') {
      o.stateTribes.forEach((state, tribes) {
        out.putIfAbsent(state, () => []);
        for (final t in tribes) {
          if (!out[state]!.contains(t)) out[state]!.add(t);
        }
      });
    }
  }
  return out;
}

/// Legacy flat `locationTribes` list (tribe names, "All" excluded).
List<String> deriveLegacyFlatTribes(List<LocationBlock> blocks) {
  final set = <String>{};
  for (final block in blocks) {
    for (final o in block.origins) {
      o.stateTribes.forEach((_, tribes) {
        for (final t in tribes) {
          if (t != 'All') set.add(t);
        }
      });
    }
  }
  return set.toList();
}

// ─────────────────────────────────────────────────────────── display

/// Human summary of one block, e.g.
/// "Nigeria (Delta, Lagos) · from Edo (Esan), Delta (Urhobo, Ijaw)".
String formatLocationBlock(LocationBlock b) {
  final residence = b.residenceStates.isEmpty
      ? '${b.residenceCountry} (anywhere)'
      : '${b.residenceCountry} (${b.residenceStates.join(', ')})';

  if (b.origins.isEmpty) return residence;

  final originParts = b.origins.map((o) {
    if (o.country == 'Nigeria' && o.stateTribes.isNotEmpty) {
      return 'Nigeria — ${formatTribePreferences(o.stateTribes)}';
    }
    return o.country;
  }).join(', ');

  return '$residence · from $originParts';
}

/// Human summary of all blocks, joined by " OR ".
String formatLocationBlocks(List<LocationBlock> blocks) =>
    blocks.map(formatLocationBlock).join('  OR  ');
