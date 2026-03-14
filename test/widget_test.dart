import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:healthkitwalker/app/app.dart';
import 'package:healthkitwalker/features/step_simulator/application/step_session_controller.dart';
import 'package:healthkitwalker/features/step_simulator/data/mock_step_writer.dart';
import 'package:healthkitwalker/features/step_simulator/data/session_persistence.dart';

void main() {
  testWidgets('renders the mock banner and app title', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final controller = StepSessionController(
      writer: const MockStepWriter(),
      persistence: SessionPersistence(preferences),
    );

    await controller.initialize();

    await tester.pumpWidget(HealthKitWalkerApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('HealthKitWalker'), findsOneWidget);
    expect(find.textContaining('mock / prototype 模式'), findsOneWidget);
  });
}
