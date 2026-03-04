import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// Cubit that holds the current [ThemeMode] and persists it.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark) {
    _loadTheme();
  }

  static const String _key = AppConstants.themeModeKey;

  Future<void> _loadTheme() async {
    try {
      final saved = StorageService.getString(_key);
      if (saved == null) {
        emit(ThemeMode.dark);
        return;
      }
      switch (saved) {
        case 'dark':
          emit(ThemeMode.dark);
          break;
        case 'system':
          emit(ThemeMode.system);
          break;
        default:
          emit(ThemeMode.dark);
      }
    } catch (_) {
      emit(ThemeMode.light);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await StorageService.saveString(_key, value);
  }

  Future<void> toggleBetweenLightAndDark() async {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(next);
  }
}
