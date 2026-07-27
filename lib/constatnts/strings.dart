const String about =
    "Software Engineer building Spring Boot backends and the Flutter clients that consume them. "
    "Currently at Longfloat Information Technology, Dubai — designing REST microservices with Spring Data JPA "
    "and Hibernate, securing them with stateless JWT auth, and dropping down to Android Native (NDK/JNI) for "
    "hardware-accelerated rendering. Previously architected the backend for a production ride-hailing platform "
    "at Electromotion E-vidyut while leading a 5-member team delivering 9+ production Flutter apps.";

// ─── Experience ───────────────────────────────────────────────────────────────

const List<String> longfloatExperience = [
  "Designed and developed Spring Boot REST microservices (Spring Data JPA, Hibernate, Flyway migrations) "
      "powering AI features and core backend APIs consumed by Flutter clients.",
  "Implemented stateless JWT authentication and role-based access control with Spring Security, plus "
      "centralized exception handling, DTO mapping, and request validation (Bean Validation).",
  "Wrote unit and integration tests with JUnit 5 and Mockito; documented endpoints with Swagger/OpenAPI "
      "and containerized services with Docker for consistent environments.",
  "Architected hardware-accelerated rendering pipelines on Android Native (NDK/JNI), cutting UI frame-drop "
      "rate by 40%; built C++/JNI bridges exposing hardware APIs to Flutter.",
  "Resolved critical memory leaks and race conditions in production Flutter apps, reducing crash rates by 35%.",
];

const List<String> electromotionExperience = [
  "Designed Spring Boot backend services for a production ride-hailing platform — trip lifecycle, fare "
      "calculation, and driver–rider matching — with layered architecture (Controller–Service–Repository).",
  "Optimized JPA/MySQL indexing and query design for low-latency geo queries; profiled and eliminated N+1 "
      "query patterns to keep matching latency low under load.",
  "Built a Google Maps routing engine and server-side tile-caching layer, reducing map API costs by 85% "
      "and total infrastructure spend by over 6×.",
  "Developed 7+ native plugins (Android/iOS) for battery, overlay display, and geolocation to support the apps.",
  "Led a 5-member team delivering 9+ production Flutter apps, including the Aamcha Chalak captain app and "
      "Aamcha Auto rider app (Uber/Rapido-style).",
  "Improved crash-free rate from 67% to 94% via Firebase Crashlytics; shipped A/B Testing, Remote Config, "
      "and FCM campaigns to decouple releases from launches.",
];

const List<String> c4dexp = [
  "Integrated WebRTC P2P audio/video — ICE/STUN/TURN configuration and WebSocket signaling for low-latency, "
      "encrypted data channels.",
  "Integrated 130+ WooCommerce REST APIs and Stripe SDK payments within Flutter apps; managed state with BLoC.",
];

const List<String> outshadeExperience = [
  "Built UI components with Flutter from Figma designs.",
  "Integrated third-party REST APIs into production Flutter screens.",
  "Enhanced Firebase push notification features.",
];

// ─── Projects ─────────────────────────────────────────────────────────────────

const List<String> salesPilotDec = [
  "Built the Spring Boot backend — REST APIs for contacts, templates, campaigns, and send-tracking history "
      "— with Spring Data JPA persistence and Gmail/SMTP integration for one-click outreach.",
  "Orchestrated multiple AI agents (LLM APIs) to create and edit HTML email templates — one agent drafts "
      "copy, another refines layout — with live preview before send.",
  "Developed a lightweight CRM layer: an embedded in-app browser auto-captures email IDs from visited pages, "
      "organized into contact profiles with interaction history, deal stage, and follow-up status.",
  "Added an AI sales advisor that analyzes campaign performance and engagement (opens, replies, stage "
      "drop-offs) and recommends who to follow up with, when, and with which template.",
];

const List<String> droopItDec = [
  "Built real-time group chat on a Spring Boot WebSocket (STOMP) backend — message persistence via Spring "
      "Data JPA, delivery/read receipts, and multi-room support for project teams.",
  "Implemented an AI project manager that breaks a goal into tasks, assigns them by workload, and follows "
      "up for progress via scheduled jobs (Spring Scheduler) and FCM notifications.",
  "Engineered serverless P2P file transfer over WebRTC data channels (Chrome Extension, Flutter Wasm) — "
      "chunked streaming writes up to 1 TB, checkpoint-based resume, SHA-256 chunk verification.",
];

// ─── Open source ──────────────────────────────────────────────────────────────

const List<String> instaVideoDownloaderDec = [
  "Published to pub.dev — a Dart CLI that downloads Instagram Reels and Videos from a URL, installable "
      "globally with `dart pub global activate insta_video_downloader`.",
  "Built a fallback resolution chain so a failed primary endpoint retries through alternates, materially "
      "improving download success rates.",
  "Runs anywhere the Dart SDK does — Android, iOS, Linux, macOS, and Windows. MIT licensed, 140/160 pub points.",
];
