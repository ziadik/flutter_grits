// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'tile_map_viewer_effect.dart';

// // Основной экран приложения
// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Tile Map with Effects',
//       theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
//       home: MapLoaderScreen(),
//     );
//   }
// }

// class MapLoaderScreen extends StatefulWidget {
//   const MapLoaderScreen({super.key});

//   @override
//   _MapLoaderScreenState createState() => _MapLoaderScreenState();
// }

// class _MapLoaderScreenState extends State<MapLoaderScreen> {
//   Map<String, dynamic>? _mapData;
//   Map<String, dynamic>? _effectsJson;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadResources();
//   }

//   Future<void> _loadResources() async {
//     try {
//       // Загружаем карту
//       final mapJson = await rootBundle.loadString('assets/maps/small_map1.json');
//       final mapData = jsonDecode(mapJson);

//       // Загружаем эффекты
//       final effectsJson = await rootBundle.loadString('assets/grits_effects.json');
//       final effectsData = jsonDecode(effectsJson);

//       setState(() {
//         _mapData = mapData;
//         _effectsJson = effectsData;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Ошибка загрузки: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         body: Center(
//           child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text('Загрузка карты...')]),
//         ),
//       );
//     }

//     if (_mapData == null || _effectsJson == null) {
//       return Scaffold(body: Center(child: Text('Не удалось загрузить ресурсы')));
//     }

//     return EffectsMapScreen(mapData: _mapData!, effectsJson: _effectsJson!);
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_grits/player.dart';

void main() => runApp(MyApp());
