
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

const pink = Color(0xFFFF2858);
const purple = Color(0xFF8B5CF6);
const background = Color(0xFF09090D);
const panel = Color(0xFF17171F);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TikTwoApp());
}

class TikTwoApp extends StatelessWidget {
  const TikTwoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTwo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: pink,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

class TikVideo {
  TikVideo({
    required this.caption,
    required this.username,
    required this.color1,
    required this.color2,
    this.file,
    this.controller,
  });

  final String caption;
  final String username;
  final Color color1;
  final Color color2;
  final File? file;
  final VideoPlayerController? controller;

  bool liked = false;
  bool following = false;
  int likes = 0;
  int comments = 0;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ImagePicker picker = ImagePicker();
  final PageController feedController = PageController();
  final TextEditingController searchController = TextEditingController();

  int tab = 0;
  int videoIndex = 0;
  bool sound = true;

  final List<TikVideo> videos = [
    TikVideo(
      username: 'TikTwo',
      caption: 'أهلاً بيكم بعالم TikTwo ❤️🔥\nشارك لحظاتك ويانه!',
      color1: const Color(0xFF32105B),
      color2: const Color(0xFFEC286A),
      likes: 128,
      comments: 12,
    ),
    TikVideo(
      username: 'creative',
      caption: 'خلي إبداعك يحچي عنك ✨🚀',
      color1: const Color(0xFF052F48),
      color2: const Color(0xFF087F8C),
      likes: 84,
      comments: 7,
    ),
    TikVideo(
      username: 'iraq',
      caption: 'أحلى الأوقات والذكريات 🇮🇶❤️',
      color1: const Color(0xFF422006),
      color2: const Color(0xFFB45309),
      likes: 256,
      comments: 24,
    ),
  ];

  @override
  void dispose() {
    feedController.dispose();
    searchController.dispose();
    for (final video in videos) {
      video.controller?.dispose();
    }
    super.dispose();
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textDirection: TextDirection.rtl),
        behavior: SnackBarBehavior.floating,
        backgroundColor: panel,
      ),
    );
  }

  Future<void> chooseVideo() async {
    try {
      final selected = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (selected == null || !mounted) return;

      final controller = VideoPlayerController.file(
        File(selected.path),
      );

      final video = TikVideo(
        username: 'user',
        caption: 'فيديو جديد من TikTwo ❤️',
        color1: pink,
        color2: purple,
        file: File(selected.path),
        controller: controller,
      );

      setState(() {
        videos.insert(0, video);
        tab = 0;
        videoIndex = 0;
      });

      if (feedController.hasClients) {
        feedController.jumpToPage(0);
      }

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(sound ? 1 : 0);
      await controller.play();

      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        message('تعذر فتح الفيديو. جرّب اختيار فيديو آخر.');
      }
    }
  }

  void changeVideo(int index) async {
    setState(() => videoIndex = index);

    for (int i = 0; i < videos.length; i++) {
      final controller = videos[i].controller;

      if (controller == null ||
          !controller.value.isInitialized) {
        continue;
      }

      if (i == index) {
        await controller.setVolume(sound ? 1 : 0);
        await controller.play();
      } else {
        await controller.pause();
      }
    }
  }

  void toggleSound() async {
    setState(() => sound = !sound);

    for (final video in videos) {
      final controller = video.controller;
      if (controller != null &&
          controller.value.isInitialized) {
        await controller.setVolume(sound ? 1 : 0);
      }
    }
  }

  void likeVideo(TikVideo video) {
    setState(() {
      video.liked = !video.liked;
      video.likes += video.liked ? 1 : -1;
    });
  }

  void openComments(TikVideo video) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: panel,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SizedBox(
                height: 350,
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    const Text(
                      'التعليقات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 25),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'التعليقات المشتركة تحتاج قاعدة بيانات.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'اكتب تعليقاً...',
                                filled: true,
                                fillColor: background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              message(
                                'حفظ التعليقات يحتاج ربط قاعدة بيانات.',
                              );
                            },
                            icon: const Icon(
                              Icons.send_rounded,
                              color: pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: tab,
            children: [
              buildFeed(),
              buildDiscover(),
              buildPlaceholder('الرسائل', Icons.forum_outlined,
                  'ستتم إضافة المحادثات عند ربط الخادم.'),
              buildProfile(),
            ],
          ),
        ),
        bottomNavigationBar: navigationBar(),
      ),
    );
  }

  Widget navigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101016),
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 7,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(0, Icons.home_rounded, 'الرئيسية'),
              navItem(1, Icons.explore_outlined, 'اكتشف'),
              GestureDetector(
                onTap: chooseVideo,
                child: Container(
                  width: 48,
                  height: 35,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: const LinearGradient(
                      colors: [pink, purple],
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
              ),
              navItem(2, Icons.forum_outlined, 'الرسائل'),
              navItem(3, Icons.person_outline_rounded, 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(int index, IconData icon, String label) {
    final active = tab == index;

    return InkWell(
      onTap: () => setState(() => tab = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 25,
              color: active ? pink : Colors.white60,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? Colors.white : Colors.white54,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFeed() {
    return Stack(
      children: [
        PageView.builder(
          controller: feedController,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: changeVideo,
          itemBuilder: (context, index) {
            final video = videos[index];

            return Stack(
              fit: StackFit.expand,
              children: [
                videoContent(video),

                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Colors.transparent,
                        Color(0xCC000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),

                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TikTwo',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(color: pink, blurRadius: 15),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'لك',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'المتابَعون',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 23,
                  right: 15,
                  left: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 37,
                            height: 37,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [pink, purple],
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            '@${video.username}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 9),
                          if (video.username != 'user' &&
                              video.username != 'TikTwo')
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  video.following = !video.following;
                                });
                                message(
                                  video.following
                                      ? 'تمت المتابعة محلياً'
                                      : 'تم إلغاء المتابعة',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: pink),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  video.following ? 'تتابعه' : 'متابعة',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        video.caption,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.music_note, size: 17),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'الصوت الأصلي · TikTwo',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Positioned(
                  left: 11,
                  bottom: 35,
                  child: Column(
                    children: [
                      action(
                        icon: video.liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: video.liked ? pink : Colors.white,
                        label: '${video.likes}',
                        onTap: () => likeVideo(video),
                      ),
                      const SizedBox(height: 23),
                      action(
                        icon: Icons.mode_comment_outlined,
                        label: '${video.comments}',
                        onTap: () => openComments(video),
                      ),
                      const SizedBox(height: 23),
                      action(
                        icon: Icons.share_outlined,
                        label: 'مشاركة',
                        onTap: () => message(
                          'مشاركة الروابط ستُضاف بعد تجهيز النظام.',
                        ),
                      ),
                      const SizedBox(height: 23),
                      action(
                        icon: sound
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        label: 'الصوت',
                        onTap: toggleSound,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        Positioned(
          top: 12,
          left: 10,
          child: IconButton(
            onPressed: toggleSound,
            icon: Icon(
              sound
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
          ),
        ),
      ],
    );
  }

  Widget videoContent(TikVideo video) {
    final controller = video.controller;

    if (controller != null && controller.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          });
        },
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [video.color1, video.color2],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 75,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TikTwo',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.file == null
                  ? 'لحظاتك تستحق أن تُشاهَد'
                  : 'جارٍ تجهيز الفيديو...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 48,
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDiscover() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          const Text(
            'اكتشف',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'اكتشف محتوى جديداً كل يوم',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => message(
              'البحث الشامل يحتاج قاعدة بيانات للفيديوهات.',
            ),
            decoration: InputDecoration(
              hintText: 'ابحث عن فيديو أو مستخدم...',
              prefixIcon: const Icon(Icons.search, color: pink),
              filled: true,
              fillColor: panel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'فيديوهات مقترحة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              itemCount: videos.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final video = videos[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      tab = 0;
                      videoIndex = index;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (feedController.hasClients) {
                        feedController.jumpToPage(index);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [video.color1, video.color2],
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (video.controller != null &&
                            video.controller!.value.isInitialized)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: video.controller!.value.size.width,
                              height: video.controller!.value.size.height,
                              child: VideoPlayer(video.controller!),
                            ),
                          ),
                        const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          right: 10,
                          left: 10,
                          bottom: 12,
                          child: Text(
                            video.caption,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Row(
                            children: [
                              const Icon(Icons.favorite, size: 15),
                              const SizedBox(width: 4),
                              Text('${video.likes}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfile() {
    final uploaded = videos.where((v) => v.file != null).length;
    final totalLikes = videos.fold<int>(
      0,
      (sum, video) => sum + video.likes,
    );

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 22),
        const Center(
          child: Text(
            'الملف الشخصي',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [pink, purple],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 65,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            '@user',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Center(
          child: Text(
            'مرحباً بك في مجتمع TikTwo ❤️',
            style: TextStyle(color: Colors.white60),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              stat('$uploaded', 'فيديو'),
              stat('$totalLikes', 'إعجاب'),
              stat('0', 'متابع'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        profileOption(
          Icons.video_library_outlined,
          'فيديوهاتي',
          'الفيديوهات المختارة على هذا الجهاز',
          () => message(
            'الفيديوهات المختارة متاحة داخل جلسة التطبيق الحالية.',
          ),
        ),
        profileOption(
          Icons.favorite_border,
          'الفيديوهات المفضلة',
          'الفيديوهات التي أعجبتك',
          () => message('يمكن تطوير حفظ المفضلة لاحقاً.'),
        ),
        profileOption(
          Icons.settings_outlined,
          'الإعدادات',
          'خيارات التطبيق والحساب',
          () => showSettings(),
        ),
        profileOption(
          Icons.info_outline,
          'حول TikTwo',
          'الإصدار 1.0.0',
          () => showAbout(),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'TikTwo · اصنع لحظتك ✨',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      ],
    );
  }

  Widget stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white60),
        ),
      ],
    );
  }

  Widget profileOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: pink),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_left,
        color: Colors.white38,
      ),
      onTap: onTap,
    );
  }

  Widget buildPlaceholder(
    String title,
    IconData icon,
    String description,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [pink, purple],
                ),
              ),
              child: Icon(icon, size: 45),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: panel,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'الإعدادات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SwitchListTile(
                    value: sound,
                    activeThumbColor: pink,
                    title: const Text('تشغيل صوت الفيديو'),
                    onChanged: (_) => toggleSound(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('معلومات التطبيق'),
                    onTap: () {
                      Navigator.pop(context);
                      showAbout();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'TikTwo',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.play_circle_fill,
        color: pink,
        size: 45,
      ),
      children: const [
        Text('TikTwo — عالم الفيديوهات القصيرة.'),
      ],
    );
  }
}
