import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../widgets/page_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xffF5F6FB),
        body: SafeArea(
          child: DashboardContent(),
        ),
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final ValueChanged<int>? onTabSelected;

  const DashboardContent({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const PageHeader(
              title: 'داشبورد',
              subtitle: 'خوش آمدید',
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: AppData.instance,
              builder: (context, _) {
                final totalStudents = AppData.instance.totalStudents;
                final totalClasses = AppData.instance.classes.length;
                final todayPresent = AppData.instance.todayPresentCount;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'سیستم مدیریت شاگردان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$totalStudents شاگرد در $totalClasses صنف ثبت شده است',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatItem(
                            icon: Icons.group,
                            color: Colors.purple,
                            value: '$totalStudents',
                            label: 'کل شاگردان',
                          ),
                          StatItem(
                            icon: Icons.check_circle,
                            color: Colors.green,
                            value: '$todayPresent',
                            label: 'حاضر امروز',
                          ),
                          StatItem(
                            icon: Icons.class_,
                            color: Colors.blue,
                            value: '$totalClasses',
                            label: 'صنف‌ها',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            MenuItem(
              title: 'ثبت حضوری',
              icon: Icons.check_box,
              onTap: () => onTabSelected?.call(2),
            ),
            MenuItem(
              title: 'لیست شاگردان',
              icon: Icons.people,
              onTap: () => onTabSelected?.call(1),
            ),
            MenuItem(
              title: 'صنف‌ها',
              icon: Icons.menu_book,
              onTap: () => onTabSelected?.call(1),
            ),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.arrow_back_ios, size: 18),
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(icon, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
