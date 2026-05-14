import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CardItem extends StatelessWidget {
  final String time; // used as tech-stack label
  final String heading;
  final String title;
  final String descriptiom;
  final String? githubUrl;

  const CardItem({
    super.key,
    required this.time,
    required this.heading,
    required this.title,
    required this.descriptiom,
    this.githubUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1629),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0FF0FC).withValues(alpha: 0.12)),
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
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 10,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (githubUrl != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse(githubUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: const Color(0xFF0FF0FC).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new,
                            size: 11, color: Color(0xFF0FF0FC)),
                        SizedBox(width: 4),
                        Text(
                          'GitHub',
                          style: TextStyle(
                            color: Color(0xFF0FF0FC),
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(heading, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF94A3B8),
                ),
          ),
          const SizedBox(height: 12),
          Text(descriptiom, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ExperienceCard extends StatelessWidget {
  final String title;
  final String companyName;
  final String description;
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1629),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0FF0FC).withValues(alpha: 0.12)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: isActive
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
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4ADE80)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(3),
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
                                companyName,
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
                          duration,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(description,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
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

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
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
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message sent!')),
                    );
                    FirebaseFirestore.instance.collection("form").add({
                      "name": _name.text,
                      "email": _email.text,
                      "subject": _subject.text,
                      "description": _message.text,
                    });
                    _email.clear();
                    _subject.clear();
                    _name.clear();
                    _message.clear();
                  }
                },
                child: const Text('SEND MESSAGE'),
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
            'linkedin.com/in/divyanshu-vaibhav',
            () => launchUrl(
              Uri.parse('https://linkedin.com/in/divyanshu-vaibhav'),
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
