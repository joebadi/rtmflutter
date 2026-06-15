/// Canonical Nigerian location data shared across the match-preference form, the
/// profile preference display, and any origin pickers.
///
/// [kStateTribes] maps each state to its major tribes. In selectors an implicit
/// "All" option is offered per state (meaning "any tribe from this state"); "All"
/// is therefore NOT included in the lists below.
library;

const Map<String, List<String>> kStateTribes = {
  'Abia': ['Igbo'],
  'Adamawa': ['Bachama', 'Bata', 'Chamba', 'Fulani', 'Kilba', 'Margi', 'Mumuye'],
  'Akwa Ibom': ['Annang', 'Efik', 'Ibibio', 'Oron'],
  'Anambra': ['Igbo'],
  'Bauchi': ['Fulani', 'Hausa', 'Jarawa', 'Sayawa'],
  'Bayelsa': ['Ijaw', 'Nembe', 'Ogbia'],
  'Benue': ['Idoma', 'Igede', 'Tiv'],
  'Borno': ['Babur', 'Kanuri', 'Margi', 'Shuwa'],
  'Cross River': ['Bekwarra', 'Efik', 'Ejagham', 'Yakurr'],
  'Delta': ['Igbo', 'Ijaw', 'Isoko', 'Itsekiri', 'Ukwuani', 'Urhobo'],
  'Ebonyi': ['Igbo'],
  'Edo': ['Afemai', 'Akoko-Edo', 'Bini', 'Esan', 'Owan'],
  'Ekiti': ['Yoruba'],
  'Enugu': ['Igbo'],
  'FCT': ['Gade', 'Gbagyi', 'Koro'],
  'Gombe': ['Fulani', 'Tangale', 'Tera', 'Waja'],
  'Imo': ['Igbo'],
  'Jigawa': ['Fulani', 'Hausa'],
  'Kaduna': ['Atyap', 'Bajju', 'Fulani', 'Gbagyi', 'Hausa'],
  'Kano': ['Fulani', 'Hausa'],
  'Katsina': ['Fulani', 'Hausa'],
  'Kebbi': ['Fulani', 'Hausa', 'Zuru'],
  'Kogi': ['Bassa', 'Ebira', 'Igala', 'Okun'],
  'Kwara': ['Bariba', 'Nupe', 'Yoruba'],
  'Lagos': ['Awori', 'Egun', 'Ijebu', 'Yoruba'],
  'Nasarawa': ['Alago', 'Eggon', 'Gwandara', 'Mada'],
  'Niger': ['Gbagyi', 'Hausa', 'Kamuku', 'Nupe'],
  'Ogun': ['Awori', 'Egba', 'Egun', 'Ijebu', 'Remo', 'Yoruba'],
  'Ondo': ['Akoko', 'Ikale', 'Ilaje', 'Yoruba'],
  'Osun': ['Ife', 'Ijesha', 'Yoruba'],
  'Oyo': ['Ibadan', 'Oyo', 'Yoruba'],
  'Plateau': ['Afizere', 'Berom', 'Ngas', 'Tarok'],
  'Rivers': ['Etche', 'Ijaw', 'Ikwerre', 'Kalabari', 'Ogoni', 'Okrika'],
  'Sokoto': ['Fulani', 'Hausa'],
  'Taraba': ['Chamba', 'Fulani', 'Jukun', 'Kuteb', 'Mumuye'],
  'Yobe': ['Bade', 'Fulani', 'Hausa', 'Kanuri', 'Ngizim'],
  'Zamfara': ['Fulani', 'Hausa'],
};

/// Flat, alphabetical list of Nigerian states (residence preference, etc.).
final List<String> kNigerianStates = kStateTribes.keys.toList();

/// Tribes available for a given state (empty list if unknown).
List<String> tribesForState(String state) => kStateTribes[state] ?? const [];

/// Format a state-of-origin -> tribes preference map for display, e.g.
/// `{ "Edo": ["Esan"], "Delta": ["All"] }` -> "Edo (Esan), Delta (All)".
String formatTribePreferences(Map<String, List<String>> prefs) {
  final segments = <String>[];
  prefs.forEach((state, tribes) {
    if (tribes.isEmpty || tribes.contains('All')) {
      segments.add('$state (All)');
    } else {
      segments.add('$state (${tribes.join(', ')})');
    }
  });
  return segments.join(', ');
}

/// Coerce a loosely-typed JSON map (e.g. from the API) into a
/// `Map<String, List<String>>` of state -> tribes.
Map<String, List<String>> parseTribePreferences(dynamic raw) {
  final result = <String, List<String>>{};
  if (raw is Map) {
    raw.forEach((key, value) {
      if (value is List) {
        result[key.toString()] =
            value.map((e) => e.toString()).toList();
      }
    });
  }
  return result;
}
