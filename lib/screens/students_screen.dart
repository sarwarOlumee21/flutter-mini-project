import 'package:flutter/material.dart';
import '../data/app_data.dart';

class ClassStudentsScreen extends StatelessWidget {
  final String className;

  const ClassStudentsScreen({super.key, required this.className});

  Future<void> _showAddStudentDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('شاگرد جدید'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'نام و تخلص',
                  hintText: 'مثلاً احمد رضایی',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'نام شاگرد را وارد کنید';
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
                child: const Text('افزودن'),
              ),
            ],
          ),
        );
      },
    );

    if (created == true && context.mounted) {
      final success =
          await AppData.instance.addStudent(className, controller.text);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('افزودن شاگرد ممکن نشد')),
        );
      }
    }

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          title: Text(className),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => _showAddStudentDialog(context),
              icon: const Icon(Icons.person_add),
              tooltip: 'شاگرد جدید',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddStudentDialog(context),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('شاگرد جدید'),
        ),
        body: ListenableBuilder(
          listenable: AppData.instance,
          builder: (context, _) {
            final students =
                AppData.instance.studentsByClass[className] ?? [];

            if (students.isEmpty) {
              return const Center(
                child: Text(
                  'هنوز شاگردی در این صنف ثبت نشده است.\nروی «شاگرد جدید» بزنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final name = student['name'] ?? '';
                final initial = name.isNotEmpty ? name[0] : '?';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF1565C0).withValues(alpha: 0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('شناسه: ${student['id'] ?? '-'}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
