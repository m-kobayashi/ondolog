import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/record_provider.dart';
import '../config/theme.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayRecords = _selectedDay != null
        ? ref.watch(dailyRecordsProvider(_selectedDay!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            locale: 'ja_JP',
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('日付を選択してください'))
                : selectedDayRecords == null
                    ? const Center(child: Text('日付を選択してください'))
                    : selectedDayRecords.when(
                        data: (records) {
                          if (records.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    DateFormat('M月d日').format(_selectedDay!),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '記録がありません',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Text(
                                '${DateFormat('M月d日（E）', 'ja').format(_selectedDay!)}の記録',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...records.map((record) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: record.isAbnormal
                                            ? AppTheme.errorColor.withOpacity(0.1)
                                            : AppTheme.successColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.thermostat,
                                        color: record.isAbnormal
                                            ? AppTheme.errorColor
                                            : AppTheme.successColor,
                                      ),
                                    ),
                                    title: Text(
                                      '${record.temperature.toStringAsFixed(1)}℃',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: record.isAbnormal
                                            ? AppTheme.errorColor
                                            : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(DateFormat('HH:mm').format(record.recordedAt)),
                                        if (record.isAbnormal && record.abnormalAction != null)
                                          Text(
                                            '対応: ${record.abnormalAction}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                      ],
                                    ),
                                    trailing: record.isAbnormal
                                        ? Icon(Icons.warning, color: AppTheme.errorColor)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text('エラー: $error'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
