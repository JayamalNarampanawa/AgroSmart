# 🌱 Agri-Bot Mobile Application

A comprehensive Flutter mobile application for monitoring and controlling an agricultural assistant robot system with real-time API integration, advanced analytics, and beautiful UI/UX.

## ✨ Features

### 🔐 Authentication
- **Modern Login Screen**: Beautiful gradient design with Inter font
- **API Integration**: Real authentication with JWT tokens
- **Animated UI**: Smooth transitions and loading states

### 📊 Enhanced Dashboard
- **Real-time Monitoring**: Live WebSocket updates from API
- **Status Cards**: Interactive cards with color-coded alerts
- **Quick Actions**: One-tap controls for critical functions
- **System Health**: Comprehensive component status monitoring

### 💧 Advanced Soil Monitoring
- **Circular Progress Indicators**: Beautiful animated gauges
- **Historical Charts**: Syncfusion charts with 24-hour data
- **Smart Alerts**: Intelligent irrigation recommendations
- **Trend Analysis**: Growth pattern recognition

### 🚿 Smart Irrigation Control
- **Auto/Manual Modes**: AI-driven and manual control options
- **Flow Monitoring**: Real-time water flow with live graphs
- **Schedule Management**: Advanced scheduling with weather integration
- **Efficiency Tracking**: Water usage optimization metrics

### 🪣 Water Level Management
- **3D Tank Visualization**: Realistic water tank display
- **Multi-level Alerts**: Critical, low, and optimal thresholds
- **Usage Analytics**: Daily and weekly consumption patterns
- **Predictive Refill**: Smart refill scheduling

### ☀️ Light Detection & Weather
- **Real-time Lux Monitoring**: Professional light sensor data
- **Weather Integration**: 5-day forecast with agricultural insights
- **Growth Optimization**: Light-based growth recommendations
- **Environmental Analytics**: Comprehensive environmental tracking

### 📹 Camera & Security
- **Live Feed Simulation**: Professional camera interface
- **Recording Management**: Video storage and playback
- **Security Zones**: Multi-zone monitoring system
- **Alert Management**: Real-time security notifications

### 📈 Advanced Analytics Dashboard
- **Water Usage Analytics**: Daily, weekly, monthly trends
- **Growth Rate Tracking**: Plant growth monitoring
- **Performance Metrics**: System efficiency analysis
- **Predictive Analytics**: AI-driven insights and recommendations

### 🌤️ Weather Station
- **Beautiful Weather UI**: Gradient backgrounds and animations
- **5-Day Forecast**: Detailed weather predictions
- **Agricultural Insights**: Crop-specific recommendations
- **Environmental Conditions**: Comprehensive weather data

## 🛠 Technical Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.10+
- **Language**: Dart
- **UI Library**: Material Design 3
- **Typography**: Inter Font Family
- **Charts**: Syncfusion Flutter Charts & FL Chart
- **Animations**: Flutter Staggered Animations
- **HTTP Client**: Dio with interceptors
- **State Management**: Provider/Riverpod ready

### Backend (Node.js API)
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Real-time**: Socket.IO WebSockets
- **Data**: Mock sensor simulation
- **Authentication**: JWT tokens
- **CORS**: Cross-origin support

### Design System
- **Font**: Inter (Google Fonts)
- **Theme**: Dark mode optimized
- **Colors**: Agricultural color palette
- **Icons**: Material Design Icons
- **Animations**: Smooth transitions
- **Responsive**: Mobile-first design

## 📁 Project Structure

```
agri-bot/
├── lib/
│   ├── main.dart                      # App entry point with theme
│   ├── services/
│   │   └── api_service.dart           # API client with models
│   └── screens/
│       ├── login_screen.dart          # Authentication
│       ├── main_navigation.dart       # Enhanced navigation
│       ├── dashboard_screen.dart      # Real-time dashboard
│       ├── soil_moisture_screen.dart  # Soil monitoring
│       ├── irrigation_control_screen.dart # Irrigation management
│       ├── water_level_screen.dart    # Water tank monitoring
│       ├── light_detector_screen.dart # Light sensor data
│       ├── camera_feed_screen.dart    # Video monitoring
│       ├── security_alarm_screen.dart # Security system
│       ├── analytics_screen.dart      # Advanced analytics
│       └── weather_screen.dart        # Weather station
├── api/
│   ├── server.js                      # Express API server
│   ├── package.json                   # Node.js dependencies
│   └── README.md                      # API documentation
├── assets/
│   ├── fonts/                         # Inter font files
│   ├── images/                        # App images
│   └── animations/                    # Lottie animations
├── setup.bat                          # Windows setup script
├── setup.sh                           # Unix setup script
└── README.md                          # This file
```

## 🚀 Quick Start

### Automated Setup

**Windows:**
```bash
setup.bat
```

**macOS/Linux:**
```bash
chmod +x setup.sh
./setup.sh
```

### Manual Setup

1. **Install Prerequisites**
   - Flutter SDK 3.10+
   - Node.js 18+
   - Android Studio/VS Code

2. **Setup API Server**
   ```bash
   cd api
   npm install
   npm start
   ```

3. **Setup Flutter App**
   ```bash
   flutter pub get
   flutter run
   ```

## 📱 App Features

### 🎨 Beautiful UI/UX
- **Inter Font**: Professional typography throughout
- **Dark Theme**: Optimized for field conditions
- **Smooth Animations**: Staggered animations and transitions
- **Color-coded Status**: Intuitive visual feedback
- **Responsive Design**: Works on all screen sizes

### 📊 Advanced Charts & Graphs
- **Circular Progress**: Animated gauge charts
- **Line Charts**: Historical data visualization
- **Bar Charts**: Usage and performance metrics
- **Doughnut Charts**: Efficiency and distribution
- **Real-time Updates**: Live data streaming

### 🔄 Real-time Features
- **WebSocket Integration**: Live sensor updates
- **Auto-refresh**: Periodic data synchronization
- **Push Notifications**: Critical alerts (ready)
- **Offline Support**: Cached data access (ready)

### 🎯 Smart Features
- **Predictive Analytics**: AI-driven insights
- **Weather Integration**: Agricultural recommendations
- **Efficiency Optimization**: Resource usage optimization
- **Alert Management**: Intelligent notification system

## 🌐 API Integration

### Endpoints
- `GET /api/sensors/all` - All sensor data
- `GET /api/weather` - Weather and forecast
- `GET /api/analytics` - Performance analytics
- `POST /api/irrigation/toggle` - Control irrigation
- `POST /api/security/toggle` - Security management

### Real-time Updates
- WebSocket connection for live data
- 3-second update intervals
- Automatic reconnection
- Error handling and fallbacks

## 📈 Analytics & Insights

### Water Management
- Daily usage tracking
- Efficiency calculations
- Waste reduction metrics
- Predictive maintenance

### Growth Monitoring
- Plant growth rates
- Environmental correlation
- Yield predictions
- Optimization recommendations

### System Performance
- Uptime monitoring
- Energy efficiency
- Component health
- Maintenance scheduling

## 🎨 Design Highlights

### Typography
- **Primary**: Inter font family
- **Weights**: Regular, Medium, SemiBold, Bold
- **Sizes**: Responsive scale from 10px to 48px

### Color Palette
- **Primary**: Green (#4CAF50)
- **Secondary**: Blue (#2196F3)
- **Accent**: Orange (#FF9800)
- **Background**: Dark (#0F0F0F)
- **Surface**: Dark Grey (#1E1E1E)

### Animations
- **Page Transitions**: Smooth slide animations
- **Loading States**: Shimmer effects
- **Data Updates**: Fade transitions
- **User Interactions**: Ripple effects

## 🔧 Development

### Adding New Features
1. Create screen in `lib/screens/`
2. Add to navigation in `main_navigation.dart`
3. Update API service if needed
4. Add corresponding API endpoints

### Customization
- Modify theme in `main.dart`
- Update colors in theme configuration
- Add new chart types in analytics
- Extend API with new endpoints

## 🚀 Production Deployment

### Flutter App
- Build release APK/IPA
- Configure app signing
- Set up app store deployment
- Enable production API endpoints

### API Server
- Deploy to cloud platform
- Set up database integration
- Configure environment variables
- Enable HTTPS and security

## 📝 License

This project is developed for educational and demonstration purposes. Feel free to use and modify for your agricultural projects.

---

**Built with ❤️ for modern agriculture**