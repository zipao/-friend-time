// lib/widgets/bottom_sheets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/time_record.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

// ─── 通用 Bottom Sheet 抓手 ───

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.textHint,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─── 通用标题行 ───

class _SheetTitle extends StatelessWidget {
  final String title;
  const _SheetTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Text(title, style: AppTextStyles.title),
    );
  }
}

// ═══════════════════════════════════════════════
// 1. 分类 + 备注选择 Bottom Sheet
// ═══════════════════════════════════════════════

Future<Map<String, dynamic>?> showCategoryNoteSheet(
  BuildContext context, {
  required DateTime startTime,
  required DateTime endTime,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (ctx) => _CategoryNoteSheet(
      startTime: startTime,
      endTime: endTime,
    ),
  );
}

class _CategoryNoteSheet extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  const _CategoryNoteSheet({required this.startTime, required this.endTime});

  @override
  State<_CategoryNoteSheet> createState() => _CategoryNoteSheetState();
}

class _CategoryNoteSheetState extends State<_CategoryNoteSheet> {
  int? _selectedCategoryId;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>().categories;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final duration = widget.endTime.difference(widget.startTime).inSeconds;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const _SheetTitle('这段时间在做什么？'),

            // 时长预览
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text(
                    '${TimeUtils.formatTime(widget.startTime)} → ${TimeUtils.formatTime(widget.endTime)}',
                    style: AppTextStyles.secondary,
                  ),
                  const SizedBox(width: 12),
                  DurationDisplay(
                    totalSeconds: duration,
                    numberFontSize: 18,
                    unitFontSize: 12,
                  ),
                ],
              ),
            ),

            // 分类网格
            if (cats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AddCategoryButton(onAdded: () {
                  context.read<CategoryProvider>().loadCategories();
                }),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: cats.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == cats.length) {
                      return _NewCategoryCard(onAdded: () {
                        context.read<CategoryProvider>().loadCategories();
                      });
                    }
                    final cat = cats[i];
                    final isSelected = _selectedCategoryId == cat.id;
                    return _CategoryCard(
                      category: cat,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedCategoryId = cat.id),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 备注输入
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _noteController,
                style: AppTextStyles.body,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '随手记一笔（可选）',
                  hintStyle: AppTextStyles.secondary.copyWith(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.cardSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 确认按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedCategoryId == null
                      ? null
                      : () => Navigator.of(context).pop({
                            'categoryId': _selectedCategoryId,
                            'note': _noteController.text.trim(),
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.confirmGreen,
                    disabledBackgroundColor: AppColors.cardSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedCategoryId == null ? '请选择分类' : '下一步',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? category.color : AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: category.color.withOpacity(0.8), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewCategoryCard extends StatelessWidget {
  final VoidCallback onAdded;
  const _NewCategoryCard({required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showAddCategorySheet(context);
        onAdded();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textHint,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.textHint, size: 22),
            SizedBox(height: 4),
            Text(
              '新增',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  final VoidCallback onAdded;
  const _AddCategoryButton({required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          await showAddCategorySheet(context);
          onAdded();
        },
        icon: const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
        label: Text('添加第一个分类', style: AppTextStyles.secondary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 2. 二次确认 Bottom Sheet
// ═══════════════════════════════════════════════

Future<bool?> showConfirmSheet(
  BuildContext context, {
  required DateTime startTime,
  required DateTime endTime,
  required Category category,
  String? note,
  bool allowEndCorrection = true,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (ctx) => _ConfirmSheet(
      startTime: startTime,
      endTime: endTime,
      category: category,
      note: note,
      allowEndCorrection: allowEndCorrection,
    ),
  );
}

class _ConfirmSheet extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final Category category;
  final String? note;
  final bool allowEndCorrection;

  const _ConfirmSheet({
    required this.startTime,
    required this.endTime,
    required this.category,
    this.note,
    required this.allowEndCorrection,
  });

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  DateTime? _correctedEnd;
  bool _showingCorrection = false;

  DateTime get displayEnd => _correctedEnd ?? widget.endTime;
  int get durationSeconds => displayEnd.difference(widget.startTime).inSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const _SheetTitle('确认记录'),

          // 摘要卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: widget.category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.category.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(widget.category.name, style: AppTextStyles.title),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${TimeUtils.formatTime(widget.startTime)}  →  ${TimeUtils.formatTime(displayEnd)}',
                        style: AppTextStyles.secondary,
                      ),
                      if (_correctedEnd != null)
                        Text(' (已修正)', style: AppTextStyles.secondary.copyWith(
                          color: AppColors.accentWarm,
                        )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DurationDisplay(
                    totalSeconds: durationSeconds,
                    numberFontSize: 28,
                    unitFontSize: 14,
                  ),
                  if (widget.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(widget.note!, style: AppTextStyles.secondary),
                  ],
                ],
              ),
            ),
          ),

          // 修正入口
          if (widget.allowEndCorrection) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showEndCorrectionPicker(),
              child: Text(
                _correctedEnd == null ? '实际结束时间不对？' : '修改结束时间修正',
                style: AppTextStyles.secondary.copyWith(
                  color: AppColors.accentWarm,
                  fontSize: 13,
                ),
              ),
            ),
          ] else
            const SizedBox(height: 16),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('返回修改'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.confirmGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      '确认保存',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEndCorrectionPicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.endTime),
      helpText: '修正结束时间',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.startGreen),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    var corrected = DateTime(
      widget.startTime.year,
      widget.startTime.month,
      widget.startTime.day,
      picked.hour,
      picked.minute,
    );
    // 如果修正时间早于开始，则 +1天
    if (corrected.isBefore(widget.startTime)) {
      corrected = corrected.add(const Duration(days: 1));
    }
    // 不允许超过原始结束时间（修正不能拉长）
    if (corrected.isAfter(widget.endTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('修正时间不能晚于实际结束时间')),
        );
      }
      return;
    }
    setState(() => _correctedEnd = corrected);
  }
}

// ═══════════════════════════════════════════════
// 3. 手动补录 Bottom Sheet
// ═══════════════════════════════════════════════

Future<Map<String, dynamic>?> showManualEntrySheet(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (ctx) => const _ManualEntrySheet(),
  );
}

class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet();
  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _endTime = DateTime.now();
  int? _selectedCategoryId;
  final _noteController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: isStart ? '开始时间' : '结束时间',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.startGreen),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final now = DateTime.now();
    var updated = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    setState(() {
      if (isStart) {
        _startTime = updated;
      } else {
        _endTime = updated;
      }
      _errorMessage = null;
    });
  }

  void _validate() {
    final resolvedEnd = TimeUtils.resolveManualEndTime(_startTime, _endTime);
    final error = TimeUtils.validateManualRecord(_startTime, resolvedEnd);
    setState(() => _errorMessage = error);
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>().categories;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final resolvedEnd = TimeUtils.resolveManualEndTime(_startTime, _endTime);
    final isCrossDay = resolvedEnd.day != _startTime.day;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const _SheetTitle('手动补录'),

            // 时间选择行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: '开始',
                      time: _startTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward, color: AppColors.textHint, size: 16),
                  ),
                  Expanded(
                    child: _TimePickerButton(
                      label: '结束',
                      time: _endTime,
                      suffix: isCrossDay ? '+1天' : null,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.stopRed, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),

            // 分类选择
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: cats.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == cats.length) {
                    return _NewCategoryCard(onAdded: () {
                      context.read<CategoryProvider>().loadCategories();
                    });
                  }
                  final cat = cats[i];
                  final isSelected = _selectedCategoryId == cat.id;
                  return _CategoryCard(
                    category: cat,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 备注
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _noteController,
                style: AppTextStyles.body,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '随手记一笔（可选）',
                  hintStyle: AppTextStyles.secondary.copyWith(
                    color: AppColors.textHint, fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.cardSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 下一步按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedCategoryId == null
                      ? null
                      : () {
                          _validate();
                          if (_errorMessage != null) return;
                          Navigator.pop(context, {
                            'startTime': _startTime,
                            'endTime': resolvedEnd,
                            'categoryId': _selectedCategoryId,
                            'note': _noteController.text.trim(),
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.confirmGreen,
                    disabledBackgroundColor: AppColors.cardSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '下一步确认',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final DateTime time;
  final String? suffix;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    this.suffix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.secondary),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  TimeUtils.formatTime(time),
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 4),
                  Text(suffix!,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.accentWarm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 4. 新增分类 Bottom Sheet
// ═══════════════════════════════════════════════

Future<void> showAddCategorySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (ctx) => const _AddCategorySheet(),
  );
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();
  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  String _selectedIcon = kIconSymbols[0];
  String? _selectedPreset;
  bool _isCustom = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await context.read<CategoryProvider>().addCategory(
      name: name,
      icon: _selectedIcon,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const _SheetTitle('添加分类'),

            // 预设快捷选项
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('快速选择', style: AppTextStyles.secondary),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kPresetCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final preset = kPresetCategories[i];
                  final isSelected = _selectedPreset == preset.name && !_isCustom;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPreset = preset.name;
                        _selectedIcon = preset.icon;
                        _isCustom = false;
                        _nameController.text = preset.name;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.startGreen.withOpacity(0.15) : AppColors.cardSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.startGreen.withOpacity(0.5))
                            : null,
                      ),
                      child: Text(
                        '${preset.icon} ${preset.name}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? AppColors.startGreen : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 自定义输入
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('自定义', style: AppTextStyles.secondary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _nameController,
                style: AppTextStyles.body,
                onChanged: (_) => setState(() => _isCustom = true),
                decoration: InputDecoration(
                  hintText: '输入名称',
                  hintStyle: AppTextStyles.secondary.copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.cardSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 图标选择
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('选择符号', style: AppTextStyles.secondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kIconSymbols.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final sym = kIconSymbols[i];
                  final isSelected = _selectedIcon == sym;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedIcon = sym;
                      _isCustom = true;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.startGreen.withOpacity(0.15) : AppColors.cardSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: AppColors.startGreen.withOpacity(0.5))
                            : null,
                      ),
                      child: Center(
                        child: Text(sym, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nameController.text.trim().isEmpty ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.confirmGreen,
                    disabledBackgroundColor: AppColors.cardSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '添加',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 5. 记录详情 Bottom Sheet（只读）
// ═══════════════════════════════════════════════

void showRecordDetailSheet(
  BuildContext context, {
  required TimeRecord record,
  required Category category,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (ctx) => _RecordDetailSheet(record: record, category: category),
  );
}

class _RecordDetailSheet extends StatelessWidget {
  final TimeRecord record;
  final Category category;
  const _RecordDetailSheet({required this.record, required this.category});

  @override
  Widget build(BuildContext context) {
    final hasCorrection = record.effectiveEndTime != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(category.icon, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: AppTextStyles.title),
                        if (record.isManual)
                          Text('手动补录', style: AppTextStyles.secondary),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.play_arrow_rounded,
                  label: '开始',
                  value: '${TimeUtils.formatFullDate(record.startTime)}  ${TimeUtils.formatTime(record.startTime)}',
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.stop_rounded,
                  label: hasCorrection ? '结束（修正）' : '结束',
                  value: '${TimeUtils.formatFullDate(record.actualEndTime)}  ${TimeUtils.formatTime(record.actualEndTime)}',
                  valueColor: hasCorrection ? AppColors.accentWarm : null,
                ),
                if (hasCorrection) ...[
                  const SizedBox(height: 4),
                  _DetailRow(
                    icon: Icons.history,
                    label: '原始结束',
                    value: TimeUtils.formatTime(record.rawEndTime),
                    valueColor: AppColors.textHint,
                  ),
                ],
                const SizedBox(height: 12),
                DurationDisplay(
                  totalSeconds: record.durationSeconds,
                  numberFontSize: 28,
                  unitFontSize: 14,
                ),
                if (record.note?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(record.note!, style: AppTextStyles.body),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Text('$label  ', style: AppTextStyles.secondary),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
