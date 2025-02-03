import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'breathing_visualizations.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

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

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _initBackgroundMusic();
  }

  Future<void> _initBackgroundMusic() async {
    await _audioManager.initialize();
    final prefs = await SharedPreferences.getInstance();
    final isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
    if (isSoundEnabled) {
      await _audioManager.playBackgroundMusic();
    }
  }

  @override
  void dispose() {
    _audioManager.dispose();
    super.dispose();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void updateTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
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
      home: HomePage(updateTheme: updateTheme, isDarkMode: _isDarkMode),
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
            Colors.black.withAlpha(51), // 0.2 opacity * 255 = 51
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Make scaffold background transparent
        extendBodyBehindAppBar: true, // Extend body behind app bar
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Make app bar transparent
          elevation: 0, // Remove app bar shadow
          title: const Text(
            'StillMind',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(40, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Image.asset(
                  'assets/icons/help.png',
                  width: 20,
                  height: 20,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildButton(context, 'Stats', 'stats.png', const StatsPage()),
              const SizedBox(height: 16),
              _buildButton(context, 'Start', 'play.png', const MainPage()),
              const SizedBox(height: 16),
              _buildButton(
                context,
                'Achievements',
                'trophy.png',
                const AchievementsPage(),
              ),
              const SizedBox(height: 16),
              _buildButton(
                context,
                'Settings',
                'settings.png',
                SettingsPage(
                  updateTheme: updateTheme,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update the button style to have some transparency
  Widget _buildButton(
      BuildContext context, String label, String iconPath, Widget destination) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context)
              .primaryColor
              .withAlpha(230), // 0.9 opacity * 255 = 230
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 3,
          minimumSize: const Size(double.infinity, 64),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/$iconPath',
              width: 28,
              height: 28,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
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

  @override
  void initState() {
    super.initState();
    _loadCyclesData();
  }

  Future<void> _loadCyclesData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('breathingCycles') ?? '{}';
    setState(() {
      cyclesData = Map<String, int>.from(json.decode(data));
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
                          style: TextStyle(fontSize: 16),
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
                          style: TextStyle(fontSize: 16),
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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundEnabled = prefs.getBool('soundEnabled') ?? true;
      _inhaleTime = prefs.getInt('inhaleTime') ?? 4;
      _holdTime = prefs.getInt('holdTime') ?? 7;
      _exhaleTime = prefs.getInt('exhaleTime') ?? 8;
    });
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
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Get existing data
    final data = prefs.getString('breathingCycles') ?? '{}';
    final cyclesMap = Map<String, int>.from(json.decode(data));

    // Update today's count
    cyclesMap[today] = (cyclesMap[today] ?? 0) + 1;

    // Save updated data
    await prefs.setString('breathingCycles', json.encode(cyclesMap));
  }

  void _restartExercise() {
    setState(() {
      _bar1Value = 0.0;
      _bar2Value = 0.0;
      _bar3Value = 0.0;
      _phase = 0;
    });
    _startBreathingExercise();
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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _visualizationType =
          VisualizationType.values[prefs.getInt('visualizationType') ?? 0];
    });
  }

  @override
  void dispose() {
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
  Map<String, int> cyclesData = {};
  int currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadAchievementData();
  }

  Future<void> _loadAchievementData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('breathingCycles') ?? '{}';
    setState(() {
      cyclesData = Map<String, int>.from(json.decode(data));
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

  int getTotalCycles() {
    return cyclesData.values.fold(0, (sum, count) => sum + count);
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
            _buildAchievementTile(
              icon: Icons.emoji_events,
              title: 'Getting Started',
              description: 'Complete your first breathing exercise',
              isCompleted: getTotalCycles() >= 1,
            ),
            _buildAchievementTile(
              icon: Icons.local_florist,
              title: 'Regular Breather',
              description: 'Complete 50 breathing exercises',
              isCompleted: getTotalCycles() >= 50,
            ),
            _buildAchievementTile(
              icon: Icons.forest,
              title: 'Breathing Master',
              description: 'Complete 100 breathing exercises',
              isCompleted: getTotalCycles() >= 100,
            ),
            _buildAchievementTile(
              icon: Icons.local_fire_department,
              title: 'Consistent',
              description: 'Maintain a 3-day streak',
              isCompleted: currentStreak >= 3,
            ),
            _buildAchievementTile(
              icon: Icons.person,
              title: 'Weekly Warrior',
              description: 'Maintain a 7-day streak',
              isCompleted: currentStreak >= 7,
            ),
            _buildAchievementTile(
              icon: Icons.star,
              title: 'Monthly Master',
              description: 'Maintain a 30-day streak',
              isCompleted: currentStreak >= 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementTile({
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
  late bool _isSoundEnabled;
  late int _inhaleTime;
  late int _holdTime;
  late int _exhaleTime;
  NotificationTime? _notificationTime;
  final AudioManager _audioManager = AudioManager();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
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
    });
  }

  Future<void> _saveSettings() async {
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

      // Reschedule notification with new time
      await _notificationService.scheduleDailyNotification(
        hour: _notificationTime!.hour,
        minute: _notificationTime!.minute,
      );
    } else {
      await prefs.remove('notificationHour');
      await prefs.remove('notificationMinute');
      await _notificationService.cancelAllNotifications();
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
