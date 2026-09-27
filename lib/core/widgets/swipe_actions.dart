import 'package:flutter/material.dart';

/// 卡片右滑露出的一个操作按钮。
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;

  /// 按钮上的文字（也是无障碍标签与测试用的定位依据）。
  final String label;

  final VoidCallback onPressed;

  /// 底色，默认取主题的 primary。
  final Color? color;
}

/// 右滑露出操作按钮的卡片容器。
///
/// ## 为什么不用 `Dismissible`
///
/// `Dismissible` 一个方向只能挂一个动作，而且松手就「消失」（是删除语义）。
/// 这里要的是**滑开停住、露出两个按钮、点哪个执行哪个**，
/// 所以自己用 `Stack` + 位移实现。
///
/// ## 手势
///
/// 横向拖动归这里，纵向仍然交给外面的列表滚 —— Flutter 的手势竞技场
/// 按「先动哪个方向」判定，不需要额外处理。
///
/// 滑开时卡片被 [AbsorbPointer] 挡住、点它只会收起（不会误进详情页）。
class SwipeActions extends StatefulWidget {
  const SwipeActions({
    super.key,
    required this.child,
    required this.actions,
    this.semanticLabel,
  });

  /// 卡片本体（要盖住操作按钮的那一层）。
  final Widget child;

  /// 从左到右排列的操作，滑开后依次露出。
  final List<SwipeAction> actions;

  /// 无障碍朗读用，例如「花魁 的快捷操作」。
  final String? semanticLabel;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions> {
  /// 单个操作按钮的宽度。
  static const double _actionWidth = 78;

  double _offset = 0;
  bool _dragging = false;

  double get _maxOffset => widget.actions.length * _actionWidth;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(0.0, _maxOffset);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _dragging = false;
      // 过半就吸附到全开，否则收回去；顺带照顾一下快速轻扫。
      final double velocity = details.velocity.pixelsPerSecond.dx;
      final bool shouldOpen = velocity > 250
          ? true
          : velocity < -250
          ? false
          : _offset > _maxOffset / 2;
      _offset = shouldOpen ? _maxOffset : 0;
    });
  }

  void _close() => setState(() => _offset = 0);

  void _run(SwipeAction action) {
    _close();
    action.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpen = _offset > 0;

    return Semantics(
      label: widget.semanticLabel,
      child: GestureDetector(
        // 滑开时点卡片 = 收起；关着时不参与竞争，卡片自己的点击照常生效。
        onTap: isOpen ? _close : null,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: ClipRRect(
          // 和 Card 默认圆角一致，滑开时露出的按钮不会溢出圆角。
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _maxOffset,
                    height: double.infinity,
                    child: Row(
                      children: <Widget>[
                        for (final SwipeAction action in widget.actions)
                          Expanded(child: _buildAction(context, action)),
                      ],
                    ),
                  ),
                ),
              ),
              // ⚠️ 位移必须包在 AbsorbPointer **外面**：
              // AbsorbPointer 的吸收区域是它自己的 size，不会跟着子树的
              // Transform 走。反过来的话，卡片虽然画到了右边，它那块「吸收区」
              // 还留在左边盖着操作按钮，点「收藏」会被当成点卡片（只会收起）。
              AnimatedContainer(
                duration: _dragging
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(_offset, 0, 0),
                child: AbsorbPointer(absorbing: isOpen, child: widget.child),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, SwipeAction action) {
    final Color background =
        action.color ?? Theme.of(context).colorScheme.primary;
    final Color foreground = Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: background,
      child: InkWell(
        onTap: () => _run(action),
        child: Tooltip(
          message: action.label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(action.icon, color: foreground, size: 22),
              const SizedBox(height: 4),
              Text(
                action.label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
