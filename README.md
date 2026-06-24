# Chameleon 🦎

A premium local pass-and-play party game of deduction, deception, and vocabulary. Built with Flutter.

## 🌟 Features

- **Local Multiplayer Mode**: Support for 3 to 20 players on a single device.
- **Rich Word Database**: Over 1,000 secret words across multiple categories with contextual clues.
- **Customizable Players**: Easily add, edit, and manage players before starting the game.
- **Interactive 3D Cards**: Immersive card flipping, X/Y 3D rotations, and responsive specular glare reflection effects.
- **Cinematic Animations**: High-fidelity screen transitions and visual effects powered by `flutter_animate`.
- **Dramatic Eliminations**: Unique diagonal laser sword-cut text slicing animation for voted-out players.
- **Accessibility & Compliance**: WCAG AA compliant layout with semantic reader support and 44x44px touch targets.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.0.0 or higher)
- Android SDK (for mobile builds)

### Installation & Run

1. Clone the repository and navigate to the project directory:
   ```bash
   git clone <repository-url>
   cd chameleon
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app in development mode:
   ```bash
   flutter run
   ```

### Building the Android APK

To compile a debug APK for Android:
```bash
flutter build apk --debug
```
The output APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.

## 🎨 Architecture & Customization

- **State Management**: Built on lightweight, reactive logic.
- **Theme**: Dark-themed aesthetic utilizing vibrant gradient flows, custom color variables, and fluid transitions.
- **Sound & Haptics**: Integrated system vibrations to complement key game-loop actions (slashes, clicks, timers).
