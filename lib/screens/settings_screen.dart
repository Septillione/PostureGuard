import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:posture/app/theme_controller.dart';
import 'package:posture/utilities/session_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 16),
              _buildChooseTheme(),
              SizedBox(height: 16),
              ValueListenableBuilder<Box<Session>>(
                valueListenable: Hive.box<Session>('sessions').listenable(),
                builder: (context, box, _) {
                  final hasData = box.isNotEmpty;
                  return Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    child: ListTile(
                      enabled: hasData,
                      leading: Icon(
                        Icons.delete_forever_rounded,
                        color:
                            hasData
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      title: const Text('Стереть все данные сессий'),
                      subtitle: Text(
                        hasData ? 'Удалит всю историю и статистику' : 'Нет данных для удаления',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      onTap: hasData ? () => _confirmAndClearSessions(context) : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndClearSessions(BuildContext context) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Удалить все сессии?'),
            content: const Text('Эту операцию нельзя отменить. Вся история и статистика будут удалены.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final box = Hive.box<Session>('sessions');
    await box.clear();
    await box.compact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Все данные сессий удалены')),
    );
  }

  ValueListenableBuilder<ThemeMode> _buildChooseTheme() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: const Text('Системная тема'),
                groupValue: mode,
                onChanged: (m) => ThemeController.instance.set(m!),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                title: const Text('Светлая тема'),
                groupValue: mode,
                onChanged: (m) => ThemeController.instance.set(m!),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: const Text('Темная тема'),
                groupValue: mode,
                onChanged: (m) => ThemeController.instance.set(m!),
              ),
            ],
          ),
        );
      },
    );
  }

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
          'Настройки',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
