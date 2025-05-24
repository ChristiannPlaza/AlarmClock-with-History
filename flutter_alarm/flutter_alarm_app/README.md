# Flutter Alarm App

## Overview
The Flutter Alarm App is a mobile application that allows users to set and manage alarms. It features a clean and modular architecture, making it easy to maintain and extend. The app includes a user-friendly interface for viewing and toggling alarms.

## Features
- List of alarms with customizable time settings.
- Toggle switches for enabling or disabling each alarm.
- Modular architecture separating concerns into different layers (data, domain, presentation).
- Easy navigation between different features of the app.

## Project Structure
```
flutter_alarm_app
├── lib
│   ├── main.dart                # Entry point of the application
│   ├── core
│   │   └── utils.dart           # Utility functions
│   ├── features
│   │   └── alarm
│   │       ├── data
│   │       │   └── alarm_model.dart       # Alarm model definition
│   │       ├── domain
│   │       │   └── alarm_entity.dart      # Domain model for alarms
│   │       ├── presentation
│   │       │   ├── alarm_screen.dart       # UI for displaying alarms
│   │       │   └── widgets
│   │       │       └── alarm_tile.dart     # Widget for individual alarm
│   │       └── alarm_repository.dart       # Data operations for alarms
│   └── routes
│       └── app_routes.dart        # Application routing
├── pubspec.yaml                   # Flutter configuration and dependencies
└── README.md                      # Project documentation
```

## Setup Instructions
1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd flutter_alarm_app
   ```
3. Install the dependencies:
   ```
   flutter pub get
   ```
4. Run the application:
   ```
   flutter run
   ```

## Usage
- Open the app to view the list of alarms.
- Use the toggle switches to enable or disable alarms.
- Add or edit alarms through the provided UI.

## Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.