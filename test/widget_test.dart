import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:healthkitwalker/app/app.dart';
import 'package:healthkitwalker/features/step_simulator/application/step_session_controller.dart';
import 'package:healthkitwalker/features/step_simulator/data/mock_step_writer.dart';
import 'package:healthkitwalker/features/step_simulator/data/session_persistence.dart';
import 'package:healthkitwalker/features/step_simulator/data/step_writer.dart';
import 'package:healthkitwalker/features/step_simulator/domain/writer_mode.dart';

void main() {
  testWidgets('renders the writer toggle and default mock banner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final controller = StepSessionController(
      writers: <WriterMode, StepWriter>{
        WriterMode.mock: const MockStepWriter(),
        WriterMode.healthKit: const MockStepWriter(),
      },
      persistence: SessionPersistence(preferences),
    );

    await controller.initialize();

    await tester.pumpWidget(HealthKitWalkerApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('HealthKitWalker'), findsOneWidget);
    expect(find.text('Mock'), findsWidgets);
    expect(find.text('HealthKit'), findsOneWidget);
    expect(find.textContaining('目前為 Mock mode'), findsOneWidget);
  });
}
