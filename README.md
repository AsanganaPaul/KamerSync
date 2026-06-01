# KamerSync

KamerSync is a Flutter-built digital land ownership platform for Cameroon that replaces fragmented paper records for citizens, surveyors, and MINDCAF officers. It features GIS boundary drawing, blockchain verification, an AI chatbot, role-based dashboards, push notifications, and QR certificates to ensure secure, transparent management.KamerSync modernises land administration in Cameroon – a centralised, transparent platform for land registration, verification, and governance.

# KamerSync – Cameroon National Land Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Key Features

- Multi-role support: Citizen, MINDCAF Officer, Surveyor, Notary, Bank, Local Council
- Land registration wizard with form, GIS boundary drawing, and document upload
- GIS mapping: interactive OpenStreetMap/satellite tiles with polygon drawing
- Real-time verification by Land ID or owner name, with QR code certificate
- Application tracking timeline: Pending → Under Review → Approved/Rejected
- Blockchain-anchored records: SHA-256 hashes for each approved transaction (tamper-proof audit trail)
- AI chatbot powered by Google Gemini for questions on processes, documents, fees
- Push notifications for real‑time status alerts
- Role-based dashboards customised for citizens, officers, and surveyors
- Complete audit log of all system actions
- Digital certificate with QR code for every approved land parcel

## Tech Stack

- Frontend: Flutter (Dart)
- State management: Riverpod + Riverpod Generator
- Navigation: GoRouter
- Maps: Flutter Map with OpenStreetMap / ArcGIS tiles
- Backend (demo): in‑memory simulated REST API (replaceable with Node.js/PostgreSQL)
- Local storage: SharedPreferences, FlutterSecureStorage
- AI: Google Gemini via google_generative_ai
- Notifications: flutter_local_notifications + FCM ready
- File picker: file_picker
- Blockchain simulation: crypto (SHA‑256)

## Getting Started

### Prerequisites

- Flutter SDK (>=3.5.0)
- Android Studio / Xcode (for mobile emulators)
- Chrome (for web)
- Git

### Installation

1. Clone the repository  
   `git clone https://github.com/AsanganaPaul/kamer-sync.git`  
   `cd kamer-sync`
2. Get dependencies  
   `flutter pub get`
3. Run the app  
   `flutter run`  
   Choose a device (mobile emulator, Chrome, etc.).

### Environment Variables (Optional)

Create a `.env` file in the project root:

`GEMINI_API_KEY=your_google_gemini_api_key`

Without the key, the chatbot runs in demo mode with predefined responses.

## Demo Accounts

All passwords are `demo123`.

- Citizen: `citizen@kamer.cm`
- MINDCAF Officer: `officer@mindcaf.cm`
- Surveyor: `surveyor@kamer.cm`

## Docker Deployment (Web)

1. Build the web app  
   `flutter build web`
2. Create a `Dockerfile` in the project root:
3. Build the Docker image  
   `docker build -t kamer-sync .`
4. Run the container  
   `docker run -d -p 8080:80 --name kamer-sync kamer-sync`
5. Open `http://localhost:8080` in your browser.

## Project Structure

kamer-sync/
├── lib/
│ ├── core/ # Theme, router, constants
│ ├── models/ # Data models (User, LandParcel, etc.)
│ ├── providers/ # Riverpod state providers
│ ├── screens/ # All UI screens (grouped by feature)
│ ├── services/ # API, auth, notification, land service
│ └── widgets/ # Reusable UI components
├── assets/ # Images, icons, fonts, animations
├── test/ # Widget and unit tests
├── pubspec.yaml # Dependencies and assets
└── README.md

## Key Workflows

1. Citizen registers land → draws GIS boundary → uploads documents → submits.
2. Surveyor logs in → adjusts boundary on map → submits survey.
3. MINDCAF Officer reviews → approves → generates Land ID + blockchain hash.
4. Any user searches by Land ID → views ownership + QR code.
5. AI chatbot answers questions instantly.

## Contributing

Contributions are welcome – open an issue or submit a pull request.

## License

MIT License – see the LICENSE file for details.

## Acknowledgements

- MINDCAF (Ministry of State Property, Surveys and Land Tenure, Cameroon)
- Google Gemini for AI capabilities
- OpenStreetMap for map tiles
- Flutter and Dart communities
