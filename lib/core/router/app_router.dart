import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/pages/role_selection_screen.dart';
import '../../features/home/presentation/pages/main_navigation_shell.dart';
import '../../features/home/presentation/pages/splash_screen.dart';
import '../../features/partner/presentation/pages/partner_dashboard_screen.dart';

// ──────────────────────────────────────────────
//  Route Names
// ──────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const roleSelection = '/role-selection';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const travelerHome = '/home';
  static const account = '/account';
  static const partnerDashboard = '/partner';
}

// ──────────────────────────────────────────────
//  Router Provider Widget
// ──────────────────────────────────────────────
class AppRouterProvider extends StatelessWidget {
  const AppRouterProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return MaterialApp.router(
          title: 'سياحة | Tourism',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          routerConfig: _buildRouter(authState),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ar', 'SA'),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  //  Router Configuration
  // ──────────────────────────────────────────────
  GoRouter _buildRouter(AuthState authState) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      redirect: (context, state) {
        final path = state.matchedLocation;

        // ── 1. جاري التهيئة → ابقَ على Splash ──────────────────────────────
        if (authState is AuthInitial) {
          return path == AppRoutes.splash ? null : AppRoutes.splash;
        }

        // ── 2. Loading → لا توجيه ────────────────────────────────────────────
        if (authState is AuthLoading) return null;

        // ── 3. من Splash → Home دائماً بغض النظر عن حالة المصادقة ───────────
        if (path == AppRoutes.splash) {
          if (authState is Authenticated || authState is RegistrationSuccess) {
            final user = authState is Authenticated
                ? (authState as Authenticated).user
                : (authState as RegistrationSuccess).user;
            return user.isPartner
                ? AppRoutes.partnerDashboard
                : AppRoutes.travelerHome;
          }
          // ضيف / غير مسجّل → Home المسافر
          return AppRoutes.travelerHome;
        }

        // ── 4. مسجّل → حماية صفحات المصادقة (login/register/roleSelection) ──
        if (authState is Authenticated || authState is RegistrationSuccess) {
          final authPages = [
            AppRoutes.roleSelection,
            AppRoutes.login,
            AppRoutes.register,
          ];
          if (authPages.any((p) => path.startsWith(p))) {
            final user = authState is Authenticated
                ? (authState as Authenticated).user
                : (authState as RegistrationSuccess).user;
            return user.isPartner
                ? AppRoutes.partnerDashboard
                : AppRoutes.travelerHome;
          }
          return null;
        }

        // ── 5. غير مسجّل يحاول فتح Account → Login ──────────────────────────
        if (path.startsWith(AppRoutes.account)) {
          return AppRoutes.login;
        }

        // ── 6. غير مسجّل يحاول فتح Partner Dashboard → Home المسافر ─────────
        if (path.startsWith(AppRoutes.partnerDashboard)) {
          return AppRoutes.travelerHome;
        }

        // ── 7. باقي الصفحات (home, login, register...) → مسموح ───────────────
        return null;
      },
      routes: [
        // ── Splash ──────────────────────────────
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const _AuthSplashScreen(),
        ),

        // ── Role Selection ───────────────────────
        GoRoute(
          path: AppRoutes.roleSelection,
          pageBuilder: (context, state) => CustomTransitionPage(
            child: RoleSelectionScreen(
              onRoleSelected: (role) => context.go(
                '${AppRoutes.register}?role=${role.name}',
              ),
            ),
            transitionsBuilder: _fadeSlideTransition,
          ),
        ),

        // ── Login ────────────────────────────────
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => CustomTransitionPage(
            child: LoginScreen(
              onNavigateToRegister: () =>
                  context.go(AppRoutes.roleSelection),
              onNavigateToForgotPassword: () =>
                  context.go(AppRoutes.forgotPassword),
            ),
            transitionsBuilder: _fadeSlideTransition,
          ),
        ),

        // ── Register ─────────────────────────────
        GoRoute(
          path: AppRoutes.register,
          pageBuilder: (context, state) {
            final roleParam =
                state.uri.queryParameters['role'] ?? 'traveler';
            final role = UserRoleX.fromString(roleParam);
            return CustomTransitionPage(
              child: RegisterScreen(
                initialRole: role,
                onNavigateToLogin: () => context.go(AppRoutes.login),
                onBack: () => context.go(AppRoutes.roleSelection),
              ),
              transitionsBuilder: _fadeSlideTransition,
            );
          },
        ),

        // ── Forgot Password ──────────────────────
        GoRoute(
          path: AppRoutes.forgotPassword,
          pageBuilder: (context, state) => CustomTransitionPage(
            child: ForgotPasswordScreen(
              onBack: () => context.go(AppRoutes.login),
            ),
            transitionsBuilder: _fadeSlideTransition,
          ),
        ),

        // ── Traveler Home ────────────────────────
        GoRoute(
          path: AppRoutes.travelerHome,
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const MainNavigationShell(),
            transitionsBuilder: _fadeTransition,
          ),
        ),

        // ── Account ──────────────────────────────
        // مسجّل: يرى بياناته | غير مسجّل: يُعاد توجيهه لـ Login (عبر redirect)
        GoRoute(
          path: AppRoutes.account,
          pageBuilder: (context, state) {
            final currentState = context.read<AuthBloc>().state;
            final user = currentState is Authenticated
                ? currentState.user
                : (currentState as RegistrationSuccess).user;
            return CustomTransitionPage(
              child: MainNavigationShell(initialAccountUser: user),
              transitionsBuilder: _fadeTransition,
            );
          },
        ),

        // ── Partner Dashboard ────────────────────
        GoRoute(
          path: AppRoutes.partnerDashboard,
          pageBuilder: (context, state) {
            final authState = context.read<AuthBloc>().state;
            final user = authState is Authenticated
                ? authState.user
                : (authState as RegistrationSuccess).user;
            return CustomTransitionPage(
              child: PartnerDashboardScreen(user: user),
              transitionsBuilder: _fadeTransition,
            );
          },
        ),
      ],
    );
  }

  // ── Transition Builders ──────────────────────
  static Widget _fadeSlideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    );
  }

  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  ThemeData _buildTheme() {
    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B4F6C),
        primary: const Color(0xFF0B4F6C),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    );
  }
}

// ──────────────────────────────────────────────
//  Auth-aware Splash Screen
// ──────────────────────────────────────────────
class _AuthSplashScreen extends StatefulWidget {
  const _AuthSplashScreen();

  @override
  State<_AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<_AuthSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();

    // ── Timeout fallback ──────────────────────────
    // إذا لم يستجب Firebase خلال 5 ثوانٍ، انتقل لـ Home المسافر مباشرة
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthInitial || authState is AuthLoading) {
        context.go(AppRoutes.travelerHome);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A7FA8), Color(0xFF0B4F6C)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.flight_takeoff_rounded,
                              size: 52,
                              color: Color(0xFF0B4F6C),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'سياحة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'استكشف العالم معنا',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.75),
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
      ),
    );
  }
}
