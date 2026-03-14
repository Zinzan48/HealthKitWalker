import 'package:flutter/material.dart';

import '../../domain/session_config.dart';
import '../../domain/session_status.dart';

class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({
    super.key,
    required this.config,
    required this.status,
    required this.completedTicks,
    required this.totalWrittenSteps,
    required this.message,
    this.timeUntilNextTick,
  });

  final SessionConfig? config;
  final SessionStatus status;
  final int completedTicks;
  final int totalWrittenSteps;
  final String message;
  final Duration? timeUntilNextTick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draftConfig = config;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Session 摘要', style: theme.textTheme.titleMedium),
                const Spacer(),
                Chip(label: Text(status.label)),
              ],
            ),
            const SizedBox(height: 12),
            if (draftConfig == null) ...<Widget>[
              Text(
                '請先輸入有效的分鐘數與步數設定。',
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...<Widget>[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _SummaryItem(
                    label: '模式',
                    value: draftConfig.mode.label,
                  ),
                  _SummaryItem(
                    label: '每回合平均步數',
                    value: '${draftConfig.averageStepsPerInterval} 步',
                  ),
                  _SummaryItem(
                    label: '間隔',
                    value: '${draftConfig.intervalMinutes} 分鐘',
                  ),
                  _SummaryItem(
                    label: '預估總步數',
                    value: draftConfig.mode.isInfiniteLoop
                        ? '無上限'
                        : '${draftConfig.estimatedTotalSteps} 步',
                  ),
                  _SummaryItem(
                    label: '預估回合數',
                    value: draftConfig.mode.isInfiniteLoop
                        ? '持續直到手動停止'
                        : '${draftConfig.estimatedTickCount} 回合',
                  ),
                  _SummaryItem(
                    label: '已完成回合',
                    value: '$completedTicks',
                  ),
                  _SummaryItem(
                    label: '累計 mock 步數',
                    value: '$totalWrittenSteps 步',
                  ),
                  _SummaryItem(
                    label: '下一次 tick',
                    value: timeUntilNextTick == null
                        ? '-'
                        : _formatDuration(timeUntilNextTick!),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
