import 'package:flutter/material.dart';
import 'auth/forgot_password_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'auth/require_auth.dart';
import 'member/dashboard_page.dart';
import 'member/placeholders.dart';
import 'member/messages_page.dart';
import 'member/find_professional_page.dart';
import 'member/sessions_page.dart';
import 'member/schedule_session_page.dart';
import 'member/settings_page.dart';
import 'member/connections_page.dart';
import 'root_gate.dart';

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
      initialRoute: '/',
      routes: {
        '/': (_) => const RootGate(),
        '/home': (_) => const HomePage(),
        '/auth/login': (_) => const LoginPage(),
        '/auth/register': (_) => const RegisterPage(),
        '/auth/forgot-password': (_) => const ForgotPasswordPage(),
        '/member/dashboard': (_) => const RequireAuth(child: DashboardPage()),
        '/member/find-professional': (_) =>
            const RequireAuth(child: FindProfessionalPage()),
        '/member/sessions': (_) => const RequireAuth(child: SessionsPage()),
        '/member/schedule-session': (_) => const RequireAuth(child: ScheduleSessionPage()),
        // '/member/zoom-call' route is handled by the web frontend via WebView; we keep native route reserved if needed.
        '/member/messages': (_) => const RequireAuth(child: MessagesPage()),
        '/member/assistant': (_) => const RequireAuth(
            child: PlaceholderPage(
                title: 'AI Assistant', route: '/member/assistant')),
        '/member/connections': (_) => const RequireAuth(child: ConnectionsPage()),
        '/member/professionals': (_) => const RequireAuth(
            child: PlaceholderPage(
                title: 'Professionals', route: '/member/professionals')),
        '/member/billing': (_) => const RequireAuth(
            child: PlaceholderPage(title: 'Billing', route: '/member/billing')),
        '/member/settings': (_) => const RequireAuth(child: SettingsPage()),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(context),
            const SizedBox(height: 24),
            _buildHowItWorksSection(),
            const SizedBox(height: 24),
            _buildServicesSection(),
            const SizedBox(height: 24),
            _buildTestimonialsSection(),
            const SizedBox(height: 24),
            _buildCTASection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empowering Your Mental, Physical & Financial Well-being',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Connect with professionals who can help you thrive in every aspect of your life.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.indigo.shade100),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/auth/register');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text(
              'Get Started',
              style: TextStyle(color: Colors.indigo),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    final steps = [
      (
        'Choose a Professional',
        'Browse our curated network of licensed therapists, certified coaches, and expert counselors.'
      ),
      (
        'Select a Service',
        'Choose from therapy, coaching, or counseling services tailored to your specific needs.'
      ),
      (
        'Connect',
        'Meet with your professional via chat, video, or messaging at times that work for you.'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How It Works',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                _StepCard(
                    number: i + 1,
                    title: steps[i].$1,
                    description: steps[i].$2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = [
      (
        'Mental Health',
        'Connect with licensed therapists and counselors specialized in anxiety, depression, stress management, and more.',
        Colors.indigo
      ),
      (
        'Physical Wellness',
        'Work with nutrition experts, fitness coaches and wellness practitioners to optimize your physical health.',
        Colors.green
      ),
      (
        'Financial Coaching',
        'Get guidance from certified financial coaches on budgeting, investing, debt management, and long-term planning.',
        Colors.blue
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Our Services',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Column(
            children: [
              for (final service in services)
                _ServiceCard(
                  title: service.$1,
                  description: service.$2,
                  color: service.$3,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    final testimonials = [
      (
        'Jane Doe',
        'Entrepreneur',
        'Mindapax connected me with a coach who changed my life.'
      ),
      (
        'John Smith',
        'Designer',
        'The therapy sessions helped me manage stress effectively.'
      ),
      (
        'Maria Garcia',
        'Developer',
        'Great platform with wonderful professionals.'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What Our Clients Say',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Column(
            children: [
              for (final t in testimonials)
                _TestimonialCard(name: t.$1, role: t.$2, quote: t.$3),
            ],
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/auth/register');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('Sign Up For Free',
                    style: TextStyle(color: Colors.indigo)),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/auth/login');
                },
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white)),
                child: const Text('Learn More'),
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
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.black54)),
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

  const _ServiceCard(
      {required this.title, required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 120, color: color),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(description,
                    style: const TextStyle(color: Colors.black54)),
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

  const _TestimonialCard(
      {required this.name, required this.role, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(role,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('"$quote"',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
