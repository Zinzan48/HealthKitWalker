import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/step_simulator/application/step_session_controller.dart';
import 'features/step_simulator/data/mock_step_writer.dart';
import 'features/step_simulator/data/session_persistence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final controller = StepSessionController(
    writer: const MockStepWriter(),
    persistence: SessionPersistence(preferences),
  );

  await controller.initialize();

  runApp(HealthKitWalkerApp(controller: controller));
}
