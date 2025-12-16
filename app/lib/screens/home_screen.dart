import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/location_provider.dart';
import '../providers/checkpoint_provider.dart';
import '../providers/record_provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'record_input_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // データ読み込み
    Future.microtask(() {
      ref.read(locationsProvider.notifier).loadLocations();
      ref.read(checkpointsProvider.notifier).loadCheckpoints();
      ref.read(recordsProvider.notifier).loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomePage(),
      const CalendarScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'カレンダー',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);
    final today = DateTime.now();
    final dateStr = DateFormat('yyyy年M月d日（E）', 'ja').format(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('オンドログ'),
        elevation: 0,
      ),
      body: locationsAsync.when(
        data: (locations) {
          if (locations.isEmpty) {
            return _buildEmptyState(context);
          }

          // 最初の店舗を表示（無料プランは1店舗のみ）
          final location = locations.first;

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(locationsProvider.notifier).loadLocations();
              await ref.read(checkpointsProvider.notifier).loadCheckpoints();
              await ref.read(recordsProvider.notifier).loadRecords();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 店舗名
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 今日の記録状況
                  _TodayRecordsSection(locationId: location.id),

                  const SizedBox(height: 24),

                  // 記録ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecordInputScreen(locationId: location.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.thermostat),
                      label: const Text('今すぐ記録する'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました\n$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(locationsProvider.notifier).loadLocations();
                },
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              '店舗が登録されていません',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '設定画面から店舗を登録してください',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: const Text('設定画面へ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayRecordsSection extends ConsumerWidget {
  final String locationId;

  const _TodayRecordsSection({required this.locationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final dailyRecordsAsync = ref.watch(dailyRecordsProvider(today));
    final checkpointsAsync = ref.watch(checkpointsByLocationProvider(locationId));

    return checkpointsAsync.when(
      data: (checkpoints) {
        if (checkpoints.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('記録ポイントが登録されていません'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    child: const Text('記録ポイントを追加'),
                  ),
                ],
              ),
            ),
          );
        }

        return dailyRecordsAsync.when(
          data: (records) {
            // チェックポイントごとの最新記録を取得
            final recordsByCheckpoint = <String, double>{};
            for (final record in records) {
              recordsByCheckpoint[record.checkpointId] = record.temperature;
            }

            final hasRecords = recordsByCheckpoint.isNotEmpty;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasRecords ? Icons.check_circle : Icons.schedule,
                          color: hasRecords ? AppTheme.successColor : AppTheme.warningColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasRecords ? '記録済み' : '未記録',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ...checkpoints.map((checkpoint) {
                      final temperature = recordsByCheckpoint[checkpoint.id];
                      final hasRecord = temperature != null;
                      final isAbnormal = hasRecord && checkpoint.isTemperatureAbnormal(temperature);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              AppConstants.checkpointTypeIcons[checkpoint.checkpointType] ?? '📍',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    checkpoint.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (checkpoint.minTemp != null && checkpoint.maxTemp != null)
                                    Text(
                                      '基準: ${checkpoint.minTemp}〜${checkpoint.maxTemp}℃',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (hasRecord)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isAbnormal
                                      ? AppTheme.errorColor.withOpacity(0.1)
                                      : AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${temperature.toStringAsFixed(1)}℃',
                                      style: TextStyle(
                                        color: isAbnormal ? AppTheme.errorColor : AppTheme.successColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isAbnormal) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.warning,
                                        size: 16,
                                        color: AppTheme.errorColor,
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            else
                              Text(
                                '--.-℃',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('記録の読み込みに失敗しました: $error'),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('チェックポイントの読み込みに失敗しました: $error'),
        ),
      ),
    );
  }
}
