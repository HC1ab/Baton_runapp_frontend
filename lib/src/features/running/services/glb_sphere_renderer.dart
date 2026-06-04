import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Renders the user_marker_sphere.glb as a flat-coloured bitmap.
///
/// Parses the GLB binary (glTF 2.0 binary container), extracts vertex
/// positions and triangle indices, projects orthographically, depth-sorts
/// faces (painter's algorithm), and fills each triangle with [baseColor].
/// Returns a [Uint8List] PNG at [logicalSize] × DPR resolution.
class GlbSphereRenderer {
  GlbSphereRenderer._();

  static const String _assetPath = 'assets/models/user_marker_sphere.glb';

  // ── Cached parse results (loaded once per app run) ─────────────────────────
  static List<_Triangle>? _triangles;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Renders the sphere mesh filled with [baseColor].
  /// [logicalSize] controls canvas size in logical pixels; actual render
  /// resolution is [logicalSize] × device pixel ratio.
  static Future<Uint8List?> render({
    required ui.Color baseColor,
    double logicalSize = 96.0,
    double devicePixelRatio = 2.0,
  }) async {
    _triangles ??= await _loadTriangles();
    final triangles = _triangles;
    if (triangles == null) return null;

    final px = (logicalSize * devicePixelRatio).round();
    return _renderToBitmap(
      triangles: triangles,
      size: px,
      color: baseColor,
    );
  }

  // ---------------------------------------------------------------------------
  // GLB Parsing
  // ---------------------------------------------------------------------------

  static Future<List<_Triangle>?> _loadTriangles() async {
    try {
      final bytes =
          (await rootBundle.load(_assetPath)).buffer.asUint8List();
      return _parseGlb(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Parses a glTF 2.0 binary (.glb) file and returns all triangles
  /// in model space.  Assumes a single mesh / primitive.
  static List<_Triangle>? _parseGlb(Uint8List bytes) {
    // ── GLB header (12 bytes) ─────────────────────────────────────────────
    final bd = ByteData.sublistView(bytes);
    final magic = bd.getUint32(0, Endian.little);
    if (magic != 0x46546C67) return null; // 'glTF'
    // version = bd.getUint32(4), length = bd.getUint32(8)

    // ── Chunk 0: JSON ─────────────────────────────────────────────────────
    final jsonLen = bd.getUint32(12, Endian.little);
    // chunkType0 = bd.getUint32(16) — 0x4E4F534A = 'JSON'
    final jsonStr = String.fromCharCodes(bytes, 20, 20 + jsonLen);
    final json = _parseJson(jsonStr);
    if (json == null) return null;

    // ── Chunk 1: BIN ──────────────────────────────────────────────────────
    final binOffset = 20 + jsonLen;
    final binLen = bd.getUint32(binOffset, Endian.little);
    // chunkType1 = bd.getUint32(binOffset + 4) — 0x004E4942 = 'BIN\0'
    final binStart = binOffset + 8;
    final bin = bytes.sublist(binStart, binStart + binLen);

    // ── Locate first mesh primitive ───────────────────────────────────────
    final meshes = json['meshes'] as List<dynamic>?;
    if (meshes == null || meshes.isEmpty) return null;
    final primitive =
        ((meshes[0] as Map)['primitives'] as List)[0] as Map<String, dynamic>;

    final attrs = primitive['attributes'] as Map<String, dynamic>;
    final posAccessorIdx = attrs['POSITION'] as int;
    final normAccessorIdx = attrs['NORMAL'] as int?;
    final idxAccessorIdx = primitive['indices'] as int;

    final accessors = json['accessors'] as List<dynamic>;
    final bufferViews = json['bufferViews'] as List<dynamic>;

    // ── Read positions ────────────────────────────────────────────────────
    final positions = _readVec3(
        bin, accessors[posAccessorIdx] as Map<String, dynamic>, bufferViews);

    // ── Read normals (optional but present in this GLB) ───────────────────
    final normals = normAccessorIdx != null
        ? _readVec3(bin,
            accessors[normAccessorIdx] as Map<String, dynamic>, bufferViews)
        : null;

    // ── Read indices ──────────────────────────────────────────────────────
    final indices = _readIndices(
        bin, accessors[idxAccessorIdx] as Map<String, dynamic>, bufferViews);
    if (indices == null || positions == null) return null;

    // ── Fixed light direction (top-left-front, normalised) ────────────────
    const lx = 0.4082482904638631;  // 1/√6 * √(2/3)
    const ly = 0.8164965809277261;  // 2/√6 * √(2/3) — stronger from above
    const lz = 0.4082482904638631;
    // (already unit-length: √(lx²+ly²+lz²) ≈ 1)

    // ── Build triangles ───────────────────────────────────────────────────
    final tris = <_Triangle>[];
    for (var i = 0; i + 2 < indices.length; i += 3) {
      final ia = indices[i], ib = indices[i + 1], ic = indices[i + 2];
      final a = positions[ia];
      final b = positions[ib];
      final c = positions[ic];

      // Face normal: average vertex normals if available, else cross product
      _Vec3 fn;
      if (normals != null) {
        fn = _Vec3(
          (normals[ia].x + normals[ib].x + normals[ic].x) / 3.0,
          (normals[ia].y + normals[ib].y + normals[ic].y) / 3.0,
          (normals[ia].z + normals[ib].z + normals[ic].z) / 3.0,
        );
      } else {
        // Cross product of edges
        final ex = b.x - a.x, ey = b.y - a.y, ez = b.z - a.z;
        final fx = c.x - a.x, fy = c.y - a.y, fz = c.z - a.z;
        fn = _Vec3(
          ey * fz - ez * fy,
          ez * fx - ex * fz,
          ex * fy - ey * fx,
        );
      }
      // Normalise face normal
      final len = (fn.x * fn.x + fn.y * fn.y + fn.z * fn.z);
      if (len > 0) {
        final inv = 1.0 / len; // avoid sqrt for perf; dot still works for shading
        fn = _Vec3(fn.x * inv, fn.y * inv, fn.z * inv);
      }

      // dot(faceNormal, lightDir) → diffuse factor ∈ [0,1]
      final dot = (fn.x * lx + fn.y * ly + fn.z * lz).clamp(0.0, 1.0);

      final depth = (a.z + b.z + c.z) / 3.0;
      tris.add(_Triangle(a, b, c, depth, _Vec3(dot, dot, dot)));
    }
    // Depth sort: back to front (painter's algorithm)
    tris.sort((x, y) => x.depth.compareTo(y.depth));
    return tris;
  }

  // ---------------------------------------------------------------------------
  // Minimal JSON parser — only handles the subset used by glTF
  // (numbers, strings, booleans, arrays, objects)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? _parseJson(String src) {
    try {
      // Use Dart's built-in JSON via dart:convert lite re-implementation
      // glTF JSON is well-formed ASCII so a simple recursive descent works.
      final p = _JsonParser(src.trim());
      final v = p.parseValue();
      return v as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Accessor helpers
  // ---------------------------------------------------------------------------

  static List<_Vec3>? _readVec3(Uint8List bin, Map<String, dynamic> accessor,
      List<dynamic> bufferViews) {
    final count = accessor['count'] as int;
    final bvIdx = accessor['bufferView'] as int;
    final bv = bufferViews[bvIdx] as Map<String, dynamic>;
    final byteOffset = (bv['byteOffset'] as int? ?? 0) +
        (accessor['byteOffset'] as int? ?? 0);
    final bd = ByteData.sublistView(bin);
    final out = <_Vec3>[];
    for (var i = 0; i < count; i++) {
      final o = byteOffset + i * 12;
      out.add(_Vec3(
        bd.getFloat32(o, Endian.little),
        bd.getFloat32(o + 4, Endian.little),
        bd.getFloat32(o + 8, Endian.little),
      ));
    }
    return out;
  }

  static List<int>? _readIndices(Uint8List bin, Map<String, dynamic> accessor,
      List<dynamic> bufferViews) {
    final count = accessor['count'] as int;
    final componentType = accessor['componentType'] as int; // 5123=UNSIGNED_SHORT
    final bvIdx = accessor['bufferView'] as int;
    final bv = bufferViews[bvIdx] as Map<String, dynamic>;
    final byteOffset = (bv['byteOffset'] as int? ?? 0) +
        (accessor['byteOffset'] as int? ?? 0);
    final bd = ByteData.sublistView(bin);
    final out = <int>[];
    for (var i = 0; i < count; i++) {
      if (componentType == 5123) {
        // UNSIGNED_SHORT
        out.add(bd.getUint16(byteOffset + i * 2, Endian.little));
      } else if (componentType == 5125) {
        // UNSIGNED_INT
        out.add(bd.getUint32(byteOffset + i * 4, Endian.little));
      } else {
        // UNSIGNED_BYTE
        out.add(bin[byteOffset + i]);
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Bitmap renderer
  // ---------------------------------------------------------------------------

  static Future<Uint8List?> _renderToBitmap({
    required List<_Triangle> triangles,
    required int size,
    required ui.Color color,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final half = size / 2.0;

    // Base RGB components
    final r = color.r;
    final g = color.g;
    final b = color.b;
    final a = color.a;

    // Orthographic projection: model coords ∈ [-1,1]; map to [0,size]
    // X-right, Y-up in model → X-right, Y-down on canvas (flip Y)
    ui.Offset project(_Vec3 v) =>
        ui.Offset(half + v.x * half, half - v.y * half);

    const ambient = 0.30;  // minimum brightness
    const diffuse = 0.70;  // max diffuse contribution

    final paint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..isAntiAlias = true;

    // Clip to circle so edges look smooth
    final clipPath = ui.Path()
      ..addOval(ui.Rect.fromCircle(
          center: ui.Offset(half, half), radius: half - 0.5));
    canvas.clipPath(clipPath);

    for (final tri in triangles) {
      final pa = project(tri.a);
      final pb = project(tri.b);
      final pc = project(tri.c);

      // tri.faceNormal.x holds the diffuse dot factor (stored in x=y=z)
      final factor = (ambient + diffuse * tri.faceNormal.x).clamp(0.0, 1.0);

      paint.color = ui.Color.from(
        alpha: a,
        red: (r * factor).clamp(0.0, 1.0),
        green: (g * factor).clamp(0.0, 1.0),
        blue: (b * factor).clamp(0.0, 1.0),
      );

      final path = ui.Path()
        ..moveTo(pa.dx, pa.dy)
        ..lineTo(pb.dx, pb.dy)
        ..lineTo(pc.dx, pc.dy)
        ..close();
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);
  final double x, y, z;
}

class _Triangle {
  const _Triangle(this.a, this.b, this.c, this.depth, this.faceNormal);
  final _Vec3 a, b, c;
  final double depth;
  final _Vec3 faceNormal;
}

// ---------------------------------------------------------------------------
// Minimal recursive-descent JSON parser
// ---------------------------------------------------------------------------

class _JsonParser {
  _JsonParser(this._src);
  final String _src;
  int _pos = 0;

  dynamic parseValue() {
    _skipWs();
    if (_pos >= _src.length) return null;
    final ch = _src[_pos];
    if (ch == '{') return _parseObject();
    if (ch == '[') return _parseArray();
    if (ch == '"') return _parseString();
    if (ch == 't') { _pos += 4; return true; }
    if (ch == 'f') { _pos += 5; return false; }
    if (ch == 'n') { _pos += 4; return null; }
    return _parseNumber();
  }

  Map<String, dynamic> _parseObject() {
    _pos++; // '{'
    final map = <String, dynamic>{};
    _skipWs();
    while (_pos < _src.length && _src[_pos] != '}') {
      _skipWs();
      final key = _parseString();
      _skipWs();
      _pos++; // ':'
      _skipWs();
      final val = parseValue();
      map[key] = val;
      _skipWs();
      if (_pos < _src.length && _src[_pos] == ',') _pos++;
      _skipWs();
    }
    _pos++; // '}'
    return map;
  }

  List<dynamic> _parseArray() {
    _pos++; // '['
    final list = <dynamic>[];
    _skipWs();
    while (_pos < _src.length && _src[_pos] != ']') {
      list.add(parseValue());
      _skipWs();
      if (_pos < _src.length && _src[_pos] == ',') _pos++;
      _skipWs();
    }
    _pos++; // ']'
    return list;
  }

  String _parseString() {
    _pos++; // opening '"'
    final buf = StringBuffer();
    while (_pos < _src.length) {
      final ch = _src[_pos];
      if (ch == '"') { _pos++; break; }
      if (ch == '\\') {
        _pos++;
        buf.write(_src[_pos]);
      } else {
        buf.write(ch);
      }
      _pos++;
    }
    return buf.toString();
  }

  num _parseNumber() {
    final start = _pos;
    final numChars = {'-', '0','1','2','3','4','5','6','7','8','9','.','e','E','+'};
    while (_pos < _src.length && numChars.contains(_src[_pos])) { _pos++; }
    final s = _src.substring(start, _pos);
    return s.contains('.') || s.contains('e') || s.contains('E')
        ? double.parse(s)
        : int.parse(s);
  }

  void _skipWs() {
    while (_pos < _src.length && _src[_pos].trim().isEmpty) { _pos++; }
  }
}
