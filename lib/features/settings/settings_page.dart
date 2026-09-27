import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/export_service.dart';
import '../../data/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/export/export_encoder.dart';
import '../../domain/settings_keys.dart';
import 'export_dialog.dart';

/// 冲煮后是否自动扣减余量（手册 §6.2），直接订阅设置表。
final StreamProvider<bool> _autoDeductStockProvider = StreamProvider<bool>(
  (Ref ref) => ref.watch(settingsRepositoryProvider).watchAutoDeductStock(),
);

/// 我的 tab：设置项（手册 §5.4）。
///
/// 主题模式、余量扣减开关、默认导出格式都真正落库。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode =
        ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final bool autoDeductStock =
        ref.watch(_autoDeductStockProvider).value ?? true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: <Widget>[
        const _SectionTitle('外观'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.brightness_6_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text('主题模式', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('浅色'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('深色'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('跟随系统'),
                    ),
                  ],
                  selected: <ThemeMode>{themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) =>
                      _saveThemeMode(context, ref, selection.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionTitle('库存'),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.inventory_2_outlined),
            title: const Text('冲煮后自动扣减余量'),
            subtitle: const Text('保存记录时按粉量扣减对应豆子的余量，关闭后完全手动'),
            value: autoDeductStock,
            onChanged: (bool value) =>
                _saveAutoDeductStock(context, ref, value),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionTitle('数据'),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('导出数据'),
                subtitle: const Text('JSON 完整备份 / CSV 表格分析'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _exportData(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('导入数据'),
                subtitle: const Text('从 JSON 备份恢复（下一步实现）'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMessage(context, '导入将在下一步实现'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: const Text('同步'),
                subtitle: const Text('WebDAV（P1）'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMessage(context, '同步将在 P1 实现'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionTitle('关于'),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('开源许可'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMessage(context, '开源许可列表将在 M2 实现（主许可证 MIT）'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('反馈'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showMessage(context, '反馈入口将在 M2 实现（GitHub Issues）'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于豆刻'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showMessage(context, '豆刻 BeanClick v0.1.0 · 本地优先，无追踪'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: <Widget>[
              Text(
                '豆刻 BeanClick',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v0.1.0',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 区块标题。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Future<void> _saveThemeMode(
  BuildContext context,
  WidgetRef ref,
  ThemeMode mode,
) async {
  try {
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
  } catch (error) {
    if (!context.mounted) return;
    _showMessage(context, '主题保存失败：$error');
  }
}

Future<void> _saveAutoDeductStock(
  BuildContext context,
  WidgetRef ref,
  bool value,
) async {
  try {
    await ref.read(settingsRepositoryProvider).setAutoDeductStock(value);
  } catch (error) {
    if (!context.mounted) return;
    _showMessage(context, '设置保存失败：$error');
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// 导出流程：读默认格式 → 让用户二选一 → 落盘 + 唤起分享 → 记住选择。
Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  final SettingsRepository settings = ref.read(settingsRepositoryProvider);

  // 默认格式来自设置表（手册 §17 决策 8：JSON 为备份默认）。
  final String? stored = await settings.get(SettingsKeys.exportFormat);
  final ExportFormat defaultFormat = ExportFormat.values.firstWhere(
    (ExportFormat format) => format.name == stored,
    orElse: () => ExportFormat.json,
  );

  if (!context.mounted) return;
  final ExportFormat? chosen =
      await showExportFormatDialog(context, defaultFormat: defaultFormat);
  if (chosen == null || !context.mounted) return;

  await runExport(context, ref.read(exportServiceProvider), chosen);
  // 记住这次的选择，下次默认选中它。
  await settings.set(SettingsKeys.exportFormat, chosen.name);
}
