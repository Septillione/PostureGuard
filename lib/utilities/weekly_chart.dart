import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:posture/app/app_colors.dart';

class WeeklyChart extends StatelessWidget {
  // Список из 7 дней недели
  final List<double> weeklySummary;
  // Максимальное значение Y
  final double maxY;
  const WeeklyChart({
    super.key,
    required this.weeklySummary,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    // Главный виджет библиотеки fl_chart
    return BarChart(
      // BarChartData описывает диаграмму
      BarChartData(
        maxY: maxY,
        minY: 0,
        // Сетка на фоне
        gridData: const FlGridData(show: false),
        // Рамка вокруг диаграммы
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround,
        // Настройка подписей на осях
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _getBottomTitles,
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox.shrink();
                }
                if (value % 1 != 0) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    '${value.toInt()} ч', // Показываем часы
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Передаём данные для колонок
        barGroups: _buildBarGroups(),
      ),
    );
  }

  // Функция создания списка колонок
  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(weeklySummary.length, (index) {
      // BarChartGroupData - группа столбцов
      return BarChartGroupData(
        x: index,
        // Список колонок в этой группе
        barRods: [
          BarChartRodData(
            toY: weeklySummary[index],
            color:
                (weeklySummary[index] > 0)
                    ? AppColors.progressColor
                    : Colors.grey[300],
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  // Функция создания подписей снизу
  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    // value - это позиция x из BarChartGroupData
    switch (value.toInt()) {
      case 0:
        text = 'Пн';
        break;
      case 1:
        text = 'Вт';
        break;
      case 2:
        text = 'Ср';
        break;
      case 3:
        text = 'Чт';
        break;
      case 4:
        text = 'Пт';
        break;
      case 5:
        text = 'Сб';
        break;
      case 6:
        text = 'Вс';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(meta: meta, child: Text(text, style: style));
  }
}
