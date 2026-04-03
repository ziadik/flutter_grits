import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grits/screens/effects_map_screen.dart';

/// Экран загрузки с асинхронной загрузкой ресурсов
class MapLoaderScreen extends StatefulWidget {
  const MapLoaderScreen({super.key});

  @override
  State<MapLoaderScreen> createState() => _MapLoaderScreenState();
}

class _MapLoaderScreenState extends State<MapLoaderScreen> {
  Map<String, dynamic>? _mapData;
  Map<String, dynamic>? _effectsJson;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      // Загружаем карту
      final mapJson = await rootBundle.loadString('assets/maps/small_map1.json');
      final mapData = jsonDecode(mapJson);

      // Загружаем эффекты
      final effectsJson = await rootBundle.loadString('assets/grits_effects.json');
      final effectsData = jsonDecode(effectsJson);

      setState(() {
        _mapData = mapData;
        _effectsJson = effectsData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Загрузка карты...'),
            ],
          ),
        ),
      );
    }

    if (_mapData == null || _effectsJson == null) {
      return const Scaffold(
        body: Center(child: Text('Не удалось загрузить ресурсы')),
      );
    }

    return EffectsMapScreen(
      mapData: _mapData!,
      effectsJson: _effectsJson!,
      effectsImage: const AssetImage('assets/grits_effects.png'),
    );
  }
}
