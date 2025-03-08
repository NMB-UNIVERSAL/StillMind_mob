import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  String? _userId;

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  String? get currentUserId => _userId;
  bool get isAuthenticated => _userId != null;
  SupabaseClient get client => _client;

  Future<void> initialize(String supabaseUrl, String supabaseKey) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    _client = Supabase.instance.client;
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final session = _client.auth.currentSession;
    _userId = session?.user.id;
  }

  // Auth methods
  Future<void> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    _userId = response.user?.id;
  }

  Future<void> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    _userId = response.user?.id;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _userId = null;
  }

  // Breathing stats methods
  Future<void> saveBreathingCycle(String date, int count) async {
    if (_userId == null) return;

    // First check if a record exists
    final response = await _client
        .from('breathing_stats')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    Map<String, dynamic> statsData = {};
    if (response != null && response['stats'] != null) {
      statsData = Map<String, dynamic>.from(response['stats']);
    }

    // Update or create the cycle count for the date
    if (statsData.containsKey(date)) {
      statsData[date] = (statsData[date] as int) + 1;
    } else {
      statsData[date] = 1;
    }

    // Save back to the database (upsert)
    await _client.from('breathing_stats').upsert(
      {
        'user_id': _userId,
        'stats': statsData,
      },
    );
  }

  Future<Map<String, int>> getBreathingStats() async {
    if (_userId == null) return {};

    final response = await _client
        .from('breathing_stats')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (response != null && response['stats'] != null) {
      final rawStats = Map<String, dynamic>.from(response['stats']);
      return rawStats.map((key, value) => MapEntry(key, value as int));
    }
    
    return {};
  }

  // Settings methods with specified format
  Future<void> saveSettings(Map<String, dynamic> rawSettings) async {
    if (_userId == null) return;

    // Debug the value before converting
    print("isDarkMode value being saved: ${rawSettings['isDarkMode']}");
    
    // Convert app settings to the specified format with more explicit boolean check
    final formattedSettings = {
      "sound": rawSettings['soundEnabled'] ?? true,
      "theme": rawSettings['isDarkMode'] == true ? "dark" : "light",
      "notifications": rawSettings['notificationsEnabled'] ?? true,
      "progress_style": _getProgressStyleString(rawSettings['visualizationType']),
      "breathing_times": {
        "hold": rawSettings['holdTime'] ?? 7,
        "exhale": rawSettings['exhaleTime'] ?? 8,
        "inhale": rawSettings['inhaleTime'] ?? 4
      }
    };

    print("Formatted theme being saved: ${formattedSettings['theme']}");

    await _client.from('app_settings').upsert({
      'user_id': _userId,
      'settings': formattedSettings,
    });
  }

  Future<Map<String, dynamic>> getSettings() async {
    if (_userId == null) return {};

    final response = await _client
        .from('app_settings')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    Map<String, dynamic> rawSettings = {};
    
    if (response != null && response['settings'] != null) {
      final dbSettings = Map<String, dynamic>.from(response['settings']);
      
      // Convert from database format to app format
      rawSettings = {
        'soundEnabled': dbSettings['sound'] ?? true,
        'isDarkMode': dbSettings['theme'] == 'dark',
        'notificationsEnabled': dbSettings['notifications'] ?? true,
        'visualizationType': _getVisualizationTypeIndex(dbSettings['progress_style']),
      };
      
      // Handle nested breathing_times
      if (dbSettings['breathing_times'] != null) {
        final breathingTimes = Map<String, dynamic>.from(dbSettings['breathing_times']);
        rawSettings['inhaleTime'] = breathingTimes['inhale'] ?? 4;
        rawSettings['holdTime'] = breathingTimes['hold'] ?? 7;
        rawSettings['exhaleTime'] = breathingTimes['exhale'] ?? 8;
      }
    }
    
    return rawSettings;
  }

  // Helper methods for formatting
  String _getProgressStyleString(dynamic visualizationType) {
    int type = 0;
    if (visualizationType is int) {
      type = visualizationType;
    }
    
    switch (type) {
      case 1: return "circle";
      case 2: return "triangle";
      default: return "bars";
    }
  }
  
  int _getVisualizationTypeIndex(String? progressStyle) {
    switch (progressStyle) {
      case "circle": return 1;
      case "triangle": return 2;
      default: return 0; // Default to bars
    }
  }

  // Notification settings methods
  Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    if (_userId == null) return;

    // Format notification settings to match the specified format
    final formattedSettings = {
      "time": "${settings['hour'].toString().padLeft(2, '0')}:${settings['minute'].toString().padLeft(2, '0')}",
      "enabled": settings['enabled'] ?? true
    };

    await _client.from('notification_settings').upsert({
      'user_id': _userId,
      'settings': formattedSettings,
    });
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    if (_userId == null) return {};

    final response = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    Map<String, dynamic> settings = {};
    
    if (response != null && response['settings'] != null) {
      final dbSettings = Map<String, dynamic>.from(response['settings']);
      
      // Convert time string back to hour and minute
      if (dbSettings['time'] != null) {
        final timeParts = dbSettings['time'].split(':');
        settings = {
          'hour': int.parse(timeParts[0]),
          'minute': int.parse(timeParts[1]),
          'enabled': dbSettings['enabled'] ?? true
        };
      }
    }
    
    return settings;
  }

  // Achievement methods
  Future<Map<String, dynamic>> getAchievements() async {
    if (_userId == null) return {};

    final response = await _client
        .from('achievements')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (response != null && response['achievements'] != null) {
      return Map<String, dynamic>.from(response['achievements']);
    }
    
    // Return default achievement structure
    return {
      "completed": [],
      "progress": {
        "breathing_exercises": 0,
        "current_streak": 0
      }
    };
  }

  Future<void> saveAchievements(Map<String, dynamic> achievements) async {
    if (_userId == null) return;

    await _client.from('achievements').upsert({
      'user_id': _userId,
      'achievements': achievements,
    });
  }

  Future<void> unlockAchievement(String achievementId) async {
    if (_userId == null) return;

    // Get current achievements
    final achievements = await getAchievements();
    
    // Get the completed list or initialize if it doesn't exist
    List<String> completed = [];
    if (achievements.containsKey('completed')) {
      completed = List<String>.from(achievements['completed']);
    }
    
    // Add the achievement if not already unlocked
    if (!completed.contains(achievementId)) {
      completed.add(achievementId);
      
      // Update the achievements
      achievements['completed'] = completed;
      await saveAchievements(achievements);
    }
  }

  Future<bool> isAchievementUnlocked(String achievementId) async {
    final achievements = await getAchievements();
    if (achievements.containsKey('completed')) {
      return List<String>.from(achievements['completed']).contains(achievementId);
    }
    return false;
  }

  Future<void> updateAchievementProgress() async {
    if (_userId == null) return;

    // Get breathing stats
    final stats = await getBreathingStats();
    final totalExercises = stats.values.fold(0, (sum, count) => sum + count);
    final currentStreak = _calculateStreak(stats);
    
    // Get current achievements
    final achievements = await getAchievements();
    
    // Initialize progress object if it doesn't exist
    if (!achievements.containsKey('progress')) {
      achievements['progress'] = {};
    }
    
    // Update progress
    achievements['progress']['breathing_exercises'] = totalExercises;
    achievements['progress']['current_streak'] = currentStreak;
    
    // Save updated achievements
    await saveAchievements(achievements);
    
    // Check if any new achievements have been unlocked
    await _checkAchievements(totalExercises, currentStreak);
  }

  int _calculateStreak(Map<String, int> stats) {
    if (stats.isEmpty) return 0;

    final now = DateTime.now();
    var currentDate = now;
    var streak = 0;

    while (true) {
      String dateKey = currentDate.toIso8601String().split('T')[0];
      if (stats.containsKey(dateKey) && stats[dateKey]! > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Future<void> _checkAchievements(int totalExercises, int currentStreak) async {
    // Get current achievements
    final achievements = await getAchievements();
    List<String> completed = [];
    if (achievements.containsKey('completed')) {
      completed = List<String>.from(achievements['completed']);
    } else {
      achievements['completed'] = completed;
    }
    
    // Check for exercise count achievements
    if (totalExercises >= 1 && !completed.contains('getting_started')) {
      completed.add('getting_started');
    }
    
    if (totalExercises >= 50 && !completed.contains('regular_breather')) {
      completed.add('regular_breather');
    }
    
    if (totalExercises >= 100 && !completed.contains('breathing_master')) {
      completed.add('breathing_master');
    }
    
    // Check for streak achievements
    if (currentStreak >= 3 && !completed.contains('consistent')) {
      completed.add('consistent');
    }
    
    if (currentStreak >= 7 && !completed.contains('weekly_warrior')) {
      completed.add('weekly_warrior');
    }
    
    if (currentStreak >= 30 && !completed.contains('monthly_master')) {
      completed.add('monthly_master');
    }
    
    // Save updated achievements
    achievements['completed'] = completed;
    await saveAchievements(achievements);
  }

  // Account methods
  String? getUserEmail() {
    final user = _client.auth.currentUser;
    return user?.email;
  }
  
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
  
  Future<void> deleteAccount() async {
    if (_userId == null) return;
    
    try {
      // Delete user's settings
      await _client.from('app_settings').delete().eq('user_id', _userId);
      
      // Delete user's notification settings
      await _client.from('notification_settings').delete().eq('user_id', _userId);
      
      // Delete user's achievements
      await _client.from('achievements').delete().eq('user_id', _userId);
      
      // Delete user's breathing stats
      await _client.from('breathing_stats').delete().eq('user_id', _userId);
      
      // For user account deletion, we'll sign out since we don't have direct
      // account deletion in the client SDK for security reasons.
      // In a production app, you'd need a server function for this.
      await signOut();
    } catch (e) {
      rethrow;
    }
  }
} 