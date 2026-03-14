import 'package:flutter/material.dart';

import '../application/step_session_controller.dart';
import '../domain/session_config.dart';
import '../domain/session_mode.dart';
import '../domain/session_status.dart';
import '../domain/writer_mode.dart';
import 'widgets/session_summary_card.dart';

class StepSimulatorPage extends StatefulWidget {
  const StepSimulatorPage({super.key, required this.controller});

  final StepSessionController controller;

  @override
  State<StepSimulatorPage> createState() => _StepSimulatorPageState();
}

class _StepSimulatorPageState extends State<StepSimulatorPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervalController;
  late final TextEditingController _averageStepsController;
  late final TextEditingController _totalMinutesController;
  late SessionMode _selectedMode;
  late WriterMode _selectedWriterMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final config = widget.controller.currentConfig;
    _selectedMode = config.mode;
    _selectedWriterMode = config.writerMode;
    _intervalController = TextEditingController(
      text: config.intervalMinutes.toString(),
    );
    _averageStepsController = TextEditingController(
      text: config.averageStepsPerInterval.toString(),
    );
    _totalMinutesController = TextEditingController(
      text: (config.totalMinutes ?? 30).toString(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.controller.handleLifecycleChange(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intervalController.dispose();
    _averageStepsController.dispose();
    _totalMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final draftConfig = _currentDraftConfig();
        final controller = widget.controller;

        return Scaffold(
          appBar: AppBar(title: const Text('HealthKitWalker')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _buildWriterBanner(context, draftConfig),
                  const SizedBox(height: 16),
                  SessionSummaryCard(
                    config: draftConfig,
                    status: controller.status,
                    completedTicks: controller.completedTicks,
                    totalWrittenSteps: controller.totalWrittenSteps,
                    message: controller.message,
                    timeUntilNextTick: controller.timeUntilNextTick,
                  ),
                  const SizedBox(height: 16),
                  _buildFormCard(context),
                  const SizedBox(height: 16),
                  _buildActionCard(context, draftConfig),
                  const SizedBox(height: 16),
                  _buildLogCard(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWriterBanner(BuildContext context, SessionConfig? draftConfig) {
    final theme = Theme.of(context);
    final writerMode =
        draftConfig?.writerMode ?? widget.controller.currentConfig.writerMode;
    final isMock = writerMode == WriterMode.mock;
    final bannerColor = isMock
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.secondaryContainer;
    final foregroundColor = isMock
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSecondaryContainer;
    final description = isMock
        ? '目前為 Mock mode。會完整模擬 session 流程，但不會真的寫入 Apple Health。'
        : '目前選擇 HealthKit mode。開始時會要求 Apple Health 權限，且只在 iPhone + entitlement 條件下可真正寫入。';

    return Material(
      color: bannerColor,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              isMock ? Icons.science_outlined : Icons.favorite_outline,
              color: foregroundColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Session 設定', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Writer 模式', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<WriterMode>(
              segments: WriterMode.values
                  .map(
                    (mode) => ButtonSegment<WriterMode>(
                      value: mode,
                      label: Text(mode.label),
                    ),
                  )
                  .toList(),
              selected: <WriterMode>{_selectedWriterMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedWriterMode = selection.first;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _selectedWriterMode.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text('Session 模式', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<SessionMode>(
              segments: SessionMode.values
                  .map(
                    (mode) => ButtonSegment<SessionMode>(
                      value: mode,
                      label: Text(mode.label),
                    ),
                  )
                  .toList(),
              selected: <SessionMode>{_selectedMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedMode = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '每次寫入間隔（分鐘）',
                      border: OutlineInputBorder(),
                    ),
                    validator: _positiveIntegerValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _averageStepsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '每回合平均步數',
                      border: OutlineInputBorder(),
                    ),
                    validator: _positiveIntegerValidator,
                  ),
                ),
              ],
            ),
            if (_selectedMode.isFixedDuration) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _totalMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '總執行時間（分鐘）',
                  border: OutlineInputBorder(),
                ),
                validator: _positiveIntegerValidator,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '目前預設抖動約 ±18%。切換 writer mode 後，新的設定會在下一次開始 session 時生效。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, SessionConfig? draftConfig) {
    final controller = widget.controller;
    final canStart =
        draftConfig != null && controller.status != SessionStatus.running;
    final canPause = controller.status == SessionStatus.running;
    final canResume = controller.status == SessionStatus.paused;
    final canStop =
        controller.status.isActive ||
        controller.status == SessionStatus.completed ||
        controller.status == SessionStatus.stopped;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilledButton.icon(
              onPressed: canStart
                  ? () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      final config = _currentDraftConfig();
                      if (config == null) {
                        return;
                      }

                      await controller.start(config);
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('開始'),
            ),
            OutlinedButton.icon(
              onPressed: canPause
                  ? () => controller.pause(reason: 'Session 已手動暫停。')
                  : null,
              icon: const Icon(Icons.pause),
              label: const Text('暫停'),
            ),
            OutlinedButton.icon(
              onPressed: canResume ? controller.resume : null,
              icon: const Icon(Icons.refresh),
              label: const Text('恢復'),
            ),
            TextButton.icon(
              onPressed: canStop
                  ? () => controller.stop(reason: 'Session 已停止。')
                  : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('停止'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context) {
    final theme = Theme.of(context);
    final ticks = widget.controller.ticks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('最近 mock tick', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (ticks.isEmpty)
              Text(
                '尚未產生任何 tick。啟動 session 後，系統會依設定的分鐘數排程下一次寫入。',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...ticks.map(
                (tick) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    child: Text('${tick.index}'),
                  ),
                  title: Text('${tick.steps} 步'),
                  subtitle: Text(
                    '${_formatDateTime(tick.recordedAt)} • 累計 ${tick.totalWrittenStepsAfterTick} 步\n${tick.message}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SessionConfig? _currentDraftConfig() {
    final interval = int.tryParse(_intervalController.text.trim());
    final averageSteps = int.tryParse(_averageStepsController.text.trim());
    final totalMinutes = _selectedMode.isFixedDuration
        ? int.tryParse(_totalMinutesController.text.trim())
        : null;

    if (interval == null || interval <= 0) {
      return null;
    }
    if (averageSteps == null || averageSteps <= 0) {
      return null;
    }
    if (_selectedMode.isFixedDuration &&
        (totalMinutes == null || totalMinutes <= 0)) {
      return null;
    }

    return SessionConfig(
      intervalMinutes: interval,
      averageStepsPerInterval: averageSteps,
      mode: _selectedMode,
      writerMode: _selectedWriterMode,
      totalMinutes: totalMinutes,
    );
  }

  String? _positiveIntegerValidator(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return '請輸入大於 0 的整數';
    }

    return null;
  }

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute:$second';
  }
}
