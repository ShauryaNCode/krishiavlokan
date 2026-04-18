<div align="center">

```
██╗  ██╗██████╗ ██╗███████╗██╗  ██╗██╗ █████╗ ██╗   ██╗██╗      ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗
██║ ██╔╝██╔══██╗██║██╔════╝██║  ██║██║██╔══██╗██║   ██║██║     ██╔═══██╗██║ ██╔╝██╔══██╗████╗  ██║
█████╔╝ ██████╔╝██║███████╗███████║██║███████║██║   ██║██║     ██║   ██║█████╔╝ ███████║██╔██╗ ██║
██╔═██╗ ██╔══██╗██║╚════██║██╔══██║██║██╔══██║╚██╗ ██╔╝██║     ██║   ██║██╔═██╗ ██╔══██║██║╚██╗██║
██║  ██╗██║  ██║██║███████║██║  ██║██║██║  ██║ ╚████╔╝ ███████╗╚██████╔╝██║  ██╗██║  ██║██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

**KrishiAvlokan**

*AI-Powered Crop Diagnosis Platform*

*Hackathon Build - April 2026*

---

</div>

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Complete File Structure](#4-complete-file-structure)
5. [Quick Start - Repository](#5-quick-start---repository)
6. [Quick Start - Flutter App](#6-quick-start---flutter-app)
7. [Quick Start - Backend](#7-quick-start---backend)
8. [Quick Start - AI Pipeline](#8-quick-start---ai-pipeline)
9. [API Contract](#9-api-contract)
10. [Voice Diagnosis Pipeline](#10-voice-diagnosis-pipeline)
11. [Screens and Navigation](#11-screens-and-navigation)
12. [Design System](#12-design-system)
13. [Connecting Frontend to Backend](#13-connecting-frontend-to-backend)
14. [Demo Scenarios](#14-demo-scenarios)
15. [Troubleshooting](#15-troubleshooting)
16. [Team Ownership](#16-team-ownership)
17. [Demo Day Checklist](#17-demo-day-checklist)

---

## 1. Project Overview

KrishiAvlokan is a guided crop diagnosis system built for fast field-level crop failure assessment. It combines a **Flutter mobile app**, a **FastAPI backend**, and a separate **AI pipeline** that reasons over crop, location, sowing date, symptoms, weather anomalies, and now voice-described symptoms.

```text
Farmer selects crop + location + sowing date + symptoms
         ↓
Flutter app builds a structured diagnosis request
         ↓
FastAPI backend validates request and calls AI pipeline
         ↓
Diagnosis engine combines weather + model/rule reasoning
         ↓
Cause, explanation, and recommendations are returned
         ↓
Result is shown in app and stored in history
```

### What makes it different

- Guided 4-step diagnosis flow designed for non-technical users
- Hybrid AI backend with live-weather-aware diagnosis engine
- Voice symptom capture for messy Hindi, Hinglish, and English speech
- Separate voice extraction pipeline with backend-driven processing
- Offline-friendly frontend patterns with persisted settings and history

---

## 2. System Architecture

```text
┌────────────────────────────────────────────────────────────────────┐
│                         FLUTTER FRONTEND                           │
│                                                                    │
│  Splash → Language → Home → Diagnosis Step 1 → Step 2 → Step 3    │
│                                              ↓                     │
│                                      Step 4 Symptoms               │
│                                              ↓                     │
│                                 Manual Select + Voice Input        │
│                                              ↓                     │
│                                      Loading → Results → History   │
└───────────────────────────────┬────────────────────────────────────┘
                                │
                                │ POST /diagnose
                                │ POST /voice/transcribe
                                │ POST /voice/extract
                                ↓
┌────────────────────────────────────────────────────────────────────┐
│                          FASTAPI BACKEND                           │
│                                                                    │
│   Pydantic Validation → Diagnosis Route → AI Pipeline             │
│                   │                           │                    │
│                   └──── Voice Routes ────────┘                    │
│                         /transcribe /extract                      │
└───────────────────────────────┬────────────────────────────────────┘
                                ↓
┌────────────────────────────────────────────────────────────────────┐
│                           AI PIPELINE                              │
│                                                                    │
│   Feature Builder → Live Weather / Model Features → Diagnosis      │
│   Rules + Templates → Explanation Generation → Recommendations     │
│   Voice Symptom Extractor → symptom keys for Step 4                │
└────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | Flutter 3.x | Cross-platform mobile UI |
| State Management | Provider | Shared diagnosis state |
| Routing | go_router | App navigation |
| Voice UX | speech_to_text, flutter_tts, record | Voice prompts, capture, chunk recording |
| HTTP | http | Backend API integration |
| Backend | FastAPI | REST API and route orchestration |
| Validation | Pydantic | Request and response schema validation |
| AI Engine | Python | Diagnosis and voice reasoning |
| Weather + ML | requests, pandas, scikit-learn, XGBoost pickles | Weather-aware diagnosis path |
| LLM Integration | Gemini API | Voice transcription and text extraction fallback/intelligence |

---

## 4. Complete File Structure

```text
KrishiAvalokan/
│
├── README.md
├── TEAM_INTEGRATION_GUIDE.md
├── krishiavlokan_app/
│   ├── README.md
│   ├── pubspec.yaml
│   ├── android/
│   ├── ios/
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── constants/app_constants.dart
│       │   └── theme/
│       ├── features/
│       │   ├── diagnosis/
│       │   │   ├── loading_screen.dart
│       │   │   ├── steps/
│       │   │   │   ├── step1_crop_screen.dart
│       │   │   │   ├── step2_location_screen.dart
│       │   │   │   ├── step3_sowing_screen.dart
│       │   │   │   └── step4_symptoms_screen.dart
│       │   │   └── voice/
│       │   │       ├── voice_api_service.dart
│       │   │       ├── voice_controller.dart
│       │   │       └── voice_session_manager.dart
│       │   ├── history/history_screen.dart
│       │   ├── home/home_screen.dart
│       │   ├── language/language_screen.dart
│       │   ├── results/results_screen.dart
│       │   ├── settings/settings_screen.dart
│       │   └── splash/splash_screen.dart
│       ├── models/analysis_model.dart
│       ├── providers/diagnosis_provider.dart
│       ├── routes/app_router.dart
│       ├── services/
│       │   ├── diagnosis_service.dart
│       │   ├── storage_service.dart
│       │   ├── symptom_voice_processor.dart
│       │   └── voice_service.dart
│       └── widgets/shared_widgets.dart
│
├── backend/
│   ├── README.md
│   ├── main.py
│   ├── schemas.py
│   ├── storage.py
│   ├── data/history.json
│   ├── routes/
│   │   ├── diagnosis.py
│   │   ├── voice.py
│   │   └── __init__.py
│   └── services/
│       ├── voice_service.py
│       └── __init__.py
│
└── ai_pipeline/
    ├── README.md
    ├── AI_NOTES.md
    ├── KrishiAvalokan_Backend_Documentation.md
    ├── diagnosis_engine.py
    ├── voice_symptom_extractor.py
    ├── data/
    ├── models/
    ├── rules/diagnosis_rules.json
    ├── templates/explanation_templates.json
    └── utils/feature_builder.py
```

---

## 5. Quick Start - Repository

### Prerequisites

- Flutter SDK 3.x
- Python 3.10+ recommended
- Android Studio or VS Code for Flutter
- A `.env` file at repo root if using Gemini-backed voice or explanation features

### Clone and inspect

```bash
git clone <your-repo-url>
cd KrishiAvalokan
```

### Recommended reading order

1. Read this root README for the full system view
2. Read `krishiavlokan_app/README.md` for mobile app details
3. Read `backend/README.md` for API and runtime details
4. Read `ai_pipeline/README.md` for diagnosis and voice reasoning internals

---

## 6. Quick Start - Flutter App

```bash
cd krishiavlokan_app
flutter pub get
flutter run
```

The app expects the backend base URL from `lib/core/constants/app_constants.dart`.

---

## 7. Quick Start - Backend

```bash
cd backend
pip install fastapi uvicorn pydantic python-multipart requests pandas scikit-learn xgboost google-generativeai python-dotenv
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Health check:

```bash
curl http://localhost:8000/health
```

---

## 8. Quick Start - AI Pipeline

```bash
cd ai_pipeline
python diagnosis_engine.py
```

The AI pipeline is also used indirectly through the backend routes.

---

## 9. API Contract

### Core diagnosis endpoint

```text
POST /diagnose
Content-Type: application/json
```

### Diagnosis request

```json
{
  "crop": "Wheat",
  "state": "Maharashtra",
  "district": "Pune",
  "sowingDate": "2025-07-01",
  "symptoms": ["drought", "heat"],
  "lat": 18.5204,
  "lon": 73.8567
}
```

### Diagnosis response

```json
{
  "causeKey": "drought",
  "causeTitle": "Drought Stress",
  "confidenceScore": 0.87,
  "explanation": "Pune ke farmer ke liye short Hinglish explanation.",
  "weatherPhases": [],
  "recommendations": [],
  "inputSummary": {},
  "modelDetails": {}
}
```

### Voice endpoints

```text
POST /voice/transcribe
POST /voice/extract
```

`/voice/transcribe` accepts multipart audio and returns:

```json
{
  "transcript": "patte peele ho rahe hain aur kale daag bhi hain"
}
```

`/voice/extract` accepts text and returns:

```json
{
  "symptoms": ["nutrient", "fungal"]
}
```

---

## 10. Voice Diagnosis Pipeline

The Step 4 voice flow is now backend-driven and layered on top of the existing symptom selection UX.

```text
User taps mic
   ↓
VoiceSessionManager records audio in short chunks
   ↓
VoiceApiService sends chunk → POST /voice/transcribe
   ↓
Transcript batch is debounced in VoiceController
   ↓
POST /voice/extract returns structured symptom keys
   ↓
DiagnosisProvider.applyVoiceDetectedSymptoms()
   ↓
Existing Step 4 UI updates without replacing manual choices
```

### Stability goals

- Continuous listening until manual stop or silence timeout
- Incremental symptom adds only
- Duplicate symptom prevention
- Minimal widget logic in Step 4
- No local hardcoded keyword matching inside the widget layer

---

## 11. Screens and Navigation

```text
Splash
  ↓
Language
  ↓
Home
  ↓
Diagnosis Step 1: Crop
  ↓
Diagnosis Step 2: Location
  ↓
Diagnosis Step 3: Sowing Date
  ↓
Diagnosis Step 4: Symptoms + Voice
  ↓
Loading
  ↓
Results
  ↓
History / Settings
```

### Main screens

| Screen | Route responsibility |
|---|---|
| `splash_screen.dart` | App bootstrap and first-run transition |
| `language_screen.dart` | Regional language selection |
| `home_screen.dart` | Entry point into diagnosis flow |
| `step1_crop_screen.dart` | Crop selection |
| `step2_location_screen.dart` | State, district, coordinates |
| `step3_sowing_screen.dart` | Sowing date input |
| `step4_symptoms_screen.dart` | Manual symptom selection + voice input |
| `loading_screen.dart` | Wait state while diagnosis runs |
| `results_screen.dart` | Diagnosis explanation and recommendations |
| `history_screen.dart` | Past analysis records |
| `settings_screen.dart` | Language, voice, and app settings |

---

## 12. Design System

The app uses a clean agricultural UI centered around clarity, large cards, and readable diagnosis summaries.

### Core frontend assets

- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_colors.dart`
- `lib/widgets/shared_widgets.dart`

### Design principles

- Guided step-by-step flow over dense dashboards
- Large tap targets for field use
- Clear state changes for selected symptoms
- Visual emphasis on diagnosis confidence and recommendations
- Voice state surfaced with status bars and badges instead of extra screens

---

## 13. Connecting Frontend to Backend

Update the backend URL in:

```text
krishiavlokan_app/lib/core/constants/app_constants.dart
```

Current constants:

```dart
static const backendBaseUrl = 'http://192.168.0.173:8000';
static const analyzeEndpoint = '$backendBaseUrl/diagnose';
```

Use the right base URL for your device:

| Device type | URL example |
|---|---|
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://localhost:8000` |
| Physical phone | `http://<your-lan-ip>:8000` |

Voice endpoints are derived automatically from `backendBaseUrl`.

---

## 14. Demo Scenarios

### Drought scenario

```text
Crop: Wheat
Location: Pune
Symptoms: drought, heat
Expected: Drought Stress or Heat Stress leaning output
```

### Waterlogging scenario

```text
Crop: Rice
Symptoms: waterlogging
Expected: Waterlogging Stress
```

### Voice demo scenario

```text
Say: "patte peele hain aur kale daag bhi hain"
Expected voice symptoms: nutrient + fungal
```

### Mixed symptom scenario

```text
Say or select: insects eating leaves, holes in leaves
Expected: Pest Pressure
```

---

## 15. Troubleshooting

| Issue | Likely cause | Fix |
|---|---|---|
| App cannot connect to backend | Wrong base URL | Update `backendBaseUrl` for your device |
| `422` from `/diagnose` | Invalid request payload | Check date format and required fields |
| Voice transcript returns empty | Gemini key missing or bad audio | Verify `.env`, microphone permissions, and audio upload |
| Voice extraction returns no symptoms | Transcript too short or unclear | Retry with longer symptom description |
| iOS mic not working | Missing permission prompt | Confirm `NSMicrophoneUsageDescription` exists |
| Backend import errors | Missing Python packages | Install backend dependencies listed above |
| Diagnosis falls back unexpectedly | Live weather/model path failed | Inspect backend logs and `modelDetails.reason` |

---

## 16. Team Ownership

| Area | Owner |
|---|---|
| `krishiavlokan_app/` | Frontend and Flutter integration |
| `backend/` | Backend and API integration |
| `ai_pipeline/` | AI, diagnosis, and voice extraction logic |
| `TEAM_INTEGRATION_GUIDE.md` | Shared contract reference |

### Shared integration rules

- Do not rename API contract fields casually
- Keep diagnosis and voice symptom keys aligned across all layers
- Avoid moving files across app, backend, and AI boundaries
- Prefer additive changes over refactors during hackathon integration

---

## 17. Demo Day Checklist

- [ ] `flutter pub get` succeeds in `krishiavlokan_app`
- [ ] Backend starts cleanly on port `8000`
- [ ] `/health` returns `{"status":"ok"}`
- [ ] Diagnosis works end-to-end with manual symptoms
- [ ] Voice flow works end-to-end in Step 4
- [ ] At least one drought, waterlogging, and pest demo scenario is tested
- [ ] Root `.env` is present for Gemini-backed features
- [ ] Phone and laptop are on the same network if using a physical device

---

<div align="center">

---

**KrishiAvlokan** - Built for hackathon demonstration, rapid iteration, and modular integration.

*Flutter Frontend · FastAPI Backend · AI Diagnosis Pipeline · April 2026*

</div>
