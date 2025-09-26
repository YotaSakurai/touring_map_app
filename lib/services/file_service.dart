import 'dart:io';
import 'package:xml/xml.dart';

/// GPX/KMLファイル処理サービス
class FileService {
  /// GPXファイルをパースしてルートデータを抽出
  Future<Map<String, dynamic>> parseGpxFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final document = XmlDocument.parse(content);

      final routes = <Map<String, dynamic>>[];
      final waypoints = <Map<String, dynamic>>[];
      final tracks = <Map<String, dynamic>>[];

      // GPXの構造を解析
      final gpx = document.rootElement;
      
      // ウェイポイントを抽出
      for (final wpt in gpx.findAllElements('wpt')) {
        final lat = double.parse(wpt.getAttribute('lat')!);
        final lon = double.parse(wpt.getAttribute('lon')!);
        final name = wpt.findElements('name').isNotEmpty 
            ? wpt.findElements('name').first.innerText 
            : null;

        waypoints.add({
          'lat': lat,
          'lon': lon,
          'name': name,
        });
      }

      // ルートを抽出
      for (final rte in gpx.findAllElements('rte')) {
        final routePoints = <Map<String, dynamic>>[];
        
        for (final rtept in rte.findAllElements('rtept')) {
          final lat = double.parse(rtept.getAttribute('lat')!);
          final lon = double.parse(rtept.getAttribute('lon')!);
          routePoints.add({'lat': lat, 'lon': lon});
        }

        if (routePoints.isNotEmpty) {
          routes.add({
            'name': rte.findElements('name').isNotEmpty 
                ? rte.findElements('name').first.innerText 
                : 'Unnamed Route',
            'points': routePoints,
          });
        }
      }

      // トラックを抽出
      for (final trk in gpx.findAllElements('trk')) {
        final trackPoints = <Map<String, dynamic>>[];
        
        for (final trkseg in trk.findAllElements('trkseg')) {
          for (final trkpt in trkseg.findAllElements('trkpt')) {
            final lat = double.parse(trkpt.getAttribute('lat')!);
            final lon = double.parse(trkpt.getAttribute('lon')!);
            final time = trkpt.findElements('time').isNotEmpty 
                ? trkpt.findElements('time').first.innerText 
                : null;
            final ele = trkpt.findElements('ele').isNotEmpty 
                ? double.tryParse(trkpt.findElements('ele').first.innerText) 
                : null;

            trackPoints.add({
              'lat': lat,
              'lon': lon,
              'time': time,
              'ele': ele,
            });
          }
        }

        if (trackPoints.isNotEmpty) {
          tracks.add({
            'name': trk.findElements('name').isNotEmpty 
                ? trk.findElements('name').first.innerText 
                : 'Unnamed Track',
            'points': trackPoints,
          });
        }
      }

      return {
        'routes': routes,
        'waypoints': waypoints,
        'tracks': tracks,
        'metadata': {
          'creator': gpx.getAttribute('creator'),
          'version': gpx.getAttribute('version'),
        },
      };
    } catch (e) {
      throw Exception('GPXファイルの解析に失敗しました: $e');
    }
  }

  /// KMLファイルをパースしてルートデータを抽出
  Future<Map<String, dynamic>> parseKmlFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final document = XmlDocument.parse(content);

      final routes = <Map<String, dynamic>>[];
      final waypoints = <Map<String, dynamic>>[];

      // KMLの構造を解析
      final kml = document.rootElement;
      
      // Placemarkを抽出
      for (final placemark in kml.findAllElements('Placemark')) {
        final name = placemark.findElements('name').isNotEmpty 
            ? placemark.findElements('name').first.innerText 
            : null;
        final description = placemark.findElements('description').isNotEmpty 
            ? placemark.findElements('description').first.innerText 
            : null;

        // LineString（ルート）を抽出
        final lineString = placemark.findElements('LineString').firstOrNull;
        if (lineString != null) {
          final coordinates = lineString.findElements('coordinates').firstOrNull?.innerText;
          if (coordinates != null) {
            final points = _parseKmlCoordinates(coordinates);
            if (points.isNotEmpty) {
              routes.add({
                'name': name,
                'description': description,
                'points': points,
              });
            }
          }
        }

        // Point（ウェイポイント）を抽出
        final point = placemark.findElements('Point').firstOrNull;
        if (point != null) {
          final coordinates = point.findElements('coordinates').firstOrNull?.innerText;
          if (coordinates != null) {
            final coords = _parseKmlCoordinates(coordinates);
            if (coords.isNotEmpty) {
              waypoints.add({
                'name': name,
                'description': description,
                'lat': coords.first['lat'],
                'lon': coords.first['lon'],
              });
            }
          }
        }
      }

      return {
        'routes': routes,
        'waypoints': waypoints,
        'metadata': {
          'name': kml.findElements('name').isNotEmpty 
              ? kml.findElements('name').first.innerText 
              : null,
        },
      };
    } catch (e) {
      throw Exception('KMLファイルの解析に失敗しました: $e');
    }
  }

  /// KMLの座標文字列をパース
  List<Map<String, double>> _parseKmlCoordinates(String coordinates) {
    final points = <Map<String, double>>[];
    final lines = coordinates.trim().split('\n');
    
    for (final line in lines) {
      final coords = line.trim().split(',');
      if (coords.length >= 2) {
        final lon = double.tryParse(coords[0].trim());
        final lat = double.tryParse(coords[1].trim());
        if (lon != null && lat != null) {
          points.add({'lat': lat, 'lon': lon});
        }
      }
    }
    
    return points;
  }

  /// ルートデータをGPX形式でエクスポート
  String exportToGpx({
    required String name,
    required List<Map<String, dynamic>> routePoints,
    List<Map<String, dynamic>>? waypoints,
    String? description,
  }) {
    final buffer = StringBuffer();
    
    // GPXヘッダー
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="TouringMapApp" xmlns="http://www.topografix.com/GPX/1/1">');
    
    // メタデータ
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>$name</name>');
    if (description != null) {
      buffer.writeln('    <desc>$description</desc>');
    }
    buffer.writeln('    <time>${DateTime.now().toIso8601String()}</time>');
    buffer.writeln('  </metadata>');
    
    // ウェイポイント
    if (waypoints != null) {
      for (final wpt in waypoints) {
        buffer.writeln('  <wpt lat="${wpt['lat']}" lon="${wpt['lon']}">');
        if (wpt['name'] != null) {
          buffer.writeln('    <name>${wpt['name']}</name>');
        }
        buffer.writeln('  </wpt>');
      }
    }
    
    // ルート
    buffer.writeln('  <rte>');
    buffer.writeln('    <name>$name</name>');
    for (final point in routePoints) {
      buffer.writeln('    <rtept lat="${point['lat']}" lon="${point['lon']}"/>');
    }
    buffer.writeln('  </rte>');
    
    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  /// ルートデータをKML形式でエクスポート
  String exportToKml({
    required String name,
    required List<Map<String, dynamic>> routePoints,
    List<Map<String, dynamic>>? waypoints,
    String? description,
  }) {
    final buffer = StringBuffer();
    
    // KMLヘッダー
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>$name</name>');
    if (description != null) {
      buffer.writeln('    <description>$description</description>');
    }
    
    // ルート（LineString）
    buffer.writeln('    <Placemark>');
    buffer.writeln('      <name>$name</name>');
    buffer.writeln('      <LineString>');
    buffer.writeln('        <coordinates>');
    for (final point in routePoints) {
      buffer.writeln('          ${point['lon']},${point['lat']}');
    }
    buffer.writeln('        </coordinates>');
    buffer.writeln('      </LineString>');
    buffer.writeln('    </Placemark>');
    
    // ウェイポイント
    if (waypoints != null) {
      for (final wpt in waypoints) {
        buffer.writeln('    <Placemark>');
        if (wpt['name'] != null) {
          buffer.writeln('      <name>${wpt['name']}</name>');
        }
        buffer.writeln('      <Point>');
        buffer.writeln('        <coordinates>${wpt['lon']},${wpt['lat']}</coordinates>');
        buffer.writeln('      </Point>');
        buffer.writeln('    </Placemark>');
      }
    }
    
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    return buffer.toString();
  }

  /// ファイルを保存
  Future<void> saveFile(String content, String filePath) async {
    final file = File(filePath);
    await file.writeAsString(content);
  }
}
