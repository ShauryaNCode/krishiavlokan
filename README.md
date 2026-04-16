<div align="center">

```
██╗  ██╗██████╗ ██╗███████╗██╗  ██╗██╗ █████╗ ██╗   ██╗ █████╗ ██╗      ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗
██║ ██╔╝██╔══██╗██║██╔════╝██║  ██║██║██╔══██╗██║   ██║██╔══██╗██║     ██╔═══██╗██║ ██╔╝██╔══██╗████╗  ██║
█████╔╝ ██████╔╝██║███████╗███████║██║███████║██║   ██║███████║██║     ██║   ██║█████╔╝ ███████║██╔██╗ ██║
██╔═██╗ ██╔══██╗██║╚════██║██╔══██║██║██╔══██║██║   ██║██╔══██║██║     ██║   ██║██╔═██╗ ██╔══██║██║╚██╗██║
██║  ██╗██║  ██║██║███████║██║  ██║██║██║  ██║╚██████╔╝██║  ██║███████╗╚██████╔╝██║  ██╗██║  ██║██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

**AI-Assisted Crop Failure Diagnosis System**

*Hackathon Build — April 2026*

---

</div>

## Table of Contents

1. Project Overview
2. System Architecture
3. Tech Stack
4. Complete File Structure
5. Quick Start — Frontend
6. Quick Start — Backend
7. Quick Start — AI Pipeline
8. API Contract
9. AI Pipeline Design
10. Screens and Navigation
11. Design System
12. Connecting Frontend to Backend
13. Demo Scenarios
14. Troubleshooting
15. Team Ownership
16. Demo Day Checklist

---

## 1. Project Overview

KrishiAvalokan is an AI-assisted crop diagnosis application designed to help farmers understand the causes of crop failure through a guided multi-step workflow.

The system combines a Flutter frontend, a FastAPI backend, and a rule-based AI inference pipeline to simulate intelligent agricultural insights.

```
User inputs crop + location + sowing date + symptoms
         ↓
Flutter app sends structured request
         ↓
Backend API processes request
         ↓
AI pipeline evaluates conditions
         ↓
Cause + explanation + recommendations generated
         ↓
Result displayed and stored in history
```

### Key Characteristics

* Step-based guided diagnosis flow
* Rule-based AI inference (mock ML)
* Weather-aware reasoning (simulated)
* Offline-compatible logic
* Full mock-first architecture for stability

---

## 2. System Architecture

```
┌──────────────────────────────────────────────┐
│              FLUTTER FRONTEND                │
│                                              │
│  Splash → Language → Home → Diagnosis Flow   │
│                         ↓                    │
│                  Results Screen              │
│                         ↓                    │
│                     History                  │
│                                              │
└──────────────────────┬───────────────────────┘
                       │  POST /diagnose
                       ↓
┌──────────────────────────────────────────────┐
│               FASTAPI BACKEND                │
│                                              │
│   Request Validation → Route Handling        │
│                        ↓                     │
│                 AI PIPELINE CALL             │
│                        ↓                     │
│              Structured Response             │
└──────────────────────┬───────────────────────┘
                       ↓
┌──────────────────────────────────────────────┐
│                AI PIPELINE                   │
│                                              │
│  Feature Extraction                          │
│  Rule-Based Inference                        │
│  Explanation Generator                       │
│  Recommendation Engine                       │
└──────────────────────────────────────────────┘
```

---

## 3. Tech Stack

| Layer            | Technology    | Purpose              |
| ---------------- | ------------- | -------------------- |
| Frontend         | Flutter 3.x   | Mobile UI            |
| State Management | Provider      | App state            |
| Backend          | FastAPI       | REST API             |
| AI Logic         | Python        | Rule-based inference |
| Data Handling    | Pandas        | Feature processing   |
| Storage          | JSON / Memory | Mock persistence     |

---

## 4. Complete File Structure

```
krishiavalokan/
│
├── krishiavlokan_app/
│   ├── pubspec.yaml
│   └── lib/
│       ├── core/
│       │   ├── constants/
│       │   │   └── app_constants.dart
│       │   └── theme/
│       │       ├── app_colors.dart
│       │       └── app_theme.dart
│       │
│       ├── features/
│       │   ├── diagnosis/
│       │   │   ├── steps/
│       │   │   │   ├── step1_crop_screen.dart
│       │   │   │   ├── step2_location_screen.dart
│       │   │   │   ├── step3_sowing_screen.dart
│       │   │   │   └── step4_symptoms_screen.dart
│       │   │   └── loading_screen.dart
│       │   │
│       │   ├── history/
│       │   │   └── history_screen.dart
│       │   ├── home/
│       │   │   └── home_screen.dart
│       │   ├── language/
│       │   │   └── language_screen.dart
│       │   ├── results/
│       │   │   └── results_screen.dart
│       │   ├── settings/
│       │   │   └── settings_screen.dart
│       │   └── splash/
│       │       └── splash_screen.dart
│       │
│       ├── models/
│       │   └── analysis_model.dart
│       │
│       ├── providers/
│       │   └── diagnosis_provider.dart
│       │
│       ├── routes/
│       │   └── app_router.dart
│       │
│       ├── services/
│       │   ├── diagnosis_service.dart
│       │   └── storage_service.dart
│       │
│       ├── widgets/
│       │   └── shared_widgets.dart
│       │
│       └── main.dart
│
├── backend/
│   ├── main.py
│   ├── routes/
│   │   └── diagnosis.py
│   ├── schemas.py
│   ├── storage.py
│   └── requirements.txt
│
└── ai_pipeline/
    ├── diagnosis_engine.py
    ├── rules/
    │   └── diagnosis_rules.json
    ├── templates/
    │   └── explanation_templates.json
    ├── data/
    │   └── sample_inputs.json
    └── utils/
        └── feature_builder.py
```

---

## 5. Quick Start — Frontend

```bash
cd krishiavlokan_app
flutter pub get
flutter run
```

The app runs fully with mock data.

---

## 6. Quick Start — Backend

```bash
cd backend
pip install fastapi uvicorn pydantic
uvicorn main:app --reload
```

---

## 7. Quick Start — AI Pipeline

```bash
cd ai_pipeline
pip install pandas
python diagnosis_engine.py
```

---

## 8. API Contract

### Endpoint

```
POST /diagnose
```

---

### Request

```json
{
  "crop": "Wheat",
  "state": "Maharashtra",
  "district": "Pune",
  "sowingDate": "2024-06-15",
  "symptoms": ["drought", "heat"],
  "isOffline": false
}
```

---

### Response

```json
{
  "crop": "Wheat",
  "state": "Maharashtra",
  "district": "Pune",
  "sowingDate": "2024-06-15",
  "symptoms": ["drought", "heat"],
  "causeKey": "drought",
  "causeTitle": "Drought Stress",
  "explanation": "Initial rainfall deficit affected crop growth.",
  "weatherPhases": [
    {"label": "Early", "status": "veryLow"},
    {"label": "Mid", "status": "low"},
    {"label": "Late", "status": "normal"}
  ],
  "recommendations": [
    {"title": "Use drought resistant seeds", "detail": "Recommended for dry regions"}
  ],
  "isLimitedAnalysis": false
}
```

---

### Enums

Symptoms:

```
drought
waterlogging
pest
fungal
heat
nutrient
```

Weather:

```
veryLow
low
normal
high
veryHigh
```

---


## 9. AI Pipeline Design

### Steps

1. Input parsing
2. Feature extraction
3. Rule matching
4. Cause scoring
5. Explanation generation
6. Recommendation selection

### Logic Type

* Deterministic rule-based system
* Weighted scoring
* No dependency on trained ML model

---

## 10. Screens and Navigation

```
Splash → Language → Home
                ↓
          Diagnosis Flow (4 steps)
                ↓
            Loading
                ↓
             Results
                ↓
            History
```

---

## 11. Design System

* Material 3
* Card-based layout
* Consistent padding and spacing
* Typography hierarchy for readability

---

## 12. Connecting Frontend to Backend

Update `diagnosis_service.dart`:

```
baseUrl = http://<your-ip>:8000
```

Disable mock mode and connect to backend endpoint.

---

## 13. Demo Scenarios

### Scenario 1

Low rainfall + drought symptom → drought stress

### Scenario 2

Heavy rainfall + waterlogging → waterlogging

### Scenario 3

Mixed symptoms → moderate confidence output

---

## 14. Troubleshooting

| Issue           | Fix                       |
| --------------- | ------------------------- |
| API not working | Ensure backend is running |
| Wrong response  | Check JSON contract       |
| App crash       | Verify provider state     |

---

## 15. Team Ownership

| Area        | Owner    |
| ----------- | -------- |
| Frontend    | You      |
| Backend     | Member 3 |
| AI Pipeline | Member 2 |

---

## 16. Demo Day Checklist

* Backend running
* API connected
* App tested end-to-end
* Offline mode tested
* Demo flow practiced

---

<div align="center">

KrishiAvalokan — Hackathon Prototype

Flutter Frontend · FastAPI Backend · Rule-Based AI Pipeline

</div>
