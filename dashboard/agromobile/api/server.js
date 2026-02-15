const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Mock sensor data
let sensorData = {
  soilMoisture: {
    current: 65.0,
    history: [],
    status: 'optimal',
    lastUpdate: new Date()
  },
  waterLevel: {
    current: 78.0,
    capacity: 1000,
    volume: 780,
    history: [],
    lastUpdate: new Date()
  },
  lightIntensity: {
    current: 750,
    level: 'medium',
    history: [],
    lastUpdate: new Date()
  },
  irrigation: {
    active: false,
    flowRate: 0.0,
    duration: 0,
    autoMode: true,
    schedule: [
      { time: '06:00', enabled: true, name: 'Morning' },
      { time: '14:00', enabled: false, name: 'Afternoon' },
      { time: '18:00', enabled: true, name: 'Evening' }
    ]
  },
  security: {
    active: true,
    triggered: false,
    zones: [
      { name: 'Field Perimeter', active: true, type: 'Motion Sensors' },
      { name: 'Equipment Shed', active: true, type: 'Door Sensor' },
      { name: 'Water Tank Area', active: true, type: 'Camera + Motion' },
      { name: 'Main Gate', active: false, type: 'Access Control' }
    ],
    alerts: []
  },
  camera: {
    online: true,
    recording: false,
    recordings: [
      { name: 'Morning_Inspection_2024.mp4', time: '2 hours ago', size: '45 MB' },
      { name: 'Irrigation_Session_2024.mp4', time: '1 day ago', size: '128 MB' },
      { name: 'Weekly_Growth_2024.mp4', time: '3 days ago', size: '256 MB' }
    ]
  },
  weather: {
    temperature: 24.5,
    humidity: 68,
    windSpeed: 12.3,
    pressure: 1013.2,
    forecast: []
  },
  analytics: {
    dailyWaterUsage: [],
    weeklyGrowth: [],
    monthlyYield: [],
    efficiency: 87.5
  }
};

// Initialize historical data
function initializeHistoricalData() {
  const now = new Date();
  
  // Generate 24 hours of historical data
  for (let i = 23; i >= 0; i--) {
    const timestamp = new Date(now.getTime() - (i * 60 * 60 * 1000));
    
    sensorData.soilMoisture.history.push({
      timestamp,
      value: 50 + Math.random() * 40
    });
    
    sensorData.waterLevel.history.push({
      timestamp,
      value: 60 + Math.random() * 35
    });
    
    sensorData.lightIntensity.history.push({
      timestamp,
      value: Math.random() * 1200
    });
  }

  // Generate weekly analytics
  for (let i = 6; i >= 0; i--) {
    const date = new Date(now.getTime() - (i * 24 * 60 * 60 * 1000));
    
    sensorData.analytics.dailyWaterUsage.push({
      date: date.toISOString().split('T')[0],
      usage: 80 + Math.random() * 60
    });
    
    sensorData.analytics.weeklyGrowth.push({
      date: date.toISOString().split('T')[0],
      growth: Math.random() * 5
    });
  }

  // Generate weather forecast
  for (let i = 0; i < 5; i++) {
    const date = new Date(now.getTime() + (i * 24 * 60 * 60 * 1000));
    sensorData.weather.forecast.push({
      date: date.toISOString().split('T')[0],
      temperature: 20 + Math.random() * 15,
      humidity: 40 + Math.random() * 40,
      condition: ['sunny', 'cloudy', 'rainy'][Math.floor(Math.random() * 3)]
    });
  }
}

// Simulate real-time data updates
function simulateRealTimeData() {
  setInterval(() => {
    // Update soil moisture
    sensorData.soilMoisture.current += (Math.random() - 0.5) * 4;
    sensorData.soilMoisture.current = Math.max(0, Math.min(100, sensorData.soilMoisture.current));
    sensorData.soilMoisture.lastUpdate = new Date();
    
    // Update water level
    sensorData.waterLevel.current += (Math.random() - 0.5) * 2;
    sensorData.waterLevel.current = Math.max(0, Math.min(100, sensorData.waterLevel.current));
    sensorData.waterLevel.volume = (sensorData.waterLevel.current / 100) * sensorData.waterLevel.capacity;
    sensorData.waterLevel.lastUpdate = new Date();
    
    // Update light intensity
    sensorData.lightIntensity.current += (Math.random() - 0.5) * 100;
    sensorData.lightIntensity.current = Math.max(0, Math.min(1500, sensorData.lightIntensity.current));
    sensorData.lightIntensity.level = sensorData.lightIntensity.current < 200 ? 'low' : 
                                     sensorData.lightIntensity.current < 800 ? 'medium' : 'high';
    sensorData.lightIntensity.lastUpdate = new Date();
    
    // Update weather
    sensorData.weather.temperature += (Math.random() - 0.5) * 2;
    sensorData.weather.humidity += (Math.random() - 0.5) * 5;
    sensorData.weather.windSpeed += (Math.random() - 0.5) * 3;
    
    // Emit real-time updates
    io.emit('sensorUpdate', sensorData);
  }, 3000);
}

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

// Authentication
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  
  // Mock authentication
  if (username && password) {
    res.json({
      success: true,
      token: 'mock-jwt-token',
      user: {
        id: 1,
        username,
        role: 'admin'
      }
    });
  } else {
    res.status(401).json({ success: false, message: 'Invalid credentials' });
  }
});

// Sensor data endpoints
app.get('/api/sensors/all', (req, res) => {
  res.json(sensorData);
});

app.get('/api/sensors/soil-moisture', (req, res) => {
  res.json(sensorData.soilMoisture);
});

app.get('/api/sensors/water-level', (req, res) => {
  res.json(sensorData.waterLevel);
});

app.get('/api/sensors/light-intensity', (req, res) => {
  res.json(sensorData.lightIntensity);
});

app.get('/api/weather', (req, res) => {
  res.json(sensorData.weather);
});

app.get('/api/analytics', (req, res) => {
  res.json(sensorData.analytics);
});

// Control endpoints
app.post('/api/irrigation/toggle', (req, res) => {
  sensorData.irrigation.active = !sensorData.irrigation.active;
  sensorData.irrigation.flowRate = sensorData.irrigation.active ? 2.5 : 0;
  
  res.json({
    success: true,
    irrigation: sensorData.irrigation
  });
});

app.post('/api/security/toggle', (req, res) => {
  sensorData.security.active = !sensorData.security.active;
  
  res.json({
    success: true,
    security: sensorData.security
  });
});

app.post('/api/camera/record', (req, res) => {
  sensorData.camera.recording = !sensorData.camera.recording;
  
  res.json({
    success: true,
    camera: sensorData.camera
  });
});

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  // Send initial data
  socket.emit('sensorUpdate', sensorData);
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Initialize and start server
initializeHistoricalData();
simulateRealTimeData();

server.listen(PORT, () => {
  console.log(`Agri-Bot API server running on port ${PORT}`);
});

module.exports = app;