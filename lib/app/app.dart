import 'package:flutter/material.dart';

import '../features/step_simulator/application/step_session_controller.dart';
import '../features/step_simulator/presentation/step_simulator_page.dart';

class HealthKitWalkerApp extends StatelessWidget {
  const HealthKitWalkerApp({super.key, required this.controller});

  final StepSessionController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthKitWalker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B6CF9)),
        useMaterial3: true,
      ),
      home: StepSimulatorPage(controller: controller),
    );
  }
}
