import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where "Get in touch" submissions are delivered.
const String contactEmail = 'divaibhavyanshu@gmail.com';

// ─── Contact line ─────────────────────────────────────────────────────────────

/// A contact detail with an explicit copy button.
///
/// Drag-to-select works (the tree is wrapped in a SelectionArea), but on a
/// canvas-rendered web app that is fiddly and easy to miss — a visitor who
/// wants the email should not have to discover it. The button copies
/// unconditionally.
class ContactLine extends StatefulWidget {
  final IconData icon;
  final String text;

  /// Copied verbatim. When null, no copy button is shown.
  final String? copyText;

  /// Fired when the label itself is tapped (mail client, dialer, …).
  final VoidCallback? onTap;

  /// What the confirmation calls this, e.g. 'Email'.
  final String label;

  const ContactLine({
    super.key,
    required this.icon,
    required this.text,
    required this.label,
    this.copyText,
    this.onTap,
  });

  @override
  State<ContactLine> createState() => _ContactLineState();
}

class _ContactLineState extends State<ContactLine> {
  bool _copied = false;
  bool _hovered = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.copyText!));
    if (!mounted) return;

    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0F1F33),
          behavior: SnackBarBehavior.floating,
          // No fixed width: labels vary in length ('Phone number copied') and
          // the system text scale can grow them further, either of which
          // overflows a hard-coded box.
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: const Color(0xFF0FF0FC).withValues(alpha: 0.35),
            ),
          ),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 15, color: Color(0xFF4ADE80)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${widget.label} copied',
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(
      widget.text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.onTap != null ? const Color(0xFF0FF0FC) : null,
          ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(widget.icon, size: 15, color: const Color(0xFF0FF0FC)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: widget.onTap == null
                ? label
                : GestureDetector(onTap: widget.onTap, child: label),
          ),
          if (widget.copyText != null) ...[
            const SizedBox(width: 6),
            _CopyButton(
              copied: _copied,
              // Always visible on touch, where there is no hover to reveal it.
              prominent: _hovered || _copied,
              onPressed: _copy,
              semanticLabel: 'Copy ${widget.label.toLowerCase()}',
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final bool copied;
  final bool prominent;
  final VoidCallback onPressed;
  final String semanticLabel;

  const _CopyButton({
    required this.copied,
    required this.prominent,
    required this.onPressed,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = copied ? const Color(0xFF4ADE80) : const Color(0xFF0FF0FC);
    return Tooltip(
      message: copied ? 'Copied' : semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          onTap: onPressed,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withValues(alpha: prominent ? 0.14 : 0.06),
                border: Border.all(
                  color: color.withValues(alpha: prominent ? 0.55 : 0.22),
                ),
              ),
              child: Icon(
                copied ? Icons.check : Icons.copy_rounded,
                size: 12,
                color: color,
              ),
            ),
          ),
        ),
      ),
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
    return _CardContent(
      time: time,
      heading: heading,
      title: title,
      descriptiom: descriptiom,
      githubUrl: githubUrl,
      pubDevUrl: pubDevUrl,
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
    return MouseRegion(
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
          ContactLine(
            icon: Icons.phone_outlined,
            text: '+91 9576671336',
            label: 'Phone number',
            copyText: '+919576671336',
            onTap: () => launchUrl(Uri(scheme: 'tel', path: '+919576671336')),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          const ContactLine(
            icon: Icons.school_outlined,
            text: 'B.E. Electronics & Communication\n'
                'Panjab University · 2020–2024',
            label: 'Education',
          ),
          const SizedBox(height: 12),
          ContactLine(
            icon: Icons.code,
            text: 'github.com/vritravaibhav',
            label: 'GitHub URL',
            copyText: 'https://github.com/vritravaibhav',
            onTap: () => launchUrl(
              Uri.parse('https://github.com/vritravaibhav'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 12),
          ContactLine(
            icon: Icons.link,
            text: 'linkedin.com/in/divyanshuvaibhav',
            label: 'LinkedIn URL',
            copyText: 'https://www.linkedin.com/in/divyanshuvaibhav/',
            onTap: () => launchUrl(
              Uri.parse('https://www.linkedin.com/in/divyanshuvaibhav/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
