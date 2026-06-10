import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_controller.dart';
import '../core/stats/daily_stats_controller.dart';
import '../core/theme/medi_theme.dart';
import '../features/auth/login_page.dart';
import '../features/auth/onboarding_flow_page.dart';
import '../features/auth/register_page.dart';
import '../features/auth/splash_page.dart';
import '../features/auth/welcome_page.dart';
import '../features/chat/chat_page.dart';
import '../features/home/home_page.dart';
import '../features/medicine/category_page.dart';
import '../features/checkout/checkout_delivery_page.dart';
import '../features/checkout/checkout_payment_page.dart';
import '../features/checkout/checkout_selection.dart';
import '../features/medicine/medicine_detail_page.dart';
import '../features/medicine/medicine_tab_page.dart';
import '../features/overview/overview_page.dart';
import '../features/profile/card_page.dart';
import '../features/profile/edit_profile_page.dart';
import '../features/profile/help_page.dart';
import '../features/profile/order_history_page.dart';
import '../features/profile/profile_page.dart';
import '../features/reminders/reminders_page.dart';
import '../features/shell/medi_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.isReady) return null;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;
      if (!auth.isLoggedIn && loc == '/onboarding') return '/welcome';
      if (auth.isLoggedIn && auth.needsOnboarding && loc.startsWith('/t/')) {
        return '/onboarding';
      }
      final guestOk = loc == '/welcome' || loc == '/login' || loc == '/register';
      if (!auth.isLoggedIn && loc.startsWith('/t')) return '/welcome';
      if (auth.isLoggedIn && guestOk) {
        return auth.needsOnboarding ? '/onboarding' : '/t/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/onboarding',
        builder: (_, __) => const OnboardingFlowPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MediShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/t/home', builder: (_, __) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/t/medicine', builder: (_, __) => const MedicineTabPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/t/chat', builder: (_, __) => const ChatPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/t/overview', builder: (_, __) => const OverviewPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/t/profile', builder: (_, __) => const ProfilePage()),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/category/:cid',
        builder: (c, s) => CategoryPage(categoryId: s.pathParameters['cid']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/medicine/:id',
        builder: (c, s) => MedicineDetailPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/checkout/delivery',
        builder: (c, s) {
          final extra = s.extra;
          if (extra is! CheckoutSelection) {
            return const Scaffold(body: Center(child: Text('Қате өту')));
          }
          return CheckoutDeliveryPage(selection: extra);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/checkout/payment',
        builder: (c, s) {
          final extra = s.extra;
          if (extra is! CheckoutSelection) {
            return const Scaffold(body: Center(child: Text('Қате өту')));
          }
          return CheckoutPaymentPage(selection: extra);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/help',
        builder: (_, __) => const HelpPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/edit-profile',
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/card',
        builder: (_, __) => const CardPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/orders',
        builder: (_, __) => const OrderHistoryPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/reminders',
        builder: (_, __) => const RemindersPage(),
      ),
    ],
  );
}

/// Один экземпляр [GoRouter] на приложение — иначе сбрасывается стек при пересборке.
class MediRoot extends StatefulWidget {
  const MediRoot({super.key});

  @override
  State<MediRoot> createState() => _MediRootState();
}

class _MediRootState extends State<MediRoot> {
  late final AuthController _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthController();
    _router = createAppRouter(_auth);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => DailyStatsController()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: buildMediTheme(),
        routerConfig: _router,
      ),
    );
  }
}
