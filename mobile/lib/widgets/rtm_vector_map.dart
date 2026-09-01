import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart'
    show Theme, ThemeReader;

/// Self-hosted Nigeria vector basemap (OpenMapTiles schema), served from the
/// VPS PMTiles server behind Apache — no API key, no third-party quota.
///
/// Overridable at build time:
///   flutter run --dart-define=RTM_TILE_URL=https://your.host/tiles/{z}/{x}/{y}.mvt
const _tileUrl = String.fromEnvironment(
  'RTM_TILE_URL',
  defaultValue: 'https://rtmadmin.e-clicks.net/tiles/nigeria/{z}/{x}/{y}.mvt',
);

Theme? _lightTheme;
Theme? _darkTheme;

/// A flutter_map layer that renders the self-hosted vector basemap. Drop-in
/// replacement for a raster `TileLayer`. Source data tops out at zoom 14; the
/// renderer over-zooms beyond that for a smooth close-up.
VectorTileLayer rtmVectorTileLayer({bool darkMode = false}) {
  final cachedTheme = darkMode ? _darkTheme : _lightTheme;
  final theme = cachedTheme ??
      ThemeReader().read(
        jsonDecode(darkMode ? _darkStyleJson : _styleJson)
            as Map<String, dynamic>,
      );
  if (darkMode) {
    _darkTheme = theme;
  } else {
    _lightTheme = theme;
  }
  return VectorTileLayer(
    // Keying on the theme forces a fresh layer when the app toggles light/dark,
    // so the renderer re-rasterises with the new theme instead of reusing the
    // previous (e.g. dark) tiles.
    key: ValueKey('rtm-vector-tile-${darkMode ? 'dark' : 'light'}'),
    theme: theme,
    maximumZoom: 20,
    tileProviders: TileProviders({
      'openmaptiles': NetworkVectorTileProvider(
        urlTemplate: _tileUrl,
        maximumZoom: 14,
        minimumZoom: 0,
      ),
    }),
  );
}

/// A compact MapLibre GL style over the OpenMapTiles schema — a clean, legible
/// light basemap. No sprite/glyph servers needed; the renderer draws labels
/// with Flutter fonts.
const String _styleJson = '''
{
  "version": 8,
  "name": "Compatible",
  "sources": {"openmaptiles": {"type": "vector"}},
  "layers": [
    {"id": "background", "type": "background", "paint": {"background-color": "#f4f2ee"}},
    {"id": "water", "type": "fill", "source": "openmaptiles", "source-layer": "water",
      "paint": {"fill-color": "#aad3df"}},
    {"id": "landcover-wood", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
      "filter": ["==", "class", "wood"], "paint": {"fill-color": "#d5e6cd", "fill-opacity": 0.7}},
    {"id": "landcover-grass", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
      "filter": ["==", "class", "grass"], "paint": {"fill-color": "#e0ead9", "fill-opacity": 0.7}},
    {"id": "landuse-residential", "type": "fill", "source": "openmaptiles", "source-layer": "landuse",
      "filter": ["==", "class", "residential"], "paint": {"fill-color": "#eceae4"}},
    {"id": "waterway", "type": "line", "source": "openmaptiles", "source-layer": "waterway",
      "paint": {"line-color": "#aad3df", "line-width": 1.2}},
    {"id": "road-minor", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
      "filter": ["in", "class", "minor", "service", "track"],
      "paint": {"line-color": "#ffffff", "line-width": {"stops": [[12, 0.5], [16, 3]]}}},
    {"id": "road-secondary", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
      "filter": ["in", "class", "secondary", "tertiary"],
      "paint": {"line-color": "#ffffff", "line-width": {"stops": [[9, 0.6], [16, 6]]}}},
    {"id": "road-primary", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
      "filter": ["==", "class", "primary"],
      "paint": {"line-color": "#ffe4b3", "line-width": {"stops": [[8, 0.8], [16, 8]]}}},
    {"id": "road-trunk", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
      "filter": ["in", "class", "trunk", "motorway"],
      "paint": {"line-color": "#f9b29c", "line-width": {"stops": [[6, 0.8], [16, 10]]}}},
    {"id": "building", "type": "fill", "source": "openmaptiles", "source-layer": "building",
      "minzoom": 14, "paint": {"fill-color": "#e2ded5", "fill-opacity": 0.7}},
    {"id": "boundary", "type": "line", "source": "openmaptiles", "source-layer": "boundary",
      "filter": ["<=", "admin_level", 4],
      "paint": {"line-color": "#9a9a9a", "line-width": 0.8, "line-dasharray": [3, 2]}},
    {"id": "place-label", "type": "symbol", "source": "openmaptiles", "source-layer": "place",
      "filter": ["in", "class", "city", "town", "village"],
      "layout": {"text-field": "{name}", "text-font": ["Roboto Regular"], "text-size": {"stops": [[6, 10], [12, 13]]}},
      "paint": {"text-color": "#4b4b4b", "text-halo-color": "#ffffff", "text-halo-width": 0.75}},
    {"id": "road-label", "type": "symbol", "source": "openmaptiles", "source-layer": "transportation_name",
      "minzoom": 13,
      "layout": {"text-field": "{name}", "text-font": ["Roboto Regular"], "text-size": 10},
      "paint": {"text-color": "#666666", "text-halo-color": "#ffffff", "text-halo-width": 0.7}}
  ]
}
''';

/// Dark companion to the light basemap. Keeping the geometry identical means
/// switching app themes only changes presentation; markers and map position do
/// not jump or reload from a different source.
const String _darkStyleJson = '''
{
  "version": 8,
  "name": "Compatible Dark",
  "sources": {"openmaptiles": {"type": "vector"}},
  "layers": [
    {"id": "background", "type": "background", "paint": {"background-color": "#101216"}},
    {"id": "water", "type": "fill", "source": "openmaptiles", "source-layer": "water",
      "paint": {"fill-color": "#182c35"}},
    {"id": "landcover-wood", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
      "filter": ["==", "class", "wood"], "paint": {"fill-color": "#17231b", "fill-opacity": 0.8}},
    {"id": "landcover-grass", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
      "filter": ["==", "class", "grass"], "paint": {"fill-color": "#1c261d", "fill-opacity": 0.8}},
    {"id": "landuse-residential", "type": "fill", "source": "openmaptiles", "source-layer": "landuse",
      "filter": ["==", "class", "residential"], "paint": {"fill-color": "#181b1f"}},
    {"id": "waterway", "type": "line", "source": "openmaptiles", "source-layer": "waterway",
      "paint": {"line-color": "#284854", "line-width": 1.2}},
    {"id": "road-minor", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
      "filter": ["in", "class", "minor", "service", "track"],
      "paint": {"line-color": "#2d3138", "line-width": {"stops": [[12, 0.5], [16, 3]]}}},
    {"id": "road-secondary", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
      "filter": ["in", "class", "secondary", "tertiary"],
      "paint": {"line-color": "#343942", "line-width": {"stops": [[9, 0.6], [16, 6]]}}},
    {"id": "road-primary", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
      "filter": ["==", "class", "primary"],
      "paint": {"line-color": "#4a4033", "line-width": {"stops": [[8, 0.8], [16, 8]]}}},
    {"id": "road-trunk", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
      "filter": ["in", "class", "trunk", "motorway"],
      "paint": {"line-color": "#60403a", "line-width": {"stops": [[6, 0.8], [16, 10]]}}},
    {"id": "building", "type": "fill", "source": "openmaptiles", "source-layer": "building",
      "minzoom": 14, "paint": {"fill-color": "#25282e", "fill-opacity": 0.8}},
    {"id": "boundary", "type": "line", "source": "openmaptiles", "source-layer": "boundary",
      "filter": ["<=", "admin_level", 4],
      "paint": {"line-color": "#59616b", "line-width": 0.8, "line-dasharray": [3, 2]}},
    {"id": "place-label", "type": "symbol", "source": "openmaptiles", "source-layer": "place",
      "filter": ["in", "class", "city", "town", "village"],
      "layout": {"text-field": "{name}", "text-font": ["Roboto Regular"], "text-size": {"stops": [[6, 10], [12, 13]]}},
      "paint": {"text-color": "#d5dae0", "text-halo-color": "#101216", "text-halo-width": 0.75}},
    {"id": "road-label", "type": "symbol", "source": "openmaptiles", "source-layer": "transportation_name",
      "minzoom": 13,
      "layout": {"text-field": "{name}", "text-font": ["Roboto Regular"], "text-size": 10},
      "paint": {"text-color": "#9ba3ad", "text-halo-color": "#101216", "text-halo-width": 0.7}}
  ]
}
''';
