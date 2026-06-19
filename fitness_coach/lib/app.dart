import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/plan_provider.dart';
import 'package:fitness_coach/providers/workout_provider.dart';
import 'package:fitness_coach/providers/settings_provider.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/services/notification_service.dart';
import 'package:fitness_coach/pages/home_page.dart';

class FitnessCoachApp extends StatelessWidget {
  final TtsService ttsService;
  final HapticService hapticService;
  final NotificationService notificationService;

  const FitnessCoachApp({
    super.key,
    required this.ttsService,
    required this.hapticService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()..loadPlans()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(
          tts: ttsService,
          haptic: hapticService,
        )),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            tts: ttsService,
            haptic: hapticService,
            notification: notificationService,
          ),
        ),
      ],
      child: MaterialApp(
        title: '跟我练',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
