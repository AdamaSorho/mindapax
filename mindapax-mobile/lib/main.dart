import 'package:flutter/material.dart';
import 'auth/forgot_password_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'auth/require_auth.dart';
import 'member/dashboard_page.dart';
import 'member/placeholders.dart';
import 'member/assistant_page.dart';
import 'member/assistant_context_page.dart';
import 'member/onboarding_flow.dart';
import 'member/goals_page.dart';
import 'member/messages_page.dart';
import 'member/find_professional_page.dart';
import 'member/sessions_page.dart';
import 'member/schedule_session_page.dart';
import 'member/payment_checkout_page.dart';
import 'member/payment_history_page.dart';
import 'member/billing_page.dart';
import 'member/packages_page.dart';
import 'member/my_subscriptions_page.dart';
import 'member/settings_page.dart';
import 'member/connections_page.dart';
import 'member/professional_availability_page.dart';
import 'member/today_page.dart';
import 'launch_gate.dart';
import 'root_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'auth/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindapax',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
      ],
      initialRoute: '/',
      routes: {
        '/': (_) => const LaunchGate(),
        '/root': (_) => const RootGate(),
        '/home': (_) => const HomePage(),
        '/auth/login': (_) => const LoginPage(),
        '/auth/register': (_) => const RegisterPage(),
        '/auth/forgot-password': (_) => const ForgotPasswordPage(),
        '/member/dashboard': (_) => const RequireAuth(child: DashboardPage()),
        '/member/today': (_) => const RequireAuth(child: TodayPage()),
        '/member/find-professional': (_) =>
            const RequireAuth(child: FindProfessionalPage()),
        '/member/sessions': (_) => const RequireAuth(child: SessionsPage()),
        '/member/schedule-session': (_) =>
            const RequireAuth(child: ScheduleSessionPage()),
        '/member/pay': (_) => const RequireAuth(child: PaymentCheckoutPage()),
        '/member/payments': (_) =>
            const RequireAuth(child: PaymentHistoryPage()),
        '/member/packages': (_) => const RequireAuth(child: PackagesPage()),
        '/member/subscriptions': (_) =>
            const RequireAuth(child: MySubscriptionsPage()),
        // '/member/zoom-call' route is handled by the web frontend via WebView; we keep native route reserved if needed.
        '/member/messages': (_) => const RequireAuth(child: MessagesPage()),
        '/member/assistant': (_) => const RequireAuth(child: AssistantPage()),
        '/member/assistant-context': (_) =>
            const RequireAuth(child: AssistantContextPage()),
        '/member/onboarding': (_) =>
            const RequireAuth(child: OnboardingFlowPage()),
        '/member/goals': (_) => const RequireAuth(child: GoalsPage()),
        '/member/connections': (_) =>
            const RequireAuth(child: ConnectionsPage()),
        '/member/availability': (_) =>
            const RequireAuth(child: ProfessionalAvailabilityPage()),
        '/member/professionals': (_) => const RequireAuth(
            child: PlaceholderPage(
                title: 'Professionals', route: '/member/professionals')),
        '/member/billing': (_) => const RequireAuth(child: BillingPage()),
        '/member/settings': (_) => const RequireAuth(child: SettingsPage()),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/mindapax_logo.svg',
              height: 32,
              semanticsLabel: 'Mindapax logo',
            ),
            const SizedBox(width: 12),
            Text(
              'Mindapax',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.indigo.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/auth/login'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.indigo.shade900,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Log in'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildHowItWorksSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildServicesSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildTestimonialsSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverToBoxAdapter(child: _buildCTASection(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final double verticalPadding =
        (media.size.height * 0.12).clamp(48.0, 160.0).toDouble();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: verticalPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 16,
            child: Opacity(
              opacity: 0.15,
              child: SvgPicture.asset(
                'assets/mindapax_logo.svg',
                width: media.size.width * 0.35,
                semanticsLabel: '',
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: media.size.width > 600 ? 480 : media.size.width * 0.9,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empowering Your Mental, Physical & Financial Well-being',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect with professionals who can help you thrive in every aspect of your life.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.indigo.shade100,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Create a new Mindapax account',
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/auth/register');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.indigo,
                        ),
                        child: const Text('Get Started'),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Learn more about Mindapax services',
                      child: OutlinedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final auth = AuthService();
                          final isAuthenticated =
                              await auth.ensureAuthenticated();
                          if (!navigator.mounted) return;
                          if (isAuthenticated) {
                            navigator.pushNamed('/member/onboarding');
                          } else {
                            navigator.pushNamed('/auth/login');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        child: const Text('Explore Mindapax'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    final steps = [
      (
        title: 'Choose a Professional',
        description:
            'Browse our curated network of licensed therapists, certified coaches, and expert counselors.',
      ),
      (
        title: 'Select a Service',
        description:
            'Choose from therapy, coaching, or counseling services tailored to your specific needs.',
      ),
      (
        title: 'Connect',
        description:
            'Meet with your professional via chat, video, or messaging at times that work for you.',
      ),
    ];

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                _StepCard(
                  number: i + 1,
                  title: steps[i].title,
                  description: steps[i].description,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    final services = [
      (
        title: 'Mental Health',
        description:
            'Connect with licensed therapists and counselors specialized in anxiety, depression, stress management, and more.',
        color: Colors.indigo,
        icon: Icons.self_improvement,
      ),
      (
        title: 'Physical Wellness',
        description:
            'Work with nutrition experts, fitness coaches and wellness practitioners to optimize your physical health.',
        color: Colors.green,
        icon: Icons.fitness_center,
      ),
      (
        title: 'Financial Coaching',
        description:
            'Get guidance from certified financial coaches on budgeting, investing, debt management, and long-term planning.',
        color: Colors.blue,
        icon: Icons.savings,
      ),
    ];

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Services',
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              for (final service in services)
                _ServiceCard(
                  title: service.title,
                  description: service.description,
                  color: service.color,
                  icon: service.icon,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(BuildContext context) {
    final testimonials = [
      (
        name: 'Amelia Rivers',
        role: 'Product Manager, Lumi Labs',
        quote:
            'Our matched counselor helped me build a sustainable routine in just six sessions.',
        rating: 4.9,
        sessionsCompleted: 6,
      ),
      (
        name: 'Jordan Malik',
        role: 'Freelance Designer',
        quote:
            'The weekly coaching check-ins keep me accountable without feeling overwhelming.',
        rating: 4.8,
        sessionsCompleted: 12,
      ),
      (
        name: 'Luis Fernández',
        role: 'Senior Engineer, MergeOne',
        quote:
            'Mindapax gave me tools to manage stress and stay focused during a tough product launch.',
        rating: 5.0,
        sessionsCompleted: 8,
      ),
    ];

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Our Clients Say',
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              for (final t in testimonials)
                _TestimonialCard(
                  name: t.name,
                  role: t.role,
                  quote: t.quote,
                  rating: t.rating,
                  sessionsCompleted: t.sessionsCompleted,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'See more client success stories',
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/member/messages');
                },
                child: const Text('See more stories'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.indigo.shade900,
      child: Column(
        children: [
          Text('Ready to Begin Your Journey?',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            'Join thousands of people who have transformed their lives with personalized professional guidance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.indigo.shade200),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Semantics(
                button: true,
                label: 'Register for Mindapax',
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth/register');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
                  ),
                  child: const Text('Sign Up For Free'),
                ),
              ),
              Semantics(
                button: true,
                label: 'Log in to your Mindapax account',
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo.shade100,
                    side: BorderSide(color: Colors.indigo.shade200),
                  ),
                  child: const Text('Log In'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _StepCard(
      {required this.number, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: Text('$number',
                  style: TextStyle(
                      color: Colors.indigo.shade800,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const _ServiceCard(
      {required this.title,
      required this.description,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: Icon(icon, size: 48, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String role;
  final String quote;
  final double rating;
  final int sessionsCompleted;

  const _TestimonialCard(
      {required this.name,
      required this.role,
      required this.quote,
      required this.rating,
      required this.sessionsCompleted});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(name[0])),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  '$sessionsCompleted sessions completed',
                  style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '"$quote"',
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
