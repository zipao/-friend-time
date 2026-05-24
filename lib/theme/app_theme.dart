import 'package:flutter/material.dart';

class AppColors {
  // 主背景 - 暖米色
  static const Color background = Color(0xFFF5F0EB);
  // 卡片背景
  static const Color cardBackground = Color(0xFFFAF6F1);
  // 次级卡片
  static const Color cardSecondary = Color(0xFFEEE8E0);
  // 主文本
  static const Color textPrimary = Color(0xFF2C2420);
  // 次级文本
  static const Color textSecondary = Color(0xFF8C7B70);
  // 弱文本（占位符）
  static const Color textHint = Color(0xFFB8A99A);
  // 分隔线
  static const Color divider = Color(0xFFE0D8CF);

  // 操作色
  static const Color startGreen = Color(0xFF6BAF7A);      // 开始按钮
  static const Color stopRed = Color(0xFFD4745A);         // 结束按钮（陶土红）
  static const Color confirmGreen = Color(0xFF6BAF7A);    // 确认保存
  static const Color accentWarm = Color(0xFFE8A87C);      // 强调暖橙

  // 记录中状态标签（柔和，不用红色）
  static const Color recordingTag = Color(0xFFEEE8E0);
  static const Color recordingTagText = Color(0xFF8C7B70);

  // 自定义分类调色板（低饱和度、呼吸感）
  static const List<Color> categoryPalette = [
    Color(0xFFB8D4C8), // 薄荷绿
    Color(0xFFD4B8C8), // 藕粉
    Color(0xFFB8C8D4), // 灰蓝
    Color(0xFFD4CDB8), // 沙黄
    Color(0xFFC8D4B8), // 嫩草
    Color(0xFFD4B8B8), // 砖粉
    Color(0xFFB8BED4), // 薰衣草
    Color(0xFFD4C8B8), // 燕麦
    Color(0xFFB8D4D4), // 天蓝灰
    Color(0xFFCDB8D4), // 丁香紫
    Color(0xFFD4D4B8), // 黄绿
    Color(0xFFB8C8B8), // 苔绿
  ];

  // 遮罩
  static const Color overlay = Color(0x80000000);
}

class AppTextStyles {
  // 数字时钟（等宽字体）
  static const TextStyle clock = TextStyle(
    fontFamily: 'monospace',
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  // 计时器大数字
  static const TextStyle timerLarge = TextStyle(
    fontFamily: 'monospace',
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 2,
  );

  // 计时器小数字
  static const TextStyle timerMedium = TextStyle(
    fontFamily: 'monospace',
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  // 日期
  static const TextStyle date = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w400,
  );

  // 标题
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // 正文
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w400,
  );

  // 次级文本
  static const TextStyle secondary = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w400,
  );

  // 时长 - 大数字部分
  static TextStyle durationNumber({double fontSize = 32}) => TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // 时长 - 小单位部分（数字的一半字号）
  static TextStyle durationUnit({double fontSize = 16}) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.startGreen,
      secondary: AppColors.accentWarm,
      surface: AppColors.cardBackground,
      background: AppColors.background,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.title,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardBackground,
      modalBackgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
  );
}
