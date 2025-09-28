import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:posture/app/app_colors.dart';
import 'package:posture/utilities/session_model.dart';
import 'package:posture/utilities/weekly_chart.dart';
import 'package:table_calendar/table_calendar.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  // Функция группировки сессии по дням
  Map<DateTime, double> _groupSessionByDay(List<Session> allSessions) {
    final Map<DateTime, double> dailyData = {};

    for (final session in allSessions) {
      final date = DateTime(
        session.completedAt.year,
        session.completedAt.month,
        session.completedAt.day,
      );

      final durationInHours = session.durationInSeconds / 3600.0;

      dailyData.update(
        date,
        (value) => value + durationInHours,
        ifAbsent: () => durationInHours,
      );
    }
    return dailyData;
  }

  // Функция подсчета стриков
  Map<String, int> _calculateStreaks(Map<DateTime, double> dailyData) {
    if (dailyData.isEmpty) {
      return {'current': 0, 'best': 0};
    }

    final activeDays = dailyData.keys.toList()..sort();

    int bestStreak = 0;
    int currentStreak = 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    bool todayIsActive = dailyData.containsKey(todayDate);
    bool yesterdayIsActive = dailyData.containsKey(yesterdayDate);

    if (!todayIsActive && !yesterdayIsActive) {
      currentStreak = 0;
    } else if (todayIsActive && !yesterdayIsActive) {
      currentStreak = 1;
    } else {
      var streak = 0;
      var dateToCheck = todayIsActive ? todayDate : yesterdayDate;

      while (dailyData.containsKey(dateToCheck)) {
        streak++;
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      }
      currentStreak = streak;
    }

    int tempStreak = 0;
    for (int i = 0; i < activeDays.length; i++) {
      tempStreak++;
      if (bestStreak < tempStreak) {
        bestStreak = tempStreak;
      }

      if (i < activeDays.length - 1) {
        final difference = activeDays[i + 1].difference(activeDays[i]).inDays;
        if (difference > 1) {
          tempStreak = 0;
        }
      }
    }
    return {'current': currentStreak, 'best': bestStreak};
  }

  // Функция подготовки данных для недельной диаграммы
  List<double> _calculateWeeklySummary(List<Session> allSessions) {
    // Список из 7 элементов 0.0
    final List<double> dailyHours = List.generate(7, (_) => 0.0);

    // Получаем текущую дату
    final now = DateTime.now();
    // Получаем дату последнего понедельника
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    // обнуляем время, чтобы получить начало дня (00:00:00)
    final startOfWeekDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    // Отбираем сессии только за текущую неделю
    final weekSessions = allSessions.where((session) {
      return session.completedAt.isAfter(startOfWeekDate);
    });

    for (final session in weekSessions) {
      final dayIndex = session.completedAt.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailyHours[dayIndex] += session.durationInSeconds / 3600.0;
      }
    }

    return dailyHours;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0,),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildStatisticsUI(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Заголовок экрана
  Column _buildHeader(BuildContext context) {
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
          'Статистика прогресса',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Функция для отображения диаграмм
  // ValueListenableBuilder слушает изменения в базе данных Hive
  ValueListenableBuilder<Box<Session>> _buildStatisticsUI() {
    return ValueListenableBuilder<Box<Session>>(
      // Подписываемся на коробку 'sessions'
      valueListenable: Hive.box<Session>('sessions').listenable(),
      // Эта функция запускается при каждом изменении в коробке
      builder: (context, box, _) {
        // Получаем все сессии в виде списка
        final allSessions = box.values.toList();

        // Если сессий нет, показываем заглушку
        if (allSessions.isEmpty) {
          return const Center(
            child: Text(
              'Здесь пока пусто.\nЗавершите первую сессию, чтобы увидеть прогресс!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Переменная с данными для диаграммы
        final weeklySummary = _calculateWeeklySummary(allSessions);

        final dailyData = _groupSessionByDay(allSessions);
        final streaks = _calculateStreaks(dailyData);

        // Вызываем функция, которая строит UI
        return _buildStatistics(context, weeklySummary, dailyData, streaks);
      },
    );
  }

  // Функция для построения списка виджетов статистики
  Widget _buildStatistics(
    BuildContext context,
    List<double> weeklySummary,
    Map<DateTime, double> dailyData,
    Map<String, int> streaks,
  ) {
    // fold "сворачивает" список в одно значение
    // к текущей сумме sum прибавляем следующий элемент item
    final totalWeekHours = weeklySummary.fold<double>(
      0.0,
      (sum, item) => sum + item,
    );
    // Фильтруем список, оставляя дни, где часы > 0
    final totalWeekSessions = weeklySummary.where((hours) => hours > 0).length;

    // Находим макс занчение в списке
    final maxHoursInWeek =
        weeklySummary.isEmpty ? 1.0 : weeklySummary.reduce(max);
    // Делаем потолок диаграммы на 20% выше, чем самая высокая колонка.
    // .ceilToDouble() округляет вверх до целого
    final chartMaxY =
        maxHoursInWeek > 0 ? (maxHoursInWeek * 1.2).ceilToDouble() : 1.0;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStreakCard(
                context,
                'Текущая серия',
                '${streaks['current']}',
                'дней подряд',
                Icons.local_fire_department_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStreakCard(
                context,
                'Лучшая серия',
                '${streaks['best']}',
                'дней подряд',
                Icons.star_rounded,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Активность за неделю',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 150,
                  // Используем виджет WeeklyChart
                  child: WeeklyChart(
                    weeklySummary: weeklySummary,
                    maxY: chartMaxY,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Всего часов',
                      totalWeekHours.toStringAsFixed(1),
                    ),
                    _buildStatItem(
                      context,
                      'Активных дней',
                      totalWeekSessions.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityCalendar(context, dailyData),
        const SizedBox(height: 20)
      ],
    );
  }

  // Виджет для отображения Всего часов и Активных дней
  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  // Виджет для отображения серии
  Widget _buildStreakCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет для отображения календаря
  Widget _buildActivityCalendar(
    BuildContext context,
    Map<DateTime, double> dailyData,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(16),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TableCalendar(
          locale: 'ru_RU',
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.progressColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.progressColor,
              shape: BoxShape.circle,
            ),
          ),
          focusedDay: DateTime.now(),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),

          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final hours = dailyData[DateTime(day.year, day.month, day.day)];
              if (hours != null && hours > 0) {
                final intensity = (hours / 4).clamp(0.2, 1.0);

                return Container(
                  width: 35,
                  decoration: BoxDecoration(
                    color: AppColors.progressColor.withOpacity(intensity),
                    shape: BoxShape.circle,
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
