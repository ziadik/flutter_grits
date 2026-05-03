import 'package:flutter/material.dart';
import 'package:flutter_grits/managers/settings_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';

/// Модальное окно настроек игры
class SettingsDialog extends StatefulWidget {
  final VoidCallback onClosed;

  const SettingsDialog({super.key, required this.onClosed});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late SettingsManager _settings;
  late bool _musicEnabled;
  late bool _sfxEnabled;
  late double _musicVolume;
  late double _sfxVolume;

  @override
  void initState() {
    super.initState();
    _settings = SettingsManager();
    _musicEnabled = _settings.musicEnabled;
    _sfxEnabled = _settings.sfxEnabled;
    _musicVolume = _settings.musicVolume;
    _sfxVolume = _settings.sfxVolume;
  }

  void _saveAndClose() {
    _settings.setMusicEnabled(_musicEnabled);
    _settings.setSfxEnabled(_sfxEnabled);
    _settings.setMusicVolume(_musicVolume);
    _settings.setSfxVolume(_sfxVolume);
    
    // Обновляем SoundManager
    SoundManager().updateFromSettings();
    
    widget.onClosed();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Музыка
            _buildSettingRow(
              icon: Icons.music_note,
              title: 'Music',
              value: _musicEnabled,
              onChanged: (value) {
                setState(() {
                  _musicEnabled = value;
                  if (!value) {
                    SoundManager().pauseBackgroundMusic();
                  }
                });
              },
              slider: _musicEnabled
                  ? Slider(
                      value: _musicVolume,
                      onChanged: (value) {
                        setState(() => _musicVolume = value);
                        _settings.setMusicVolume(value);
                      },
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.grey[800],
                    )
                  : null,
              volumeValue: _musicVolume,
            ),
            
            const SizedBox(height: 16),
            
            // Звуковые эффекты
            _buildSettingRow(
              icon: Icons.volume_up,
              title: 'Sound Effects',
              value: _sfxEnabled,
              onChanged: (value) {
                setState(() => _sfxEnabled = value);
                if (value) {
                  // Тестовый звук для проверки
                  SoundManager().playSfx(SoundAssets.menuSelect);
                }
              },
              slider: _sfxEnabled
                  ? Slider(
                      value: _sfxVolume,
                      onChanged: (value) {
                        setState(() => _sfxVolume = value);
                        _settings.setSfxVolume(value);
                      },
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.grey[800],
                    )
                  : null,
              volumeValue: _sfxVolume,
            ),
            
            const SizedBox(height: 32),
            
            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClosed();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _saveAndClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    Widget? slider,
    double? volumeValue,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blueAccent,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[800],
            ),
          ],
        ),
        if (slider != null && value) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.grey, size: 20),
              Expanded(child: slider),
              const Icon(Icons.volume_up, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                '${(volumeValue! * 100).toInt()}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
