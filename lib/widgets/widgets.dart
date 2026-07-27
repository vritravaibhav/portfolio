import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where "Get in touch" submissions are delivered.
const String contactEmail = 'divaibhavyanshu@gmail.com';

// ─── 3D tilt on mouse hover ───────────────────────────────────────────────────

class Tilt3DWrapper extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final double perspective;

  const Tilt3DWrapper({
    super.key,
    required this.child,
    this.maxTilt = 0.12,
    this.perspective = 0.0008,
  });

  @override
  State<Tilt3DWrapper> createState() => _Tilt3DWrapperState();
}

class _Tilt3DWrapperState extends State<Tilt3DWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _rotX = 0, _rotY = 0;
  double _targetX = 0, _targetY = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(() {
        setState(() {
          _rotX += (_targetX - _rotX) * 0.1;
          _rotY += (_targetY - _rotY) * 0.1;
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(event.position);
        final nx = (local.dx / box.size.width - 0.5) * 2;
        final ny = (local.dy / box.size.height - 0.5) * 2;
        _targetY = nx * widget.maxTilt;
        _targetX = -ny * widget.maxTilt;
      },
      onExit: (_) {
        _targetX = 0;
        _targetY = 0;
      },
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateX(_rotX)
          ..rotateY(_rotY),
        child: widget.child,
      ),
    );
  }
}

// ─── Floating up/down animation ───────────────────────────────────────────────

class FloatingWidget extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;

  const FloatingWidget({
    super.key,
    required this.child,
    this.amplitude = 8.0,
    this.period = const Duration(seconds: 3),
  });

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: widget.period)
          ..repeat(reverse: true);
    _anim = Tween(begin: -widget.amplitude, end: widget.amplitude).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _anim.value), child: child),
      child: widget.child,
    );
  }
}

// ─── Cards ────────────────────────────────────────────────────────────────────

/// Bulleted body copy shared by experience and project cards.
class BulletList extends StatelessWidget {
  final List<String> items;
  const BulletList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 9),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0FF0FC),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Small outlined "open in new tab" chip used for GitHub / pub.dev links.
class _LinkChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String url;

  const _LinkChip({
    required this.label,
    required this.icon,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: const Color(0xFF0FF0FC).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: const Color(0xFF0FF0FC)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0FF0FC),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final String time; // used as tech-stack label
  final String heading;
  final String title;
  final List<String> descriptiom;
  final String? githubUrl;
  final String? pubDevUrl;

  const CardItem({
    super.key,
    required this.time,
    required this.heading,
    required this.title,
    required this.descriptiom,
    this.githubUrl,
    this.pubDevUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Tilt3DWrapper(
      child: _CardContent(
        time: time,
        heading: heading,
        title: title,
        descriptiom: descriptiom,
        githubUrl: githubUrl,
        pubDevUrl: pubDevUrl,
      ),
    );
  }
}

class _CardContent extends StatefulWidget {
  final String time;
  final String heading;
  final String title;
  final List<String> descriptiom;
  final String? githubUrl;
  final String? pubDevUrl;

  const _CardContent({
    required this.time,
    required this.heading,
    required this.title,
    required this.descriptiom,
    this.githubUrl,
    this.pubDevUrl,
  });

  @override
  State<_CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<_CardContent> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFF111E38)
              : const Color(0xFF0F1629),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF0FF0FC).withValues(alpha: 0.35)
                : const Color(0xFF0FF0FC).withValues(alpha: 0.12),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF0FF0FC).withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.time,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 10,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.pubDevUrl != null) ...[
                  const SizedBox(width: 8),
                  _LinkChip(
                    label: 'pub.dev',
                    icon: Icons.inventory_2_outlined,
                    url: widget.pubDevUrl!,
                  ),
                ],
                if (widget.githubUrl != null) ...[
                  const SizedBox(width: 8),
                  _LinkChip(
                    label: 'GitHub',
                    icon: Icons.open_in_new,
                    url: widget.githubUrl!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(widget.heading,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF94A3B8),
                  ),
            ),
            const SizedBox(height: 12),
            BulletList(items: widget.descriptiom),
          ],
        ),
      ),
    );
  }
}

class ExperienceCard extends StatefulWidget {
  final String title;
  final String companyName;
  final List<String> description;
  final String duration;
  final bool isActive;

  const ExperienceCard({
    super.key,
    required this.title,
    required this.companyName,
    required this.description,
    required this.duration,
    this.isActive = false,
  });

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tilt3DWrapper(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF111E38) : const Color(0xFF0F1629),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF0FF0FC).withValues(alpha: 0.35)
                  : const Color(0xFF0FF0FC).withValues(alpha: 0.12),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF0FF0FC).withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? const Color(0xFF0FF0FC)
                        : const Color(0xFF1E3A5F),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ),
                                      if (widget.isActive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4ADE80)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            border: Border.all(
                                              color: const Color(0xFF4ADE80)
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: const Text(
                                            'active',
                                            style: TextStyle(
                                              color: Color(0xFF4ADE80),
                                              fontSize: 9,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.companyName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: const Color(0xFFFFB703),
                                          fontSize: 13,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.duration,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        BulletList(items: widget.description),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactUsForm extends StatefulWidget {
  const ContactUsForm({super.key});

  @override
  State<ContactUsForm> createState() => _ContactUsFormState();
}

class _ContactUsFormState extends State<ContactUsForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _sending = true);

    final name = _name.text.trim();
    final email = _email.text.trim();
    final subject = _subject.text.trim();
    final message = _message.text.trim();

    try {
      final db = FirebaseFirestore.instance;

      // Keep the raw submission log.
      await db.collection('form').add({
        'name': name,
        'email': email,
        'subject': subject,
        'description': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Queue the notification email. Consumed by the Firebase
      // "Trigger Email from Firestore" extension, which watches this
      // collection and delivers via the configured SMTP account.
      await db.collection('mail').add({
        'to': [contactEmail],
        'replyTo': email,
        'message': {
          'subject': 'Portfolio enquiry: $subject',
          'text': 'From: $name <$email>\n'
              'Subject: $subject\n\n'
              '$message',
          'html': '<p><strong>From:</strong> ${_esc(name)} '
              '(<a href="mailto:${_esc(email)}">${_esc(email)}</a>)</p>'
              '<p><strong>Subject:</strong> ${_esc(subject)}</p>'
              '<hr>'
              '<p>${_esc(message).replaceAll('\n', '<br>')}</p>',
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent — thanks, I\'ll be in touch.')),
      );
      _email.clear();
      _subject.clear();
      _name.clear();
      _message.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text('Could not send: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1629),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0FF0FC).withValues(alpha: 0.12)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get in touch',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subject,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter the subject' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _message,
              maxLines: 4,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(labelText: 'Message'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter your message' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      )
                    : const Text('SEND MESSAGE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactUsContainer extends StatelessWidget {
  const ContactUsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1629),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0FF0FC).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Divyanshu Vaibhav',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 20),
          _contactRow(
            context,
            Icons.phone_outlined,
            '+91 9576671336',
            () => launchUrl(Uri(scheme: 'tel', path: '+919576671336')),
          ),
          const SizedBox(height: 12),
          _contactRow(
            context,
            Icons.email_outlined,
            'divaibhavyanshu@gmail.com',
            () => launchUrl(
              Uri.parse(
                  'https://mail.google.com/mail/?view=cm&fs=1&to=divaibhavyanshu@gmail.com'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 12),
          _contactRow(
            context,
            Icons.school_outlined,
            'B.E. Electronics & Communication\nPanjab University · 2020–2024',
            null,
          ),
          const SizedBox(height: 12),
          _contactRow(
            context,
            Icons.code,
            'github.com/vritravaibhav',
            () => launchUrl(
              Uri.parse('https://github.com/vritravaibhav'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 12),
          _contactRow(
            context,
            Icons.link,
            'linkedin.com/in/divyanshuvaibhav',
            () => launchUrl(
              Uri.parse('https://www.linkedin.com/in/divyanshuvaibhav/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback? onTap,
  ) {
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0FF0FC)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onTap != null ? const Color(0xFF0FF0FC) : null,
                ),
          ),
        ),
      ],
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
