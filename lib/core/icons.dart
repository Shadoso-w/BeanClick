import 'package:flutter/material.dart';

/// 「新增」类入口统一用的图标：**圆圈加号**。
///
/// 用户反馈：豆库里「新增咖啡豆 / 新增磨豆机」的入口分散在好几处
/// （豆库右下角、豆子编辑页的「再来一袋」、冲煮记录表单里的内联新增），
/// 有的用实心 + 有的用文字按钮，看起来不像同一件事。
/// 统一从这个常量取，避免以后又长出第二种样式。
const IconData addCircleIcon = Icons.add_circle_outline;

/// 收藏（记录页右滑、筛选入口、表单开关都用它）。
const IconData favoriteIcon = Icons.bookmark_border_rounded;

/// 已收藏（实心）。
const IconData favoriteFilledIcon = Icons.bookmark_rounded;
