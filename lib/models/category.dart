// lib/models/category.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Category {
  final int? id;
  final String name;
  final String icon; // 线性符号文字，如 "📚" 替换为内置 icon name
  final Color color;
  final bool isArchived;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isArchived = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color.value,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    icon: map['icon'] as String,
    color: Color(map['color'] as int),
    isArchived: (map['is_archived'] as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    Color? color,
    bool? isArchived,
    DateTime? createdAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );
}

// 预设类别快捷选项
class PresetCategory {
  final String name;
  final String icon;

  const PresetCategory(this.name, this.icon);
}

const List<PresetCategory> kPresetCategories = [
  PresetCategory('睡眠', '🌙'),
  PresetCategory('学习', '📖'),
  PresetCategory('工作', '💼'),
  PresetCategory('吃饭', '🍚'),
  PresetCategory('运动', '🏃'),
  PresetCategory('读书', '📚'),
  PresetCategory('看小说', '📝'),
  PresetCategory('打游戏', '🎮'),
  PresetCategory('刷视频', '📱'),
  PresetCategory('家务', '🧹'),
  PresetCategory('休息', '☕'),
  PresetCategory('赶路', '🚌'),
  PresetCategory('其他', '◉'),
];

// 内置线性符号列表（不用 emoji，用文字符号）
const List<String> kIconSymbols = [
  '◉', '◎', '○', '●', '◆', '◇', '▲', '△', '▼', '▽',
  '★', '☆', '♦', '♠', '♣', '♥', '◐', '◑', '◒', '◓',
  '⊕', '⊗', '⊙', '⊚', '⊛', '⊜', '⊝', '⊞', '⊟', '⊠',
  '⌘', '⌛', '⌚', '⚡', '✦', '✧', '✩', '✪', '✫', '✬',
  '❖', '❋', '❊', '❉', '❈', '❇', '❆', '❅', '❄', '❃',
];
