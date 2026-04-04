import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grits/screens/effects_map_screen.dart';

class MapLoaderScreen extends StatefulWidget {
  const MapLoaderScreen({super.key});

  @override
  State<MapLoaderScreen> createState() => _MapLoaderScreenState();
}

class _MapLoaderScreenState extends State<MapLoaderScreen> {
  Map<String, dynamic>? _mapData;
  Map<String, dynamic>? _effectsJson;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      debugPrint('Начинаем загрузку ресурсов...');

      // Загружаем карту
      final mapJsonString = await rootBundle.loadString(
        'assets/maps/small_map1.json',
      );
      debugPrint('Карта загружена, длина: ${mapJsonString.length}');
      final mapData = jsonDecode(mapJsonString);

      // Загружаем эффекты
      final effectsJsonString = await rootBundle.loadString(
        'assets/grits_effects.json',
      );
      debugPrint('Эффекты загружены, длина: ${effectsJsonString.length}');
      final effectsData = jsonDecode(effectsJsonString);

      if (mounted) {
        setState(() {
          _mapData = mapData;
          _effectsJson = effectsData;
          _isLoading = false;
        });
        debugPrint('Ресурсы успешно загружены');
      }
    } catch (e, stackTrace) {
      debugPrint('Ошибка загрузки: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text('Ошибка загрузки ресурсов:'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
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
