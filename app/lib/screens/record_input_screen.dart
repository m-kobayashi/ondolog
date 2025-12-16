import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/checkpoint_provider.dart';
import '../providers/record_provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class RecordInputScreen extends ConsumerStatefulWidget {
  final String locationId;

  const RecordInputScreen({super.key, required this.locationId});

  @override
  ConsumerState<RecordInputScreen> createState() => _RecordInputScreenState();
}

class _RecordInputScreenState extends ConsumerState<RecordInputScreen> {
  final Map<String, double> _temperatures = {};
  final Map<String, String> _abnormalActions = {};
  bool _isLoading = false;

  Future<void> _saveRecords() async {
    if (_temperatures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('温度を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final records = _temperatures.entries.map((entry) {
        return {
          'checkpoint_id': entry.key,
          'temperature': entry.value,
          'recorded_at': DateTime.now().toIso8601String(),
          'abnormal_action': _abnormalActions[entry.key],
        };
      }).toList();

      final result = await ref.read(recordsProvider.notifier).createBulkRecords(records: records);

      if (mounted) {
        setState(() => _isLoading = false);

        if (result != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result['recorded_count']}件の記録を保存しました'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkpointsAsync = ref.watch(checkpointsByLocationProvider(widget.locationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('温度記録'),
      ),
      body: checkpointsAsync.when(
        data: (checkpoints) {
          if (checkpoints.isEmpty) {
            return const Center(child: Text('記録ポイントがありません'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: checkpoints.length,
                  itemBuilder: (context, index) {
                    final checkpoint = checkpoints[index];
                    final temperature = _temperatures[checkpoint.id];
                    final isAbnormal = temperature != null &&
                        checkpoint.isTemperatureAbnormal(temperature);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppConstants.checkpointTypeIcons[checkpoint.checkpointType] ?? '📍',
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        checkpoint.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (checkpoint.minTemp != null && checkpoint.maxTemp != null)
                                        Text(
                                          '基準: ${checkpoint.minTemp}〜${checkpoint.maxTemp}℃',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: '温度',
                                      suffixText: '℃',
                                    ),
                                    onChanged: (value) {
                                      final temp = double.tryParse(value);
                                      if (temp != null) {
                                        setState(() => _temperatures[checkpoint.id] = temp);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (temperature != null)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isAbnormal
                                          ? AppTheme.errorColor.withOpacity(0.1)
                                          : AppTheme.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isAbnormal ? Icons.warning : Icons.check_circle,
                                      color: isAbnormal ? AppTheme.errorColor : AppTheme.successColor,
                                    ),
                                  ),
                              ],
                            ),
                            if (isAbnormal) ...[
                              const SizedBox(height: 16),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: '異常時の対応',
                                  hintText: '対応内容を入力してください',
                                ),
                                maxLines: 2,
                                onChanged: (value) {
                                  setState(() => _abnormalActions[checkpoint.id] = value);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveRecords,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('記録を保存', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }
}
