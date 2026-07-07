import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'web_data_store.dart';

class AppData extends ChangeNotifier {
  AppData._();

  static final AppData instance = AppData._();

  final List<String> classes = [];
  final Map<String, List<Map<String, String>>> studentsByClass = {};
  final Map<String, int> _classIdsByName = {};
  final Map<String, Map<String, String>> _attendanceByDate = {};

  bool _initialized = false;

  static const presentStatus = '\u062d\u0627\u0636\u0631';
  static const absentStatus = '\u063a\u06cc\u0631\u062d\u0627\u0636\u0631';
  static const leaveStatus = '\u0631\u062e\u0635\u062a';

  int get totalStudents =>
      studentsByClass.values.fold(0, (sum, list) => sum + list.length);

  int get todayPresentCount {
    final statuses = _attendanceByDate[_dateKey(DateTime.now())];
    if (statuses == null) return 0;
    return statuses.values.where((status) => status == presentStatus).length;
  }

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      if (!_loadWebData()) {
        _seedMemoryData();
        _saveWebData();
      }
      _initialized = true;
      notifyListeners();
      return;
    }

    await _ensureSeedData();
    await _loadClassesAndStudents();
    await loadAttendanceForDate(DateTime.now());
    _initialized = true;
    notifyListeners();
  }

  Future<bool> addClass(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || classes.contains(trimmed)) {
      return false;
    }

    if (kIsWeb) {
      classes.add(trimmed);
      studentsByClass[trimmed] = [];
      final saved = _saveWebData();
      if (!saved) {
        classes.remove(trimmed);
        studentsByClass.remove(trimmed);
        return false;
      }
      notifyListeners();
      return true;
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'classes',
      {'name': trimmed, 'created_at': now},
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    await _loadClassesAndStudents();
    notifyListeners();
    return true;
  }

  Future<bool> addStudent(String className, String name) async {
    final trimmed = name.trim();
    if (kIsWeb) {
      if (trimmed.isEmpty || !studentsByClass.containsKey(className)) {
        return false;
      }
      studentsByClass[className]!.add({
        'id': _nextWebStudentId(),
        'name': trimmed,
      });
      _saveWebData();
      notifyListeners();
      return true;
    }

    final classId = _classIdsByName[className];
    if (trimmed.isEmpty || classId == null) {
      return false;
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('students', {
      'class_id': classId,
      'name': trimmed,
      'created_at': now,
    });
    await _loadClassesAndStudents();
    notifyListeners();
    return true;
  }

  Future<Map<String, String>> loadAttendanceForDate(DateTime date) async {
    final key = _dateKey(date);
    if (kIsWeb) {
      return Map<String, String>.from(_attendanceByDate[key] ?? {});
    }

    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [key],
    );
    final statuses = <String, String>{
      for (final row in rows) '${row['student_id']}': row['status'] as String,
    };
    _attendanceByDate[key] = statuses;
    notifyListeners();
    return Map<String, String>.from(statuses);
  }

  Future<void> saveAttendance({
    required DateTime date,
    required Map<String, String> statusesByStudentId,
  }) async {
    if (kIsWeb) {
      _attendanceByDate[_dateKey(date)] = Map<String, String>.from(
        statusesByStudentId,
      );
      _saveWebData();
      notifyListeners();
      return;
    }

    final db = await AppDatabase.instance.database;
    final key = _dateKey(date);
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    for (final entry in statusesByStudentId.entries) {
      final studentId = int.tryParse(entry.key);
      if (studentId == null) continue;
      batch.insert(
        'attendance',
        {
          'student_id': studentId,
          'date': key,
          'status': entry.value,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    _attendanceByDate[key] = Map<String, String>.from(statusesByStudentId);
    notifyListeners();
  }

  Future<bool> addGrade({
    required String studentId,
    required String subject,
    required double score,
    required DateTime date,
  }) async {
    final id = int.tryParse(studentId);
    final trimmedSubject = subject.trim();
    if (id == null || trimmedSubject.isEmpty) return false;
    if (kIsWeb) {
      return true;
    }

    final db = await AppDatabase.instance.database;
    await db.insert('grades', {
      'student_id': id,
      'subject': trimmedSubject,
      'score': score,
      'date': _dateKey(date),
      'created_at': DateTime.now().toIso8601String(),
    });
    notifyListeners();
    return true;
  }

  Future<void> _loadClassesAndStudents() async {
    final db = await AppDatabase.instance.database;
    final classRows = await db.query('classes', orderBy: 'id ASC');
    final studentRows = await db.rawQuery('''
      SELECT students.id, students.name, classes.name AS class_name
      FROM students
      INNER JOIN classes ON classes.id = students.class_id
      ORDER BY students.id ASC
    ''');

    classes
      ..clear()
      ..addAll(classRows.map((row) => row['name'] as String));

    _classIdsByName
      ..clear()
      ..addEntries(
        classRows.map(
          (row) => MapEntry(row['name'] as String, row['id'] as int),
        ),
      );

    studentsByClass
      ..clear()
      ..addEntries(
        classes.map((name) => MapEntry(name, <Map<String, String>>[])),
      );

    for (final row in studentRows) {
      final className = row['class_name'] as String;
      studentsByClass.putIfAbsent(className, () => []);
      studentsByClass[className]!.add({
        'id': '${row['id']}',
        'name': row['name'] as String,
      });
    }
  }

  Future<void> _ensureSeedData() async {
    final db = await AppDatabase.instance.database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM classes'),
        ) ??
        0;
    if (count > 0) return;

    final seed = <String, List<String>>{
      '\u0635\u0646\u0641 7': [
        '\u0627\u062d\u0645\u062f \u0631\u0636\u0627\u06cc\u06cc',
        '\u0645\u062d\u0645\u062f \u0639\u0644\u06cc',
        '\u062d\u0633\u06cc\u0646 \u06a9\u0631\u06cc\u0645\u06cc',
      ],
      '\u0635\u0646\u0641 8': [
        '\u0633\u0627\u0631\u0627 \u0645\u062d\u0645\u062f\u06cc',
        '\u0641\u0627\u0637\u0645\u0647 \u0627\u062d\u0645\u062f\u06cc',
        '\u0632\u0647\u0631\u0627 \u0646\u0648\u0631\u06cc',
      ],
      '\u0635\u0646\u0641 9': [
        '\u0639\u0644\u06cc \u062d\u0633\u06cc\u0646\u06cc',
        '\u0631\u0636\u0627 \u0627\u062d\u0645\u062f\u06cc',
      ],
      '\u0635\u0646\u0641 10': [
        '\u0645\u0631\u06cc\u0645 \u0635\u0627\u062f\u0642\u06cc',
        '\u0627\u0645\u06cc\u0631 \u062d\u0633\u06cc\u0646\u06cc',
        '\u0646\u0631\u06af\u0633 \u0631\u062d\u06cc\u0645\u06cc',
      ],
    };

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    final classIds = <String, int>{};
    for (final className in seed.keys) {
      final id = await db.insert('classes', {
        'name': className,
        'created_at': now,
      });
      classIds[className] = id;
    }

    for (final entry in seed.entries) {
      final classId = classIds[entry.key]!;
      for (final studentName in entry.value) {
        batch.insert('students', {
          'class_id': classId,
          'name': studentName,
          'created_at': now,
        });
      }
    }
    await batch.commit(noResult: true);
  }

  bool _loadWebData() {
    final raw = WebDataStore.read();
    if (raw == null || raw.isEmpty) return false;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedClasses = List<String>.from(decoded['classes'] as List? ?? []);
      final savedStudents = decoded['studentsByClass'] as Map? ?? {};
      final savedAttendance = decoded['attendanceByDate'] as Map? ?? {};

      classes
        ..clear()
        ..addAll(savedClasses);

      studentsByClass
        ..clear()
        ..addEntries(
          savedStudents.entries.map((entry) {
            final students = (entry.value as List? ?? [])
                .map((student) => Map<String, String>.from(student as Map))
                .toList();
            return MapEntry(entry.key as String, students);
          }),
        );

      for (final className in classes) {
        studentsByClass.putIfAbsent(className, () => []);
      }

      _attendanceByDate
        ..clear()
        ..addEntries(
          savedAttendance.entries.map((entry) {
            return MapEntry(
              entry.key as String,
              Map<String, String>.from(entry.value as Map),
            );
          }),
        );
      return classes.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _saveWebData() {
    final payload = jsonEncode({
      'classes': classes,
      'studentsByClass': studentsByClass,
      'attendanceByDate': _attendanceByDate,
    });
    WebDataStore.write(
      payload,
    );
    return WebDataStore.read() == payload;
  }

  void _seedMemoryData() {
    final seed = _seedStudents();
    var id = 1;
    classes
      ..clear()
      ..addAll(seed.keys);
    studentsByClass
      ..clear()
      ..addEntries(seed.entries.map((entry) {
        return MapEntry(
          entry.key,
          entry.value.map((studentName) {
            return {
              'id': '${id++}',
              'name': studentName,
            };
          }).toList(),
        );
      }));
  }

  String _nextWebStudentId() {
    var maxId = 0;
    for (final list in studentsByClass.values) {
      for (final student in list) {
        final id = int.tryParse(student['id'] ?? '') ?? 0;
        if (id > maxId) maxId = id;
      }
    }
    return '${maxId + 1}';
  }

  Map<String, List<String>> _seedStudents() {
    return {
      '\u0635\u0646\u0641 7': [
        '\u0627\u062d\u0645\u062f \u0631\u0636\u0627\u06cc\u06cc',
        '\u0645\u062d\u0645\u062f \u0639\u0644\u06cc',
        '\u062d\u0633\u06cc\u0646 \u06a9\u0631\u06cc\u0645\u06cc',
      ],
      '\u0635\u0646\u0641 8': [
        '\u0633\u0627\u0631\u0627 \u0645\u062d\u0645\u062f\u06cc',
        '\u0641\u0627\u0637\u0645\u0647 \u0627\u062d\u0645\u062f\u06cc',
        '\u0632\u0647\u0631\u0627 \u0646\u0648\u0631\u06cc',
      ],
      '\u0635\u0646\u0641 9': [
        '\u0639\u0644\u06cc \u062d\u0633\u06cc\u0646\u06cc',
        '\u0631\u0636\u0627 \u0627\u062d\u0645\u062f\u06cc',
      ],
      '\u0635\u0646\u0641 10': [
        '\u0645\u0631\u06cc\u0645 \u0635\u0627\u062f\u0642\u06cc',
        '\u0627\u0645\u06cc\u0631 \u062d\u0633\u06cc\u0646\u06cc',
        '\u0646\u0631\u06af\u0633 \u0631\u062d\u06cc\u0645\u06cc',
      ],
    };
  }

  static const List<String> weekdayNames = [
    '\u062f\u0648\u0634\u0646\u0628\u0647',
    '\u0633\u0647\u200c\u0634\u0646\u0628\u0647',
    '\u0686\u0647\u0627\u0631\u0634\u0646\u0628\u0647',
    '\u067e\u0646\u062c\u200c\u0634\u0646\u0628\u0647',
    '\u062c\u0645\u0639\u0647',
    '\u0634\u0646\u0628\u0647',
    '\u06cc\u06a9\u0634\u0646\u0628\u0647',
  ];

  static String weekdayName(DateTime date) {
    return weekdayNames[date.weekday - 1];
  }

  static String formatDate(DateTime date) {
    return _dateKey(date);
  }

  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String _dateKey(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
