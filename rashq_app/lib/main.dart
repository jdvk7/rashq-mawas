import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isRegisterMode = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUserDocument(User user) async {
    final ref =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'email': user.email,
        'points': 0,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('اكتب البريد الإلكتروني وكلمة المرور');
      return;
    }

    if (password.length < 6) {
      showMessage('كلمة المرور يجب أن تكون 6 أحرف أو أكثر');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isRegisterMode) {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          await createUserDocument(credential.user!);
        }

        if (mounted) {
          showMessage('تم إنشاء الحساب بنجاح ✅');
        }
      } else {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          await createUserDocument(credential.user!);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صحيح';
          break;

        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          break;

        case 'email-already-in-use':
          message = 'هذا البريد مستخدم مسبقاً';
          break;

        case 'weak-password':
          message = 'كلمة المرور ضعيفة';
          break;

        case 'too-many-requests':
          message = 'محاولات كثيرة، حاول لاحقاً';
          break;

        case 'network-request-failed':
          message = 'تحقق من اتصال الإنترنت';
          break;

        default:
          message = e.message ?? 'حدث خطأ أثناء المصادقة';
      }

      if (mounted) {
        showMessage(message);
      }
    } catch (_) {
      if (mounted) {
        showMessage('حدث خطأ غير متوقع');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('اكتب بريدك الإلكتروني أولاً');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (mounted) {
        showMessage('تم إرسال رابط إعادة تعيين كلمة المرور 📩');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showMessage(e.message ?? 'تعذر إرسال البريد');
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.flash_on,
                  size: 80,
                  color: Colors.deepPurpleAccent,
                ),

                const SizedBox(height: 15),

                const Text(
                  'رشق مواس',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isRegisterMode
                      ? 'أنشئ حسابك وابدأ الآن'
                      : 'سجل دخولك للمتابعة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 35),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isRegisterMode
                                ? 'إنشاء حساب'
                                : 'تسجيل الدخول',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                if (!isRegisterMode)
                  TextButton(
                    onPressed: isLoading ? null : resetPassword,
                    child: const Text(
                      'نسيت كلمة المرور؟',
                    ),
                  ),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            isRegisterMode = !isRegisterMode;
                          });
                        },
                  child: Text(
                    isRegisterMode
                        ? 'لديك حساب؟ تسجيل الدخول'
                        : 'ليس لديك حساب؟ إنشاء حساب',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PointPackage {
  final int points;
  final int price;
  final String badge;

  const PointPackage({
    required this.points,
    required this.price,
    this.badge = '',
  });
}

const packages = <PointPackage>[
  PointPackage(points: 500, price: 750),
  PointPackage(points: 1000, price: 1250, badge: '⭐'),
  PointPackage(points: 2000, price: 2000),
  PointPackage(points: 3000, price: 2750),
  PointPackage(points: 5000, price: 4000, badge: '🔥'),
  PointPackage(points: 7500, price: 5500),
  PointPackage(points: 10000, price: 7000, badge: '⭐'),
  PointPackage(points: 15000, price: 9500),
  PointPackage(points: 20000, price: 12000),
  PointPackage(points: 25000, price: 14000),
  PointPackage(points: 35000, price: 18000),
  PointPackage(points: 50000, price: 25000, badge: '🔥'),
  PointPackage(points: 75000, price: 34000),
  PointPackage(points: 100000, price: 43000),
  PointPackage(points: 150000, price: 62000),
  PointPackage(points: 200000, price: 80000),
  PointPackage(points: 300000, price: 115000),
  PointPackage(points: 400000, price: 145000),
  PointPackage(points: 500000, price: 175000, badge: '🔥'),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String formatNumber(int number) {
    final text = number.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data?.data() ?? {};

        final pointsValue = data['points'];

        int points = 0;

        if (pointsValue is int) {
          points = pointsValue;
        } else if (pointsValue is num) {
          points = pointsValue.toInt();
        }

        final role = data['role'] as String? ?? 'user';

        final bool isDeveloper = role == 'admin';

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'رشق مواس',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: logout,
                icon: const Icon(Icons.logout),
              ),
            ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeveloper
                            ? 'أهلاً بالمطور 👑'
                            : 'أهلاً بك 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (user.email != null)
                        Text(
                          user.email!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),

                      const SizedBox(height: 12),

                      const Text(
                        'رصيد النقاط',
                        style: TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        isDeveloper
                            ? '∞ نقطة'
                            : '${formatNumber(points)} نقطة',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.badge),
                    ),
                    title: const Text(
                      'معرّف الحساب UID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: SelectableText(
                      user.uid,
                      textDirection: TextDirection.ltr,
                    ),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PackagesPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'شراء النقاط',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  String formatNumber(int number) {
    final text = number.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  Future<void> createPurchaseRequest(
    BuildContext context,
    PointPackage package,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
        ),
      );

      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('purchase_requests')
          .add({
        'userId': user.uid,
        'email': user.email,
        'points': package.points,
        'price': package.price,
        'paymentNumber': '07760656110',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('تم إرسال الطلب ✅'),
            content: Text(
              'الباقة: ${formatNumber(package.points)} نقطة\n'
              'السعر: ${formatNumber(package.price)} د.ع\n\n'
              'رقم الدفع:\n'
              '07760656110\n\n'
              'تم إرسال طلبك للمراجعة. '
              'لن تتم إضافة النقاط إلا بعد التحقق وقبول الطلب.',
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('حسنًا'),
              ),
            ],
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'تعذر إرسال الطلب',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('باقات النقاط'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  package.badge.isEmpty
                      ? '⭐'
                      : package.badge,
                ),
              ),
              title: Text(
                '${formatNumber(package.points)} نقطة',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${formatNumber(package.price)} د.ع',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(
                      '${formatNumber(package.points)} نقطة',
                    ),
                    content: Text(
                      'السعر: ${formatNumber(package.price)} د.ع\n\n'
                      'رقم الدفع:\n'
                      '07760656110\n\n'
                      'بعد إتمام الدفع اضغط "إرسال طلب".',
                      textDirection: TextDirection.rtl,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);

                          createPurchaseRequest(
                            context,
                            package,
                          );
                        },
                        child: const Text('إرسال طلب'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
