import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/checkpoint_provider.dart';
import '../config/constants.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final checkpointsAsync = ref.watch(checkpointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ユーザー情報
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user.displayName ?? user.email),
                  subtitle: Text('プラン: ${user.plan == 'free' ? '無料' : user.plan}'),
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // 店舗管理
          const Text(
            '店舗情報',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          locationsAsync.when(
            data: (locations) {
              return Card(
                child: Column(
                  children: [
                    ...locations.map((location) => ListTile(
                          leading: const Icon(Icons.store),
                          title: Text(location.name),
                          subtitle: location.address != null ? Text(location.address!) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: 編集画面
                            },
                          ),
                        )),
                    if (locations.isEmpty)
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('店舗を追加'),
                        onTap: () => _showAddLocationDialog(context, ref),
                      )
                    else if (locations.length < AppConstants.freeMaxLocations)
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('店舗を追加'),
                        onTap: () => _showAddLocationDialog(context, ref),
                      ),
                  ],
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('エラー: $error'),
          ),
          const SizedBox(height: 24),

          // チェックポイント管理
          const Text(
            '記録ポイント',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          checkpointsAsync.when(
            data: (checkpoints) {
              return Card(
                child: Column(
                  children: [
                    ...checkpoints.map((cp) => ListTile(
                          leading: Text(
                            AppConstants.checkpointTypeIcons[cp.checkpointType] ?? '📍',
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(cp.name),
                          subtitle: Text(
                            '${AppConstants.checkpointTypeNames[cp.checkpointType]} • ${cp.minTemp}〜${cp.maxTemp}℃',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: 編集画面
                            },
                          ),
                        )),
                    if (checkpoints.length < AppConstants.freeMaxCheckpoints)
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('記録ポイントを追加'),
                        onTap: () => _showAddCheckpointDialog(context, ref),
                      ),
                  ],
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('エラー: $error'),
          ),
          const SizedBox(height: 24),

          // ログアウト
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
              onTap: () => _showLogoutDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddLocationDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '店舗名'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: '住所（任意）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final success = await ref.read(locationsProvider.notifier).createLocation(
            name: nameController.text,
            address: addressController.text.isEmpty ? null : addressController.text,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? '店舗を追加しました' : '追加に失敗しました')),
        );
      }
    }
  }

  Future<void> _showAddCheckpointDialog(BuildContext context, WidgetRef ref) async {
    final locationsAsync = ref.read(locationsProvider);
    final locations = locationsAsync.value ?? [];

    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に店舗を追加してください')),
      );
      return;
    }

    final nameController = TextEditingController();
    String? selectedType = 'refrigerator';
    final minTempController = TextEditingController(text: '0');
    final maxTempController = TextEditingController(text: '10');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('記録ポイントを追加'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '名前'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'タイプ'),
                items: AppConstants.checkpointTypeNames.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) => selectedType = value,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minTempController,
                      decoration: const InputDecoration(labelText: '最低温度'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: maxTempController,
                      decoration: const InputDecoration(labelText: '最高温度'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final success = await ref.read(checkpointsProvider.notifier).createCheckpoint(
            locationId: locations.first.id,
            name: nameController.text,
            checkpointType: selectedType!,
            minTemp: double.tryParse(minTempController.text),
            maxTemp: double.tryParse(maxTempController.text),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? '記録ポイントを追加しました' : '追加に失敗しました')),
        );
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(userProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
