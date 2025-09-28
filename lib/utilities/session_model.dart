import 'package:hive/hive.dart';

part 'session_model.g.dart';

@HiveType(typeId: 0)
class Session extends HiveObject {
  @HiveField(0)
  final DateTime completedAt;

  @HiveField(1)
  final int durationInSeconds;

  Session({required this.completedAt, required this.durationInSeconds});
}