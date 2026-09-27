/// 导出选择弹窗（手册 §17 决策 8：导出时二选一，JSON 为备份默认）。
library;

import 'package:beanclick/data/export_service.dart';
import 'package:beanclick/domain/export/export_encoder.dart';
import 'package:flutter/material.dart';

/// 弹出导出格式选择，返回用户选的格式；取消则返回 null。
///
/// [defaultFormat] 来自设置里的 `exportFormat`（默认 JSON）。
Future<ExportFormat?> showExportFormatDialog(
  BuildContext context, {
  ExportFormat defaultFormat = ExportFormat.json,
}) {
  return showDialog<ExportFormat>(
    context: context,
    builder: (BuildContext context) =>
        _ExportFormatDialog(defaultFormat: defaultFormat),
  );
}

class _ExportFormatDialog extends StatefulWidget {
  const _ExportFormatDialog({required this.defaultFormat});

  final ExportFormat defaultFormat;

  @override
  State<_ExportFormatDialog> createState() => _ExportFormatDialogState();
}

class _ExportFormatDialogState extends State<_ExportFormatDialog> {
  late ExportFormat _selected = widget.defaultFormat;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出数据'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RadioGroup<ExportFormat>(
            groupValue: _selected,
            onChanged: (ExportFormat? value) {
              if (value != null) setState(() => _selected = value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final ExportFormat format in ExportFormat.values)
                  RadioListTile<ExportFormat>(
                    contentPadding: EdgeInsets.zero,
                    value: format,
                    title: Text(format.label),
                    subtitle: Text(format.description),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '数据只存在这台设备上，导出文件由你自己保管。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('导出'),
        ),
      ],
    );
  }
}

/// 执行导出并展示结果。
///
/// 返回是否成功导出（可用于刷新界面或写设置）。
Future<bool> runExport(
  BuildContext context,
  Exporter service,
  ExportFormat format,
) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  try {
    final ExportOutcome outcome = await service.exportAndShare(format);
    if (outcome.shared) {
      _show(messenger, '已导出 ${outcome.fileName}');
    } else {
      // 文件其实已经写成功了，只是没能唤起分享面板。
      _show(messenger, '已保存 ${outcome.fileName}（未能唤起分享：${outcome.shareError}）');
    }
    return true;
  } catch (error) {
    _show(messenger, '导出失败：$error');
    return false;
  }
}

void _show(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
}
