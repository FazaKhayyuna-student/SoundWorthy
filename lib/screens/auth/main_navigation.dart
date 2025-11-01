import 'package:flutter/material.dart';
import 'dart:ui'; // efek blur
import 'package:reviewmusik/models/user_model.dart';
import 'package:reviewmusik/screens/auth/login_screen.dart';
import 'package:reviewmusik/screens/auth/profile_tab.dart';
import 'package:reviewmusik/screens/favorite/favorites_tab.dart';
import 'package:reviewmusik/screens/my_reviews/my_reviews_screen.dart';
import 'package:reviewmusik/screens/search/search_screen.dart';
import 'package:reviewmusik/screens/auth/home_tab.dart';
import 'package:reviewmusik/services/auth_service.dart';
import 'package:reviewmusik/services/notification_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  User? currentUser;
  final NotificationService _notificationService = NotificationService();

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.library_books_rounded,
    Icons.search_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    currentUser = AuthService().currentUser;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      });
    }

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _notificationService.cancelThanksNotification();
        break;
      case AppLifecycleState.paused:
        _notificationService.scheduleThanksNotification(seconds: 5);
        break;
      default:
        break;
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2E),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      const HomeTab(),
      const MyReviewsTab(),
      const SearchScreen(),
      const FavoritesTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),

          // 🌌 Floating Glass Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 14, // aman di atas gesture bar
            child: SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_icons.length, (index) {
                        final isActive = _currentIndex == index;
                        return GestureDetector(
                          onTap: () => _onTabTapped(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.symmetric(
                              horizontal: isActive ? 16 : 0,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF7A00FF).withOpacity(0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _icons[index],
                                  size: 26,
                                  color: isActive
                                      ? const Color(0xFFBB86FC)
                                      : Colors.white60,
                                ),
                                const SizedBox(height: 4),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: isActive ? 13 : 0,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFBB86FC),
                                  ),
                                  child: Text(_getLabel(index)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Beranda';
      case 1:
        return 'Ulasan';
      case 2:
        return 'Cari';
      case 3:
        return 'Favorit';
      case 4:
        return 'Profil';
      default:
        return '';
    }
  }
}
