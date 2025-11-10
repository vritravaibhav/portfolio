import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CardItem extends StatelessWidget {
  final String time;
  final String heading;
  final String title;
  final String descriptiom;

  const CardItem(
      {super.key,
      required this.time,
      required this.heading,
      required this.title,
      required this.descriptiom});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width < 800
          ? null
          : (MediaQuery.of(context).size.width / 2) - 100,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row with Icon and Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                radius: 20,
                child: Icon(
                  Icons.flutter_dash,
                  color: Colors.white,
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          SizedBox(height: 15),
          // Middle Texts
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 5),
          Text(
            heading,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 5),
          Text(
            descriptiom,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class ExperienceCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String companyName;
  final String description;
  final String duration;

  ExperienceCard({
    required this.imagePath,
    required this.title,
    required this.companyName,
    required this.description,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.all(10),
      width: size.width < 800 ? null : (size.width / 2) - 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Expanded(child: SizedBox()),
                    Text(
                      duration,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  companyName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 10),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactUsForm extends StatefulWidget {
  @override
  _ContactUsFormState createState() => _ContactUsFormState();
}

class _ContactUsFormState extends State<ContactUsForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _email = TextEditingController();
  TextEditingController _name = TextEditingController();
  TextEditingController _subject = TextEditingController();
  TextEditingController _descriptiom = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Us Title
            Center(
              child: Text(
                'Get in touch',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            SizedBox(height: 20),

            // Name Field
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            SizedBox(height: 15),

            // Email Field
            TextFormField(
              controller: _email,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 15),

            // Subject Field
            TextFormField(
              controller: _subject,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the subject';
                }
                return null;
              },
            ),
            SizedBox(height: 15),

            // Message Field
            TextFormField(
              controller: _descriptiom,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your message';
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    // Process data
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Submitting form')),
                    );
                    FirebaseFirestore.instance.collection("form").add({
                      "name": _name.text,
                      "email": _email.text,
                      "subject": _subject.text,
                      "description": _descriptiom.text
                    });
                    _email.clear();
                    _subject.clear();
                    _name.clear();
                    _descriptiom.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Send',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactUsContainer extends StatelessWidget {
  final String name = 'Divyanshu Vaibhav';
  final String phoneNumber = '+91 9576671336';
  final String email = 'divaibhavyanshu@gmail.com';
  final String degree = 'Bachelor of Engineering';
  final String university = 'Panjab University';
  final String githubUrl =
      'https://github.com/vritravaibhav'; // Replace with your GitHub URL
  final String linkedinUrl =
      'https://www.linkedin.com/in/divyanshu-vaibhav-6a7965202/'; // Replace with your LinkedIn URL
  final String batchYears = '2020-2024';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      margin: EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          color: Theme.of(context).colorScheme.secondary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.phone,
                        color: Theme.of(context).colorScheme.tertiary),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse('tel:$phoneNumber')),
                      child: Text(
                        phoneNumber,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.email,
                        color: Theme.of(context).colorScheme.tertiary),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse('mailto:$email')),
                      child: Text(
                        email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.school,
                        color: Theme.of(context).colorScheme.tertiary),
                    SizedBox(width: 8),
                    Text(
                      degree,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  university,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 5),
                Text(
                  batchYears,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.code,
                        color: Theme.of(context).colorScheme.tertiary),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(githubUrl)),
                      child: Text(
                        'GitHub Profile',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.link,
                        color: Theme.of(context).colorScheme.tertiary),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(linkedinUrl)),
                      child: Text(
                        'LinkedIn Profile',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

