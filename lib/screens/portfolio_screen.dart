import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/constatnts/strings.dart';
import 'package:portfolio/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class PortfolioScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildWideLayout(context);
          } else {
            return _buildNarrowLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildLeftColumn(context),
        ),
        Expanded(
          flex: 3,
          child: _buildRightColumn(context),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLeftColumn(context),
        const SizedBox(height: 30),
        _buildRightColumn(context),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 70,
              backgroundImage: AssetImage("assets/profilepic.jpg"),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Divyanshu Vaibhav',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Flutter Developer',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.github),
                onPressed: () {
                  launchUrl(Uri.parse("https://github.com/vritravaibhav"));
                },
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.linkedin),
                onPressed: () {
                  launchUrl(Uri.parse(
                      "https://www.linkedin.com/in/divyanshu-vaibhav-6a7965202/"));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'About Me',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        Text(
          about,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 30),
        Text(
          'Skills',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            Chip(label: Text('Flutter')),
            Chip(label: Text('Dart')),
            Chip(label: Text('Firebase')),
            Chip(label: Text('Node.js')),
            Chip(label: Text('Express.js')),
            Chip(label: Text('MongoDB')),
            Chip(label: Text('Git')),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'Experience',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        ExperienceCard(
          imagePath: "dfsd",
          title: "Internship",
          companyName: "Outshade Digital Media",
          description: outshadeExperience,
          duration: "May 2024 - August 2024",
        ),
        const SizedBox(height: 20),
        ExperienceCard(
          imagePath: "dfsd",
          title: "Freelance",
          companyName: "Aypex pvt ltd",
          description: aypexExperience,
          duration: "October 2023 - currenly working",
        ),
        const SizedBox(height: 20),
        ExperienceCard(
          imagePath: "dfsd",
          title: "Flutter Developer",
          companyName: "Connect 4 digial India",
          description: c4dexp,
          duration: "April 2024 - currently working",
        ),
        const SizedBox(height: 30),
        Text(
          'Projects',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 20),
        ProjectCard(
          projectName: 'Fullstack Instagram using Flutter and Firebase',
          projectDescription:
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, quam et tempus pharetra, purus turpis tempus leo, quis pulvinar velit ex at odio.',
        ),
        const SizedBox(height: 30),
        Text(
          'Contact Us',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 20),
        ContactUsForm(),
        const SizedBox(height: 20),
        ContactUsContainer(),
      ],
    );
  }
}

class ProjectCard extends StatelessWidget {
  final String projectName;
  final String projectDescription;

  const ProjectCard({
    Key? key,
    required this.projectName,
    required this.projectDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            children: [
              CardItem(
                time: "18 months ago",
                heading: "Fullstack Instagram Clone using Flutter and Firebase",
                title: 'Instagram with chat and Dating Option',
                descriptiom: instaCloneDec,
              ),
              SizedBox(
                width: 20,
              ),
              CardItem(
                time: "15 months ago",
                heading: 'Amazon Clone',
                title: 'Amazon clone using Node.js',
                descriptiom:
                    'I developed a Flutter-based Amazon app using Express.js, Node.js, and MongoDB. The project features authorization with JSON Web Token and Node.js, and it uses MongoDB for data storage. I implemented CRUD operations in the database using Express.js. The project was built using Node.js, Express.js, Dart, and Flutter',
              ),
              CardItem(
                time: "1 months ago",
                heading: 'Multiuser video call using WEBRTC and firebase',
                title: 'Multiuser video call',
                descriptiom: webrtcdec,
              )
            ],
          ),
        ],
      ),
    );
  }
}
