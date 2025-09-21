# AquaSense: Smart Water Quality Monitoring & Prediction App

<p align="center">
  <img src="./assets/main_logo_circle.png" alt="AquaSense Logo" width="150" height="150">
  <br>
  <span style="font-size: 14px; color: gray;"><b>This app is designed to operate on live streaming sensor data</b></span>
</p>

## 🎬 Full Demo

<p align="center">
  <a href="https://youtube.com/watch?v=your-demo-video-id">
    <img src="./images/miscellaneous/full_demo.gif" alt="AquaSense Full Demo" width="300">
  </a>
  <br>
  <span style="font-size: 14px; color: gray;"><b>👆 Click to watch the complete demo on YouTube</b></span>
</p>

---

## 📋 Overview

**AquaSense** is a comprehensive full-stack IoT solution that combines real-time water quality monitoring with machine learning-powered predictions. The system integrates hardware sensors, AWS IoT infrastructure, and a Flutter mobile application to provide instant water potability assessments with an intuitive, user-friendly interface.

The platform is designed for environmental monitoring, water quality management, and educational purposes, featuring real-time data visualization, trend analysis, and comprehensive logging capabilities.

---

## 🏗️ System Architecture

### Core Components

**AquaSense** consists of three integrated layers:

1. **ML Model Training & Optimization**
   - XGBoost-based water quality prediction model
   - Feature engineering and hyperparameter tuning
   - Model persistence with joblib serialization

2. **Backend Infrastructure** 
   - FastAPI REST API for model inference
   - PostgreSQL database hosted on Railway
   - Real-time logging and data persistence

3. **Flutter Mobile Application**
   - Cross-platform iOS/Android compatibility
   - Real-time AWS MQTT integration
   - Interactive data visualization and user interface

---

## ✨ Key Features

### 🌊 Real-time Monitoring
- **5 Water Quality Parameters**: pH, TDS, Turbidity, Temperature, Dissolved Oxygen
- **AWS IoT Integration**: Secure MQTT communication with hardware sensors
- **Live Data Updates**: Instant display of sensor readings with trend indicators

### 🤖 AI-Powered Predictions
- **Machine Learning Classification**: XGBoost model predicts water potability
- **Instant Results**: <img src="./assets/leaf.svg" width="16" height="16"> **Potable** or <img src="./assets/block.svg" width="16" height="16"> **Not Potable** classifications
- **Error Handling**: <img src="./assets/danger.svg" width="16" height="16"> Graceful error management and user feedback

### 📊 Interactive Visualizations
- **Dynamic Graphs**: Scrollable, zoomable time-series data
- **Expandable Tiles**: Detailed parameter analysis with historical trends
- **Real-time Updates**: Live chart updates as new data arrives

### 📱 User Experience
- **Intuitive Interface**: Clean, modern material design
- **Responsive Layout**: Optimized for various screen sizes
- **Accessibility**: High contrast colors and clear navigation

---

## 🎯 Application Features

### 1. Splash Screen & App Launch

<p align="center">
  <img src="./images/1_intro_splash_screen_and_start_button/App_Launch_&_Splash_Screen.gif" alt="App Launch & Splash Screen" width="250">
  <br>
  <span style="font-size: 12px; color: gray;"><b>Animated splash screen with VIT Chennai branding</b></span>
</p>

**Features:**
- Elegant Lottie animation background
- VIT Chennai university logo integration
- Smooth transition to main interface
- Interactive START button with haptic feedback

### 2. Home Screen & Sensor Dashboard

<div align="center">
  <img src="./images/2_home_screen_sensor_tiles_and_core_actions/Main_Home_Screen.png" alt="Main Home Screen" width="250" style="margin: 0 10px;">
  <img src="./images/2_home_screen_sensor_tiles_and_core_actions/Dynamic_Tile_&_Trend_Line_Updates.gif" alt="Dynamic Updates" width="250" style="margin: 0 10px;">
  <br>
  <span style="font-size: 12px; color: gray;"><b>Main dashboard with real-time sensor data and trend visualization</b></span>
</div>

**Core Functionality:**
- **5 Parameter Tiles**: pH, TDS, Turbidity, Temperature, Dissolved Oxygen
- **Real-time Updates**: Live sensor data via AWS MQTT
- **Trend Indicators**: Mini-charts showing parameter history
- **Central Predict Button**: Triggers ML inference workflow

### 3. Prediction Results & Classification

<div align="center">
  <img src="./images/3_result_tiles/Full_Prediction_Cycle_to_Potable.gif" alt="Potable Prediction" width="250" style="margin: 0 10px;">
  <img src="./images/3_result_tiles/Prediction_Cycle_to_Not_Potable.gif" alt="Not Potable Prediction" width="250" style="margin: 0 10px;">
  <br>
  <span style="font-size: 12px; color: gray;"><b>AI-powered water quality predictions with visual feedback</b></span>
</div>

**Prediction System:**
- **Loading Animation**: Smooth prediction processing indicator
- **Color-coded Results**: Green for potable, red for not potable, orange for errors
- **Instant Feedback**: Results appear immediately after inference
- **Result Logging**: All predictions stored for historical analysis

### 4. Interactive Data Visualization

<div align="center">
  <img src="./images/4_maximizingminimizing_sensor_tiles_and_scrollable_graphs/Maximizing_Tile_to_View_Graph.gif" alt="Maximizing Tiles" width="200" style="margin: 0 5px;">
  <img src="./images/4_maximizingminimizing_sensor_tiles_and_scrollable_graphs/Switching_Between_Different_Parameter_Graphs.gif" alt="Parameter Switching" width="200" style="margin: 0 5px;">
  <img src="./images/4_maximizingminimizing_sensor_tiles_and_scrollable_graphs/Interacting_with_Graph_Data.gif" alt="Graph Interaction" width="200" style="margin: 0 5px;">
  <br>
  <span style="font-size: 12px; color: gray;"><b>Advanced graph interactions: maximize, zoom, pan, and switch between parameters</b></span>
</div>

**Graph Features:**
- **Expandable Views**: Tap any tile to view detailed historical data
- **Interactive Charts**: Pinch to zoom, pan to scroll through time
- **Multi-parameter Analysis**: Switch between different sensor parameters
- **Timestamp Tooltips**: Precise data point information on tap

### 5. Navigation & Menu System

<div align="center">
  <img src="./images/5_sidebar_navigation/Opening_the_Sidebar.gif" alt="Opening Sidebar" width="250" style="margin: 0 10px;">
  <img src="./images/5_sidebar_navigation/Sidebar_Menu.png" alt="Sidebar Menu" width="250" style="margin: 0 10px;">
  <br>
  <span style="font-size: 12px; color: gray;"><b>Comprehensive sidebar navigation with connection status and app info</b></span>
</div>

**Menu Options:**
- **Log Management**: View, download, share session data
- **Connection Status**: Real-time AWS and backend connectivity indicators
- **App Information**: Version details and developer credits
- **External Links**: Direct access to institutional websites

### 6. Comprehensive Log Management

<div align="center">
  <img src="./images/6_log_management_actions/Main_Log_List_View.png" alt="Log List" width="180" style="margin: 0 5px;">
  <img src="./images/6_log_management_actions/Expanded_Log_with_Copy_Option.png" alt="Expanded Log" width="180" style="margin: 0 5px;">
  <img src="./images/6_log_management_actions/Accessing_and_Filtering_Logs.gif" alt="Log Filtering" width="180" style="margin: 0 5px;">
  <br>
  <span style="font-size: 12px; color: gray;"><b>Advanced log management with filtering, sharing, and detailed view options</b></span>
</div>

<div align="center">
  <img src="./images/6_log_management_actions/Downloading_Logs.gif" alt="Download Logs" width="200" style="margin: 0 10px;">
  <img src="./images/6_log_management_actions/Sharing_Logs.gif" alt="Share Logs" width="200" style="margin: 0 10px;">
  <img src="./images/6_log_management_actions/Clearing_Logs.gif" alt="Clear Logs" width="200" style="margin: 0 10px;">
  <br>
  <span style="font-size: 12px; color: gray;"><b>Export, share, and manage prediction logs with multiple format options</b></span>
</div>

**Log Features:**
- **Smart Filtering**: <img src="./assets/filter.svg" width="14" height="14"> Filter by result type (All, Potable, Not Potable, Error)
- **Data Export**: <img src="./assets/clear.svg" width="14" height="14"> Download logs as JSON files
- **Native Sharing**: Share logs via email, messaging, cloud storage
- **Expandable Entries**: Detailed view of individual predictions with copy functionality

### 7. Convenience & Accessibility

<div align="center">
  <img src="./images/7_ease_of_access_and_convenience_features/External_Link_from_Branding.gif" alt="External Links" width="250">
  <br>
  <span style="font-size: 12px; color: gray;"><b>Quick access to institutional websites through branding elements</b></span>
</div>

**User Experience Enhancements:**
- **External Integration**: Tap university logo to visit official website
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Error Handling**: Comprehensive error states with clear user feedback
- **Performance Optimization**: Smooth animations and efficient data handling

---

## ⚙️ Technical Implementation

### Backend Architecture

| Component                    | Technology        |
|-----------------------------|-------------------|
| **API Framework**           | FastAPI           |
| **Database**                | PostgreSQL        |
| **Hosting Platform**        | Railway           |
| **ML Model**                | XGBoost           |
| **Model Serialization**     | joblib            |

### Mobile Application

| Component                    | Technology        |
|-----------------------------|-------------------|
| **Framework**               | Flutter/Dart      |
| **State Management**        | StatefulWidget    |
| **Charting Library**        | FL Chart          |
| **IoT Communication**       | MQTT Client       |
| **File Operations**         | File Picker       |

### IoT Infrastructure

| Component                    | Technology        |
|-----------------------------|-------------------|
| **Cloud Platform**          | AWS IoT Core      |
| **Communication Protocol**  | MQTT over TLS     |
| **Security**                | X.509 Certificates|
| **Data Format**             | JSON              |

---

## 📊 Model Performance

| Metric                      | Value             |
|-----------------------------|-------------------|
| **Algorithm**               | XGBoost Classifier|
| **Training Accuracy**       | ~94%              |
| **Cross-validation Score**  | ~92%              |
| **Inference Time**          | <100ms            |
| **Model Size**              | ~500KB            |

**Features Used:**
- pH level (optimal range: 6.5-8.5)
- Total Dissolved Solids (TDS)
- Turbidity (water clarity)
- Temperature
- Dissolved Oxygen content

---

## 🔧 Installation & Setup

### Prerequisites

```bash
# Flutter SDK (latest stable)
flutter --version

# Python 3.8+
python --version

# PostgreSQL database access
```

### Backend Setup

```bash
# Navigate to backend directory
cd backend/

# Install Python dependencies
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="your-postgresql-url"

# Run development server
uvicorn app.main:app --reload
```

### Mobile App Setup

```bash
# Install Flutter dependencies
flutter pub get

# Configure AWS IoT certificates
# Add your certificates to assets/aws/

# Run on device/simulator
flutter run
```

### Database Setup

```sql
-- PostgreSQL table creation
CREATE TABLE IF NOT EXISTS logs (
    timestamp TEXT,
    inputs JSONB,
    result TEXT
);
```

---

## 📁 Repository Structure

```
📂 AquaSense/
│
├── 📁 assets/              # App resources and icons
│   ├── 📁 fonts/          # Custom typography
│   ├── 🎨 *.svg           # Vector icons for UI
│   ├── 🖼️ *.png           # Logos and branding
│   └── 🎬 *.json          # Lottie animations
│
├── 📁 backend/             # FastAPI backend service
│   ├── 📁 app/            # Application modules
│   │   ├── 🐍 db.py       # Database operations
│   │   ├── 🐍 main.py     # FastAPI application
│   │   ├── 🐍 model.py    # ML model inference
│   │   └── 🐍 logs.py     # Log management API
│   ├── 📁 model/          # Trained ML models
│   └── 📄 requirements.txt # Python dependencies
│
├── 📁 lib/                # Flutter application code
│   ├── 📁 screens/        # App screens/pages
│   ├── 📁 widgets/        # Reusable UI components
│   └── 🎯 main.dart      # App entry point
│
├── 📁 images/             # Documentation screenshots
└── 📄 README.md          # Project documentation
```

---
