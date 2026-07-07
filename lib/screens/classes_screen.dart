import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../widgets/page_header.dart';
import 'students_screen.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  Future<void> _showAddClassDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('صنف جدید'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'نام صنف',
                  hintText: 'مثلاً صنف ۱۱',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'نام صنف را وارد کنید';
                  }
                  if (AppData.instance.classes.contains(trimmed)) {
                    return 'این صنف قبلاً ثبت شده است';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('لغو'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                child: const Text('ایجاد'),
              ),
            ],
          ),
        );
      },
    );

    if (created == true && context.mounted) {
      final className = controller.text.trim();
      try {
        final success = await AppData.instance.addClass(className);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'صنف "$className" ذخیره شد' : 'ایجاد صنف ممکن نشد',
            ),
          ),
        );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره صنف: $error')),
        );
      }
    }

    controller.dispose();
  }

  void _openClassStudents(BuildContext context, String className) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClassStudentsScreen(className: className),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: AppData.instance,
        builder: (context, _) {
          final classes = AppData.instance.classes;

          return SingleChildScrollView(
            child: Column(
              children: [
                const PageHeader(
                  title: 'صنف‌ها',
                  subtitle: 'مدیریت صنف‌ها و شاگردان',
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صنف‌ها',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddClassDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('جدید'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (classes.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Text(
                              'هنوز صنفی ایجاد نشده است.\nروی «جدید» بزنید.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final className = classes[index];
                            final studentCount = AppData
                                    .instance.studentsByClass[className]
                                    ?.length ??
                                0;

                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 0,
                              shadowColor:
                                  Colors.grey.withValues(alpha: 0.15),
                              child: InkWell(
                                onTap: () =>
                                    _openClassStudents(context, className),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey
                                            .withValues(alpha: 0.15),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.class_rounded,
                                        size: 40,
                                        color: Color(0xFF1565C0),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        className,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$studentCount شاگرد',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
}
