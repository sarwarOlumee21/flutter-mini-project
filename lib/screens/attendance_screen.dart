import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../widgets/page_header.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime? _selectedDate;
  String? _selectedClass;
  final Map<String, String> _attendanceStatus = {};
  bool _isSaving = false;

  bool get _canTakeAttendance =>
      _selectedDate != null && _selectedClass != null;

  List<Map<String, String>> get _students {
    if (_selectedClass == null) return [];
    return AppData.instance.studentsByClass[_selectedClass] ?? [];
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _attendanceStatus.clear();
    });
    await _loadSelectedAttendance();
  }

  Future<void> _loadSelectedAttendance() async {
    final date = _selectedDate;
    if (date == null) return;

    final savedStatuses = await AppData.instance.loadAttendanceForDate(date);
    if (!mounted) return;

    setState(() {
      _attendanceStatus
        ..clear()
        ..addAll(savedStatuses);
    });
  }

  Future<void> _saveAttendance() async {
    final date = _selectedDate;
    if (date == null || _students.isEmpty) return;

    final statuses = <String, String>{};
    for (final student in _students) {
      final id = student['id'];
      if (id == null) continue;
      statuses[id] = _attendanceStatus[id] ?? 'حاضر';
    }

    setState(() => _isSaving = true);
    await AppData.instance.saveAttendance(
      date: date,
      statusesByStudentId: statuses,
    );
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _attendanceStatus
        ..clear()
        ..addAll(statuses);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('حاضری ذخیره شد')),
    );
  }

  Future<void> _pickDateFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'انتخاب تاریخ',
      cancelText: 'لغو',
      confirmText: 'تأیید',
    );
    if (picked != null) {
      await _selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = AppData.startOfWeek(_selectedDate ?? DateTime.now());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: AppData.instance,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const PageHeader(
                  title: 'حاضری',
                  subtitle: 'ثبت حضور و غیاب',
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حاضری',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildWeekDaysRow(weekStart),
                      const SizedBox(height: 12),
                      _buildDateSelector(),
                      const SizedBox(height: 16),
                      _buildClassSelector(),
                      const SizedBox(height: 16),
                      _buildContent(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekDaysRow(DateTime weekStart) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final isSelected = _selectedDate != null &&
              day.year == _selectedDate!.year &&
              day.month == _selectedDate!.month &&
              day.day == _selectedDate!.day;
          final isToday = day.year == DateTime.now().year &&
              day.month == DateTime.now().month &&
              day.day == DateTime.now().day;

          return Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1565C0)
                      : isToday
                          ? const Color(0xFFE3F2FD)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      AppData.weekdayNames[index].substring(0, 3),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? const Color(0xFF1565C0)
                                : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDateFromCalendar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedDate != null
                ? const Color(0xFF1565C0)
                : Colors.grey.shade300,
            width: _selectedDate != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: _selectedDate != null
                  ? const Color(0xFF1565C0)
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDate != null
                        ? AppData.formatDate(_selectedDate!)
                        : 'تاریخ را انتخاب کنید',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedDate != null
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                  if (_selectedDate != null)
                    Text(
                      AppData.weekdayName(_selectedDate!),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedClass != null
              ? const Color(0xFF1565C0)
              : Colors.grey.shade300,
          width: _selectedClass != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Row(
            children: [
              Icon(Icons.class_rounded, color: Colors.grey),
              SizedBox(width: 12),
              Text('صنف را انتخاب کنید'),
            ],
          ),
          value: _selectedClass,
          items: AppData.instance.classes.map((className) {
            return DropdownMenuItem(
              value: className,
              child: Text(className),
            );
          }).toList(),
          onChanged: (value) async {
            setState(() {
              _selectedClass = value;
              _attendanceStatus.clear();
            });
            await _loadSelectedAttendance();
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!_canTakeAttendance) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedDate == null
                ? 'ابتدا تاریخ را انتخاب کنید'
                : 'صنف را انتخاب کنید',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedDate == null) ...[
            const SizedBox(height: 8),
            Text(
              'روز هفته را لمس کنید یا از تقویم استفاده کنید',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    if (_students.isEmpty) {
      return const Center(
        child: Text('شاگردی در این صنف ثبت نشده است'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'حاضری $_selectedClass - ${AppData.formatDate(_selectedDate!)} (${AppData.weekdayName(_selectedDate!)})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];
            final studentId = student['id']!;
            final status = _attendanceStatus[studentId] ?? 'حاضر';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  student['name']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: DropdownButton<String>(
                  value: status,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'حاضر', child: Text('حاضر')),
                    DropdownMenuItem(value: 'غیرحاضر', child: Text('غیرحاضر')),
                    DropdownMenuItem(value: 'رخصت', child: Text('رخصت')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _attendanceStatus[studentId] = value;
                      });
                    }
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAttendance,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'در حال ذخیره...' : 'ذخیره حاضری'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
