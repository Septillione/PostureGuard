import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:percent_indicator/flutter_percent_indicator.dart';
import 'package:posture/app/app_colors.dart';
import 'package:posture/utilities/session_model.dart';
import 'package:posture/utilities/timer_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Перечисление состояний ActivePanel
enum ActivePanel { session, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Переменные состояния
  ActivePanel _activePanel = ActivePanel.session;
  int _settingsDurationMinutes = 25;
  bool _notificationsEnabled = true;
  double _dailyGoalHours = 6.0;

  // ignore: constant_identifier_names
  static const String DURATION_KEY = 'settings_duration_minutes';
  // ignore: constant_identifier_names
  static const String GOAL_KEY = 'settings_daily_goal_hours';
  // ignore: constant_identifier_names
  static const String NOTIFICATIONS_KEY = 'settings_notifications_enabled';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Функция загрузки значений дневной цели, длительности сессии и уведомлений
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settingsDurationMinutes = prefs.getInt(DURATION_KEY) ?? 25;
      _dailyGoalHours = prefs.getDouble(GOAL_KEY) ?? 6;
      _notificationsEnabled = prefs.getBool(NOTIFICATIONS_KEY) ?? true;
    });
  }

  // Функция сохранения значения длительности сессии
  Future<void> _saveSessionDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(DURATION_KEY, minutes);
  }

  // Функция сохранения значения дневной цели
  Future<void> _saveDailyGoal(double hours) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(GOAL_KEY, hours);
  }

  // Функция сохранения значения уведомлений
  Future<void> _saveNotificationsEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(NOTIFICATIONS_KEY, isEnabled);
  }

  // Функция сохранения сессии
  void _addSession(Duration duration) {
    if (duration.inSeconds <= 0) return;

    final session = Session(
      completedAt: DateTime.now(),
      durationInSeconds: duration.inSeconds,
    );
    Hive.box<Session>('sessions').add(session);
    // ignore: avoid_print
    print('Session saved: ${duration.inSeconds} seconds');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // SafeArea отодвигает содержимое от системных элементов
      body: SafeArea(
        // SingleChildScrollView оборачивает содержимое для прокручивания экрана,
        // если контент не помещается по высоте
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildProgressCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              // const SizedBox(height: 10),
              Expanded(child: _buildDynamicPanel()),
            ],
          ),
        ),
      ),
    );
  }

  // Заголовок экрана
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PostureGuard',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Сегодняшний прогресс',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Прогресс за день
  Widget _buildProgressCard() {
    final sessionsBox = Hive.box<Session>('sessions');

    return ValueListenableBuilder<Box<Session>>(
      valueListenable: sessionsBox.listenable(),
      builder: (context, box, _) {
        // --- НАЧАЛО ЛОГИКИ ПОДСЧЕТА ---
        final today = DateTime.now();

        // Фильтруем сессии, оставляя только сегодняшние
        final todaySessions = box.values.where((session) {
          return session.completedAt.year == today.year &&
              session.completedAt.month == today.month &&
              session.completedAt.day == today.day;
        });

        // Считаем общую длительность в секундах
        final totalSecondsToday = todaySessions.fold<int>(
          0,
          (sum, session) => sum + session.durationInSeconds,
        );

        // Конвертируем в часы
        final double completedHours = totalSecondsToday / 3600;
        final double goalHours =
            _dailyGoalHours; // Используем переменную состояния
        final double remainingHours = (goalHours - completedHours).clamp(
          0,
          goalHours,
        );
        final double progressPercent = (completedHours / goalHours).clamp(
          0,
          1.0,
        );

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Цель',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${goalHours.toStringAsFixed(1)} часов',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressInfoRow(
                        label: 'Выполнено',
                        value: '${completedHours.toStringAsFixed(1)} часа',
                        color: AppColors.completedColor,
                      ),
                      const SizedBox(height: 8),
                      _buildProgressInfoRow(
                        label: 'Осталось',
                        value: '${remainingHours.toStringAsFixed(1)} часа',
                        color: AppColors.notCompletedColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularPercentIndicator(
                    radius: 60,
                    lineWidth: 13,
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    progressColor: AppColors.progressColor,
                    animation: true,
                    animationDuration: 730,
                    percent: progressPercent,
                    center: Text(
                      '${(progressPercent * 100).truncate()}%',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Контейнер с оставшимся временем для _buildProgressCard
  Widget _buildProgressInfoRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Кнопки "Быстрые действия"
  Widget _buildActionButtons() {
    final ButtonStyle actionButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      splashFactory: NoSplash.splashFactory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _activePanel = ActivePanel.session;
                  });
                },
                style: actionButtonStyle,
                child: _buildActionButtonChild(
                  icon: Icons.play_arrow,
                  text: 'Начать сессию',
                  isActive: _activePanel == ActivePanel.session,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _activePanel = ActivePanel.settings;
                  });
                },
                style: actionButtonStyle,
                child: _buildActionButtonChild(
                  icon: Icons.timer_outlined,
                  text: 'Настройки',
                  isActive: _activePanel == ActivePanel.settings,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Кнопка для _buildActionButtons
  Widget _buildActionButtonChild({
    required IconData icon,
    required String text,
    required bool isActive,
  }) {
    final Color iconColor =
        isActive
            ? Theme.of(context).colorScheme.primaryFixed
            : Theme.of(context).colorScheme.onPrimaryFixed;
    final Color circleColor =
        isActive
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.onSecondaryFixed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Панель с таймером и настройками таймера
  Widget _buildDynamicPanel() {
    return IndexedStack(
      index: _activePanel == ActivePanel.session ? 0 : 1,
      children: [_buildSessionView(), _buildSettingsView()],
    );
  }

  // Панель с таймером
  Widget _buildSessionView() {
    return TimerCard(
      key: ValueKey(_settingsDurationMinutes),
      initialMinutes: _settingsDurationMinutes,
      notificationsEnabled: _notificationsEnabled,
      onSessionCompleted: (duration) => _addSession(duration),
      onSessionReset: (duration) => _addSession(duration),
    );
  }

  // Панель с настройками таймера
  Widget _buildSettingsView() {
    return Container(
      key: const ValueKey('SettingsView'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          // key: const ValueKey('SettingsView'),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   'Настройки таймера',
            //   style: Theme.of(
            //     context,
            //   ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 10),
            SwitchListTile(
              title: const Text(
                'Уведомления',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveNotificationsEnabled(value);
              },
              contentPadding: EdgeInsets.zero,
              activeTrackColor: AppColors.progressColor,
              activeThumbColor: AppColors.backgroundColor,
            ),
            const Divider(),
            Text(
              'Дневная цель: ${_dailyGoalHours.toStringAsFixed(1)} ч.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _dailyGoalHours,
              min: 1,
              max: 12,
              divisions: 22,
              label: _dailyGoalHours.toStringAsFixed(1),
              onChanged: (double value) {
                final roundedValue = (value * 2).round() / 2;
                setState(() {
                  _dailyGoalHours = roundedValue;
                });
                _saveDailyGoal(roundedValue);
              },
              activeColor: AppColors.progressColor,
            ),
            const Divider(),
            Text(
              'Длительность сессии: $_settingsDurationMinutes мин.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _settingsDurationMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: _settingsDurationMinutes.toString(),
              onChanged: (double value) {
                final roundedValue = value.round();
                setState(() {
                  _settingsDurationMinutes = roundedValue;
                });
                _saveSessionDuration(roundedValue);
              },
              activeColor: AppColors.progressColor,
            ),
          ],
        ),
      ),
    );
  }
}
