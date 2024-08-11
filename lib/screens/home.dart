import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:portfolio/constatnts/strings.dart';
import 'package:portfolio/main.dart';
import 'package:portfolio/screens/demo.dart';
import 'package:portfolio/widgets/widgets.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isHovering = false;
  bool skills = false;
  bool experience = false;
  bool projects = false;
  bool profile = false;

  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).size.width);
    return Scaffold(
      backgroundColor: Color(0xFF112240), // Dark blue container color

      appBar: ((MediaQuery.of(context).size.width > 640) &&
              !skills &&
              !experience &&
              !projects)
          ? AppBar(
              backgroundColor: Colors.transparent,
              actions: [
                MouseRegion(
                    onEnter: (event) {
                      experience = true;
                      setState(() {});
                    },
                    child: TextButton(
                        onPressed: () {}, child: Text("Experience"))),

                //  App(),

                MouseRegion(
                    onEnter: (event) {
                      projects = true;
                      setState(() {});
                    },
                    child: TextButton(
                        onPressed: () {},
                        child: Text(
                          "Projects",
                          style: TextStyle(),
                        ))),
                MouseRegion(
                  onEnter: (event) {
                    skills = true;
                    setState(() {});
                  },
                  child: TextButton(
                    onPressed: () {},
                    child: Text("Skills"),
                  ),
                ),
                // TextButton(onPressed: (){}, child: Text("Experience"))
                // Padding(padding: EdgeInsets.only(left: 20))
                // App(),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.02,
                )
              ],
              // leadingWidth: 260,
              // flexibleSpace: Text("lol"),
              title: Row(
                children: [
                  Text(
                    'Divyanshu Vaibhav',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFCCCCCC),
                        fontSize: 30),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Wrap(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Image.asset(
                            "assets/github-logo.png",
                            height: 30,
                            width: 50,
                          ),
                        ),
                        Image.asset(
                          "assets/logo-linkedin-logo-icon-png-svg.png",
                          height: 40,
                          width: 50,
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          : (skills)
              ? AppBar(
                  actions: [
                    MouseRegion(
                      onExit: (event) {
                        skills = false;
                        setState(() {});
                      },
                      child: Row(children: [
                        TextButton(
                          onPressed: () {},
                          child: Text("Flutter"),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Firebase"),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Dart"),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Others"),
                        ),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.02,
                        )
                      ]),
                    )
                  ],
                )
              : projects
                  ? AppBar(
                      actions: [
                        MouseRegion(
                          onExit: (event) {
                            projects = false;
                            setState(() {});
                          },
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: Text("InstaClone"),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text("AmazonClone"),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text("Others"),
                              ),
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width * 0.02,
                              )
                            ],
                          ),
                        )
                      ],
                    )
                  : experience
                      ? AppBar(
                          actions: [
                            MouseRegion(
                              onExit: (event) {
                                experience = false;
                                setState(() {});
                              },
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: Text("Outshade company"),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text("Freelance"),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text("Others"),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.sizeOf(context).width * 0.02,
                                  )
                                ],
                              ),
                            )
                          ],
                        )
                      : AppBar(
                          title: Row(
                            children: [
                              Text(
                                'Divyanshu Vaibhav',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFCCCCCC),
                                    fontSize: 30),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Wrap(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Image.asset(
                                        "assets/github-logo.png",
                                        height: 30,
                                        width: 50,
                                      ),
                                    ),
                                    Image.asset(
                                      "assets/logo-linkedin-logo-icon-png-svg.png",
                                      height: 40,
                                      width: 50,
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            Center(
              child: MouseRegion(
                onEnter: (event) {
                  profile = true;
                  setState(() {});
                },
                onExit: (event) {
                  profile = false;
                  setState(() {});
                },
                child: CircleAvatar(
                    radius: profile ? 200 : 70,
                    backgroundImage: AssetImage(
                      "assets/profilepic.jpg",
                    )),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            //  App(),
            Text(
              'About Me',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF90CAF9)),
            ),
            SizedBox(height: 10),
            Text(
              about,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64FFDA),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Experience',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF90CAF9),
              ),
            ),
            //  App(),
            SizedBox(height: 10),
            Wrap(
              children: [
                ExperienceCard(
                    imagePath: "dfsd",
                    title: "Internship",
                    companyName: "Outshade Digital Media",
                    description: outshadeExperience,
                    duration: "May 2024 - August 2024"),
                SizedBox(
                  width: 20,
                ),
                ExperienceCard(
                    imagePath: "dfsd",
                    title: "Freelance",
                    companyName: "Aypex pvt ltd",
                    description: aypexExperience,
                    duration: "October 2023 - currenly working"),
                ExperienceCard(
                    imagePath: "dfsd",
                    title: "Flutter Developer",
                    companyName: "Connect 4 digial India",
                    description: c4dexp,
                    duration: "April 2024 - currently working")
              ],
            ),

            // Add more ExperienceItem widgets for additional experiences
            SizedBox(height: 30),
            Text(
              'Projects',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF90CAF9),
              ),
            ),
            SizedBox(height: 20),
            ProjectCard(
              projectName: 'Fullstack Instagram using Flutter and Firebase',
              projectDescription:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, quam et tempus pharetra, purus turpis tempus leo, quis pulvinar velit ex at odio.',
            ),
            Text(
              'Contact Us',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF90CAF9)),
            ),
            Align(
                alignment: Alignment.center,
                child: Wrap(
                  children: [
                    Column(
                      children: [ContactUsContainer()],
                    ),
                    ContactUsForm(),
                  ],
                ))
            // Add more ProjectCard widgets for additional projects
          ],
        ),
      ),
    );
  }
}

class ExperienceItem extends StatelessWidget {
  final String company;
  final String position;
  final String duration;
  final String description;

  const ExperienceItem({
    Key? key,
    required this.company,
    required this.position,
    required this.duration,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$position at $company',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '$duration',
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 20),
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
