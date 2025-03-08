import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stillmind/services/supabase_service.dart';
import 'package:stillmind/screens/auth_screen.dart';
import 'screens/account_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize Supabase
  final supabaseService = SupabaseService();
  await supabaseService.initialize(
    'https://aapfficpraduyrwccqyc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhcGZmaWNwcmFkdXlyd2NjcXljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEyNTA2ODksImV4cCI6MjA1NjgyNjY4OX0.ioe9RxNUJgD4Y0UJIHD1pkVVRHm9QJoWFizlmQ4i6-Y',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  final AudioManager _audioManager = AudioManager();
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initBackgroundMusic();
  }

  Future<void> _initBackgroundMusic() async {
    await _audioManager.initialize();
    
    // Get sound settings from Supabase if user is logged in
    bool isSoundEnabled = true;
    if (_supabaseService.isAuthenticated) {
      final settings = await _supabaseService.getSettings();
      isSoundEnabled = settings['soundEnabled'] ?? true;
    } else {
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
    }
    
    if (isSoundEnabled) {
      await _audioManager.playBackgroundMusic();
    }
  }

  @override
  void dispose() {
    _audioManager.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (_supabaseService.isAuthenticated) {
      // Get settings from Supabase
      final settings = await _supabaseService.getSettings();
      setState(() {
        _isDarkMode = settings['isDarkMode'] ?? false;
      });
    } else {
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      });
    }
  }

  void updateTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
    
    // Print debug information
    print("updateTheme called with isDarkMode: $isDarkMode");
    
    // Save theme setting to proper storage
    if (_supabaseService.isAuthenticated) {
      _supabaseService.saveSettings({
        'isDarkMode': isDarkMode,
        'soundEnabled': true,  // We'll fetch the actual value in a full implementation
        'visualizationType': 0, // Default to avoid overwriting other settings
      });
    } else {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('isDarkMode', isDarkMode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StillMind',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // White
        primaryColor: const Color(0xFF859FBB), // Green
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFFF9800),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)), // Dark Gray
        ),
        iconTheme: const IconThemeData(color: Color(0xFF555555)), // Gray
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Very Dark Gray
        primaryColor: const Color(0xFF766E7A), // Bright Blue
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFFFFAB40),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)), // Light Gray
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)), // White
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: _supabaseService.isAuthenticated ? '/home' : '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => HomePage(updateTheme: updateTheme, isDarkMode: _isDarkMode),
        '/account': (context) => const AccountPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final Function(bool) updateTheme;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.updateTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: AppBackground(
        isDarkMode: isDarkMode,
        child: Stack(
          children: [
            // Top right buttons
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  // Account button
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton.icon(
                      icon: const Icon(Icons.account_circle, color: Colors.white),
                      label: const Text(
                        'Account',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/account');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Help button
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.help, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('How to use StillMind'),
                            content: const SingleChildScrollView(
                              child: Text(
                                'StillMind is a breathing exercise app designed to help you '
                                'reduce stress and improve focus.\n\n'
                                'Follow the breathing patterns on the main screen. '
                                'The app will guide you through inhaling, holding, and exhaling.\n\n'
                                'Track your progress on the Stats page and earn achievements '
                                'as you develop a consistent breathing practice.\n\n'
                                'Customize your experience in the Settings page.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'StillMind',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Navigation buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          _buildNavButton(
                            context,
                            icon: Icons.play_arrow,
                            label: 'Start',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MainPage()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildNavButton(
                            context,
                            icon: Icons.bar_chart,
                            label: 'Stats',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StatsPage()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildNavButton(
                            context,
                            icon: Icons.emoji_events,
                            label: 'Achievements',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AchievementsPage()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildNavButton(
                            context,
                            icon: Icons.settings,
                            label: 'Settings',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsPage(
                                  updateTheme: updateTheme,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton.icon(
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  const AppBackground({
    super.key,
    required this.child,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            isDarkMode
                ? 'assets/images/dark_background.jpg'
                : 'assets/images/light_background.jpg',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withAlpha(51),
            BlendMode.darken,
          ),
        ),
      ),
      child: child,
    );
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, int> cyclesData = {};
  int currentStreak = 0;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadCyclesData();
  }

  Future<void> _loadCyclesData() async {
    final stats = await _supabaseService.getBreathingStats();
    setState(() {
      cyclesData = stats;
      currentStreak = _calculateStreak();
    });
  }

  int _calculateStreak() {
    if (cyclesData.isEmpty) return 0;

    final now = DateTime.now();
    var currentDate = now;
    var streak = 0;

    while (true) {
      String dateKey = currentDate.toIso8601String().split('T')[0];
      if (cyclesData.containsKey(dateKey) && cyclesData[dateKey]! > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  List<BarChartGroupData> _createBarGroups() {
    // Get the last 7 days
    final now = DateTime.now();
    final dates = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return date.toIso8601String().split('T')[0];
    });

    return dates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: cyclesData[date]?.toDouble() ?? 0,
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCycles = cyclesData.values.fold(0, (sum, count) => sum + count);

    return AppBackground(
      isDarkMode: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Statistics',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Breathing Cycles - Last 7 Days',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: cyclesData.isEmpty
                    ? const Center(child: Text('No data available yet'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (cyclesData.values.isEmpty
                                  ? 1
                                  : cyclesData.values.reduce((max, value) =>
                                          max > value ? max : value) +
                                      1)
                              .toDouble(),
                          minY: 0,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final date = DateTime.now().subtract(
                                      Duration(days: 6 - value.toInt()));
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${date.month}/${date.day}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value == value.roundToDouble()) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white30 : Colors.black12,
                                width: 1,
                              ),
                              left: BorderSide(
                                color: isDark ? Colors.white30 : Colors.black12,
                                width: 1,
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: isDark ? Colors.white10 : Colors.black12,
                              strokeWidth: 1,
                            ),
                          ),
                          barGroups: _createBarGroups(),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          totalCycles.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Total Cycles',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          currentStreak.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Day Streak',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _controller;
  String _text = 'Ready';
  int _phase = 0;
  double _bar1Value = 0.0;
  double _bar2Value = 0.0;
  double _bar3Value = 0.0;
  bool _isActive = true;
  late String _currentQuote;
  late VisualizationType _visualizationType;
  late AudioPlayer _audioPlayer;
  late int _inhaleTime;
  late int _holdTime;
  late int _exhaleTime;
  late bool _isSoundEnabled;
  final SupabaseService _supabaseService = SupabaseService();

  // List of meditation and breathing quotes
  final List<String> _quotes = [
    "Breathe deeply, for each breath is a new opportunity. -Unknown",
    "Inhale strength, exhale weakness. -Unknown",
    "“Your breath is your anchor. Use it to return to the present\n moment.” – Unknown",
    "“The mind is like water. When it's calm, everything is clear\n.” – Unknown",
    "“Take a deep breath. It's just a bad day, not a bad life.”\n – Unknown",
    "“To breathe is to live, and to live is to be mindful.” – Unknown",
    "“Every breath you take can change your life.” – Unknown",
    "“Mindfulness isn't difficult. What's difficult is to remember\n to be mindful.” – Sharon Salzberg",
    "“Breathe in peace, breathe out stress.” – Unknown"
        "“Life is a balance of holding on and\n letting go. Breathe deeply\n with every in-breath.” – Unknown",
    "“Strength doesn't come from what\n you can do. It comes from overcoming the things you once\n thought you couldn't.” – Rikki Rogers",
    "“The strongest people are not those who show strength in front of\n us but those who win battles we know nothing about.” – Unknown",
    "You are stronger than you think. Your resilience is your power."
        "“Fall seven times, stand up eight.” – Japanese Proverb",
    "“What lies behind us and what lies before us are tiny matters compared\n to what lies within us.” – Ralph Waldo Emerson",
    "“Your strength is a culmination of your struggles.” – Unknown",
    "“You never know how strong you are until\n being strong is your only choice\n.” – Bob Marley",
    "“Strength grows in the moments when you\n think you can't go on but you keep\n going anyway.” – Unknown",
    "“Difficulties mastered are opportunities won.” – Winston Churchill",
    "It's not the load that breaks you down, it's the way you carry it.",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _currentQuote = _quotes[_getRandomIndex()];
    _loadVisualizationType();
    _startBreathingExercise();
    _initAudio();
    _loadSettings();
  }

  int _getRandomIndex() {
    return DateTime.now().millisecondsSinceEpoch % _quotes.length;
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
  }

  Future<void> _loadSettings() async {
    if (_supabaseService.isAuthenticated) {
      final settings = await _supabaseService.getSettings();
      setState(() {
        _isSoundEnabled = settings['soundEnabled'] ?? true;
        _inhaleTime = settings['inhaleTime'] ?? 4;
        _holdTime = settings['holdTime'] ?? 7;
        _exhaleTime = settings['exhaleTime'] ?? 8;
        _visualizationType = VisualizationType.values[settings['visualizationType'] ?? 0];
      });
    } else {
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
        _inhaleTime = prefs.getInt('inhaleTime') ?? 4;
        _holdTime = prefs.getInt('holdTime') ?? 7;
        _exhaleTime = prefs.getInt('exhaleTime') ?? 8;
        _visualizationType = VisualizationType.values[prefs.getInt('visualizationType') ?? 0];
      });
    }
  }

  Future<void> _playPhaseAudio(String phase) async {
    if (_isSoundEnabled) {
      await _audioPlayer.play(AssetSource('audio/$phase.mp3'));
    }
  }

  Future<void> _startBreathingExercise() async {
    // Initial countdown
    setState(() => _text = 'Ready');
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _text = '3');
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _text = '2');
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _text = '1');
    await Future.delayed(const Duration(seconds: 1));

    while (mounted && _isActive) {
      // Inhale
      setState(() {
        _phase = 1;
        _text = 'Inhale';
        _bar1Value = 0.0;
      });
      _playPhaseAudio('inhale');
      for (int i = 0; i < (_inhaleTime * 10) && mounted && _isActive; i++) {
        setState(() => _bar1Value = (i + 1) / (_inhaleTime * 10));
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!_isActive) break;

      // Hold
      setState(() {
        _phase = 2;
        _text = 'Hold';
        _bar2Value = 0.0;
      });
      _playPhaseAudio('hold');
      for (int i = 0; i < (_holdTime * 10) && mounted && _isActive; i++) {
        setState(() => _bar2Value = (i + 1) / (_holdTime * 10));
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!_isActive) break;

      // Exhale
      setState(() {
        _phase = 3;
        _text = 'Exhale';
        _bar3Value = 0.0;
      });
      _playPhaseAudio('exhale');
      for (int i = 0; i < (_exhaleTime * 10) && mounted && _isActive; i++) {
        setState(() => _bar3Value = (i + 1) / (_exhaleTime * 10));
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!_isActive) break;

      // Save cycle completion and reset for next cycle
      if (_isActive) {
        await _saveCycleCompletion();
        setState(() {
          _bar1Value = 0.0;
          _bar2Value = 0.0;
          _bar3Value = 0.0;
        });
      }
    }
  }

  Future<void> _saveCycleCompletion() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _supabaseService.saveBreathingCycle(today, 1);
    
    // Update achievements after completing a cycle
    await _supabaseService.updateAchievementProgress();
  }

  void _restartExercise() {
    // Cancel current exercise
    _isActive = false;
    _timer?.cancel();

    // Replace current page with a new instance
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  void _completeExercise() async {
    setState(() => _isActive = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsPage()),
    ).then((_) {
      if (mounted) {
        setState(() => _isActive = true);
        _startBreathingExercise();
      }
    });
  }

  void _loadVisualizationType() async {
    if (_supabaseService.isAuthenticated) {
      final settings = await _supabaseService.getSettings();
      setState(() {
        _visualizationType = VisualizationType.values[settings['visualizationType'] ?? 0];
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _visualizationType = VisualizationType.values[prefs.getInt('visualizationType') ?? 0];
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      isDarkMode: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Breathing Exercise',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Text(
                  _text,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                if (_visualizationType == VisualizationType.bars)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: LinearProgressIndicator(
                          value: _bar1Value,
                          minHeight: 20,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _phase == 1 ? Colors.blue : Colors.grey[400]!,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: LinearProgressIndicator(
                          value: _bar2Value,
                          minHeight: 20,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _phase == 2 ? Colors.blue : Colors.grey[400]!,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: LinearProgressIndicator(
                          value: _bar3Value,
                          minHeight: 20,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _phase == 3 ? Colors.blue : Colors.grey[400]!,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_visualizationType == VisualizationType.circle)
                  CircularBreathingIndicator(
                    bar1Value: _bar1Value,
                    bar2Value: _bar2Value,
                    bar3Value: _bar3Value,
                    phase: _phase,
                  )
                else
                  TriangleBreathingIndicator(
                    bar1Value: _bar1Value,
                    bar2Value: _bar2Value,
                    bar3Value: _bar3Value,
                    phase: _phase,
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _restartExercise,
                      child: const Text('Restart'),
                    ),
                    ElevatedButton(
                      onPressed: _completeExercise,
                      child: const Text('Done'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _currentQuote,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic> _achievements = {};
  bool _isLoading = true;

  // Define achievement data
  final List<Map<String, dynamic>> _achievementsList = [
    {
      'id': 'getting_started',
      'icon': Icons.emoji_events,
      'title': 'Getting Started',
      'description': 'Complete your first breathing exercise',
      'requirement': 1, // 1 exercise
    },
    {
      'id': 'regular_breather',
      'icon': Icons.local_florist,
      'title': 'Regular Breather',
      'description': 'Complete 50 breathing exercises',
      'requirement': 50, // 50 exercises
    },
    {
      'id': 'breathing_master',
      'icon': Icons.forest,
      'title': 'Breathing Master',
      'description': 'Complete 100 breathing exercises',
      'requirement': 100, // 100 exercises
    },
    {
      'id': 'consistent',
      'icon': Icons.local_fire_department,
      'title': 'Consistent',
      'description': 'Maintain a 3-day streak',
      'streak_requirement': 3, // 3-day streak
    },
    {
      'id': 'weekly_warrior',
      'icon': Icons.person,
      'title': 'Weekly Warrior',
      'description': 'Maintain a 7-day streak',
      'streak_requirement': 7, // 7-day streak
    },
    {
      'id': 'monthly_master',
      'icon': Icons.star,
      'title': 'Monthly Master',
      'description': 'Maintain a 30-day streak',
      'streak_requirement': 30, // 30-day streak
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAchievementData();
  }

  Future<void> _loadAchievementData() async {
    setState(() => _isLoading = true);
    
    // Update achievement progress based on latest stats
    await _supabaseService.updateAchievementProgress();
    
    // Load current achievements
    _achievements = await _supabaseService.getAchievements();
    
    setState(() => _isLoading = false);
  }

  bool _isAchievementCompleted(String achievementId) {
    if (_achievements.containsKey('completed')) {
      return List<String>.from(_achievements['completed']).contains(achievementId);
    }
    return false;
  }

  int _getTotalExercises() {
    if (_achievements.containsKey('progress') && 
        _achievements['progress'].containsKey('breathing_exercises')) {
      return _achievements['progress']['breathing_exercises'];
    }
    return 0;
  }

  int _getCurrentStreak() {
    if (_achievements.containsKey('progress') && 
        _achievements['progress'].containsKey('current_streak')) {
      return _achievements['progress']['current_streak'];
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return AppBackground(
        isDarkMode: isDark,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Achievements'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppBackground(
      isDarkMode: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Achievements',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.only(
            top: 100,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          children: [
            // Stats card
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          _getTotalExercises().toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Total Exercises',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          _getCurrentStreak().toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Day Streak',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Achievement list
            ..._achievementsList.map((achievement) => _buildAchievementTile(
              id: achievement['id'],
              icon: achievement['icon'],
              title: achievement['title'],
              description: achievement['description'],
              isCompleted: _isAchievementCompleted(achievement['id']),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementTile({
    required String id,
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
        trailing: Icon(
          isCompleted ? Icons.check_circle : Icons.lock,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Function(bool) updateTheme;
  final bool isDarkMode;

  const SettingsPage({
    super.key,
    required this.updateTheme,
    required this.isDarkMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum VisualizationType {
  bars,
  circle,
  triangle,
}

class NotificationTime {
  final int hour;
  final int minute;

  NotificationTime(this.hour, this.minute);

  String get formatted {
    final hour12 = hour > 12 ? hour - 12 : hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  late AudioPlayer _backgroundPlayer;
  bool _isInitialized = false;

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal() {
    _backgroundPlayer = AudioPlayer();
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      _backgroundPlayer = AudioPlayer();
      _isInitialized = true;
    }
  }

  Future<void> playBackgroundMusic() async {
    await _backgroundPlayer.play(AssetSource('audio/background.mp3'));
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> stopBackgroundMusic() async {
    await _backgroundPlayer.stop();
  }

  void dispose() {
    _backgroundPlayer.dispose();
    _isInitialized = false;
  }
}

class _SettingsPageState extends State<SettingsPage> {
  late VisualizationType _visualizationType = VisualizationType.bars;
  late bool _isSoundEnabled;
  late int _inhaleTime;
  late int _holdTime;
  late int _exhaleTime;
  NotificationTime? _notificationTime;
  final AudioManager _audioManager = AudioManager();
  final NotificationService _notificationService = NotificationService();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    if (_supabaseService.isAuthenticated) {
      // Load settings from Supabase
      final settings = await _supabaseService.getSettings();
      final notificationSettings = await _supabaseService.getNotificationSettings();
      
      setState(() {
        _visualizationType = VisualizationType.values[settings['visualizationType'] ?? 0];
        _isSoundEnabled = settings['soundEnabled'] ?? true;
        _inhaleTime = settings['inhaleTime'] ?? 4;
        _holdTime = settings['holdTime'] ?? 7;
        _exhaleTime = settings['exhaleTime'] ?? 8;
        
        // Load notification time
        final hour = notificationSettings['hour'];
        final minute = notificationSettings['minute'];
        if (hour != null && minute != null) {
          _notificationTime = NotificationTime(hour, minute);
        }
        
        _isLoading = false;
      });
    } else {
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _visualizationType = VisualizationType.values[prefs.getInt('visualizationType') ?? 0];
        _isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
        _inhaleTime = prefs.getInt('inhaleTime') ?? 4;
        _holdTime = prefs.getInt('holdTime') ?? 7;
        _exhaleTime = prefs.getInt('exhaleTime') ?? 8;

        // Load notification time
        final hour = prefs.getInt('notificationHour');
        final minute = prefs.getInt('notificationMinute');
        if (hour != null && minute != null) {
          _notificationTime = NotificationTime(hour, minute);
        }
        
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_supabaseService.isAuthenticated) {
      // Save all settings to Supabase in the specified format
      await _supabaseService.saveSettings({
        'isDarkMode': widget.isDarkMode,
        'soundEnabled': _isSoundEnabled,
        'notificationsEnabled': _notificationTime != null,
        'inhaleTime': _inhaleTime,
        'holdTime': _holdTime,
        'exhaleTime': _exhaleTime,
        'visualizationType': _visualizationType.index,
      });
      
      // Save notification settings separately
      if (_notificationTime != null) {
        await _supabaseService.saveNotificationSettings({
          'hour': _notificationTime!.hour,
          'minute': _notificationTime!.minute,
          'enabled': true
        });
        
        // Schedule notification
        await _notificationService.scheduleDailyNotification(
          hour: _notificationTime!.hour,
          minute: _notificationTime!.minute,
        );
      } else {
        await _supabaseService.saveNotificationSettings({
          'enabled': false
        });
        await _notificationService.cancelAllNotifications();
      }
    } else {
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      
      // Save theme setting
      await prefs.setBool('isDarkMode', widget.isDarkMode);
      
      // Save sound settings
      await prefs.setBool('soundEnabled', _isSoundEnabled);
      
      // Save breathing durations
      await prefs.setInt('inhaleTime', _inhaleTime);
      await prefs.setInt('holdTime', _holdTime);
      await prefs.setInt('exhaleTime', _exhaleTime);
      
      // Save notification time
      if (_notificationTime != null) {
        await prefs.setInt('notificationHour', _notificationTime!.hour);
        await prefs.setInt('notificationMinute', _notificationTime!.minute);
        
        // Schedule notification
        await _notificationService.scheduleDailyNotification(
          hour: _notificationTime!.hour,
          minute: _notificationTime!.minute,
        );
      } else {
        await prefs.remove('notificationHour');
        await prefs.remove('notificationMinute');
        await _notificationService.cancelAllNotifications();
      }
      
      // Save visualization type
      await prefs.setInt('visualizationType', _visualizationType.index);
    }

    // Update background music state
    if (_isSoundEnabled) {
      await _audioManager.playBackgroundMusic();
    } else {
      await _audioManager.stopBackgroundMusic();
    }
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime != null
          ? TimeOfDay(
              hour: _notificationTime!.hour, minute: _notificationTime!.minute)
          : TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _notificationTime = NotificationTime(picked.hour, picked.minute);
      });
      await _saveSettings();

      // Schedule daily notification
      await _notificationService.scheduleDailyNotification(
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: widget.isDarkMode,
            onChanged: (value) async {
              widget.updateTheme(value);
              await _saveSettings();
            },
            activeColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.grey,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Enable or disable all sounds'),
            value: _isSoundEnabled,
            onChanged: (value) async {
              setState(() {
                _isSoundEnabled = value;
              });
              await _saveSettings();
            },
            activeColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.grey,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Exercise Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Inhale Duration'),
            subtitle: Text('$_inhaleTime seconds'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _inhaleTime > 2
                      ? () {
                          setState(() {
                            _inhaleTime--;
                          });
                          _saveSettings();
                        }
                      : null,
                ),
                Text('$_inhaleTime'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _inhaleTime < 10
                      ? () {
                          setState(() {
                            _inhaleTime++;
                          });
                          _saveSettings();
                        }
                      : null,
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Hold Duration'),
            subtitle: Text('$_holdTime seconds'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _holdTime > 2
                      ? () {
                          setState(() {
                            _holdTime--;
                          });
                          _saveSettings();
                        }
                      : null,
                ),
                Text('$_holdTime'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _holdTime < 15
                      ? () {
                          setState(() {
                            _holdTime++;
                          });
                          _saveSettings();
                        }
                      : null,
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Exhale Duration'),
            subtitle: Text('$_exhaleTime seconds'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _exhaleTime > 2
                      ? () {
                          setState(() {
                            _exhaleTime--;
                          });
                          _saveSettings();
                        }
                      : null,
                ),
                Text('$_exhaleTime'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _exhaleTime < 15
                      ? () {
                          setState(() {
                            _exhaleTime++;
                          });
                          _saveSettings();
                        }
                      : null,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Daily Reminder'),
            subtitle: Text(_notificationTime != null
                ? 'Set for ${_notificationTime!.formatted}'
                : 'Not set'),
            trailing: IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: _selectNotificationTime,
            ),
          ),
          ListTile(
            title: const Text('Visualization Style'),
            trailing: DropdownButton<VisualizationType>(
              value: _visualizationType,
              onChanged: (VisualizationType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _visualizationType = newValue;
                  });
                  _saveSettings();
                }
              },
              items: VisualizationType.values.map((VisualizationType type) {
                return DropdownMenuItem<VisualizationType>(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> helpsections = {
      "Getting Started": [
        "Click 'Start' to begin a breathing exercise",
        "Follow the on-screen instructions for inhaling, holding, and exhaling",
        "Complete cycles to earn achievements"
      ],
      "Features": [
        "Track your progress in the Stats page",
        "Earn achievements as you practice",
        "Customize your experience in Settings",
        "Choose different progress indicators"
      ],
      "Settings": [
        "Toggle Dark/Light mode",
        "Enable/Disable sounds",
        "Adjust breathing times",
        "Change progress style"
      ],
      "Tips": [
        "Practice regularly for best results",
        "Find a quiet, comfortable space",
        "Maintain good posture while breathing",
        "Stay consistent to build streaks"
      ]
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: helpsections.length,
        itemBuilder: (context, index) {
          final sectionTitle = helpsections.keys.elementAt(index);
          final sectionItems = helpsections[sectionTitle]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                sectionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: sectionItems
                  .map((item) => ListTile(
                        leading: const Icon(Icons.arrow_right),
                        title: Text(item),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/notification_icon',
      [
        NotificationChannel(
          channelKey: 'scheduled_channel',
          channelName: 'Scheduled Notifications',
          channelDescription: 'Channel for scheduled notifications',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
        )
      ],
    );
  }

  Future<void> requestPermissions() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    // Cancel any existing notifications first
    await cancelAllNotifications();

    // Calculate next occurrence of the specified time
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'scheduled_channel',
        title: 'Time to Meditate',
        body: 'Take a moment to breathe and relax.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true,
      ),
    );
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
  }
}

// Circular Visualization
class CircularBreathingIndicator extends StatelessWidget {
  final double bar1Value;
  final double bar2Value;
  final double bar3Value;
  final int phase;

  const CircularBreathingIndicator({
    super.key,
    required this.bar1Value,
    required this.bar2Value,
    required this.bar3Value,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: CircularBreathingPainter(
          bar1Value: bar1Value,
          bar2Value: bar2Value,
          bar3Value: bar3Value,
          phase: phase,
        ),
      ),
    );
  }
}

class CircularBreathingPainter extends CustomPainter {
  final double bar1Value;
  final double bar2Value;
  final double bar3Value;
  final int phase;

  CircularBreathingPainter({
    required this.bar1Value,
    required this.bar2Value,
    required this.bar3Value,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0;

    // Draw background arcs
    paint.color = Colors.grey[300]!;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      2 * math.pi / 3,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      math.pi / 6,
      2 * math.pi / 3,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      5 * math.pi / 6,
      2 * math.pi / 3,
      false,
      paint,
    );

    // Draw progress arcs
    paint.color = Colors.blue;
    if (phase == 1) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        -math.pi / 2,
        2 * math.pi / 3 * bar1Value,
        false,
        paint,
      );
    } else if (phase == 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        math.pi / 6,
        2 * math.pi / 3 * bar2Value,
        false,
        paint,
      );
    } else if (phase == 3) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        5 * math.pi / 6,
        2 * math.pi / 3 * bar3Value,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Triangle Visualization
class TriangleBreathingIndicator extends StatelessWidget {
  final double bar1Value;
  final double bar2Value;
  final double bar3Value;
  final int phase;

  const TriangleBreathingIndicator({
    super.key,
    required this.bar1Value,
    required this.bar2Value,
    required this.bar3Value,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: TriangleBreathingPainter(
          bar1Value: bar1Value,
          bar2Value: bar2Value,
          bar3Value: bar3Value,
          phase: phase,
        ),
      ),
    );
  }
}

class TriangleBreathingPainter extends CustomPainter {
  final double bar1Value;
  final double bar2Value;
  final double bar3Value;
  final int phase;

  TriangleBreathingPainter({
    required this.bar1Value,
    required this.bar2Value,
    required this.bar3Value,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0;

    final double triangleHeight = size.height * 0.8;
    final double triangleBase = size.width * 0.8;
    final double startX = size.width * 0.1;
    final double startY = size.height * 0.9;

    // Draw background lines
    paint.color = Colors.grey[300]!;
    // Bottom line
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX + triangleBase, startY),
      paint,
    );
    // Right line
    canvas.drawLine(
      Offset(startX + triangleBase, startY),
      Offset(startX + triangleBase / 2, startY - triangleHeight),
      paint,
    );
    // Left line
    canvas.drawLine(
      Offset(startX + triangleBase / 2, startY - triangleHeight),
      Offset(startX, startY),
      paint,
    );

    // Draw progress lines
    paint.color = Colors.blue;
    if (phase == 1) {
      // Bottom line progress
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + (triangleBase * bar1Value), startY),
        paint,
      );
    } else if (phase == 2) {
      // Right line progress
      final double progressX =
          startX + triangleBase - (triangleBase * bar2Value / 2);
      final double progressY = startY - (triangleHeight * bar2Value);
      canvas.drawLine(
        Offset(startX + triangleBase, startY),
        Offset(progressX, progressY),
        paint,
      );
    } else if (phase == 3) {
      // Left line progress
      final double progressX =
          startX + triangleBase / 2 - (triangleBase * bar3Value / 2);
      final double progressY =
          startY - triangleHeight + (triangleHeight * bar3Value);
      canvas.drawLine(
        Offset(startX + triangleBase / 2, startY - triangleHeight),
        Offset(progressX, progressY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}