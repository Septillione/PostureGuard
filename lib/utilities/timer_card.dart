import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:posture/app/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:posture/main.dart';

// Перечисление состояний TimerState
enum TimerState { stopped, running, paused }

class TimerCard extends StatefulWidget {
  const TimerCard({
    super.key,
    this.initialMinutes = 25,
    this.notificationsEnabled = true,
    this.onSessionCompleted,
    this.onSessionReset,
  });

  final int initialMinutes;
  final bool notificationsEnabled;
  final Function(Duration duration)? onSessionCompleted;
  final Function(Duration duration)? onSessionReset;

  @override
  State<TimerCard> createState() => _TimerCardState();
}

// with WidgetsBindingObserver - это "миксин",
// который позволяет классу "подписаться" на события жизненного цикла приложения.
class _TimerCardState extends State<TimerCard> with WidgetsBindingObserver {
  // Переменные состояния
  late Duration _duration; // Длительность таймера
  late int _remainingSeconds; // Сколько секунд осталось
  DateTime? _endTime; // Точное время в будущем, когда таймер должен закончиться
  bool _isForeground = true; //  Флаг, находится ли приложение на переднем плане

  TimerState _timerState = TimerState.stopped; // Текущее состояние таймера
  Timer? _timer; // Объект UI-таймера, который обновляет экран каждую секунду

  // Константы для сохранения состояния
  static const String endTimeKey = 'timer_end_time';
  static const String initialStateKey = 'timer_initial_state';

  // initState вызывается при создании виджета
  @override
  void initState() {
    super.initState();
    _duration = Duration(minutes: widget.initialMinutes);
    _remainingSeconds = _duration.inSeconds;
    WidgetsBinding.instance.addObserver(
      this,
    ); // Подписываемся на события жизненного цикла
    _restoreTimerState(); // Пытаемся восстановить таймер при запуске
  }

  // dispose вызывается когда виджет удаляется с экрана
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Отписываемся от событий
    _timer?.cancel(); // Отменяем таймер, чтобы избежать утечек памяти
    super.dispose();
  }

  // Проверка активности приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    _isForeground = state == AppLifecycleState.resumed;

    if (_timerState == TimerState.running && _endTime != null) {
      if (_isForeground) {
        _cancelNotification();
        _updateTimerOnResume();
      } else {
        if (widget.notificationsEnabled) {
          _scheduleNotification(
            _endTime!,
            'Время вышло!',
            'Пора сменить позу.',
          );
        }
      }
    }
  }

  // Восстановление таймера
  void _restoreTimerState() async {
    // Получаем с диска время окончания и начальную длительность в секундах
    final prefs = await SharedPreferences.getInstance();
    final endTimeMillis = prefs.getInt(endTimeKey);
    final initialDurationSeconds = prefs.getInt(initialStateKey);

    if (endTimeMillis != null && initialDurationSeconds != null) {
      _endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      _duration = Duration(seconds: initialDurationSeconds);

      if (_endTime!.isAfter(DateTime.now())) {
        _remainingSeconds = _endTime!.difference(DateTime.now()).inSeconds;
        _startUiTimer();
        setState(() {
          _timerState = TimerState.running;
        });
      } else {
        _resetTimer();
      }
    }
  }

  // Синхронизирует UI с реальным таймером
  void _updateTimerOnResume() {
    if (_timerState == TimerState.running && _endTime != null) {
      if (_endTime!.isAfter(DateTime.now())) {
        setState(() {
          _remainingSeconds = _endTime!.difference(DateTime.now()).inSeconds;
        });
      } else {
        _stopTimer(isFinished: true);
      }
    }
  }

  // Запуск таймера
  void _startTimer() async {
    if (_timerState == TimerState.stopped) {
      _remainingSeconds = _duration.inSeconds;
    }

    _endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(endTimeKey, _endTime!.millisecondsSinceEpoch);
    await prefs.setInt(initialStateKey, _duration.inSeconds);

    _startUiTimer();
    setState(() {
      _timerState = TimerState.running;
    });
  }

  // Таймера для интерфейса
  void _startUiTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer(isFinished: true);
      }
    });
  }

  // Пауза таймера
  void _pauseTimer() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(endTimeKey);
    await prefs.remove(initialStateKey);

    if (widget.notificationsEnabled) await _cancelNotification();

    setState(() {
      _timerState = TimerState.paused;
    });
  }

  // Остановка таймера
  void _stopTimer({bool isFinished = false}) async {
    _timer?.cancel();
    _endTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(endTimeKey);
    await prefs.remove(initialStateKey);

    if (isFinished) {
      widget.onSessionCompleted?.call(_duration);
    }

    if (mounted) {
      setState(() {
        _timerState = TimerState.stopped;
        if (isFinished) {
          _remainingSeconds = _duration.inSeconds;
        }
      });
    }
  }

  // Сброс таймера
  void _resetTimer() {
    final elapsedSeconds = _duration.inSeconds - _remainingSeconds;
    if (elapsedSeconds > 59) {
      widget.onSessionReset?.call(Duration(seconds: elapsedSeconds));
    }
    _stopTimer(isFinished: false);
    setState(() {
      _remainingSeconds = _duration.inSeconds;
    });
  }

  // Запланировать уведомление
  Future<void> _scheduleNotification(
    DateTime time,
    String title,
    String body,
  ) async {
    final android =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    bool canExact = false;
    // ignore: unused_local_variable
    bool notificationsEnabled = true;

    if (android != null) {
      notificationsEnabled = await (android.areNotificationsEnabled()) ?? true;
      canExact = await (android.canScheduleExactNotifications()) ?? false;
    }

    final scheduleMode =
        canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.alarmClock;

    final scheduled = tz.TZDateTime.from(time, tz.local);
    print('Scheduling at: $scheduled, mode: $scheduleMode');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'posture_timer_channel',
          'Posture Timer',
          channelDescription: 'Notification for posture timer',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Отменить уведомление
  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  // Формат таймера
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Кнопки таймера
  Widget _buildControlButtons() {
    final ButtonStyle actionButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      splashFactory: NoSplash.splashFactory,
    );

    if (_timerState == TimerState.running) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButtonsChild(
            func: _pauseTimer,
            style: actionButtonStyle,
            icon: Icons.pause_rounded,
          ),
        ],
      );
    } else if (_timerState == TimerState.paused) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButtonsChild(
            func: _resetTimer,
            style: actionButtonStyle,
            icon: Icons.stop_rounded,
          ),
          const SizedBox(width: 40),
          _buildControlButtonsChild(
            func: _startTimer,
            style: actionButtonStyle,
            icon: Icons.play_arrow_rounded,
          ),
        ],
      );
    } else {
      return _buildControlButtonsChild(
        func: _startTimer,
        style: actionButtonStyle,
        icon: Icons.play_arrow_rounded,
      );
    }
  }

  // Кнопка для _buildControlButtons
  Widget _buildControlButtonsChild({
    required Function() func,
    required ButtonStyle style,
    required IconData icon,
  }) {
    return ElevatedButton(
      onPressed: func,
      style: style,
      child: Icon(icon, size: 40, color: AppColors.backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            _formatDuration(_remainingSeconds),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          _buildControlButtons(),
        ],
      ),
    );
  }
}
