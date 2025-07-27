# Somali Language Learning Platform

This project is a comprehensive language learning platform focused on the Somali language. It consists of three main components: a dataset management system, a mobile application, and a backend server.

## Project Structure

```
├── somali-dataset/    # Dataset Management System
├── mymobileapp/       # Flutter Mobile Application
└── backend/          # Node.js Backend Server
```

## Components

### 1. Somali Dataset Management System (`/somali-dataset`)
A web-based system for managing Somali language datasets.

**Tech Stack:**
- React.js with Vite
- Tailwind CSS
- Node.js

**Key Features:**
- Dataset visualization and management
- Data entry and validation tools
- Interactive UI for dataset manipulation

**Setup:**
```bash
cd somali-dataset
npm install
npm run dev
```

### 2. Mobile Application (`/mymobileapp`)
A cross-platform mobile application built with Flutter.

**Tech Stack:**
- Flutter/Dart
- Multiple platform support (iOS, Android, Web)

**Key Features:**
- Cross-platform compatibility
- Interactive learning interface
- Asset management for language resources

**Setup:**
```bash
cd mymobileapp
flutter pub get
flutter run
```

### 3. Backend Server (`/backend`)
A Node.js server handling API requests and data management.

**Tech Stack:**
- Node.js
- Express.js
- MongoDB (assumed based on structure)

**Key Directory Structure:**
```
backend/
├── config/         # Configuration files
├── controllers/    # Request handlers
├── middleware/     # Custom middleware
├── model/         # Data models
├── routes/        # API routes
└── uploads/       # File upload directory
```

**Setup:**
```bash
cd backend
npm install
npm start
```

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/alidiamond1/final.git
```

2. Set up each component following their respective setup instructions above.

3. Configure environment variables:
   - Create `.env` files in both backend and dataset directories
   - Set up necessary database connections and API keys

## Development Requirements

- Node.js (v14 or higher)
- Flutter SDK
- MongoDB
- IDE with Flutter and Dart support (VS Code recommended)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 