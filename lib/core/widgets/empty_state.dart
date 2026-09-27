import 'package:flutter/material.dart';

/// 通用空状态占位。
///
/// 列表没有数据时给出图标、说明与可选的引导按钮，
/// 例如「添加第一支豆子 / 第一台磨豆机」（手册 §9）。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// 顶部图标。
  final IconData icon;

  /// 主标题，一句话说明当前状态。
  final String title;

  /// 补充说明，通常给出下一步操作引导。
  final String message;

  /// 引导按钮文案，与 [onAction] 同时提供时才展示按钮。
  final String? actionLabel;

  /// 引导按钮回调。
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String? label = actionLabel;
    final VoidCallback? action = onAction;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: colors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (label != null && action != null) ...<Widget>[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: action,
                icon: const Icon(Icons.add),
                label: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
