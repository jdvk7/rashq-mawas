import 'package:flutter/material.dart';

void main() {
  runApp(const RashqMawasApp());
}

class RashqMawasApp extends StatelessWidget {
  const RashqMawasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رشق مواس',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0B14),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رشق مواس',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6C2BD9),
                    Color(0xFFB52BD9),
                  ],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أهلاً بك 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'رصيد النقاط',
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '0 نقطة',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'الخدمات',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _ServiceCard(
              icon: Icons.people_alt,
              title: 'متابعين ثابتين',
              onTap: () {},
            ),
            _ServiceCard(
              icon: Icons.favorite,
              title: 'لايكات ثابتين',
              onTap: () {},
            ),
            _ServiceCard(
              icon: Icons.repeat,
              title: 'إعادة نشر ثابتين',
              onTap: () {},
            ),
            _ServiceCard(
              icon: Icons.bookmark,
              title: 'حفظ ثابتين',
              onTap: () {},
            ),
            _ServiceCard(
              icon: Icons.explore,
              title: 'إكسبلور ثابتين',
              onTap: () {},
            ),
            _ServiceCard(
              icon: Icons.visibility,
              title: 'مشاهدات ثابتين',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart),
              label: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'شراء النقاط',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
