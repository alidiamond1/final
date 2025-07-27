# Somali Dataset Repository Platform

A comprehensive multi-platform system for managing, uploading, and downloading Somali language datasets, featuring separate platforms for administrators, users, and backend services.

## Project Architecture

```
├── somali-dataset/    # Admin Web Platform
├── mymobileapp/       # User Mobile Application
└── backend/          # Central Backend Server
```

## Platform Components

### 1. Admin Web Platform (`/somali-dataset`)
A web-based administration system for dataset management and user administration.

**Tech Stack:**
- React.js with Vite
- Material UI components
- Tailwind CSS for styling

**Key Features:**
- Dataset Management:
  - Upload new datasets with metadata
  - Browse and search existing datasets
  - Edit dataset information
  - Delete outdated datasets
  - Track dataset statistics and downloads
- User Administration:
  - Manage user accounts and permissions
  - Monitor user activity
  - Control access to sensitive datasets
- Dashboard Analytics:
  - Dataset usage statistics
  - User engagement metrics
  - System performance monitoring

**Setup for Admin Platform:**
```bash
cd somali-dataset
npm install
npm run dev
```

### 2. User Mobile Application (`/mymobileapp`)
A Flutter-based mobile application for accessing and downloading datasets.

**Tech Stack:**
- Flutter/Dart
- Provider for state management
- Flutter Downloader for file management

**User Features:**
- Dataset Access:
  - Browse available datasets
  - Search and filter datasets
  - View dataset details and metadata
  - Download datasets for offline use
- User Account Management:
  - Create and manage user profile
  - Track download history
  - Save favorite datasets
- Mobile-Optimized Experience:
  - Responsive UI for various device sizes
  - Background downloads
  - Offline functionality for downloaded datasets

**Setup for Mobile App:**
```bash
cd mymobileapp
flutter pub get
flutter run
```

### 3. Backend Server (`/backend`)
RESTful API server handling dataset operations and user authentication.

**Tech Stack:**
- Node.js with Express.js
- MongoDB for database
- JWT for authentication
- Multer for file uploads

**API Features:**
```
backend/
├── controllers/    # Request handlers
│   ├── datasetController.js  # Dataset operations
│   └── userController.js     # User management
├── middleware/     # Request processors
│   └── authMiddleware.js     # Authentication
├── model/         # Data schemas
├── routes/        # API endpoints
│   ├── datasetRoutes.js      # Dataset endpoints
│   └── userRoute.js          # User endpoints
└── uploads/       # File storage for datasets
```

**Key Endpoints:**
- Dataset Management:
  - `POST /api/datasets` - Upload new dataset
  - `GET /api/datasets` - List all datasets
  - `GET /api/datasets/:id` - Get dataset details
  - `GET /api/datasets/:id/download` - Download dataset
  - `PUT /api/datasets/:id` - Update dataset
  - `DELETE /api/datasets/:id` - Delete dataset
- User Operations:
  - Authentication endpoints
  - User profile management
  - Permission controls

**Setup for Backend:**
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

2. Set up each platform:
   - Start with the backend server
   - Configure the admin web platform
   - Deploy the mobile application

3. Environment Configuration:
   - Backend: Create `.env` with database connection, JWT secret, and storage paths
   - Admin: Configure API endpoints in the environment settings
   - Mobile: Set up API connection in the app configuration

## Development Requirements

- Admin Platform:
  - Node.js (v14 or higher)
  - npm or yarn
  - Modern web browser
  
- Mobile App:
  - Flutter SDK
  - Android Studio / Xcode
  - Physical or virtual mobile device
  
- Backend:
  - Node.js runtime
  - MongoDB
  - Storage space for dataset files

## Data Security

- Access Control:
  - Role-based permissions (admin/user)
  - JWT authentication for API access
  - Secure download links

- File Management:
  - Secure file storage
  - Validation of uploaded files
  - Backup systems for dataset preservation

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 