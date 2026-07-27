import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/constatnts/strings.dart';
import 'package:portfolio/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Static backdrop ──────────────────────────────────────────────────────────

/// Paint-once atmosphere: two stacked gradients, no ticker and no particles.
/// Everything here is `const`, so it rasterises on first frame and is never
/// invalidated again — a low-end device does zero per-frame work for it.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base: deep navy, lighter toward the top.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF101A2E),
                  Color(0xFF0A0E1A),
                  Color(0xFF070A12),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Cyan bloom behind the header, fading out well before mid-page.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.55, -0.85),
                radius: 1.1,
                colors: [
                  Color(0x2A0FF0FC),
                  Color(0x000FF0FC),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skills, grouped as on the résumé ─────────────────────────────────────────

const Map<String, List<String>> _skillGroups = {
  'BACKEND': [
    'Java',
    'Spring Boot',
    'Spring Security (JWT)',
    'Spring Data JPA',
    'Hibernate',
    'Spring MVC',
    'RESTful APIs',
    'Microservices',
    'RabbitMQ',
    'Flyway',
    'Maven',
  ],
  'DATABASES & CACHING': [
    'MySQL',
    'MongoDB',
    'Redis',
    'Query Optimization',
    'Indexing',
    'Firebase',
  ],
  'TESTING & DEVOPS': [
    'JUnit 5',
    'Mockito',
    'Swagger/OpenAPI',
    'Docker',
    'Postman',
    'Git',
    'GitHub Actions',
  ],
  'MOBILE & FRONTEND': [
    'Flutter',
    'Dart',
    'BLoC',
    'Riverpod',
    'Provider',
    'Android Native (NDK/JNI)',
    'C++',
    'WebRTC',
  ],
  'OTHER': [
    'Stripe SDK',
    'FCM',
    'Crashlytics',
    'A/B Testing',
    'Remote Config',
    'AI Agents (LLM APIs)',
    'Figma',
  ],
};

// ─── Portfolio screen ─────────────────────────────────────────────────────────

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    // Runs once on load, then the controller idles and the app stops
    // producing frames entirely.
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          FadeTransition(
            opacity: _fadeIn,
            child: SelectionArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth > 800
                      ? _buildWide(context)
                      : _buildNarrow(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(child: _leftContent(context)),
        ),
        Container(
          width: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0FF0FC).withValues(alpha: 0.0),
                const Color(0xFF0FF0FC).withValues(alpha: 0.22),
                const Color(0xFF0FF0FC).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 60),
            children: _rightItems(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _leftContent(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(children: _rightItems(context)),
          ),
        ],
      ),
    );
  }

  Widget _leftContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0FF0FC), Color(0xFF005CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // One modest shadow instead of two wide blurs.
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0FF0FC).withValues(alpha: 0.28),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 62,
                backgroundImage: AssetImage('assets/profilepic.jpeg'),
                backgroundColor: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _GlowText(
            'Divyanshu\nVaibhav',
            style: Theme.of(context)
                .textTheme
                .displayMedium!
                .copyWith(height: 1.1),
          ),
          const SizedBox(height: 10),
          Text('Software Engineer',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0FF0FC).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: const Color(0xFF0FF0FC).withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0FF0FC).withValues(alpha: 0.08),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StatusDot(),
                const SizedBox(width: 7),
                Text('@ Longfloat · Dubai',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _SocialBtn(
                icon: FontAwesomeIcons.github,
                label: 'GitHub',
                url: 'https://github.com/vritravaibhav',
              ),
              _SocialBtn(
                icon: FontAwesomeIcons.linkedin,
                label: 'LinkedIn',
                url: 'https://www.linkedin.com/in/divyanshuvaibhav/',
              ),
            ],
          ),
          const SizedBox(height: 36),
          _sideLabel(context, '// contact'),
          const SizedBox(height: 14),
          ContactLine(
            icon: Icons.phone_outlined,
            text: '+91 9576671336',
            label: 'Phone number',
            copyText: '+919576671336',
            onTap: () => launchUrl(Uri(scheme: 'tel', path: '+919576671336')),
          ),
          const SizedBox(height: 10),
          ContactLine(
            icon: Icons.email_outlined,
            text: contactEmail,
            label: 'Email',
            copyText: contactEmail,
            onTap: () => launchUrl(
              Uri.parse(
                  'https://mail.google.com/mail/?view=cm&fs=1&to=$contactEmail'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 36),
          _sideLabel(context, '// education'),
          const SizedBox(height: 14),
          Text('B.E. Electronics & Communication',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text('Panjab University',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text('2020 – 2024', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 36),
          _sideLabel(context, '// skills'),
          const SizedBox(height: 16),
          ..._skillGroups.entries.expand(
            (group) => [
              Text(
                group.key,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: const Color(0xFFFFB703),
                      fontSize: 10,
                      letterSpacing: 1.4,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    group.value.map((s) => _SkillChip(label: s)).toList(),
              ),
              const SizedBox(height: 18),
            ],
          ),
          const SizedBox(height: 18),
          _sideLabel(context, '// problem solving'),
          const SizedBox(height: 14),
          ...[
            'Solved 400+ DSA problems on LeetCode and Codeforces (Java / Dart)',
            'Ranked #5,466 worldwide — Codeforces Round 889 (Div. 2)',
          ].map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('▸  ',
                      style: TextStyle(color: Color(0xFF0FF0FC), fontSize: 12)),
                  Expanded(
                      child: Text(a,
                          style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rightItems(BuildContext context) {
    return [
      _sectionTitle(context, 'Experience'),
      const SizedBox(height: 20),
      const ExperienceCard(
        title: 'Software Engineer',
        companyName: 'Longfloat Information Technology Pvt. Ltd., Dubai',
        description: longfloatExperience,
        duration: 'Jan 2026 – Present',
        isActive: true,
      ),
      const SizedBox(height: 14),
      const ExperienceCard(
        title: 'Software Developer',
        companyName: 'Electromotion E-vidyut',
        description: electromotionExperience,
        duration: 'Sep 2024 – Jan 2026',
      ),
      const SizedBox(height: 14),
      const ExperienceCard(
        title: 'Flutter Developer',
        companyName: 'Connect 4 Digital India',
        description: c4dexp,
        duration: 'Mar 2024 – Aug 2024',
      ),
      const SizedBox(height: 14),
      const ExperienceCard(
        title: 'Flutter Developer Intern',
        companyName: 'Outshade Digital Media',
        description: outshadeExperience,
        duration: 'Jun 2023 – Aug 2023',
      ),
      const SizedBox(height: 40),
      _sectionTitle(context, 'Projects'),
      const SizedBox(height: 20),
      const CardItem(
        time: 'Spring Boot · Spring Data JPA · MySQL · Flutter · LLM APIs',
        heading: 'SalesPilot — AI-Powered Sales Outreach Suite',
        title:
            'Multi-agent AI email authoring, contact capture, and campaign pipelines',
        descriptiom: salesPilotDec,
      ),
      const SizedBox(height: 14),
      const CardItem(
        time: 'Spring Boot · WebSocket/STOMP · WebRTC · Flutter Wasm · LLM APIs',
        heading: 'DroopIt — P2P Collaboration Platform',
        title:
            'Team chat, 1 TB serverless P2P file transfer, and an AI project manager',
        descriptiom: droopItDec,
        githubUrl: 'https://github.com/vritravaibhav/droopit',
      ),
      const SizedBox(height: 40),
      _sectionTitle(context, 'Contribution'),
      const SizedBox(height: 20),
      const CardItem(
        time: 'Dart · CLI · pub.dev · v1.0.0 · MIT',
        heading: 'insta_video_downloader',
        title: 'Published Dart package — Instagram Reel/Video downloader CLI',
        descriptiom: instaVideoDownloaderDec,
        pubDevUrl: 'https://pub.dev/packages/insta_video_downloader',
        githubUrl: 'https://github.com/vritravaibhav/insta_reel_cli',
      ),
      const SizedBox(height: 40),
      _sectionTitle(context, 'Contact'),
      const SizedBox(height: 20),
      const ContactUsForm(),
      const SizedBox(height: 16),
      const ContactUsContainer(),
    ];
  }

  Widget _sideLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: const Color(0xFF64748B),
            letterSpacing: 2,
            fontSize: 10,
          ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0FF0FC).withValues(alpha: 0.45),
                  const Color(0xFF0FF0FC).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}

// ─── Standalone private widgets ───────────────────────────────────────────────

/// Static "available" indicator. Previously pulsed on a repeating controller,
/// which kept the whole app in a 60fps frame loop for a 7px dot.
class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.55),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _GlowText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _GlowText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    // A single text shadow rather than a blurred copy stacked behind a second
    // Text: same neon read, one layout pass and no saveLayer.
    return Text(
      text,
      style: style.copyWith(
        shadows: [
          Shadow(
            color: const Color(0xFF0FF0FC).withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _SocialBtn extends StatefulWidget {
  final FaIconData icon;
  final String label;
  final String url;

  const _SocialBtn({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  State<_SocialBtn> createState() => _SocialBtnState();
}

class _SocialBtnState extends State<_SocialBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(widget.url),
            mode: LaunchMode.externalApplication),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: const Color(0xFF0FF0FC)
                  .withValues(alpha: _hovered ? 0.70 : 0.30),
            ),
            color: const Color(0xFF0FF0FC)
                .withValues(alpha: _hovered ? 0.12 : 0.05),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF0FF0FC).withValues(alpha: 0.22),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(widget.icon, size: 13, color: const Color(0xFF0FF0FC)),
              const SizedBox(width: 6),
              Text(widget.label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends StatefulWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  State<_SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<_SkillChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _hovered
              ? const Color(0xFF0FF0FC).withValues(alpha: 0.13)
              : const Color(0xFF0F1F33),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF0FF0FC).withValues(alpha: 0.65)
                : const Color(0xFF0FF0FC).withValues(alpha: 0.20),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF0FF0FC).withValues(alpha: 0.22),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 11,
                color: _hovered
                    ? const Color(0xFF0FF0FC)
                    : const Color(0xFF94A3B8),
              ),
        ),
      ),
    );
  }
}
