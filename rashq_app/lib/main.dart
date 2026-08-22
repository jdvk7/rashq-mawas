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
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B35D9),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0B14),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF0D0B14),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF17131F),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(14),
            ),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: Colors.white12,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: Color(0xFF9C4DFF),
              width: 1.5,
            ),
          ),
        ),
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
          return const SplashPage();
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
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
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6C2BD9),
                        Color(0xFFB52BD9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/file_00000000b14c8246975f949ff9c7408c.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.flash_on,
                          size: 55,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'رشق مواس',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
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
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email),
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
                const SizedBox(height: 8),
                if (!isRegisterMode)
                  TextButton(
                    onPressed: isLoading ? null : resetPassword,
                    child: const Text('نسيت كلمة المرور؟'),
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

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
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
          return const SplashPage();
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
        final isDeveloper = role == 'admin';

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'رشق مواس',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (isDeveloper)
                IconButton(
                  tooltip: 'لوحة المطور',
                  icon: const Icon(
                    Icons.admin_panel_settings,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPage(),
                      ),
                    );
                  },
                ),
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
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
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (user.email != null)
                          Text(
                            user.email!,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 18),
                        const Text(
                          'رصيد النقاط',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isDeveloper
                              ? '∞ نقطة'
                              : '${formatNumber(points)} نقطة',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.account_circle),
                      ),
                      title: const Text(
                        'الحساب',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        isDeveloper ? 'مطور' : 'مستخدم',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'الخدمات',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceCard(
                    icon: Icons.people_alt,
                    title: 'متابعين ثابتين',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const FollowersServicePage(),
                        ),
                      );
                    },
                  ),
                  _ServiceCard(
                    icon: Icons.favorite,
                    title: 'لايكات ثابتين',
                    onTap: () {
                      showComingSoon(context);
                    },
                  ),
                  _ServiceCard(
                    icon: Icons.repeat,
                    title: 'إعادة نشر ثابتين',
                    onTap: () {
                      showComingSoon(context);
                    },
                  ),
                  _ServiceCard(
                    icon: Icons.bookmark,
                    title: 'حفظ ثابتين',
                    onTap: () {
                      showComingSoon(context);
                    },
                  ),
                  _ServiceCard(
                    icon: Icons.explore,
                    title: 'إكسبلور ثابتين',
                    onTap: () {
                      showComingSoon(context);
                    },
                  ),
                  _ServiceCard(
                    icon: Icons.visibility,
                    title: 'مشاهدات ثابتين',
                    onTap: () {
                      showComingSoon(context);
                    },
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PackagesPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text(
                        'شراء النقاط',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        leading: CircleAvatar(
          radius: 25,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
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

void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'هذه الخدمة سيتم تفعيلها قريباً 🚀',
        textDirection: TextDirection.rtl,
      ),
    ),
  );
}

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  Future<void> createPurchaseRequest(
    BuildContext context,
    PointPackage package,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(context, 'يجب تسجيل الدخول أولاً');
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
              'لن تتم إضافة النقاط إلا بعد قبول الطلب.',
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسنًا'),
              ),
            ],
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        showMessage(
          context,
          e.message ?? 'تعذر إرسال الطلب',
        );
      }
    }
  }

  void showMessage(
    BuildContext context,
    String message,
  ) {
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
      appBar: AppBar(
        title: const Text('باقات النقاط'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
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
                          onPressed: () => Navigator.pop(context),
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
      ),
    );
  }
}

class FollowersServicePage extends StatefulWidget {
  const FollowersServicePage({super.key});

  @override
  State<FollowersServicePage> createState() =>
      _FollowersServicePageState();
}

class _FollowersServicePageState
    extends State<FollowersServicePage> {
  final linkController = TextEditingController();
  final quantityController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    linkController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    final link = linkController.text.trim();
    final quantityText = quantityController.text.trim();

    if (user == null) {
      showMessage('يجب تسجيل الدخول أولاً');
      return;
    }

    if (link.isEmpty) {
      showMessage('أدخل الرابط');
      return;
    }

    final quantity = int.tryParse(quantityText);

    if (quantity == null || quantity <= 0) {
      showMessage('أدخل كمية صحيحة');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('service_requests')
          .add({
        'userId': user.uid,
        'email': user.email,
        'service': 'followers',
        'serviceName': 'متابعين ثابتين',
        'link': link,
        'quantity': quantity,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      linkController.clear();
      quantityController.clear();

      if (mounted) {
        showMessage('تم إرسال الطلب للمراجعة ✅');
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        showMessage(
          e.message ?? 'تعذر إرسال الطلب',
        );
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
      appBar: AppBar(
        title: const Text('متابعين ثابتين'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6C2BD9),
                      Color(0xFFB52BD9),
                    ],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.people_alt,
                      size: 45,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'متابعين ثابتين',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'أرسل رابط الحساب والكمية المطلوبة.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: linkController,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'الرابط',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'الكمية',
                  hintText: 'مثال: 1000',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed:
                      isLoading ? null : submitRequest,
                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    isLoading
                        ? 'جاري الإرسال...'
                        : 'إرسال الطلب',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SplashPage();
        }

        final data = snapshot.data?.data() ?? {};
        final role =
            data['role'] as String? ?? 'user';

        if (role != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('لوحة المطور'),
            ),
            body: const Center(
              child: Text(
                'ليس لديك صلاحية الدخول 🚫',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return const AdminDashboard();
      },
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المطور 👑'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AdminCard(
              icon: Icons.payment,
              title: 'طلبات شراء النقاط',
              subtitle:
                  'مراجعة وقبول أو رفض طلبات الدفع',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PurchaseRequestsPage(),
                  ),
                );
              },
            ),
            _AdminCard(
              icon: Icons.miscellaneous_services,
              title: 'طلبات الخدمات',
              subtitle: 'مراجعة طلبات الخدمات',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ServiceRequestsPage(),
                  ),
                );
              },
            ),
            _AdminCard(
              icon: Icons.people,
              title: 'المستخدمون',
              subtitle:
                  'عرض المستخدمين والأرصدة',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const UsersPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 5),
          child: Text(subtitle),
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

class PurchaseRequestsPage
    extends StatelessWidget {
  const PurchaseRequestsPage({super.key});

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  Future<void> updatePurchase(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data,
    String status,
  ) async {
    try {
      if (status == 'approved') {
        final userId =
            data['userId'] as String?;

        final pointsValue = data['points'];

        if (userId == null ||
            pointsValue is! num) {
          throw Exception(
            'بيانات الطلب غير صحيحة',
          );
        }

        final points =
            pointsValue.toInt();

        final firestore =
            FirebaseFirestore.instance;

        await firestore.runTransaction(
          (transaction) async {
            final userRef = firestore
                .collection('users')
                .doc(userId);

            final requestRef = firestore
                .collection('purchase_requests')
                .doc(requestId);

            final userSnapshot =
                await transaction.get(userRef);

            final requestSnapshot =
                await transaction.get(
              requestRef,
            );

            final currentRequest =
                requestSnapshot.data();

            if (currentRequest == null ||
                currentRequest['status'] !=
                    'pending') {
              throw Exception(
                'هذا الطلب تمت معالجته مسبقاً',
              );
            }

            final currentPoints =
                (userSnapshot.data()?['points']
                            as num?)
                        ?.toInt() ??
                    0;

            transaction.update(
              userRef,
              {
                'points':
                    currentPoints + points,
              },
            );

            transaction.update(
              requestRef,
              {
                'status': 'approved',
                'approvedAt':
                    FieldValue.serverTimestamp(),
              },
            );
          },
        );
      } else {
        await FirebaseFirestore.instance
            .collection('purchase_requests')
            .doc(requestId)
            .update({
          'status': 'rejected',
          'rejectedAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'تم قبول الطلب وإضافة النقاط ✅'
                  : 'تم رفض الطلب ❌',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تنفيذ العملية: $e',
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
        title:
            const Text('طلبات شراء النقاط'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(
                  'purchase_requests')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .snapshots(),
          builder:
              (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ: ${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            final docs =
                snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد طلبات حالياً',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder:
                  (context, index) {
                final doc =
                    docs[index];

                final data =
                    doc.data();

                final points =
                    (data['points']
                                as num?)
                            ?.toInt() ??
                        0;

                final price =
                    (data['price']
                                as num?)
                            ?.toInt() ??
                        0;

                final status =
                    data['status']
                            as String? ??
                        'pending';

                final email =
                    data['email']
                            as String? ??
                        'بدون بريد';

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          '${formatNumber(points)} نقطة',
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          '${formatNumber(price)} د.ع',
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          email,
                          textDirection:
                              TextDirection
                                  .ltr,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        _StatusChip(
                          status: status,
                        ),
                        if (status ==
                            'pending') ...[
                          const SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      () {
                                    updatePurchase(
                                      context,
                                      doc.id,
                                      data,
                                      'approved',
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .check,
                                  ),
                                  label:
                                      const Text(
                                    'قبول',
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child:
                                    OutlinedButton
                                        .icon(
                                  onPressed:
                                      () {
                                    updatePurchase(
                                      context,
                                      doc.id,
                                      data,
                                      'rejected',
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .close,
                                  ),
                                  label:
                                      const Text(
                                    'رفض',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

class ServiceRequestsPage
    extends StatelessWidget {
  const ServiceRequestsPage({super.key});

  Future<void> updateService(
    BuildContext context,
    String id,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(id)
          .update({
        'status': status,
        '${status}At':
            FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'تم قبول طلب الخدمة ✅'
                  : 'تم رفض طلب الخدمة ❌',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تنفيذ العملية: $e',
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
        title:
            const Text('طلبات الخدمات'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(
                  'service_requests')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .snapshots(),
          builder:
              (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ: ${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            final docs =
                snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد طلبات حالياً',
                ),
              );
            }

            return ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder:
                  (context, index) {
                final doc =
                    docs[index];

                final data =
                    doc.data();

                final serviceName =
                    data['serviceName']
                            as String? ??
                        'خدمة';

                final link =
                    data['link']
                            as String? ??
                        '';

                final quantity =
                    (data['quantity']
                                as num?)
                            ?.toInt() ??
                        0;

                final email =
                    data['email']
                            as String? ??
                        'بدون بريد';

                final status =
                    data['status']
                            as String? ??
                        'pending';

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          serviceName,
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          'الكمية: $quantity',
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          email,
                          textDirection:
                              TextDirection
                                  .ltr,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'الرابط:',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        SelectableText(
                          link,
                          textDirection:
                              TextDirection
                                  .ltr,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        _StatusChip(
                          status: status,
                        ),
                        if (status ==
                            'pending') ...[
                          const SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      () {
                                    updateService(
                                      context,
                                      doc.id,
                                      'approved',
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .check,
                                  ),
                                  label:
                                      const Text(
                                    'قبول',
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child:
                                    OutlinedButton
                                        .icon(
                                  onPressed:
                                      () {
                                    updateService(
                                      context,
                                      doc.id,
                                      'rejected',
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .close,
                                  ),
                                  label:
                                      const Text(
                                    'رفض',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  Future<void> addPoints(
    BuildContext context,
    String userId,
    int currentPoints,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('إضافة نقاط'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عدد النقاط',
              hintText: 'مثال: 1000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    int.tryParse(
                  controller.text.trim(),
                );

                if (amount == null ||
                    amount <= 0) {
                  return;
                }

                try {
                  await FirebaseFirestore
                      .instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'points':
                        currentPoints + amount,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تمت إضافة النقاط ✅',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'تعذر إضافة النقاط: $e',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> removePoints(
    BuildContext context,
    String userId,
    int currentPoints,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('خصم نقاط'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عدد النقاط',
              hintText: 'مثال: 500',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    int.tryParse(
                  controller.text.trim(),
                );

                if (amount == null ||
                    amount <= 0) {
                  return;
                }

                final newPoints =
                    currentPoints - amount < 0
                        ? 0
                        : currentPoints - amount;

                try {
                  await FirebaseFirestore
                      .instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'points': newPoints,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم خصم النقاط ✅',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'تعذر خصم النقاط: $e',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('خصم'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .snapshots(),
          builder:
              (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ: ${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            final docs =
                snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا يوجد مستخدمون',
                ),
              );
            }

            return ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder:
                  (context, index) {
                final doc =
                    docs[index];

                final data =
                    doc.data();

                final email =
                    data['email']
                            as String? ??
                        'بدون بريد';

                final role =
                    data['role']
                            as String? ??
                        'user';

                final points =
                    (data['points']
                                as num?)
                            ?.toInt() ??
                        0;

                final isAdmin =
                    role == 'admin';

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              child: Icon(
                                isAdmin
                                    ? Icons
                                        .admin_panel_settings
                                    : Icons
                                        .person,
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    email,
                                    textDirection:
                                        TextDirection
                                            .ltr,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    isAdmin
                                        ? 'مطور 👑'
                                        : 'مستخدم',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(12),
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            color:
                                Colors.white10,
                          ),
                          child: Text(
                            'الرصيد: ${formatNumber(points)} نقطة',
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                        if (!isAdmin) ...[
                          const SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      () {
                                    addPoints(
                                      context,
                                      doc.id,
                                      points,
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons.add,
                                  ),
                                  label:
                                      const Text(
                                    'إضافة',
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child:
                                    OutlinedButton
                                        .icon(
                                  onPressed:
                                      () {
                                    removePoints(
                                      context,
                                      doc.id,
                                      points,
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .remove,
                                  ),
                                  label:
                                      const Text(
                                    'خصم',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String text;

    IconData icon;

    switch (status) {
      case 'approved':
        text = 'مقبول';
        icon = Icons.check_circle;
        break;

      case 'rejected':
        text = 'مرفوض';
        icon = Icons.cancel;
        break;

      default:
        text = 'قيد المراجعة';
        icon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
