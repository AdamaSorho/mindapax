import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IntroCarouselPage extends StatefulWidget {
  final VoidCallback onFinished;
  const IntroCarouselPage({super.key, required this.onFinished});

  @override
  State<IntroCarouselPage> createState() => _IntroCarouselPageState();
}

class _IntroCarouselPageState extends State<IntroCarouselPage> {
  late final PageController _controller;
  int _index = 0;

  final _slides = const [
    _IntroSlide(
      title: 'Welcome to Mindapax',
      description:
          'Blend mental, physical, and financial wellness with one personalised companion.',
      asset: 'assets/mindapax_logo.svg',
      background: [Color(0xFF4C6EF5), Color(0xFF9775FA)],
    ),
    _IntroSlide(
      title: 'Meet with professionals',
      description:
          'Book secure sessions with trusted experts and keep every conversation in one place.',
      icon: Icons.video_chat_outlined,
      background: [Color(0xFF51CF66), Color(0xFF69DB7C)],
    ),
    _IntroSlide(
      title: 'Track your goals',
      description:
          'Stay motivated with progress insights, guided goals, and tailored recommendations.',
      icon: Icons.flag_outlined,
      background: [Color(0xFFFF922B), Color(0xFFFFB347)],
    ),
    _IntroSlide(
      title: 'Unlock more with packages',
      description:
          'Activate a plan to enjoy session bundles, premium tools, and concierge support.',
      icon: Icons.workspace_premium_outlined,
      background: [Color(0xFF5C7CFA), Color(0xFF74C0FC)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() => widget.onFinished();

  void _next() {
    if (_index >= _slides.length - 1) {
      widget.onFinished();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  _Dots(count: _slides.length, activeIndex: _index),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                        _index == _slides.length - 1 ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

class _SlideView extends StatelessWidget {
  final _IntroSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final padding =
        EdgeInsets.symmetric(horizontal: isWide ? size.width * 0.2 : 24);

    return Padding(
      padding: padding,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: slide.background,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(child: _SlideIllustration(slide: slide)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SlideIllustration extends StatelessWidget {
  final _IntroSlide slide;
  const _SlideIllustration({required this.slide});

  @override
  Widget build(BuildContext context) {
    if (slide.asset != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: SvgPicture.asset(
          slide.asset!,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      );
    }
    return Icon(
      slide.icon ?? Icons.explore_outlined,
      size: 96,
      color: Colors.white,
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _Dots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          height: 10,
          width: active ? 20 : 10,
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _IntroSlide {
  final String title;
  final String description;
  final String? asset;
  final IconData? icon;
  final List<Color> background;

  const _IntroSlide({
    required this.title,
    required this.description,
    this.asset,
    this.icon,
    required this.background,
  });
}
