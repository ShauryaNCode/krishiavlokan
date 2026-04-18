<div align="center">

```
██╗  ██╗██████╗ ██╗███████╗██╗  ██╗██╗ █████╗ ██╗   ██╗██╗      ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗
██║ ██╔╝██╔══██╗██║██╔════╝██║  ██║██║██╔══██╗██║   ██║██║     ██╔═══██╗██║ ██╔╝██╔══██╗████╗  ██║
█████╔╝ ██████╔╝██║███████╗███████║██║███████║██║   ██║██║     ██║   ██║█████╔╝ ███████║██╔██╗ ██║
██╔═██╗ ██╔══██╗██║╚════██║██╔══██║██║██╔══██║╚██╗ ██╔╝██║     ██║   ██║██╔═██╗ ██╔══██║██║╚██╗██║
██║  ██╗██║  ██║██║███████║██║  ██║██║██║  ██║ ╚████╔╝ ███████╗╚██████╔╝██║  ██╗██║  ██║██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

**KrishiAvlokan App**

*Flutter Frontend for Guided Crop Diagnosis*

*Hackathon Build - April 2026*

---

</div>

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Frontend Architecture](#2-frontend-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Complete File Structure](#4-complete-file-structure)
5. [Quick Start](#5-quick-start)
6. [Diagnosis Flow](#6-diagnosis-flow)
7. [Voice Layer](#7-voice-layer)
8. [Provider and State](#8-provider-and-state)
9. [Screen Map](#9-screen-map)
10. [Navigation](#10-navigation)
11. [Design System](#11-design-system)
12. [Backend Integration](#12-backend-integration)
13. [Platform Permissions](#13-platform-permissions)
14. [Demo Scenarios](#14-demo-scenarios)
15. [Troubleshooting](#15-troubleshooting)
16. [Team Ownership](#16-team-ownership)
17. [Demo Day Checklist](#17-demo-day-checklist)

---

## 1. Project Overview

This folder contains the Flutter client for KrishiAvlokan. The app guides the user through a structured diagnosis journey and surfaces AI-generated crop failure insights in a mobile-friendly flow.

### Frontend goals

- Keep the diagnosis flow simple and guided
- Support manual symptom selection and voice-driven symptom input
- Preserve history, settings, and language preferences locally
- Keep backend integration isolated inside service and voice modules

---

## 2. Frontend Architecture

```text
main.dart
   ↓
Provider tree
   ↓
go_router routes
   ↓
Feature screens
   ↓
DiagnosisProvider
   ↓
services/ + diagnosis voice layer
   ↓
FastAPI backend
```

### Key frontend responsibilities

- Collect crop, location, sowing date, and symptoms
- Manage screen-to-screen diagnosis state
- Trigger diagnosis requests and map responses to UI
- Run Step 4 voice capture and incremental symptom application

---

## 3. Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| UI | Flutter | Mobile application |
| State | Provider | Shared diagnosis and settings state |
| Routing | go_router | Route management |
| Animations | flutter_animate, lottie | Motion and UI polish |
| Voice Prompting | flutter_tts | Spoken prompts in earlier steps |
| Speech UX | speech_to_text, record | Voice listen flow and audio chunk capture |
| Networking | http | Diagnosis and voice API calls |
| Persistence | shared_preferences | Settings and local state |

---

## 4. Complete File Structure

```text
krishiavlokan_app/
│
├── README.md
├── pubspec.yaml
├── android/
├── ios/
└── lib/
    ├── main.dart
    ├── core/
    │   ├── constants/app_constants.dart
    │   └── theme/
    │       ├── app_colors.dart
    │       └── app_theme.dart
    ├── features/
    │   ├── diagnosis/
    │   │   ├── loading_screen.dart
    │   │   ├── steps/
    │   │   │   ├── step1_crop_screen.dart
    │   │   │   ├── step2_location_screen.dart
    │   │   │   ├── step3_sowing_screen.dart
    │   │   │   └── step4_symptoms_screen.dart
    │   │   └── voice/
    │   │       ├── voice_api_service.dart
    │   │       ├── voice_controller.dart
    │   │       └── voice_session_manager.dart
    │   ├── history/history_screen.dart
    │   ├── home/home_screen.dart
    │   ├── language/language_screen.dart
    │   ├── results/results_screen.dart
    │   ├── settings/settings_screen.dart
    │   └── splash/splash_screen.dart
    ├── models/analysis_model.dart
    ├── providers/diagnosis_provider.dart
    ├── routes/app_router.dart
    ├── services/
    │   ├── diagnosis_service.dart
    │   ├── storage_service.dart
    │   ├── symptom_voice_processor.dart
    │   └── voice_service.dart
    └── widgets/shared_widgets.dart
```

---

## 5. Quick Start

### Prerequisites

- Flutter 3.x
- Android Studio or VS Code with Flutter support
- Android emulator, iOS simulator, or physical device

### Install and run

```bash
cd krishiavlokan_app
flutter pub get
flutter run
```

### Useful commands

```bash
flutter clean
flutter pub get
flutter analyze
```

---

## 6. Diagnosis Flow

```text
Splash
  ↓
Language
  ↓
Home
  ↓
Step 1: Crop
  ↓
Step 2: Location
  ↓
Step 3: Sowing Date
  ↓
Step 4: Symptoms
  ↓
Loading
  ↓
Results
  ↓
History
```

### Data collected

- Crop
- State and district
- Coordinates
- Sowing date
- Selected symptoms
- Voice-detected symptoms in Step 4

---

## 7. Voice Layer

The new Step 4 voice system is intentionally modular and lives inside:

```text
lib/features/diagnosis/voice/
```

### Files and roles

| File | Responsibility |
|---|---|
| `voice_session_manager.dart` | Chunk recording, silence detection, session lifecycle |
| `voice_api_service.dart` | Calls `/voice/transcribe` and `/voice/extract` |
| `voice_controller.dart` | Debounces transcript batches and applies symptoms via provider |

### Voice flow

```text
Tap mic
  ↓
Record chunked audio
  ↓
POST /voice/transcribe
  ↓
Batch transcript text
  ↓
POST /voice/extract
  ↓
applyVoiceDetectedSymptoms()
  ↓
UI cards update incrementally
```

---

## 8. Provider and State

Shared diagnosis state is managed in:

```text
lib/providers/diagnosis_provider.dart
```

### Provider responsibilities

- Crop, location, sowing date, and symptom state
- Voice flags for step-based interactions
- Results and status management
- History persistence integration
- Voice-detected symptom tracking for Step 4

### Key Step 4 provider methods

- `startVoiceDetectionSession()`
- `applyVoiceDetectedSymptoms(List<String>)`
- `endVoiceDetectionSession()`
- `stopVoiceCompletely()`

---

## 9. Screen Map

| Screen | File | Purpose |
|---|---|---|
| Splash | `features/splash/splash_screen.dart` | Entry transition |
| Language | `features/language/language_screen.dart` | Language selection |
| Home | `features/home/home_screen.dart` | Start diagnosis |
| Crop Step | `features/diagnosis/steps/step1_crop_screen.dart` | Crop selection |
| Location Step | `features/diagnosis/steps/step2_location_screen.dart` | State and district |
| Sowing Step | `features/diagnosis/steps/step3_sowing_screen.dart` | Date input |
| Symptoms Step | `features/diagnosis/steps/step4_symptoms_screen.dart` | Manual and voice symptom capture |
| Loading | `features/diagnosis/loading_screen.dart` | Request wait state |
| Results | `features/results/results_screen.dart` | Diagnosis output |
| History | `features/history/history_screen.dart` | Past analyses |
| Settings | `features/settings/settings_screen.dart` | Preferences and toggles |

---

## 10. Navigation

Routes are defined in:

```text
lib/routes/app_router.dart
```

### Main navigation chain

```text
/splash
  → /language
  → /home
  → /diagnosis/crop
  → /diagnosis/location
  → /diagnosis/sowing
  → /diagnosis/symptoms
  → /loading
  → /results
  → /history
  → /settings
```

---

## 11. Design System

Core theme files:

```text
lib/core/theme/app_theme.dart
lib/core/theme/app_colors.dart
lib/widgets/shared_widgets.dart
```

### UI principles

- Card-heavy layouts for easy scanning
- Warm agricultural color palette
- Large icons and obvious selected states
- Consistent scaffold and button patterns across diagnosis steps
- Non-invasive voice UI layered into Step 4 instead of separate screens

---

## 12. Backend Integration

The app reads backend settings from:

```text
lib/core/constants/app_constants.dart
```

### Relevant constants

```dart
static const backendBaseUrl = 'http://192.168.0.173:8000';
static const analyzeEndpoint = '$backendBaseUrl/diagnose';
```

The voice module derives:

- `POST /voice/transcribe`
- `POST /voice/extract`

No widget should hardcode backend URLs directly.

---

## 13. Platform Permissions

### Android

`android/app/src/main/AndroidManifest.xml` includes:

- `RECORD_AUDIO`
- `INTERNET`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

### iOS

`ios/Runner/Info.plist` includes:

- `NSMicrophoneUsageDescription`

If you later add iOS location prompts, document them here as well.

---

## 14. Demo Scenarios

### Manual diagnosis demo

```text
Select:
Crop: Wheat
State: Maharashtra
District: Pune
Symptoms: drought + heat
```

### Voice demo

```text
Say:
"patte peele hain aur kale daag bhi hain"
Expected:
nutrient + fungal cards become selected
```

### Pest demo

```text
Say:
"keede patte kha rahe hain"
Expected:
pest gets added without removing existing symptoms
```

---

## 15. Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| Flutter app does not launch | Missing dependencies | Run `flutter pub get` |
| Diagnosis button stays disabled | Symptoms missing or voice still active | Stop voice or select symptoms |
| Voice starts but no symptoms appear | Backend voice API unavailable | Verify backend base URL and `.env` |
| iOS mic prompt missing | Info.plist not updated | Confirm `NSMicrophoneUsageDescription` |
| Android device cannot hit localhost backend | Wrong host | Use LAN IP or `10.0.2.2` for emulator |

---

## 16. Team Ownership

| Area | Owner |
|---|---|
| `lib/features/*` | Frontend |
| `lib/providers/diagnosis_provider.dart` | Frontend integration owner |
| `lib/features/diagnosis/voice/*` | Voice integration owner |
| `lib/services/diagnosis_service.dart` | Frontend-backend integration |
| `lib/core/theme/*` and `lib/widgets/*` | UI layer owner |

---

## 17. Demo Day Checklist

- [ ] `flutter pub get` is clean
- [ ] Backend base URL is correct for the demo network
- [ ] Manual diagnosis flow works end-to-end
- [ ] Voice symptom flow works end-to-end
- [ ] Results screen shows recommendations cleanly
- [ ] History screen still works after multiple runs
- [ ] Microphone permission is granted on the demo device

---

<div align="center">

---

**KrishiAvlokan App** - Mobile diagnosis experience for guided crop analysis and voice-assisted symptom capture.

*Flutter · Provider · go_router · Voice Step 4 Integration · April 2026*

</div>
