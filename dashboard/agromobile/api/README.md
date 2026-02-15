# Agri-Bot API Server

A Node.js/Express API server that provides real-time sensor data and control endpoints for the Agri-Bot mobile application.

## Features

- **Real-time Data**: WebSocket connections for live sensor updates
- **RESTful API**: Standard HTTP endpoints for data retrieval and control
- **Mock Sensors**: Simulated sensor data with realistic variations
- **Authentication**: Basic login endpoint
- **Analytics**: Historical data and performance metrics

## Installation

1. **Install Node.js** (version 14 or higher)

2. **Install dependencies**:
   ```bash
   cd api
   npm install
   ```

3. **Start the server**:
   ```bash
   npm start
   ```
   
   Or for development with auto-reload:
   ```bash
   npm run dev
   ```

4. **Server will run on**: `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login

### Sensor Data
- `GET /api/sensors/all` - Get all sensor data
- `GET /api/sensors/soil-moisture` - Soil moisture data
- `GET /api/sensors/water-level` - Water level data
- `GET /api/sensors/light-intensity` - Light sensor data

### Weather & Analytics
- `GET /api/weather` - Weather data and forecast
- `GET /api/analytics` - Analytics and performance data

### Control Actions
- `POST /api/irrigation/toggle` - Start/stop irrigation
- `POST /api/security/toggle` - Enable/disable security system
- `POST /api/camera/record` - Start/stop camera recording

### System
- `GET /api/health` - Health check endpoint

## WebSocket Events

The server provides real-time updates via Socket.IO:

- **Connection**: Client connects to receive real-time data
- **sensorUpdate**: Broadcasts updated sensor data every 3 seconds

## Data Structure

### Sensor Data Response
```json
{
  "soilMoisture": {
    "current": 65.0,
    "history": [...],
    "status": "optimal",
    "lastUpdate": "2024-01-01T12:00:00Z"
  },
  "waterLevel": {
    "current": 78.0,
    "capacity": 1000,
    "volume": 780,
    "history": [...],
    "lastUpdate": "2024-01-01T12:00:00Z"
  },
  "lightIntensity": {
    "current": 750,
    "level": "medium",
    "history": [...],
    "lastUpdate": "2024-01-01T12:00:00Z"
  },
  "irrigation": {
    "active": false,
    "flowRate": 0.0,
    "duration": 0,
    "autoMode": true,
    "schedule": [...]
  },
  "security": {
    "active": true,
    "triggered": false,
    "zones": [...],
    "alerts": [...]
  },
  "camera": {
    "online": true,
    "recording": false,
    "recordings": [...]
  },
  "weather": {
    "temperature": 24.5,
    "humidity": 68,
    "windSpeed": 12.3,
    "pressure": 1013.2,
    "forecast": [...]
  },
  "analytics": {
    "dailyWaterUsage": [...],
    "weeklyGrowth": [...],
    "monthlyYield": [...],
    "efficiency": 87.5
  }
}
```

## Environment Variables

Create a `.env` file in the api directory:

```env
PORT=3000
NODE_ENV=development
```

## Development

The server includes:
- **Mock Data Generation**: Realistic sensor data simulation
- **Real-time Updates**: Automatic data updates every 3 seconds
- **CORS Support**: Cross-origin requests enabled
- **Error Handling**: Comprehensive error responses
- **Logging**: Request and error logging

## Production Deployment

For production deployment:

1. Set `NODE_ENV=production`
2. Use a process manager like PM2
3. Set up proper logging
4. Configure reverse proxy (nginx)
5. Enable HTTPS
6. Set up monitoring

## Testing

Test the API endpoints:

```bash
# Health check
curl http://localhost:3000/api/health

# Get all sensor data
curl http://localhost:3000/api/sensors/all

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Toggle irrigation
curl -X POST http://localhost:3000/api/irrigation/toggle
```