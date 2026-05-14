import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/constatnts/strings.dart';
import 'package:portfolio/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          SelectionArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth > 800
                    ? _buildWideLayout(context)
                    : _buildNarrowLayout(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(child: _leftContent(context)),
        ),
        Container(
            width: 1,
            color: const Color(0xFF0FF0FC).withValues(alpha: 0.12)),
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

  Widget _buildNarrowLayout(BuildContext context) {
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
          // Avatar with cyan glow ring
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
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0FF0FC).withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 62,
                backgroundImage: AssetImage('assets/profilepic.jpg'),
                backgroundColor: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Name
          Text(
            'Divyanshu\nVaibhav',
            style: Theme.of(context)
                .textTheme
                .displayMedium!
                .copyWith(height: 1.1),
          ),
          const SizedBox(height: 10),
          Text(
            'Software Engineer',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),

          // Active badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0FF0FC).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: const Color(0xFF0FF0FC).withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '@ Longfloat · Dubai',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Social buttons
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
                url: 'https://linkedin.com/in/divyanshu-vaibhav',
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Contact
          _sideLabel(context, '// contact'),
          const SizedBox(height: 14),
          _infoRow(
            context,
            Icons.phone_outlined,
            '+91 9576671336',
            () => launchUrl(Uri(scheme: 'tel', path: '+919576671336')),
          ),
          const SizedBox(height: 10),
          _infoRow(
            context,
            Icons.email_outlined,
            'divaibhavyanshu@gmail.com',
            () => launchUrl(
              Uri.parse(
                  'https://mail.google.com/mail/?view=cm&fs=1&to=divaibhavyanshu@gmail.com'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 36),

          // Education
          _sideLabel(context, '// education'),
          const SizedBox(height: 14),
          Text('B.E. Electronics & Communication',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text('Panjab University',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text('2020 – 2024',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 36),

          // Skills
          _sideLabel(context, '// skills'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Flutter',
              'Dart',
              'C++ / NDK',
              'JNI / JVM',
              'WebRTC',
              'BLoC',
              'Riverpod',
              'Provider',
              'Firebase',
              'Android Native',
              'ML Kit',
              'Dialogflow CX',
              'Node.js',
              'MongoDB',
              'Stripe SDK',
              'Git',
              'Figma',
              'Postman',
            ].map((s) => _SkillChip(label: s)).toList(),
          ),
          const SizedBox(height: 36),

          // Achievements
          _sideLabel(context, '// achievements'),
          const SizedBox(height: 14),
          ...[
            '30+ production apps — Flutter, Firebase, WebRTC, Android Native',
            '400+ competitive programming problems on Codeforces, CodeChef, LeetCode, GFG',
            'Ranked #5,466 worldwide — Codeforces Round 889 (Div. 2)',
          ].map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '▸  ',
                    style: TextStyle(
                        color: Color(0xFF0FF0FC), fontSize: 12),
                  ),
                  Expanded(
                    child: Text(a,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
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
      // Experience
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
        title: 'Flutter Developer',
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
        companyName: 'Outshade',
        description: outshadeExperience,
        duration: 'Jun 2023 – Aug 2023',
      ),
      const SizedBox(height: 40),

      // Projects
      _sectionTitle(context, 'Projects'),
      const SizedBox(height: 20),
      const CardItem(
        time: 'Flutter · Wasm · WebRTC · JS Interop · STUN/TURN',
        heading: 'High-Speed P2P File Transfer Chrome Extension',
        title: 'Serverless browser-native transfers up to 1 TB',
        descriptiom: p2pFileTransferDec,
      ),
      const SizedBox(height: 14),
      const CardItem(
        time: 'Flutter · Firebase Realtime Database · WebRTC',
        heading: 'MultiUser Video Call',
        title: 'Mesh-topology multi-peer video conferencing',
        descriptiom: webrtcdec,
        githubUrl: 'https://github.com/vritravaibhav',
      ),
      const SizedBox(height: 14),
      const CardItem(
        time: 'Flutter · Firebase Auth · Firestore · Storage',
        heading: 'Full-Stack Instagram Clone',
        title: 'Feature-complete social platform',
        descriptiom: instaCloneDec,
        githubUrl: 'https://github.com/vritravaibhav',
      ),
      const SizedBox(height: 40),

      // Contact
      _sectionTitle(context, 'Contact'),
      const SizedBox(height: 20),
      const ContactUsForm(),
      const SizedBox(height: 16),
      const ContactUsContainer(),
    ];
  }

  // ── helpers ──────────────────────────────────────────────────────────────

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

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF0FF0FC)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: const Color(0xFF0FF0FC),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── standalone widget classes ─────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0FF0FC).withValues(alpha: 0.032)
      ..style = PaintingStyle.fill;
    const gap = 28.0;
    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _SocialBtn({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
              color: const Color(0xFF0FF0FC).withValues(alpha: 0.3)),
          color: const Color(0xFF0FF0FC).withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 13, color: const Color(0xFF0FF0FC)),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: const Color(0xFF0F1F33),
        border:
            Border.all(color: const Color(0xFF0FF0FC).withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall!
            .copyWith(fontSize: 11),
      ),
    );
  }
}
