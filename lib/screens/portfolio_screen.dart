import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/constatnts/strings.dart';
import 'package:portfolio/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Star types ───────────────────────────────────────────────────────────────

enum _StarKind { good, evil }

// ─── Star particle ────────────────────────────────────────────────────────────

class _Star {
  double x, y, z, speed, brightness;
  Color color;
  double cooldown;
  _StarKind kind;
  _Star({
    required this.x,
    required this.y,
    required this.z,
    required this.speed,
    required this.brightness,
    required this.color,
    required this.kind,
    this.cooldown = 0,
  });
}

// ─── Burst animation ──────────────────────────────────────────────────────────

class _BurstSpark {
  final double angle;
  final double speed;
  final double size;
  _BurstSpark({required this.angle, required this.speed, required this.size});
}

class _Burst {
  final Offset center;
  final Color color;
  final List<_BurstSpark> sparks;
  final _StarKind kind;
  double life;

  _Burst({
    required this.center,
    required this.color,
    required this.sparks,
    required this.kind,
  }) : life = 1.0;
}

// ─── CustomPainter: perspective grid + starfield ──────────────────────────────

class _ScenePainter extends CustomPainter {
  final List<_Star> stars;
  final double gridTime;
  final Offset mouseNorm;
  final Offset mousePos;
  final List<_Burst> bursts;
  final double health; // 0.0 – 1.0
  final Size screenSize;

  _ScenePainter({
    required this.stars,
    required this.gridTime,
    required this.mouseNorm,
    required this.mousePos,
    required this.bursts,
    required this.health,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawStars(canvas, size);
    _drawBursts(canvas);
    _drawHealthBar(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final vpX = size.width / 2 + mouseNorm.dx * 18;
    final vpY = size.height * 0.52 + mouseNorm.dy * 10;
    final bottom = size.height + 120.0;

    // Vertical converging lines
    const numV = 20;
    for (int i = 0; i <= numV; i++) {
      final t = i / numV;
      final bx = size.width * t;
      final edgeFade = 1.0 - ((t - 0.5).abs() * 1.9).clamp(0.0, 1.0);
      if (edgeFade <= 0) continue;
      canvas.drawLine(
        Offset(vpX + (bx - vpX) * 0.015, vpY),
        Offset(bx, bottom),
        Paint()
          ..color = const Color(0xFF0FF0FC).withValues(alpha: 0.16 * edgeFade)
          ..strokeWidth = 0.7,
      );
    }

    // Horizontal animated lines (scroll toward camera)
    const numH = 14;
    for (int i = 0; i < numH; i++) {
      final phase = (i / numH + gridTime) % 1.0;
      final perspT = math.pow(phase, 1.7).toDouble();
      final y = vpY + (bottom - vpY) * perspT;
      if (y < vpY) continue;
      final half = (vpX * perspT * 1.5).clamp(0.0, size.width / 2);
      final alpha = (perspT * 0.3).clamp(0.0, 0.3);
      canvas.drawLine(
        Offset(vpX - half, y),
        Offset(vpX + half, y),
        Paint()
          ..color = const Color(0xFF0FF0FC).withValues(alpha: alpha)
          ..strokeWidth = 0.7,
      );
    }

    // Horizon glow
    final horizonRect = Rect.fromCenter(
      center: Offset(vpX, vpY),
      width: size.width * 0.75,
      height: 70,
    );
    canvas.drawRect(
      horizonRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF0FF0FC).withValues(alpha: 0.20),
            const Color(0xFF0FF0FC).withValues(alpha: 0.0),
          ],
          radius: 0.5,
        ).createShader(horizonRect),
    );

    // Ambient vertical glow beam
    final beamRect =
        Rect.fromLTWH(vpX - 120, vpY - 40, 240, size.height - vpY + 40);
    canvas.drawRect(
      beamRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0FF0FC).withValues(alpha: 0.04),
            const Color(0xFF0FF0FC).withValues(alpha: 0.0),
          ],
        ).createShader(beamRect),
    );
  }

  void _drawStars(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;
    const depth = 330.0;

    for (final s in stars) {
      if (s.cooldown > 0) continue;

      final px = (s.x + mouseNorm.dx * 14 * (depth / s.z)) * depth / s.z + cx;
      final py = (s.y + mouseNorm.dy * 10 * (depth / s.z)) * depth / s.z + cy;

      if (px < -20 || px > size.width + 20 || py < -20 || py > size.height + 20)
        continue;

      final radius = (2.8 * depth / s.z).clamp(0.3, 5.0);
      final alpha = (s.brightness * (1 - s.z / 640)).clamp(0.0, 1.0);
      final pos = Offset(px, py);

      if (s.kind == _StarKind.evil) {
        // Evil: red/orange/purple with warning ring
        canvas.drawCircle(pos, radius * 2.2,
            Paint()..color = s.color.withValues(alpha: alpha * 0.10));
        canvas.drawCircle(
          pos,
          radius * 2.2,
          Paint()
            ..color = s.color.withValues(alpha: alpha * 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
        );
        canvas.drawCircle(pos, radius * 0.6,
            Paint()..color = s.color.withValues(alpha: alpha * 0.95));
        // 4-point cross to look spiky
        final r = radius * 1.3;
        final linePaint = Paint()
          ..color = s.color.withValues(alpha: alpha * 0.5)
          ..strokeWidth = 0.5;
        canvas.drawLine(Offset(px, py - r), Offset(px, py + r), linePaint);
        canvas.drawLine(Offset(px - r, py), Offset(px + r, py), linePaint);
      } else {
        // Good: soft cyan/green glowing dot
        canvas.drawCircle(pos, radius * 2.2,
            Paint()..color = s.color.withValues(alpha: alpha * 0.12));
        canvas.drawCircle(pos, radius * 0.45,
            Paint()..color = Colors.white.withValues(alpha: alpha * 0.95));
      }
    }
  }

  void _drawHealthBar(Canvas canvas) {
    if (mousePos == Offset.zero || screenSize == Size.zero) return;

    const barW = 84.0;
    const barH = 9.0;
    final bx = mousePos.dx - barW / 2;
    final by = mousePos.dy - 34;

    // Background pill
    final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx - 2, by - 2, barW + 4, barH + 4),
        const Radius.circular(6));
    canvas.drawRRect(bgRect,
        Paint()..color = const Color(0xFF000000).withValues(alpha: 0.60));

    // Fill
    final fillColor = _hpColor(health);
    if (health > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, barW * health, barH),
            const Radius.circular(4)),
        Paint()..color = fillColor,
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, barW, barH), const Radius.circular(4)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Cursor ring (colour-coded)
    canvas.drawCircle(
      mousePos,
      7,
      Paint()
        ..color = fillColor.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  Color _hpColor(double h) {
    if (h > 0.55) {
      return Color.lerp(
          const Color(0xFFFFD700), const Color(0xFF00FF87), (h - 0.55) / 0.45)!;
    } else if (h > 0.25) {
      return Color.lerp(
          const Color(0xFFFF6B35), const Color(0xFFFFD700), (h - 0.25) / 0.30)!;
    }
    return Color.lerp(
        const Color(0xFFFF1744), const Color(0xFFFF6B35), h / 0.25)!;
  }

  void _drawBursts(Canvas canvas) {
    for (final b in bursts) {
      final t = 1.0 - b.life; // progress 0→1

      // Outer expanding ring
      canvas.drawCircle(
        b.center,
        58.0 * t,
        Paint()
          ..color = b.color.withValues(alpha: b.life * 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * b.life,
      );

      // Inner ring (slightly delayed)
      if (t > 0.12) {
        final t2 = (t - 0.12) / 0.88;
        canvas.drawCircle(
          b.center,
          28.0 * t2,
          Paint()
            ..color = Colors.white.withValues(alpha: b.life * 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 * b.life,
        );
      }

      // Center flash (first 20%)
      if (t < 0.20) {
        final f = 1.0 - (t / 0.20);
        canvas.drawCircle(
          b.center,
          14.0 * f,
          Paint()
            ..color = Colors.white.withValues(alpha: f * 0.88)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      // Spark streaks (no blur on tips — too expensive per-spark)
      for (final s in b.sparks) {
        final dist = s.speed * t;
        final tip = Offset(
          b.center.dx + math.cos(s.angle) * dist,
          b.center.dy + math.sin(s.angle) * dist,
        );
        final tail = Offset(
          b.center.dx + math.cos(s.angle) * (dist * 0.5),
          b.center.dy + math.sin(s.angle) * (dist * 0.5),
        );
        canvas.drawLine(
          tail,
          tip,
          Paint()
            ..color = b.color.withValues(alpha: b.life * 0.80)
            ..strokeWidth = s.size * b.life * 0.9
            ..strokeCap = StrokeCap.round,
        );
        // Plain bright tip dot (no blur)
        canvas.drawCircle(
          tip,
          s.size * b.life * 0.9,
          Paint()..color = Colors.white.withValues(alpha: b.life * 0.88),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => true;
}

// ─── Animated background widget ───────────────────────────────────────────────

class _AnimatedBackground extends StatefulWidget {
  final ValueNotifier<Offset> mouseNotifier;
  const _AnimatedBackground({required this.mouseNotifier});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _last = Duration.zero;
  double _gridTime = 0;
  double _health = 1.0;
  final List<_Star> _stars = [];
  final List<_Burst> _bursts = [];
  final _rng = math.Random(77);

  // Updated by pointer events; ticker reads them each frame — no extra setState
  Offset _mouseNorm = Offset.zero;
  Offset _mousePos = Offset.zero;
  Size _size = Size.zero;

  static const _goodColors = [
    Color(0xFF0FF0FC), // cyan
    Color(0xFF00BFFF), // blue
    Color(0xFF00FF87), // green
    Color(0xFF7DF9FF), // light cyan
  ];
  static const _evilColors = [
    Color(0xFFFF3030), // red
    Color(0xFFFF6B35), // orange-red
    Color(0xFFBF00FF), // purple
    Color(0xFFFF1744), // crimson
  ];

  static const double _burstRadius = 24.0;
  static const double _burstCooldown = 1.2;
  static const double _burstDuration = 0.72;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 75; i++) {
      _stars.add(_newStar(initial: true));
    }
    _ticker = createTicker(_onTick)..start();
  }

  _Star _newStar({bool initial = false}) {
    final evil = _rng.nextDouble() < 0.32; // 32 % evil
    final colors = evil ? _evilColors : _goodColors;
    final cIdx = _rng.nextInt(colors.length);
    return _Star(
      x: (_rng.nextDouble() - 0.5) * 1500,
      y: (_rng.nextDouble() - 0.5) * 850,
      z: initial ? _rng.nextDouble() * 600 + 30 : 600 + _rng.nextDouble() * 40,
      speed: 0.5 + _rng.nextDouble() * 1.5,
      brightness: 0.35 + _rng.nextDouble() * 0.65,
      color: colors[cIdx],
      kind: evil ? _StarKind.evil : _StarKind.good,
    );
  }

  _Burst _makeBurst(Offset center, Color color, _StarKind kind) {
    const sparkCount = 8;
    final sparks = List.generate(sparkCount, (i) {
      final angle =
          (i / sparkCount) * math.pi * 2 + _rng.nextDouble() * 0.35 - 0.175;
      return _BurstSpark(
        angle: angle,
        speed: 44 + _rng.nextDouble() * 28,
        size: 1.2 + _rng.nextDouble() * 1.3,
      );
    });
    return _Burst(center: center, color: color, sparks: sparks, kind: kind);
  }

  Offset _project(_Star s) {
    if (_size == Size.zero) return Offset.zero;
    const depth = 330.0;
    final cx = _size.width / 2;
    final cy = _size.height * 0.38;
    final px = (s.x + _mouseNorm.dx * 14 * (depth / s.z)) * depth / s.z + cx;
    final py = (s.y + _mouseNorm.dy * 10 * (depth / s.z)) * depth / s.z + cy;
    return Offset(px, py);
  }

  void _onTick(Duration elapsed) {
    final pos = widget.mouseNotifier.value;
    _mousePos = pos;
    if (_size != Size.zero && pos != Offset.zero) {
      _mouseNorm = Offset(
        (pos.dx / _size.width - 0.5) * 2,
        (pos.dy / _size.height - 0.5) * 2,
      );
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (!mounted) return;
    setState(() {
      _gridTime = (_gridTime + dt * 0.21) % 1.0;

      for (int i = 0; i < _stars.length; i++) {
        _stars[i].z -= _stars[i].speed * dt * 58;
        if (_stars[i].z < 6) _stars[i] = _newStar();
        if (_stars[i].cooldown > 0) _stars[i].cooldown -= dt;
      }

      // Proximity burst check
      if (_mousePos != Offset.zero) {
        for (int i = 0; i < _stars.length; i++) {
          if (_stars[i].cooldown > 0) continue;
          final screen = _project(_stars[i]);
          if ((screen - _mousePos).distance < _burstRadius) {
            final s = _stars[i];
            _bursts.add(_makeBurst(screen, s.color, s.kind));
            _stars[i].cooldown = _burstCooldown;
            if (s.kind == _StarKind.good) {
              _health = (_health + 0.09).clamp(0.0, 1.0);
            } else {
              _health = (_health - 0.13).clamp(0.0, 1.0);
            }
          }
        }
      }

      for (int i = _bursts.length - 1; i >= 0; i--) {
        _bursts[i].life -= dt / _burstDuration;
        if (_bursts[i].life <= 0) _bursts.removeAt(i);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ScenePainter(
          stars: _stars,
          gridTime: _gridTime,
          mouseNorm: _mouseNorm,
          mousePos: _mousePos,
          bursts: _bursts,
          health: _health,
          screenSize: _size,
        ),
        child: const SizedBox.expand(),
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
  final _mouseNotifier = ValueNotifier<Offset>(Offset.zero);

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _mouseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: (event) => _mouseNotifier.value = event.position,
        onPointerMove: (event) => _mouseNotifier.value = event.position,
        child: Stack(
          children: [
            Positioned.fill(
              child: _AnimatedBackground(mouseNotifier: _mouseNotifier),
            ),
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
            child: FloatingWidget(
              amplitude: 7,
              child: Tilt3DWrapper(
                maxTilt: 0.2,
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
                        color: const Color(0xFF0FF0FC).withValues(alpha: 0.40),
                        blurRadius: 48,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFF005CFF).withValues(alpha: 0.22),
                        blurRadius: 70,
                        spreadRadius: 2,
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
                const _PulsingDot(),
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
          _infoRow(context, Icons.phone_outlined, '+91 9576671336',
              () => launchUrl(Uri(scheme: 'tel', path: '+919576671336'))),
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
        githubUrl: 'https://github.com/vritravaibhav',
      ),
      const SizedBox(height: 40),
      _sectionTitle(context, 'Open Source'),
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: const Color(0xFF0FF0FC)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Standalone private widgets ───────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween(begin: 0.65, end: 1.35)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.65),
                blurRadius: 7,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
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
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..color = const Color(0xFF0FF0FC).withValues(alpha: 0.12)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          ),
        ),
        Text(text, style: style),
      ],
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
