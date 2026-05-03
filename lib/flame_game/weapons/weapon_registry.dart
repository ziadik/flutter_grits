// lib/flame_game/weapons/weapon_registry.dart
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/weapons/machine_gun.dart';
import 'package:flutter_grits/flame_game/weapons/shot_gun.dart';
import 'package:flutter_grits/flame_game/weapons/chain_gun.dart';
import 'package:flutter_grits/flame_game/weapons/rocket_launcher.dart';
import 'package:flutter_grits/flame_game/weapons/grenade_launcher.dart';
import 'package:flutter_grits/flame_game/weapons/shield.dart';
import 'package:flutter_grits/flame_game/weapons/railgun.dart';

/// Factory для создания оружия по имени.
///
/// Регистрирует все доступные виды оружия и позволяет создавать их экземпляры.
class WeaponRegistry {
  static final Map<String, WeaponBase Function()> _weapons = {};

  /// Регистрация всех оружий (вызывать один раз при инициализации)
  static void register() {
    _weapons['MachineGun'] = () => MachineGun();
    _weapons['ShotGun'] = () => ShotGun();
    _weapons['ChainGun'] = () => ChainGun();
    _weapons['RocketLauncher'] = () => RocketLauncher();
    _weapons['GrenadeLauncher'] = () => GrenadeLauncher();
    _weapons['Railgun'] = () => Railgun();
  }

  /// Создание оружия по имени
  ///
  /// [name] - название оружия (должно быть зарегистрировано)
  ///
  /// [throws] если оружие не найдено
  static WeaponBase createWeapon(String name) {
    final factory = _weapons[name];
    if (factory == null) {
      throw Exception(
        'Unknown weapon: $name. Registered weapons: ${_weapons.keys}',
      );
    }
    return factory();
  }

  /// Получить список всех зарегистрированных оружий
  static List<String> getRegisteredWeapons() {
    return _weapons.keys.toList();
  }

  /// Проверка, зарегистрировано ли оружие
  static bool isRegistered(String name) {
    return _weapons.containsKey(name);
  }
}

/// Типы оружия (соответствует JS коду)
enum WeaponType {
  /// Прямой огонь (MachineGun, ShotGun, ChainGun)
  directFire,

  /// Навесной огонь (GrenadeLauncher, RocketLauncher)
  indirectFire,

  /// Особое / Дефенсивное (Shield, Landmine, Sword, Thrusters)
  special,
}

/// Метаданные оружия для UI
class WeaponMetadata {
  final String itemID;
  final String displayName;
  final String displayDesc;
  final WeaponType type;
  final double damage;
  final double fireRate; // выстрелов в секунду
  final String icon;
  final double energyCost;
  final String logicClass;

  const WeaponMetadata({
    required this.itemID,
    required this.displayName,
    required this.displayDesc,
    required this.type,
    required this.damage,
    required this.fireRate,
    required this.icon,
    required this.energyCost,
    required this.logicClass,
  });
}
