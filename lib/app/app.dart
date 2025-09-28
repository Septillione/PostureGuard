import 'package:flutter/material.dart';
import 'package:posture/app/app_colors.dart';
import 'package:posture/screens/home_screen.dart';
import 'package:posture/screens/progress_screen.dart';
import 'package:posture/screens/settings_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Переменная состояния
  int _selectedIndex = 0;

  // Список экранов
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  // Метод обработки нажатий
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack сохраняет состояние неактивных экранов
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // Виджет для нижней панели
      bottomNavigationBar: NavigationBarTheme(
        data: Theme.of(context).navigationBarTheme,
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          // Передает число - индекс страницы
          onDestinationSelected: _onItemTapped,
          indicatorColor: AppColors.progressColor,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              selectedIcon: Icon(
                Icons.home_rounded,
                color: AppColors.backgroundColor,
              ),
              icon: Icon(Icons.home_rounded),
              label: 'Главная',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                Icons.signal_cellular_alt_rounded,
                color: AppColors.backgroundColor,
              ),
              icon: Icon(Icons.signal_cellular_alt_rounded),
              label: 'Прогресс',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                Icons.settings_rounded,
                color: AppColors.backgroundColor,
              ),
              icon: Icon(Icons.settings_rounded),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }
}
