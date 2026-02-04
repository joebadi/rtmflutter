---
description: Develop VPS backend and Flutter app simultaneously
---

# VPS + Flutter Development Workflow

This workflow guides you through developing the RTM backend on your Contabo VPS while simultaneously developing and testing the Flutter mobile app locally.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Setup                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  LOCAL MACHINE (Windows)                                     │
│  ├─ Flutter App (c:\Users\Joeey\Documents\RTM\apps\rtm_app) │
│  │  └─ Points to VPS API via tunnel/public IP               │
│  │                                                            │
│  └─ VS Code Remote SSH → VPS Development                    │
│                                                               │
│  CONTABO VPS (Ubuntu)                                        │
│  ├─ Backend API (Node.js/Express)                           │
│  │  └─ /home/joeey/rtmapi.e-clicks.net/                     │
│  │     ├─ PostgreSQL Database                               │
│  │     ├─ JWT Authentication                                │
│  │     └─ Socket.io for real-time features                  │
│  │                                                            │
│  └─ Admin Dashboard (Next.js)                               │
│     └─ /home/joeey/rtmadmin.e-clicks.net/                   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Set Up Environment Configuration

Create environment-specific configuration files for the Flutter app to easily switch between local, VPS development, and production environments.

### 1.1 Create environment configuration file

Create `mobile/lib/config/environment.dart`:

```dart
enum Environment { local, development, production }

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;
  
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }
  
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.local:
        return 'http://192.168.1.89:4000/api'; // Your local dev server
      case Environment.development:
        return 'https://rtmapi.e-clicks.net/api'; // VPS development
      case Environment.production:
        return 'https://rtmapi.e-clicks.net/api'; // Production (same for now)
    }
  }
  
  static String get socketUrl {
    switch (_currentEnvironment) {
      case Environment.local:
        return 'http://192.168.1.89:4000';
      case Environment.development:
        return 'https://rtmapi.e-clicks.net';
      case Environment.production:
        return 'https://rtmapi.e-clicks.net';
    }
  }
  
  static bool get isProduction => _currentEnvironment == Environment.production;
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isLocal => _currentEnvironment == Environment.local;
}
```

### 1.2 Update auth_service.dart to use environment config

Update the baseUrl to use the environment configuration instead of hardcoded values.

## Step 2: Connect to VPS via VS Code Remote SSH

### 2.1 Open VS Code Remote SSH connection

1. Open a new VS Code window
2. Press `F1` or `Ctrl+Shift+P`
3. Type "Remote-SSH: Connect to Host"
4. Select your Contabo VPS (should be configured from previous session)
5. Once connected, open folder: `/home/joeey/rtmapi.e-clicks.net/`

### 2.2 Verify VPS connection

In the VS Code terminal on VPS, run:
```bash
pwd
# Should output: /home/joeey/rtmapi.e-clicks.net
```

## Step 3: Set Up Backend API on VPS

### 3.1 Initialize Node.js project structure

```bash
cd /home/joeey/rtmapi.e-clicks.net
mkdir -p src/{controllers,models,routes,middleware,services,config,utils}
npm init -y
```

### 3.2 Install backend dependencies

```bash
npm install express cors dotenv pg socket.io jsonwebtoken bcryptjs
npm install -D typescript @types/node @types/express @types/cors @types/jsonwebtoken @types/bcryptjs ts-node nodemon
```

### 3.3 Initialize TypeScript configuration

```bash
npx tsc --init
```

### 3.4 Create .env file

```bash
nano .env
```

Add the following (adjust values as needed):
```env
PORT=4000
NODE_ENV=development
DATABASE_URL=postgresql://username:password@localhost:5432/rtm_db
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

### 3.5 Create basic server structure

Create `src/index.ts` with Express server, PostgreSQL connection, and Socket.io setup.

### 3.6 Start development server

```bash
npm run dev
```

The API should now be running on the VPS at port 4000.

## Step 4: Configure Nginx Reverse Proxy (if not already done)

### 4.1 Create Nginx configuration for API

```bash
sudo nano /etc/nginx/sites-available/rtmapi.e-clicks.net
```

Add:
```nginx
server {
    listen 80;
    server_name rtmapi.e-clicks.net;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 4.2 Enable site and restart Nginx

```bash
sudo ln -s /etc/nginx/sites-available/rtmapi.e-clicks.net /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 4.3 Set up SSL with Let's Encrypt

```bash
sudo certbot --nginx -d rtmapi.e-clicks.net
```

## Step 5: Develop Flutter App to Connect to VPS

### 5.1 Update Flutter app to use VPS API

In your local Flutter project, update the environment to development mode in `main.dart`:

```dart
import 'config/environment.dart';

void main() {
  // Set to development to use VPS API
  EnvironmentConfig.setEnvironment(Environment.development);
  
  runApp(MyApp());
}
```

### 5.2 Test API connectivity

Run the Flutter app and try to login/register. The app should now communicate with your VPS backend.

## Step 6: Development Workflow

### 6.1 Backend Development (on VPS via VS Code Remote SSH)

1. Make changes to backend code in VS Code (connected to VPS)
2. Save files - nodemon will auto-restart the server
3. Test API endpoints using:
   - Flutter app
   - Postman/Thunder Client
   - curl commands

### 6.2 Flutter Development (local)

1. Make changes to Flutter code locally
2. Hot reload to see changes immediately
3. The app communicates with VPS backend in real-time

### 6.3 Switching between local and VPS backend

**To use local backend** (for offline development):
```dart
// In main.dart
EnvironmentConfig.setEnvironment(Environment.local);
```

**To use VPS backend** (for testing with real server):
```dart
// In main.dart
EnvironmentConfig.setEnvironment(Environment.development);
```

## Step 7: Make Flutter App Interactive (Beyond Demo Mode)

### 7.1 Implement real authentication flow

Update `auth_provider.dart` and `auth_service.dart` to handle real API responses:
- Store JWT tokens securely
- Handle token refresh
- Implement proper error handling
- Add loading states

### 7.2 Implement real data fetching

Create services for:
- User profile management (`profile_service.dart`)
- Match discovery (`match_service.dart`)
- Messaging (`message_service.dart`)
- Real-time updates with Socket.io

### 7.3 Replace mock data with API calls

Update all screens to:
- Fetch data from API instead of using hardcoded values
- Show loading states while fetching
- Handle errors gracefully
- Implement pull-to-refresh

### 7.4 Add state management

Use Provider to manage:
- Authentication state
- User profile data
- Match data
- Message conversations
- Real-time updates

## Step 8: Real-time Features with Socket.io

### 8.1 Set up Socket.io client in Flutter

Install dependency:
```bash
cd mobile
flutter pub add socket_io_client
```

### 8.2 Create socket service

Create `mobile/lib/services/socket_service.dart` to handle:
- Connection to VPS Socket.io server
- Real-time message delivery
- Online status updates
- Typing indicators
- Match notifications

### 8.3 Integrate with message screens

Update chat screens to use Socket.io for real-time messaging instead of polling.

## Step 9: Testing the Full Stack

### 9.1 Test authentication flow

1. Register a new user from Flutter app
2. Verify user is created in PostgreSQL database on VPS
3. Login with the new user
4. Verify JWT token is stored and used for subsequent requests

### 9.2 Test real-time features

1. Open app on two devices/emulators
2. Send messages between users
3. Verify messages appear in real-time
4. Check online status updates

### 9.3 Test profile updates

1. Update user profile from Flutter app
2. Verify changes are saved in database
3. Verify changes reflect immediately in app

## Step 10: Monitoring and Debugging

### 10.1 Backend logs (on VPS)

```bash
# View real-time logs
cd /home/joeey/rtmapi.e-clicks.net
npm run dev

# Or if using PM2:
pm2 logs rtm-api
```

### 10.2 Flutter logs (local)

```bash
cd mobile
flutter run -v
```

### 10.3 Database inspection (on VPS)

```bash
# Connect to PostgreSQL
psql -U username -d rtm_db

# View users
SELECT * FROM users;

# View messages
SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;
```

## Quick Reference Commands

### VPS Backend Commands
```bash
# Start development server
npm run dev

# View logs
npm run dev | tee logs/dev.log

# Run database migrations
npm run migrate

# Seed database
npm run seed
```

### Flutter Commands
```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Hot reload
r (in terminal while app is running)

# Hot restart
R (in terminal while app is running)

# Clean and rebuild
flutter clean && flutter pub get && flutter run
```

### Switching Environments
```dart
// Local development (offline)
EnvironmentConfig.setEnvironment(Environment.local);

// VPS development (online testing)
EnvironmentConfig.setEnvironment(Environment.development);

// Production
EnvironmentConfig.setEnvironment(Environment.production);
```

## Troubleshooting

### Issue: Flutter app can't connect to VPS

**Solution:**
1. Verify VPS API is running: `curl https://rtmapi.e-clicks.net/api/health`
2. Check Nginx configuration: `sudo nginx -t`
3. Verify SSL certificate: `sudo certbot certificates`
4. Check firewall: `sudo ufw status`

### Issue: CORS errors

**Solution:**
Update CORS configuration in backend to allow your development environment.

### Issue: Socket.io connection fails

**Solution:**
1. Verify Socket.io server is running on VPS
2. Check Nginx WebSocket proxy configuration
3. Verify client is using correct URL and protocol

### Issue: JWT token expired

**Solution:**
Implement token refresh mechanism in `auth_service.dart`.

## Next Steps

1. ✅ Set up environment configuration
2. ✅ Connect to VPS via Remote SSH
3. ✅ Initialize backend API structure
4. ✅ Configure Nginx reverse proxy
5. ✅ Update Flutter app to use VPS API
6. 🔄 Implement authentication endpoints
7. 🔄 Create user profile management
8. 🔄 Build matching system
9. 🔄 Implement real-time messaging
10. 🔄 Add premium features

---

**Last Updated:** 2026-01-19
**Environment:** Development
**Status:** Active Development
